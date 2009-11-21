/*
 * ctok.l - a lex rule for C
 * 
 * Copyright (C) 2004-2005 Akira Tanaka <akr@m17n.org> 
 *     All rights reserved.
 *     This is free software with ABSOLUTELY NO WARRANTY.
 * 
 * You can redistribute it and/or modify it under the terms of 
 * the GNU General Public License version 2.
 */

%option reentrant
%option prefix="langscan_c_lex_"
%option noyywrap
%option nodefault
%s PREPROC
%s CLASSHEAD
%s CLASSHEAD_TRAILER
%s CLASSDECL

escchar [a-z\\'\x22\x3f]
escoct  [0-7]|[0-7][0-7]|[0-3][0-7][0-7]
eschex  x[0-9a-fA-F][0-9a-fA-F]
esccontent {escchar}|{escoct}|{eschex}|\n
escseq  \\{esccontent}
intsuf  [lLuU]*

slash           \/
star            \*
nonstar         [^\*]
nonslashstar    [^\/\*]
commentcontent  {star}+{nonslashstar}{nonstar}*
kandr_comment   {slash}{star}{nonstar}*{commentcontent}*{star}+{slash}
c99_comment     {slash}{slash}[^\n]*
comment         {kandr_comment}|{c99_comment}

id              [A-Za-z_][0-9A-Za-z_]*
whtespace       [ \t\n]|{comment}|{c99_comment}

%{

#include "c.h"

#define YY_EXTRA_TYPE langscan_c_lex_extra_t *

#if YY_NULL != 0
#error "YY_NULL is not 0."
#endif

#define YY_DECL langscan_c_token_t langscan_c_lex_lex(yyscan_t yyscanner)

#define YY_INPUT(buf,result,max_size) \
  if (!yyextra->eof) { \
    result = yyextra->user_read(&(yyextra->user_data), (buf), (max_size)); \
    if (result == 0) \
      yyextra->eof = 1; \
  }

#define UPD update_pos(yyextra, yytext, yyleng)
static void update_pos(langscan_c_lex_extra_t *, char *, int);

#define report(token) \
  do { \
    yyextra->text = yytext; \
    yyextra->leng = yyleng; \
    return langscan_c_##token; \
  } while (0)

#define matched_is(str) (yyleng == sizeof(str)-1 && strncmp(str, yytext, sizeof(str)-1) == 0)

static int ident_length(unsigned char *ptr, int max);

%}

%%
^[ \t]*#                { UPD;
    if (YY_START == INITIAL || yyleng == 1) {
      BEGIN(PREPROC);
      report(preproc_beg);
    }
    else {
      yyless(yyleng-1);
      report(space);
    }
  }
<PREPROC>\\\n           { UPD; report(space); }
<PREPROC>\n             { UPD; BEGIN(INITIAL); report(preproc_end); }

<CLASSHEAD>{id}{whtespace}*[:;\{]       { yyless(ident_length(yytext, yyleng)); UPD; BEGIN(CLASSHEAD_TRAILER); report(classdef); }
<CLASSHEAD,CLASSHEAD_TRAILER>{id} { UPD; report(classref); }
<CLASSHEAD,CLASSHEAD_TRAILER>\{   { UPD; BEGIN(INITIAL); report(punct); }

<CLASSDECL>{id}{whtespace}*;       { yyless(ident_length(yytext, yyleng)); UPD; report(classdecl); }
<CLASSDECL>{id}         { UPD; report(classref); }
<CLASSDECL>;            { UPD; BEGIN(INITIAL); report(punct); }

class/{whtespace}[^\{;]*\{   { UPD; BEGIN(CLASSHEAD); report(ident); }
struct/{whtespace}[^\{;]*\{   { UPD; BEGIN(CLASSHEAD); report(ident); }
class/{whtespace}[^\{;]*;    { UPD; BEGIN(CLASSDECL); report(ident); }
struct/{whtespace}[^\{;]*;    { UPD; BEGIN(CLASSDECL); report(ident); }

[ \t\f\r]+              { UPD; report(space); }
\n                      { UPD; report(space); }
{comment}               { UPD; report(comment); }
\"([^\\\"]|{escseq})*\" { UPD; report(string); }
'([^\\']|{escseq})'     { UPD; report(character); }
0[0-7]*{intsuf}         { UPD; report(integer); }
[1-9][0-9]*{intsuf}     { UPD; report(integer); }
0[xX][0-9A-Fa-f]+{intsuf}       { UPD; report(integer); }
([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([eE][+\-]?[0-9]+)?[fFlL]?       { UPD; report(floating); }
{id}  { UPD; report(ident); }
\+\+|--|<<|>>|<=|>=|==|!=|&&|\|\||\*=|\/=|%=|\+=|-=|<<=|>>=|&=|^=|\|=|->|.      { UPD; report(punct); }

%%

static void update_pos(
  langscan_c_lex_extra_t *extra,
  char *text,
  int leng)
{
  int i, j;
  extra->beg_byteno = extra->end_byteno;
  extra->beg_lineno = extra->end_lineno;
  extra->beg_columnno = extra->end_columnno;
  j = 0;
  for (i = 0; i < leng; i++) {
    if (text[i] == '\n') {
      extra->end_lineno++;
      j = i + 1;
      extra->end_columnno = 0;
    }
  }
  extra->end_columnno += leng - j;
  extra->end_byteno += leng;
}

static int ident_length(unsigned char *ptr, int max)
{
  int len = 0;
  while (0 < max &&
         (('0' <= *ptr && *ptr <= '9') ||
          ('A' <= *ptr && *ptr <= 'Z') ||
          ('a' <= *ptr && *ptr <= 'z') ||
          *ptr == '_')) {
    ptr++;
    len++;
    max--;
  }
  return len;
}

langscan_c_tokenizer_t *langscan_c_make_tokenizer(
  size_t (*user_read)(void **user_data_p, char *buf, size_t maxlen),
  void *user_data)
{
  langscan_c_tokenizer_t *tokenizer;
  langscan_c_lex_extra_t *extra;
  tokenizer = (langscan_c_tokenizer_t *)malloc(sizeof(langscan_c_tokenizer_t));
  if (tokenizer == NULL)
    return NULL;
  extra = (langscan_c_lex_extra_t *)malloc(sizeof(langscan_c_lex_extra_t));
  if (extra == NULL)
    return NULL;
  extra->user_read = user_read;
  extra->user_data = user_data;
  extra->beg_lineno = 1;
  extra->beg_columnno = 0;
  extra->beg_byteno = 0;
  extra->end_lineno = 1;
  extra->end_columnno = 0;
  extra->end_byteno = 0;
  extra->eof = 0;
  tokenizer->extra = extra;
  langscan_c_lex_lex_init(&tokenizer->scanner);
  langscan_c_lex_set_extra(extra, tokenizer->scanner);
  return tokenizer;
}

langscan_c_token_t langscan_c_get_token(langscan_c_tokenizer_t *tokenizer) 
{
  return langscan_c_lex_lex(tokenizer->scanner);
}

void langscan_c_free_tokenizer(langscan_c_tokenizer_t *tokenizer) 
{
  langscan_c_lex_extra_t *extra = langscan_c_lex_get_extra(tokenizer->scanner);
  free((void *)extra);
  langscan_c_lex_lex_destroy(tokenizer->scanner);
  free((void *)tokenizer);
}

user_read_t langscan_c_tokenizer_get_user_read(langscan_c_tokenizer_t *tokenizer)
{
  return tokenizer->extra->user_read;
}

void *langscan_c_tokenizer_get_user_data(langscan_c_tokenizer_t *tokenizer)
{
  return tokenizer->extra->user_data;
}

const char *langscan_c_token_name(langscan_c_token_t token)
{
  static char *token_names[] = {
    "*eof*",
#define LANGSCAN_C_TOKEN(name) #name,
    LANGSCAN_C_TOKEN_LIST
#undef LANGSCAN_C_TOKEN
  };

  return token_names[token];
}

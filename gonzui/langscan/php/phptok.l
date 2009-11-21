/*
 * phptok.l - a lex rule for PHP
 * 
 * Copyright (C) 2005 MATSUNO Tokuhiro <tokuhirom at yahoo.co.jp>
 *     All rights reserved.
 *     This is free software with ABSOLUTELY NO WARRANTY.
 * 
 * You can redistribute it and/or modify it under the terms of 
 * the GNU General Public License version 2.
 */

%option reentrant
%option prefix="langscan_php_lex_"
%option noyywrap
%option nodefault

%x CLASSDEF
%x FUNDEF
%x SCRIPT
%x HEREDOC
%x HEREDOCBEG

newline         (\r\n|\r|\n)
escseq          \\.
string          '([^\\\']|{escseq})*'|\"([^\\\"]|{escseq})*\"
integer         0x[0-9a-fA-F]+|[0-9]+
pointfloat      [0-9]*\.[0-9]+|[0-9]+\.[0-9]*
exponent        [eE][+\-][0-9]+
ident		[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*
floatnumber     {pointfloat}{exponent}?|[0-9]+{exponent}
space		[ \t\r\n]

slash           \/
star            \*
nonstar         [^\*]
nonslashstar    [^\/\*]
commentcontent  {star}+{nonslashstar}{nonstar}*
mullinecomment  {slash}{star}{nonstar}*{commentcontent}*{star}+{slash}

%{

#include "php.h"

#define YY_EXTRA_TYPE langscan_php_lex_extra_t *

#if YY_NULL != 0
#error "YY_NULL is not 0."
#endif

#define YY_DECL langscan_php_token_t langscan_php_lex_lex(yyscan_t yyscanner)

#define YY_INPUT(buf,result,max_size) \
  if (!yyextra->eof) { \
    result = yyextra->user_read(&(yyextra->user_data), (buf), (max_size)); \
    if (result == 0) \
      yyextra->eof = 1; \
  }

#define UPD update_pos(yyextra, yytext, yyleng)
static void update_pos(langscan_php_lex_extra_t *, char *, int);

#define report(token) \
  do { \
    yyextra->text = yytext; \
    yyextra->leng = yyleng; \
    return langscan_php_##token; \
  } while (0)

char *heredocident=NULL;
int heredocidentlen=0;
%}


%%
<INITIAL>"<script"{space}+language{space}*={space}*(php|\"php\"|\'php\'){space}*> { UPD; BEGIN(SCRIPT); report(ident);} 
<INITIAL><%=?|"<?"=?     { UPD; BEGIN(SCRIPT); report(ident);} 
<INITIAL>"<?php"{space}  { UPD; BEGIN(SCRIPT); report(ident);} 
<INITIAL>([^<]|<[^?s%])+ { UPD; report(comment);}
<INITIAL>.               { UPD; report(comment);}

<HEREDOC>{ident};?{newline}  {
	int identlen = strpbrk(yytext, ";\r\n")-yytext;
	if (heredocidentlen==identlen && !strncmp(heredocident, yytext, identlen)) {
		free(heredocident);
		heredocident = NULL;
		BEGIN(SCRIPT);
		yyless(0);
	} else {
		UPD;
		report(string);
	}
}
<HEREDOC>[^\r\n]*{newline} { UPD; report(string);}

<HEREDOCBEG>[ \t]*    { UPD; report(space); }
<HEREDOCBEG>{ident}   { UPD; heredocident=strdup(yytext); heredocidentlen=yyleng; report(ident); }
<HEREDOCBEG>{newline} { UPD;
	if(heredocident) {
		BEGIN(HEREDOC);
		report(space);
	} else { /* invalid here-document */
		BEGIN(SCRIPT);
		report(space);
	}
}

<SCRIPT>class                                  { UPD; BEGIN(CLASSDEF); report(keyword); }
<SCRIPT>function                               { UPD; BEGIN(FUNDEF); report(keyword); }
<CLASSDEF>{ident}                              { UPD; BEGIN(SCRIPT); report(classdef); }
<FUNDEF>{ident}                                { UPD; BEGIN(SCRIPT); report(fundef); }
<SCRIPT><<<                                    { UPD; BEGIN(HEREDOCBEG); report(punct); }
<SCRIPT>::|<>|=>|"++"|--|"||"|&&|AND|XOR|<<|>> { UPD; report(punct); }
<SCRIPT,FUNDEF>[={}+\-;:,.\[\]()|^&/*%!~$<>?@] { UPD; report(punct); }
<SCRIPT>(==|!=|<<|>>)=                         { UPD; report(punct); }
<SCRIPT>[<>+\-!*/.%&|^]=                       { UPD; report(punct); }
<SCRIPT>[?%]>|"</script"{space}*">"            { UPD; BEGIN(INITIAL); report(ident);}
<SCRIPT,CLASSDEF,FUNDEF>{mullinecomment}       { UPD; report(comment);}
<SCRIPT,CLASSDEF,FUNDEF>[ \t\f]+               { UPD; report(space); }
<SCRIPT,CLASSDEF,FUNDEF>{newline}              { UPD; report(space); }
<SCRIPT,CLASSDEF,FUNDEF>(#|"//")([^?%\r\n]|[?%][^>])*{newline}? { UPD; report(comment); }
<SCRIPT>{string}                     { UPD; report(string); }
<SCRIPT>{integer}                    { UPD; report(integer); }
<SCRIPT>{floatnumber}                { UPD; report(floating); }
<SCRIPT>{ident}{space}*\(            { yyless(strpbrk(yytext, " \t\b\f\r\n(")-yytext); UPD; report(funcall); }
<SCRIPT>\$?{ident}                   { UPD; report(ident); }
<SCRIPT,HEREDOCBEG,FUNDEF,CLASSDEF>. { UPD; fprintf(stderr, "Token Error : %s\n", yytext); report(punct); }

%%

static void update_pos(
  langscan_php_lex_extra_t *extra,
  char *text,
  int leng)
{
  int i, j;
  extra->beg_byteno = extra->end_byteno;
  extra->beg_lineno = extra->end_lineno;
  extra->beg_columnno = extra->end_columnno;
  j = 0;
  for (i = 0; i < leng; i++) {
    if (text[i] == '\r' || (i == 0 || text[i - 1] != '\r') && text[i] == '\n') {
      extra->end_lineno++;
      j = i + 1;
      extra->end_columnno = 0;
    }
  }
  extra->end_columnno += leng - j;
  extra->end_byteno += leng;
}

langscan_php_tokenizer_t *langscan_php_make_tokenizer(
  size_t (*user_read)(void **user_data_p, char *buf, size_t maxlen),
  void *user_data)
{
  langscan_php_tokenizer_t *tokenizer;
  langscan_php_lex_extra_t *extra;
  tokenizer = (langscan_php_tokenizer_t *)malloc(sizeof(langscan_php_tokenizer_t));
  if (tokenizer == NULL)
    return NULL;
  extra = (langscan_php_lex_extra_t *)malloc(sizeof(langscan_php_lex_extra_t));
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
  langscan_php_lex_lex_init(&tokenizer->scanner);
  langscan_php_lex_set_extra(extra, tokenizer->scanner);
  return tokenizer;
}

langscan_php_token_t langscan_php_get_token(langscan_php_tokenizer_t *tokenizer) 
{
  return langscan_php_lex_lex(tokenizer->scanner);
}

void langscan_php_free_tokenizer(langscan_php_tokenizer_t *tokenizer) 
{
  langscan_php_lex_extra_t *extra = langscan_php_lex_get_extra(tokenizer->scanner);
  free((void *)extra);
  langscan_php_lex_lex_destroy(tokenizer->scanner);
  free((void *)tokenizer);
  free(heredocident);
}

user_read_t langscan_php_tokenizer_get_user_read(langscan_php_tokenizer_t *tokenizer)
{
  return tokenizer->extra->user_read;
}

void *langscan_php_tokenizer_get_user_data(langscan_php_tokenizer_t *tokenizer)
{
  return tokenizer->extra->user_data;
}

const char *langscan_php_token_name(langscan_php_token_t token)
{
  static char *token_names[] = {
    "*eof*",
#define LANGSCAN_PHP_TOKEN(name) #name,
    LANGSCAN_PHP_TOKEN_LIST
#undef LANGSCAN_PHP_TOKEN
  };

  return token_names[token];
}

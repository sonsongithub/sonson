/*
 * pythontok.l - a lex rule for python
 * 
 * Copyright (C) 2005 Yoshinori K. Okuji <okuji@enbug.org>
 *     All rights reserved.
 *     This is free software with ABSOLUTELY NO WARRANTY.
 * 
 * You can redistribute it and/or modify it under the terms of 
 * the GNU General Public License version 2.
 */

%option reentrant
%option prefix="langscan_python_lex_"
%option noyywrap
%option nodefault

newline         \r\n|\r|\n
stringprefix    r|u|ur|R|U|UR|Ur|uR
escseq          \\({newline}|.)
shortstring     '([^\\\n\r']|{escseq})*'|\"([^\\\n\r\"]|{escseq})*\"
longstring      '''('{1,2}[^']|[^\\']|{escseq})*'''|\"\"\"(\"{1,2}[^\"]|[^\\\"]|{escseq})*\"\"\"
string          {stringprefix}?({longstring}|{shortstring})
integer         0[xX][0-9a-fA-F]+|[0-9]+
longinteger     {integer}[lL]
pointfloat      [0-9]*\.[0-9]+|[0-9]+\.
exponent        [eE][+\-][0-9]+
floatnumber     {pointfloat}{exponent}?|[0-9]+{exponent}
imagnumber      {floatnumber}|{integer}[jJ]

%{

#include "python.h"

#define YY_EXTRA_TYPE langscan_python_lex_extra_t *

#if YY_NULL != 0
#error "YY_NULL is not 0."
#endif

#define YY_DECL langscan_python_token_t langscan_python_lex_lex(yyscan_t yyscanner)

#define YY_INPUT(buf,result,max_size) \
  if (!yyextra->eof) { \
    result = yyextra->user_read(&(yyextra->user_data), (buf), (max_size)); \
    if (result == 0) \
      yyextra->eof = 1; \
  }

#define UPD update_pos(yyextra, yytext, yyleng)
static void update_pos(langscan_python_lex_extra_t *, char *, int);

#define report(token) \
  do { \
    yyextra->text = yytext; \
    yyextra->leng = yyleng; \
    return langscan_python_##token; \
  } while (0)

%}

%%
[ \t\f]+              { UPD; report(space); }
{newline}             { UPD; report(space); }
\#.*                   { UPD; report(comment); }
{string}              { UPD; report(string); }
{integer}|{longinteger}  { UPD; report(integer); }
{floatnumber}         { UPD; report(floating); }
{imagnumber}          { UPD; report(imaginary); }
[A-Za-z_][0-9A-Za-z_]*  { UPD; report(ident); }
.                     { UPD; report(punct); }

%%

static void update_pos(
  langscan_python_lex_extra_t *extra,
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

langscan_python_tokenizer_t *langscan_python_make_tokenizer(
  size_t (*user_read)(void **user_data_p, char *buf, size_t maxlen),
  void *user_data)
{
  langscan_python_tokenizer_t *tokenizer;
  langscan_python_lex_extra_t *extra;
  tokenizer = (langscan_python_tokenizer_t *)malloc(sizeof(langscan_python_tokenizer_t));
  if (tokenizer == NULL)
    return NULL;
  extra = (langscan_python_lex_extra_t *)malloc(sizeof(langscan_python_lex_extra_t));
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
  langscan_python_lex_lex_init(&tokenizer->scanner);
  langscan_python_lex_set_extra(extra, tokenizer->scanner);
  return tokenizer;
}

langscan_python_token_t langscan_python_get_token(langscan_python_tokenizer_t *tokenizer) 
{
  return langscan_python_lex_lex(tokenizer->scanner);
}

void langscan_python_free_tokenizer(langscan_python_tokenizer_t *tokenizer) 
{
  langscan_python_lex_extra_t *extra = langscan_python_lex_get_extra(tokenizer->scanner);
  free((void *)extra);
  langscan_python_lex_lex_destroy(tokenizer->scanner);
  free((void *)tokenizer);
}

user_read_t langscan_python_tokenizer_get_user_read(langscan_python_tokenizer_t *tokenizer)
{
  return tokenizer->extra->user_read;
}

void *langscan_python_tokenizer_get_user_data(langscan_python_tokenizer_t *tokenizer)
{
  return tokenizer->extra->user_data;
}

const char *langscan_python_token_name(langscan_python_token_t token)
{
  static char *token_names[] = {
    "*eof*",
#define LANGSCAN_PYTHON_TOKEN(name) #name,
    LANGSCAN_PYTHON_TOKEN_LIST
#undef LANGSCAN_PYTHON_TOKEN
  };

  return token_names[token];
}

/*
 * shtok.l - a lex rule for shell scripts
 * 
 * Copyright (C) 2005 Kenichi Ishibashi <bashi at dream.ie.ariake-nct.ac.jp>
 *     All rights reserved.
 *     This is free software with ABSOLUTELY NO WARRANTY.
 * 
 * You can redistribute it and/or modify it under the terms of 
 * the GNU General Public License version 2.
 */

%option reentrant
%option prefix="langscan_sh_lex_"
%option noyywrap
%option nodefault
%option stack
%s DQUOTE
%s BQUOTE
%s BRACE_SUBST
%s PAREN_SUBST
%s IN_BRACE
%s HEREDOC_DELIMITER
%s HEREDOC

space           [ \t]+
newline         \r\n|\r|\n
escseq          \\({newline}|.)
ident           [0-9A-Za-z_][0-9A-Za-z_\-\.]*
squote          \'[^\']*\'
specialvar      (\$|\#|\*|@|\?|\-|\!|\_)
var_ident       ([A-Za-z_][0-9A-Za-z_]*|[0-9]|{specialvar})

%{

#include "sh.h"

#define YY_EXTRA_TYPE langscan_sh_lex_extra_t *

#if YY_NULL != 0
#error "YY_NULL is not 0."
#endif

#define YY_DECL langscan_sh_token_t langscan_sh_lex_lex(yyscan_t yyscanner)

#define YY_INPUT(buf,result,max_size) \
  if (!yyextra->eof) { \
    result = yyextra->user_read(&(yyextra->user_data), (buf), (max_size)); \
    if (result == 0) \
      yyextra->eof = 1; \
  }

#define UPD update_pos(yyextra, yytext, yyleng)
static void update_pos(langscan_sh_lex_extra_t *, char *, int);

#define report(token) \
  do { \
    yyextra->text = yytext; \
    yyextra->leng = yyleng; \
    return langscan_sh_##token; \
  } while (0)

#define PUSH_STATE(state) yy_push_state(state, yyscanner)
#define POP_STATE yy_pop_state(yyscanner)

static int ident_length(unsigned char *ptr, int max);

static char *heredoc_delimiter;
static enum { HEREDOC_TAB_NO_STRIP, HEREDOC_TAB_STRIP } heredoc_type;
static int set_heredoc_delimiter(unsigned char *ptr, int max);

%}

%%
<INITIAL,IN_BRACE>\<\<\-?                 {
  if (yytext[yyleng - 1] == '-')
    heredoc_type = HEREDOC_TAB_STRIP;
  else
    heredoc_type = HEREDOC_TAB_NO_STRIP;
  UPD;
  PUSH_STATE(HEREDOC_DELIMITER);
  report(punct);
}
<HEREDOC_DELIMITER>[^ \t\r\n].*           {
  int delimiter_leng;
  delimiter_leng = set_heredoc_delimiter(yytext, yyleng);
  if (delimiter_leng == -1) YY_FATAL_ERROR("Can't allocate memory");
  yyless(delimiter_leng);
	PUSH_STATE(HEREDOC);
  UPD;
  report(heredoc_beg);
}
<HEREDOC>^.+                              {
  int sleng;
  sleng = 0;
  if (heredoc_type == HEREDOC_TAB_STRIP) {
    while (yytext[sleng] == ' ' || yytext[sleng] =='\t') {
      sleng++;
      if (sleng >= yyleng) { UPD; report(space); }
    }
  }
  if (strcmp((yytext + sleng), heredoc_delimiter) == 0) { /* end-of-heredoc */
    free(heredoc_delimiter);
		POP_STATE;
		POP_STATE;
    UPD; report(heredoc_end);
  }
  else {
    UPD; report(string);
  }
}
<HEREDOC><<EOF>>                          {
  free(heredoc_delimiter);
  BEGIN(INITIAL);
  UPD; report(string);
}


<INITIAL,BQUOTE,BRACE_SUBST,PAREN_SUBST,IN_BRACE>\"      {
		PUSH_STATE(DQUOTE);
		UPD; report(punct);
}
<DQUOTE>\"                                               {
		POP_STATE;
		UPD; report(punct);
}
<DQUOTE><<EOF>>                       { BEGIN(INITIAL); }
<DQUOTE>([^\"\`\$\\]|{escseq})+       { UPD; report(string); }


<INITIAL,DQUOTE,BRACE_SUBST,PAREN_SUBST,IN_BRACE>\`      {
		PUSH_STATE(BQUOTE);
		UPD; report(punct);
}
<BQUOTE>\`                                               {
		POP_STATE;
		UPD; report(punct);
}
<BQUOTE><<EOF>>  { BEGIN(INITIAL); }


<INITIAL,DQUOTE,BQUOTE,PAREN_SUBST,IN_BRACE>\$\{         {
		PUSH_STATE(BRACE_SUBST);
		UPD; report(punct);
}
<BRACE_SUBST>\}                                          {
		POP_STATE;
		UPD; report(punct);
}
<BRACE_SUBST>{var_ident}             { UPD; report(ident); }
<BRACE_SUBST><<EOF>>                 { BEGIN(INITIAL); }


\{                                                       {
		PUSH_STATE(IN_BRACE);
		UPD; report(punct);
}
<IN_BRACE>\}                                             {
		POP_STATE;
		UPD; report(punct);
}
<IN_BRACE><<EOF>>                    { BEGIN(INITIAL); }


\$?\(                                                    {
		PUSH_STATE(PAREN_SUBST);
		UPD; report(punct);
}
<PAREN_SUBST>\)                                          {
		POP_STATE;
		UPD; report(punct);
}
<PAREN_SUBST><<EOF>>                 { BEGIN(INITIAL); }


<INITIAL,BQUOTE,PAREN_SUBST,IN_BRACE>^\#.*                  { UPD; report(comment); }
<INITIAL,BQUOTE,PAREN_SUBST,IN_BRACE>{space}\#.*            { UPD; report(comment); }
<INITIAL,BQUOTE,BRACE_SUBST,PAREN_SUBST,IN_BRACE>{squote}   { UPD; report(string); }

{space}                              { UPD; report(space); }
{newline}                            { UPD; report(space); }
{ident}[ \t]*\([ \t]*\)              { yyless(ident_length(yytext, yyleng)); UPD; report(fundef); }
{ident}                              { UPD; report(ident); }
\${var_ident}                        { UPD; report(ident); }
\\.                                  { UPD; report(punct); }
>=|<=|!=|\;\;|\<\<\<|&&|\|\||>&|<&   { UPD; report(punct); }
.                                    { UPD; report(punct); }

%%

static void update_pos(
  langscan_sh_lex_extra_t *extra,
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
          *ptr == '_' || *ptr == '-' || *ptr == '.')) {
    ptr++;
    len++;
    max--;
  }
  return len;
}

static int set_heredoc_delimiter(unsigned char *ptr, int max)
{
  char *dst, quote_char;
  int in_quote, len;
  heredoc_delimiter = malloc(max + 1);
  if (heredoc_delimiter == NULL) return -1;
  dst = heredoc_delimiter;
  len = 0;
  in_quote = 0;
  while (len < max) {
    if (in_quote == 0) {  /* unquoted delimiter */
      if (*ptr == '\'' || *ptr == '\"') {
        quote_char = *ptr;
        in_quote = 1;
        ptr++;
        if (++len >= max) break;
        continue;
      }
      if (*ptr == ' ' || *ptr == '\t') break;
      if (*ptr == '\\') {
        ptr++;
        if (++len >= max) break;
      }
    }
    else {                /* quoted delimiter */
      if (*ptr == quote_char) {
        in_quote = 0;
        ptr++;
        if (len++ >= max) break;
        continue;
      }
    }
    *dst++ = *ptr++;
    len++;
  }
  *dst = '\0';
  return len;
}

langscan_sh_tokenizer_t *langscan_sh_make_tokenizer(
  size_t (*user_read)(void **user_data_p, char *buf, size_t maxlen),
  void *user_data)
{
  langscan_sh_tokenizer_t *tokenizer;
  langscan_sh_lex_extra_t *extra;
  tokenizer = (langscan_sh_tokenizer_t *)malloc(sizeof(langscan_sh_tokenizer_t));
  if (tokenizer == NULL)
    return NULL;
  extra = (langscan_sh_lex_extra_t *)malloc(sizeof(langscan_sh_lex_extra_t));
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
  langscan_sh_lex_lex_init(&tokenizer->scanner);
  langscan_sh_lex_set_extra(extra, tokenizer->scanner);
  return tokenizer;
}

langscan_sh_token_t langscan_sh_get_token(langscan_sh_tokenizer_t *tokenizer) 
{
  return langscan_sh_lex_lex(tokenizer->scanner);
}

void langscan_sh_free_tokenizer(langscan_sh_tokenizer_t *tokenizer) 
{
  langscan_sh_lex_extra_t *extra = langscan_sh_lex_get_extra(tokenizer->scanner);
  free((void *)extra);
  langscan_sh_lex_lex_destroy(tokenizer->scanner);
  free((void *)tokenizer);
}

user_read_t langscan_sh_tokenizer_get_user_read(langscan_sh_tokenizer_t *tokenizer)
{
  return tokenizer->extra->user_read;
}

void *langscan_sh_tokenizer_get_user_data(langscan_sh_tokenizer_t *tokenizer)
{
  return tokenizer->extra->user_data;
}

const char *langscan_sh_token_name(langscan_sh_token_t token)
{
  static char *token_names[] = {
    "*eof*",
#define LANGSCAN_SH_TOKEN(name) #name,
    LANGSCAN_SH_TOKEN_LIST
#undef LANGSCAN_SH_TOKEN
  };

  return token_names[token];
}

#ifndef LANGSCAN_LANGNAME_H
#define LANGSCAN_LANGNAME_H

@LANGSCAN_LANGNAME_TOKEN_LIST@

typedef enum {
  langscan_langname_eof = 0,
#define LANGSCAN_LANGNAME_TOKEN(name) langscan_langname_##name,
  LANGSCAN_LANGNAME_TOKEN_LIST
#undef LANGSCAN_LANGNAME_TOKEN
} langscan_langname_token_t;

typedef struct {
  int beg_lineno;
  int beg_columnno;
  int beg_byteno;
  int end_lineno;
  int end_columnno;
  int end_byteno;
  int eof;
  char *text;
  int leng;
  size_t (*user_read)(void **user_data_p, char *buf, size_t maxlen);
  void *user_data;
} langscan_langname_lex_extra_t;

typedef struct langscan_langname_tokenizer_tag {
  langscan_langname_lex_extra_t *extra;
  void *scanner;
} langscan_langname_tokenizer_t;

typedef size_t (*user_read_t)(void **user_data_p, char *buf, size_t maxlen);

langscan_langname_tokenizer_t *langscan_langname_make_tokenizer(user_read_t user_read, void *user_data);
langscan_langname_token_t langscan_langname_get_token(langscan_langname_tokenizer_t *tokenizer);
void langscan_langname_free_tokenizer(langscan_langname_tokenizer_t *tokenizer);

user_read_t langscan_langname_tokenizer_get_user_read(langscan_langname_tokenizer_t *tokenizer);
void *langscan_langname_tokenizer_get_user_data(langscan_langname_tokenizer_t *tokenizer);

const char *langscan_langname_token_name(langscan_langname_token_t token);
#define langscan_langname_curtoken_beg_lineno(tokenizer) ((tokenizer)->extra->beg_lineno)
#define langscan_langname_curtoken_beg_columnno(tokenizer) ((tokenizer)->extra->beg_columnno)
#define langscan_langname_curtoken_beg_byteno(tokenizer) ((tokenizer)->extra->beg_byteno)
#define langscan_langname_curtoken_end_lineno(tokenizer) ((tokenizer)->extra->end_lineno)
#define langscan_langname_curtoken_end_columnno(tokenizer) ((tokenizer)->extra->end_columnno)
#define langscan_langname_curtoken_end_byteno(tokenizer) ((tokenizer)->extra->end_byteno)
#define langscan_langname_curtoken_text(tokenizer) ((tokenizer)->extra->text)
#define langscan_langname_curtoken_leng(tokenizer) ((tokenizer)->extra->leng)

void langscan_langname_extract_functions(langscan_langname_tokenizer_t *);

#endif

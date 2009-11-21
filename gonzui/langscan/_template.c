/* -*- mode: C; indent-tabs-mode: nil; c-basic-offset: 2 c-style: "BSD" -*- */
/*
 * _template.c - a template file for LangScan modules
 * 
 * Copyright (C) 2004-2005 Akira Tanaka <akr@m17n.org> 
 *     All rights reserved.
 *     This is free software with ABSOLUTELY NO WARRANTY.
 * 
 * You can redistribute it and/or modify it under the terms of 
 * the GNU General Public License version 2.
 */


#include <ruby.h>
#include "langname.h"

static VALUE token_symbol_list[
#define LANGSCAN_LANGNAME_TOKEN(token) 1 +
  1 + LANGSCAN_LANGNAME_TOKEN_LIST 0
#undef LANGSCAN_LANGNAME_TOKEN
];

static size_t user_read_str(void **user_data_p, char *buf, size_t maxlen)
{
  VALUE user_str = (VALUE)*user_data_p;
  StringValue(user_str);
  if (!FL_TEST(user_str, ELTS_SHARED)) {
    user_str = rb_str_new3(rb_str_new4(user_str));
    *user_data_p = (void *)user_str;
  }
  if (RSTRING(user_str)->len < maxlen) {
    maxlen = RSTRING(user_str)->len;
  }
  memcpy(buf, RSTRING(user_str)->ptr, maxlen);
  RSTRING(user_str)->ptr += maxlen;
  RSTRING(user_str)->len -= maxlen;
  return maxlen;
}

static void tokenizer_mark(langscan_langname_tokenizer_t *tokenizer)
{
  if (tokenizer == NULL)
    return;
  rb_gc_mark((VALUE)langscan_langname_tokenizer_get_user_data(tokenizer));
}

static void tokenizer_free(langscan_langname_tokenizer_t *tokenizer)
{
  if (tokenizer == NULL)
    return;
  langscan_langname_free_tokenizer(tokenizer);
}

static VALUE tokenizer_s_allocate(VALUE klass)
{
  return Data_Wrap_Struct(klass, tokenizer_mark, tokenizer_free, NULL);
}

static VALUE tokenizer_initialize(VALUE self, VALUE user_data)
{
  VALUE tmp;
  user_read_t user_read;
  langscan_langname_tokenizer_t *tokenizer;
  Data_Get_Struct(self, langscan_langname_tokenizer_t, tokenizer);
  StringValue(user_data);
  user_read = user_read_str;
  user_data = rb_str_new3(rb_str_new4(user_data));
  DATA_PTR(self) = langscan_langname_make_tokenizer(user_read, (void *)user_data);
  return self;
}

static VALUE tokenizer_get_token(VALUE self)
{
  langscan_langname_tokenizer_t *tokenizer;
  langscan_langname_token_t token;
  Data_Get_Struct(self, langscan_langname_tokenizer_t, tokenizer);
  if (tokenizer == NULL) { return Qnil; }
  token = langscan_langname_get_token(tokenizer);
  if (token == langscan_langname_eof) {
    DATA_PTR(self) = NULL;
    langscan_langname_free_tokenizer(tokenizer);
    return Qnil;
  }
  return rb_ary_new3(8,
    token_symbol_list[token],
    rb_str_new(langscan_langname_curtoken_text(tokenizer), langscan_langname_curtoken_leng(tokenizer)),
    INT2NUM(langscan_langname_curtoken_beg_lineno(tokenizer)),
    INT2NUM(langscan_langname_curtoken_beg_columnno(tokenizer)),
    INT2NUM(langscan_langname_curtoken_beg_byteno(tokenizer)),
    INT2NUM(langscan_langname_curtoken_end_lineno(tokenizer)),
    INT2NUM(langscan_langname_curtoken_end_columnno(tokenizer)),
    INT2NUM(langscan_langname_curtoken_end_byteno(tokenizer)));
}

static VALUE tokenizer_close(VALUE self)
{
  langscan_langname_tokenizer_t *tokenizer;
  Data_Get_Struct(self, langscan_langname_tokenizer_t, tokenizer);
  if (tokenizer == NULL) { return Qnil; }
  DATA_PTR(self) = NULL;
  langscan_langname_free_tokenizer(tokenizer);
  return Qnil;
}

void Init_langname()
{
  VALUE LangScan = rb_define_module("LangScan");
  VALUE LangScan_LANGNAME = rb_define_module_under(LangScan, "LangName");
  VALUE Tokenizer = rb_define_class_under(LangScan_LANGNAME, "Tokenizer", rb_cData);
  langscan_langname_token_t token_id;

  token_id = 0;
  token_symbol_list[token_id++] = Qnil;
#define LANGSCAN_LANGNAME_TOKEN(token) token_symbol_list[token_id++] = ID2SYM(rb_intern(#token));
  LANGSCAN_LANGNAME_TOKEN_LIST
#undef LANGSCAN_LANGNAME_TOKEN

  rb_define_alloc_func(Tokenizer, tokenizer_s_allocate);
  rb_define_method(Tokenizer, "initialize", tokenizer_initialize, 1);
  rb_define_method(Tokenizer, "get_token", tokenizer_get_token, 0);
  rb_define_method(Tokenizer, "close", tokenizer_close, 0);
}

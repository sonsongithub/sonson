/*
 * pairmatcher.c - a pair matching parser
 *
 * Copyright (C) 2005 Akira Tanaka <akr@m17n.org> 
 *     All rights reserved.
 *     This is free software with ABSOLUTELY NO WARRANTY.
 * 
 * You can redistribute it and/or modify it under the terms of 
 * the GNU General Public License version 2.
 */

#include <ruby.h>

static ID id_get_token, id_new, id_call;
static VALUE Fragment;

static VALUE
fragment_type(VALUE fragment)
{
  VALUE val;
  Check_Type(fragment, T_STRUCT);
  if (RBASIC(fragment)->klass != Fragment) {
    rb_raise(rb_eTypeError, "not fragment");
  }
  val = RSTRUCT(fragment)->ptr[0];
  Check_Type(val, T_SYMBOL);
  return val;
}

static VALUE
fragment_text(VALUE fragment)
{
  VALUE val;
  Check_Type(fragment, T_STRUCT);
  if (RBASIC(fragment)->klass != Fragment) {
    rb_raise(rb_eTypeError, "not fragment");
  }
  val = RSTRUCT(fragment)->ptr[1];
  StringValue(val);
  return val;
}

static int
fragment_byteno(VALUE fragment)
{
  VALUE val;
  Check_Type(fragment, T_STRUCT);
  if (RBASIC(fragment)->klass != Fragment) {
    rb_raise(rb_eTypeError, "not fragment");
  }
  val = RSTRUCT(fragment)->ptr[3];
  return NUM2INT(val);
}

typedef struct {
  unsigned char before_open_max;
  unsigned char after_open_max;
  unsigned char before_close_max;
  unsigned char after_close_max;
  VALUE pair_defs;
  VALUE intertoken_defs;
  VALUE recent_tokens;
  VALUE pair_stack;
  VALUE closed_pairs;
} pairmatcher_t;

static void pairmatcher_mark(pairmatcher_t *pairmatcher)
{
  if (pairmatcher == NULL)
    return;
  rb_gc_mark(pairmatcher->pair_defs);
  rb_gc_mark(pairmatcher->intertoken_defs);
  rb_gc_mark(pairmatcher->recent_tokens);
  rb_gc_mark(pairmatcher->pair_stack);
  rb_gc_mark(pairmatcher->closed_pairs);
}

static void pairmatcher_free(pairmatcher_t *pairmatcher)
{
  if (pairmatcher == NULL)
    return;
  free((void *)pairmatcher);
}

static VALUE pairmatcher_s_allocate(VALUE klass)
{
  return Data_Wrap_Struct(klass, pairmatcher_mark, pairmatcher_free, NULL);
}

static VALUE pairmatcher_initialize(
    VALUE self,
    VALUE before_open_max,
    VALUE after_open_max,
    VALUE before_close_max,
    VALUE after_close_max)
{
  pairmatcher_t *pairmatcher;

  Data_Get_Struct(self, pairmatcher_t, pairmatcher);
  if (pairmatcher != NULL) { rb_raise(rb_eArgError, "called twice"); }

  pairmatcher = ALLOC(pairmatcher_t);
  pairmatcher->before_open_max = NUM2INT(before_open_max);
  pairmatcher->after_open_max = NUM2INT(after_open_max);
  pairmatcher->before_close_max = NUM2INT(before_close_max);
  pairmatcher->after_close_max = NUM2INT(after_close_max);
  pairmatcher->pair_defs = rb_ary_new();
  //RBASIC(pairmatcher->pair_defs)->klass = 0;
  pairmatcher->intertoken_defs = rb_ary_new();
  //RBASIC(pairmatcher->intertoken_defs)->klass = 0;
  pairmatcher->recent_tokens = rb_ary_new();
  //RBASIC(pairmatcher->recent_tokens)->klass = 0;
  pairmatcher->pair_stack = rb_ary_new();
  //RBASIC(pairmatcher->pair_stack)->klass = 0;
  pairmatcher->closed_pairs = rb_ary_new();
  //RBASIC(pairmatcher->closed_pairs)->klass = 0;
  DATA_PTR(self) = pairmatcher;
  return self;
}

#define GetPM(obj, var) \
  do { \
    Data_Get_Struct((obj), pairmatcher_t, (var)); \
    if ((var) == NULL) { rb_raise(rb_eArgError, "not initialized"); } \
  } while(0)

static VALUE
pairmatcher_get_before_open_max(VALUE self)
{
  pairmatcher_t *pairmatcher;
  GetPM(self, pairmatcher);
  if (pairmatcher == NULL) { rb_raise(rb_eArgError, "not initialized"); }
  return INT2NUM(pairmatcher->before_open_max);
}

static VALUE
pairmatcher_get_after_open_max(VALUE self)
{
  pairmatcher_t *pairmatcher;
  GetPM(self, pairmatcher);
  return INT2NUM(pairmatcher->after_open_max);
}

static VALUE
pairmatcher_get_before_close_max(VALUE self)
{
  pairmatcher_t *pairmatcher;
  GetPM(self, pairmatcher);
  return INT2NUM(pairmatcher->before_close_max);
}

static VALUE
pairmatcher_get_after_close_max(VALUE self)
{
  pairmatcher_t *pairmatcher;
  GetPM(self, pairmatcher);
  return INT2NUM(pairmatcher->after_close_max);
}

static VALUE
pairmatcher_define_pair(VALUE self, VALUE pair_type, VALUE open_type, VALUE open_text, VALUE close_type, VALUE close_text)
{
  pairmatcher_t *pairmatcher;
  VALUE def;
  Check_Type(open_type, T_SYMBOL);
  if (open_text != Qnil) {
    StringValue(open_text);
    open_text = rb_str_new4(open_text);
  }
  Check_Type(close_type, T_SYMBOL);
  if (close_text != Qnil) {
    StringValue(close_text);
    close_text = rb_str_new4(close_text);
  }

  def = rb_ary_new3(5, open_type, open_text, close_type, close_text, pair_type);
  //RBASIC(def)->klass = 0;

  GetPM(self, pairmatcher);
  rb_ary_push(pairmatcher->pair_defs, def);

  return Qnil;
}

static VALUE
pairmatcher_define_intertoken_fragment(VALUE self, VALUE type, VALUE text)
{
  pairmatcher_t *pairmatcher;
  VALUE def;
  Check_Type(type, T_SYMBOL);
  if (text != Qnil) {
    StringValue(text);
    text = rb_str_new4(text);
  }

  def = rb_ary_new3(2, type, text);
  //RBASIC(def)->klass = 0;

  GetPM(self, pairmatcher);
  rb_ary_push(pairmatcher->intertoken_defs, def);

  return Qnil;
}

static VALUE
get_token(VALUE tokenizer)
{
  return rb_funcall(tokenizer, id_get_token, 0);
}

static VALUE
open_token_p(pairmatcher_t *pairmatcher, VALUE token)
{
  int i;
  VALUE type = fragment_type(token);
  VALUE text = fragment_text(token);
  for (i = 0; i < RARRAY(pairmatcher->pair_defs)->len; i++) {
    VALUE def = RARRAY(pairmatcher->pair_defs)->ptr[i];
    VALUE open_type = RARRAY(def)->ptr[0];
    VALUE open_text = RARRAY(def)->ptr[1];
    if (open_type == Qnil || open_type == type) {
      if (open_text == Qnil || rb_str_cmp(open_text, text) == 0) {
        return def;
      }
    }
  }
  return Qfalse;
}

static VALUE
close_token_p(pairmatcher_t *pairmatcher, VALUE token)
{
  int i;
  VALUE type = fragment_type(token);
  VALUE text = fragment_text(token);
  for (i = 0; i < RARRAY(pairmatcher->pair_defs)->len; i++) {
    VALUE def = RARRAY(pairmatcher->pair_defs)->ptr[i];
    VALUE close_type = RARRAY(def)->ptr[2];
    VALUE close_text = RARRAY(def)->ptr[3];
    if (close_type == Qnil || close_type == type) {
      if (close_text == Qnil || rb_str_cmp(close_text, text) == 0) {
        return def;
      }
    }
  }
  return Qfalse;
}

#define pair_get_pair_def(pair) (RSTRUCT(pair)->ptr[0])
#define pair_get_before_open_len(pair) FIX2INT(RSTRUCT(pair)->ptr[1])
#define pair_get_around_open_tokens(pair) (RSTRUCT(pair)->ptr[2])
#define pair_get_before_close_len(pair) FIX2INT(RSTRUCT(pair)->ptr[3])
#define pair_get_around_close_tokens(pair) (RSTRUCT(pair)->ptr[4])
#define pair_get_outer(pair) (RSTRUCT(pair)->ptr[5])
#define pair_set_pair_def(pair, val) (RSTRUCT(pair)->ptr[0] = (val))
#define pair_set_before_open_len(pair, len) (RSTRUCT(pair)->ptr[1] = INT2FIX(len))
#define pair_set_around_open_tokens(pair, val) (RSTRUCT(pair)->ptr[2] = (val))
#define pair_set_before_close_len(pair, len) (RSTRUCT(pair)->ptr[3] = INT2FIX(len))
#define pair_set_around_close_tokens(pair, val) (RSTRUCT(pair)->ptr[4] = (val))

#define pair_get_after_open_len(pair) (RARRAY(pair_get_around_open_tokens(pair))->len-pair_get_before_open_len(pair)-1)
#define pair_get_after_close_len(pair) (RARRAY(pair_get_around_close_tokens(pair))->len-pair_get_before_close_len(pair)-1)

static VALUE Pair;

static VALUE
make_pair(VALUE pair_def, int before_open_len, VALUE around_open_tokens, VALUE outer)
{
  VALUE pair = rb_struct_new(Pair, 
      pair_def,
      INT2FIX(before_open_len),
      around_open_tokens,
      Qnil,
      Qnil,
      outer);
  return pair;
}

static int
concat_recent_tokens(pairmatcher_t *pm, int max, VALUE ary)
{
  if (RARRAY(pm->recent_tokens)->len <= max) {
    MEMCPY(RARRAY(ary)->ptr+RARRAY(ary)->len,
           RARRAY(pm->recent_tokens)->ptr,
           VALUE, RARRAY(pm->recent_tokens)->len);
    RARRAY(ary)->len += RARRAY(pm->recent_tokens)->len;
    return RARRAY(pm->recent_tokens)->len;
  }
  else {
    MEMCPY(RARRAY(ary)->ptr+RARRAY(ary)->len,
           RARRAY(pm->recent_tokens)->ptr +
           RARRAY(pm->recent_tokens)->len - max,
           VALUE, max);
    RARRAY(ary)->len += max;
    return max;
  }
}

static void
put_open_token(pairmatcher_t *pm, VALUE open_token, VALUE pair_def)
{
  int before_open_len, stack_len;
  VALUE pair;
  VALUE around_open_tokens;
  around_open_tokens = rb_ary_new2(pm->before_open_max+1+pm->after_open_max);
  before_open_len = concat_recent_tokens(pm, pm->before_open_max, around_open_tokens);
  rb_ary_push(around_open_tokens, open_token);
  stack_len = RARRAY(pm->pair_stack)->len;
  pair = make_pair(pair_def, before_open_len, around_open_tokens,
      stack_len ? RARRAY(pm->pair_stack)->ptr[stack_len-1] : Qnil);
  rb_ary_push(pm->pair_stack, pair);
}

static int
matching_open_depth(pairmatcher_t *pm, VALUE open_token, VALUE pair_def)
{
  int i;
  for (i = RARRAY(pm->pair_stack)->len - 1; 0 <= i; i--) {
    if (pair_get_pair_def(RARRAY(pm->pair_stack)->ptr[i]) == pair_def) {
      return i;
    }
  }
  return -1;
}

static void
report_token_list_now(pairmatcher_t *pm, VALUE reporter, VALUE token_list, int beg, int len)
{
  while (len) {
    rb_funcall(reporter, id_call, 1, RARRAY(token_list)->ptr[beg]);
    beg++;
    len--;
  }
}
      
static void
report_token_list_open_pair(pairmatcher_t *pm, VALUE reporter, VALUE token_list, int beg, int len)
{
  int i;
  for (i = RARRAY(pm->pair_stack)->len - 1; 0 <= i; i--) {
    VALUE pair = RARRAY(pm->pair_stack)->ptr[i];
    VALUE around_open = pair_get_around_open_tokens(pair);
    int first_byteno = fragment_byteno(RARRAY(around_open)->ptr[0]);
    int last_byteno = fragment_byteno(RARRAY(around_open)->ptr[RARRAY(around_open)->len-1]);
    if (last_byteno < fragment_byteno(RARRAY(token_list)->ptr[beg])) {
      report_token_list_now(pm, reporter, token_list, beg, len);
      return;
    }
    /* last_byteno >= fragment_byteno(RARRAY(token_list)->ptr[beg]) */
    if (fragment_byteno(RARRAY(token_list)->ptr[beg+len-1]) < first_byteno)
      continue;
    /*
     * fragment_byteno(RARRAY(token_list)->ptr[beg]) <= last_byteno
     * first_byteno <= fragment_byteno(RARRAY(token_list)->ptr[beg+len-1])
     */
    if (last_byteno < fragment_byteno(RARRAY(token_list)->ptr[beg+len-1])) {
      int beg2 = beg+len-1;
      int len2 = 1;
      while (beg <= beg2 && last_byteno < fragment_byteno(RARRAY(token_list)->ptr[beg2-1])) {
        beg2--;
        len2++;
      }
      report_token_list_now(pm, reporter, token_list, beg2, len2);
      len -= len2;
    }
    /*
     * first_byteno <= fragment_byteno(RARRAY(token_list)->ptr[beg+len-1]) <= last_byteno
     * fragment_byteno(RARRAY(token_list)->ptr[beg])                       <= last_byteno
     */
    while (0 < len && first_byteno <= fragment_byteno(RARRAY(token_list)->ptr[beg+len-1])) {
      len--;
    }
    if (len == 0)
      return;
  }
  report_token_list_now(pm, reporter, token_list, beg, len);
}

static void
report_token_list_rec_closed_pair(pairmatcher_t *pm, VALUE reporter, VALUE token_list, int beg, int len, int closed_pairs_index)
{
  VALUE pair;
  VALUE around_close, around_open, first, last;
  int first_byteno, last_byteno;
  if (RARRAY(pm->closed_pairs)->len <= closed_pairs_index) {
    report_token_list_open_pair(pm, reporter, token_list, beg, len);
    return;
  }
  pair = RARRAY(pm->closed_pairs)->ptr[closed_pairs_index];
  if (pair == Qnil) {
    report_token_list_rec_closed_pair(pm, reporter, token_list, beg, len, closed_pairs_index+1);
    return;
  }
  around_close = pair_get_around_close_tokens(pair);
  first = RARRAY(around_close)->ptr[0];
  first_byteno = fragment_byteno(first);
  while (0 < len && first_byteno <= fragment_byteno(RARRAY(token_list)->ptr[beg+len-1]))
    len--;
  if (len == 0)
    return;
  around_open = pair_get_around_open_tokens(pair);
  first = RARRAY(around_open)->ptr[0];
  first_byteno = fragment_byteno(first);
  last = RARRAY(around_open)->ptr[RARRAY(around_open)->len-1];
  last_byteno = fragment_byteno(last);
  if (last_byteno < fragment_byteno(RARRAY(token_list)->ptr[beg]) ||
      fragment_byteno(RARRAY(token_list)->ptr[beg+len-1]) < first_byteno) {
    report_token_list_rec_closed_pair(pm, reporter, token_list, beg, len, closed_pairs_index+1);
  }
  else if (first_byteno <= fragment_byteno(RARRAY(token_list)->ptr[beg])) {
    while (0 < len && fragment_byteno(RARRAY(token_list)->ptr[beg]) <= last_byteno) {
      beg++;
      len--;
    }
    if (len)
      report_token_list_rec_closed_pair(pm, reporter, token_list, beg, len, closed_pairs_index+1);
  }
  else if (fragment_byteno(RARRAY(token_list)->ptr[beg+len-1]) <= last_byteno) {
    while (0 < len && first_byteno <= fragment_byteno(RARRAY(token_list)->ptr[beg+len-1]))
      len--;
    if (len)
      report_token_list_rec_closed_pair(pm, reporter, token_list, beg, len, closed_pairs_index+1);
  }
  else {
    int beg1, len1;
    int beg2, len2;
    beg1 = beg;
    len1 = 1;
    while (len1 < len && fragment_byteno(RARRAY(token_list)->ptr[beg1+len1]) < first_byteno)
      len1++;
    beg2 = beg + len - 1;
    len2 = 1;
    while (beg <= beg2-1 && last_byteno < fragment_byteno(RARRAY(token_list)->ptr[beg2-1])) {
      beg2--;
      len2++;
    }
    report_token_list_rec_closed_pair(pm, reporter, token_list, beg1, len1, closed_pairs_index+1);
    report_token_list_rec_closed_pair(pm, reporter, token_list, beg2, len2, closed_pairs_index+1);
  }
}

static void
report_token_list(pairmatcher_t *pm, VALUE token_list, int beg, int len, VALUE reporter)
{
  if (len < 0)
    len = RARRAY(token_list)->len - beg;
  if (len == 0)
    return;
  if (RARRAY(pm->recent_tokens)->len != 0) {
    int first_byteno = fragment_byteno(RARRAY(pm->recent_tokens)->ptr[0]);
    if (first_byteno <= fragment_byteno(RARRAY(token_list)->ptr[0]))
      return;
    while (0 < len && first_byteno <= fragment_byteno(RARRAY(token_list)->ptr[beg+len-1]))
      len--;
  }
  report_token_list_rec_closed_pair(pm, reporter, token_list, beg, len, 0);
}

static void
discard_unmatched_pair(pairmatcher_t *pm, VALUE reporter)
{
  VALUE pair = RARRAY(pm->pair_stack)->ptr[--RARRAY(pm->pair_stack)->len];
  report_token_list(pm, pair_get_around_open_tokens(pair), 0, -1, reporter);
}

static void
put_close_token(pairmatcher_t *pm, VALUE close_token, VALUE pair_def, int depth, VALUE reporter)
{
  VALUE pair, around_close_tokens;
  int before_close_len;
  while (depth+1 < RARRAY(pm->pair_stack)->len) {
    discard_unmatched_pair(pm, reporter);
  }
  pair = RARRAY(pm->pair_stack)->ptr[--RARRAY(pm->pair_stack)->len];
  around_close_tokens = rb_ary_new2(pm->before_close_max+1+pm->after_close_max);
  before_close_len = concat_recent_tokens(pm, pm->before_close_max, around_close_tokens);
  rb_ary_push(around_close_tokens, close_token);
  pair_set_before_close_len(pair, before_close_len);
  pair_set_around_close_tokens(pair, around_close_tokens);
  rb_ary_push(pm->closed_pairs, pair);
}

static void
add_recent(pairmatcher_t *pm, VALUE reporter, VALUE token)
{
  int max = pm->before_open_max;
  if (max < pm->before_close_max)
    max = pm->before_close_max;
  if (max == 0)
    return;
  if (RARRAY(pm->recent_tokens)->len < max) {
    rb_ary_push(pm->recent_tokens, token);
  }
  else {
    VALUE val = RARRAY(pm->recent_tokens)->ptr[0];
    MEMMOVE(RARRAY(pm->recent_tokens)->ptr,
            RARRAY(pm->recent_tokens)->ptr+1,
            VALUE, max-1);
    RARRAY(pm->recent_tokens)->ptr[max-1] = token;
    report_token_list(pm, rb_ary_new3(1, val), 0, -1, reporter);
  }
}

static void
add_after_open(pairmatcher_t *pm, VALUE token)
{
  int i;
  int max = pm->after_open_max;
  VALUE pair;
  for (i = RARRAY(pm->pair_stack)->len-1; 0 <= i; i--) {
    pair = RARRAY(pm->pair_stack)->ptr[i];
    if (max <= pair_get_after_open_len(pair))
      break;
    rb_ary_push(pair_get_around_open_tokens(pair), token);
  }
  for (i = 0; i < RARRAY(pm->closed_pairs)->len; i++) {
    pair = RARRAY(pm->closed_pairs)->ptr[i];
    if (pair == Qnil)
      continue;
    if (pair_get_after_open_len(pair) < max)
      rb_ary_push(pair_get_around_open_tokens(pair), token);
  }
}

static void
add_after_close(pairmatcher_t *pm, VALUE token)
{
  int i;
  int max = pm->after_close_max;
  VALUE pair;
  for (i = RARRAY(pm->closed_pairs)->len - 1; 0 <= i; i--) {
    pair = RARRAY(pm->closed_pairs)->ptr[i];
    if (pair == Qnil)
      continue;
    if (max <= pair_get_after_close_len(pair))
      break;
    rb_ary_push(pair_get_around_close_tokens(pair), token);
  }
}

static void
discard_matched_pair(pairmatcher_t *pm, VALUE pair, VALUE reporter)
{
  VALUE around_open = pair_get_around_open_tokens(pair);
  VALUE around_close = pair_get_around_close_tokens(pair);
  if (fragment_byteno(RARRAY(around_close)->ptr[0]) <= 
      fragment_byteno(RARRAY(around_open)->ptr[RARRAY(around_open)->len-1])) {
    int len1 = RARRAY(around_open)->len;
    while (0 < len1 && fragment_byteno(RARRAY(around_close)->ptr[0]) <= fragment_byteno(RARRAY(around_open)->ptr[len1-1]))
      len1--;
    if (len1) {
      report_token_list(pm, around_open, 0, len1, reporter);
    }
    report_token_list(pm, around_close, 0, -1, reporter);
  }
  else {
    report_token_list(pm, around_open, 0, -1, reporter);
    report_token_list(pm, around_close, 0, -1, reporter);
  }
}

static VALUE
ary_alloc(void)
{
  NEWOBJ(ary, struct RArray);
  OBJSETUP(ary, rb_cArray, T_ARRAY);

  ary->len = 0;
  ary->ptr = 0;
  ary->aux.capa = 0;

  return (VALUE)ary;
}

static VALUE
ary_subseq(VALUE ary, int beg, int len)
{
  VALUE ret;
  if (len == 0)
    return Qnil;
  ret = ary_alloc();
  FL_SET(ret, ELTS_SHARED);
  RARRAY(ret)->aux.shared = ary;
  RARRAY(ret)->ptr = RARRAY(ary)->ptr + beg;
  RARRAY(ret)->len = len;
  return ret;
}

static void
yield_pair(VALUE pair)
{
  rb_yield(pair);
}

static VALUE
pair_before_open_tokens(VALUE pair)
{
  int before_len;
  VALUE around_open = pair_get_around_open_tokens(pair);
  before_len = pair_get_before_open_len(pair);
  return ary_subseq(around_open, 0, before_len);
}

static VALUE
pair_around_open(VALUE pair, VALUE index)
{
  int before_len;
  int i = NUM2INT(index);
  VALUE around_open = pair_get_around_open_tokens(pair);
  before_len = pair_get_before_open_len(pair);
  if (-before_len <= i && i <= pair_get_after_open_len(pair))
    return rb_ary_entry(around_open, before_len+i);
  else
    return Qnil;
}

static VALUE
pair_open_token(VALUE pair)
{
  int before_len;
  VALUE around_open = pair_get_around_open_tokens(pair);
  before_len = pair_get_before_open_len(pair);
  return rb_ary_entry(around_open, before_len);
}

static VALUE
pair_after_open_tokens(VALUE pair)
{
  int before_len, after_len;
  VALUE around_open = pair_get_around_open_tokens(pair);
  before_len = pair_get_before_open_len(pair);
  after_len = pair_get_after_open_len(pair);
  return ary_subseq(around_open, before_len+1, after_len);
  return ary_subseq(around_open, 0, before_len);
}

static VALUE
pair_before_close_tokens(VALUE pair)
{
  int before_len;
  VALUE around_close = pair_get_around_close_tokens(pair);
  if (around_close == Qnil) return Qnil;
  before_len = pair_get_before_close_len(pair);
  return ary_subseq(around_close, 0, before_len);
}

static VALUE
pair_around_close(VALUE pair, VALUE index)
{
  int before_len;
  int i = NUM2INT(index);
  VALUE around_close = pair_get_around_close_tokens(pair);
  if (around_close == Qnil) return Qnil;
  before_len = pair_get_before_close_len(pair);
  if (-before_len <= i && i <= pair_get_after_close_len(pair))
    return rb_ary_entry(around_close, before_len+i);
  else
    return Qnil;
}

static VALUE
pair_close_token(VALUE pair)
{
  int before_len;
  VALUE around_close = pair_get_around_close_tokens(pair);
  if (around_close == Qnil) return Qnil;
  before_len = pair_get_before_close_len(pair);
  return rb_ary_entry(around_close, before_len);
}

static VALUE
pair_after_close_tokens(VALUE pair)
{
  int before_len, after_len;
  VALUE around_close = pair_get_around_close_tokens(pair);
  if (around_close == Qnil) return Qnil;
  before_len = pair_get_before_close_len(pair);
  after_len = pair_get_after_close_len(pair);
  return ary_subseq(around_close, before_len+1, after_len);
  return ary_subseq(around_close, 0, before_len);
}

static VALUE
pair_before_open_length(VALUE pair)
{
  return INT2FIX(pair_get_before_open_len(pair));
}

static VALUE
pair_after_open_length(VALUE pair)
{
  return INT2FIX(pair_get_after_open_len(pair));
}

static VALUE
pair_before_close_length(VALUE pair)
{
  VALUE around_close = pair_get_around_close_tokens(pair);
  if (around_close == Qnil) return Qnil;
  return INT2FIX(pair_get_before_close_len(pair));
}

static VALUE
pair_after_close_length(VALUE pair)
{
  VALUE around_close = pair_get_around_close_tokens(pair);
  if (around_close == Qnil) return Qnil;
  return INT2FIX(pair_get_after_close_len(pair));
}

static VALUE
pair_pair_type(VALUE pair)
{
  VALUE def = pair_get_pair_def(pair);
  return RARRAY(def)->ptr[4];
}

static void
check_closed_pairs(pairmatcher_t *pm, VALUE reporter)
{
  int i, j;
  int after_open_max = pm->after_open_max;
  int after_close_max = pm->after_close_max;
  VALUE pair;
  for (i = 0; i < RARRAY(pm->closed_pairs)->len; i++) {
    pair = RARRAY(pm->closed_pairs)->ptr[i];
    if (pair == Qnil)
      continue;
    if (pair_get_after_open_len(pair) == after_open_max &&
        pair_get_after_close_len(pair) == after_close_max) {
      RARRAY(pm->closed_pairs)->ptr[i] = Qnil;
      yield_pair(pair);
      discard_matched_pair(pm, pair, reporter);
    }
  }
  j = 0;
  for (i = 0; i < RARRAY(pm->closed_pairs)->len; i++) {
    if (RARRAY(pm->closed_pairs)->ptr[i] != Qnil) {
      RARRAY(pm->closed_pairs)->ptr[j] = RARRAY(pm->closed_pairs)->ptr[i];
      j++;
    }
  }
  RARRAY(pm->closed_pairs)->len = j;
}

static void
put_token(pairmatcher_t *pairmatcher, VALUE token, VALUE reporter)
{
  VALUE pair_def;
  int depth;
  add_after_open(pairmatcher, token);
  add_after_close(pairmatcher, token);
  check_closed_pairs(pairmatcher, reporter);

  if ((pair_def = open_token_p(pairmatcher, token))) {
    put_open_token(pairmatcher, token, pair_def);
  }
  else if ((pair_def = close_token_p(pairmatcher, token)) &&
           0 <= (depth = matching_open_depth(pairmatcher, token, pair_def))) {
    put_close_token(pairmatcher, token, pair_def, depth, reporter);
  }
  add_recent(pairmatcher, reporter, token);
}

static int
intertoken_p(pairmatcher_t *pairmatcher, VALUE token_type)
{
  int i;
  for (i = 0; i < RARRAY(pairmatcher->intertoken_defs)->len; i++) {
    VALUE def = RARRAY(pairmatcher->intertoken_defs)->ptr[i];
    VALUE def_type = RARRAY(def)->ptr[0];
    //VALUE def_text = RARRAY(def)->ptr[1];
    if (def_type == token_type) {
      return 1;
    }
  }
  return 0;
}

static void
finish(pairmatcher_t *pm, VALUE reporter)
{
  int i;
  VALUE pair;
  for (i = 0; i < RARRAY(pm->closed_pairs)->len; i++) {
    pair = RARRAY(pm->closed_pairs)->ptr[i];
    if (pair == Qnil)
      continue;
    RARRAY(pm->closed_pairs)->ptr[i] = Qnil;
    yield_pair(pair);
    discard_matched_pair(pm, pair, reporter);
  }
  while (RARRAY(pm->pair_stack)->len) {
    discard_unmatched_pair(pm, reporter);
  }
  report_token_list_now(pm, reporter, pm->recent_tokens, 0, RARRAY(pm->recent_tokens)->len);
}

static void
parse(pairmatcher_t *pm, VALUE tokenizer, VALUE reporter)
{
  VALUE token_info;
  while ((token_info = get_token(tokenizer)) != Qnil) {
    VALUE token_type, token_text, token_lineno, token_byteno;
    VALUE token;
    Check_Type(token_info, T_ARRAY);
    if (RARRAY(token_info)->len != 8) {
      rb_raise(rb_eArgError, "unexpected token");
    }
    token_type = RARRAY(token_info)->ptr[0];
    token_text = RARRAY(token_info)->ptr[1];
    token_lineno = RARRAY(token_info)->ptr[2];
    token_byteno = RARRAY(token_info)->ptr[4];
    token = rb_funcall(Fragment, id_new, 4, token_type, token_text, token_lineno, token_byteno);
    if (intertoken_p(pm, token_type)) {
      rb_funcall(reporter, id_call, 1, token);
    }
    else {
      put_token(pm, token, reporter);
    }
  }
  finish(pm, reporter);
}

static VALUE
pairmatcher_parse(VALUE self, VALUE tokenizer, VALUE reporter)
{
  pairmatcher_t *pairmatcher;
  GetPM(self, pairmatcher);
  parse(pairmatcher, tokenizer, reporter);

  return Qnil;
}

void Init_pairmatcher(void)
{
  VALUE LangScan = rb_const_get(rb_cObject, rb_intern("LangScan"));
  VALUE PairMatcher = rb_define_class_under(LangScan, "PairMatcher", rb_cData);
  Fragment = rb_const_get(LangScan, rb_intern("Fragment"));
  rb_global_variable(&Fragment);

  id_get_token = rb_intern("get_token");
  id_new = rb_intern("new");
  id_call = rb_intern("call");

  rb_define_alloc_func(PairMatcher, pairmatcher_s_allocate);
  rb_define_method(PairMatcher, "initialize", pairmatcher_initialize, 4);
  //rb_define_method(PairMatcher, "initialize_copy", pairmatcher_initialize_copy, 1);
  rb_define_method(PairMatcher, "define_intertoken_fragment", pairmatcher_define_intertoken_fragment, 2);
  rb_define_method(PairMatcher, "define_pair", pairmatcher_define_pair, 5);
  rb_define_method(PairMatcher, "before_open_max", pairmatcher_get_before_open_max, 0);
  rb_define_method(PairMatcher, "after_open_max", pairmatcher_get_after_open_max, 0);
  rb_define_method(PairMatcher, "before_close_max", pairmatcher_get_before_close_max, 0);
  rb_define_method(PairMatcher, "after_close_max", pairmatcher_get_after_close_max, 0);
  rb_define_method(PairMatcher, "parse", pairmatcher_parse, 2);

  Pair = rb_struct_define("LangScanPair",
      "pair_def",
      "before_open_len",
      "around_open_tokens",
      "before_close_len",
      "around_close_tokens",
      "outer",
      NULL);
  rb_define_method(Pair, "before_open_tokens", pair_before_open_tokens, 0);
  rb_define_method(Pair, "before_open_length", pair_before_open_length, 0);
  rb_define_method(Pair, "around_open", pair_around_open, 1);
  rb_define_method(Pair, "open_token", pair_open_token, 0);
  rb_define_method(Pair, "after_open_tokens", pair_after_open_tokens, 0);
  rb_define_method(Pair, "after_open_length", pair_after_open_length, 0);
  rb_define_method(Pair, "before_close_tokens", pair_before_close_tokens, 0);
  rb_define_method(Pair, "before_close_length", pair_before_close_length, 0);
  rb_define_method(Pair, "around_close", pair_around_close, 1);
  rb_define_method(Pair, "close_token", pair_close_token, 0);
  rb_define_method(Pair, "after_close_tokens", pair_after_close_tokens, 0);
  rb_define_method(Pair, "after_close_length", pair_after_close_length, 0);
  rb_define_method(Pair, "pair_type", pair_pair_type, 0);
}

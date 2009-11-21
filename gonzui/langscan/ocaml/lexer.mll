(*
  camlexer - Lexical Analyzer for Gonzui ocamlsupport

  Copyright (C) 2005 Soutaro Matsumoto <matsumoto@soutaro.com>
      All rights reserved.
      This is free software with ABSOLUTELY NO WARRANTY.

  You can redistribute it and/or modify it under the terms of
  the GNU General Public License version 2.

*)

(* $Id: lexer.mll,v 1.2 2005/05/26 09:15:07 soutaro Exp $ *)

{
exception EOF
    
open Types

let lnum = ref 1
let inc_lnum () =
  begin
    lnum := !lnum+1;
  end

let reset () = 
  lnum := 1

let get_pos lexbuf = 
  let pos = Lexing.lexeme_start_p lexbuf in
  let boff = pos.Lexing.pos_bol in
  let cnum = pos.Lexing.pos_cnum in
    !lnum,boff+cnum

let str_lexbuf = ref (None: (Lexing.lexbuf) option)

}

let newline = ('\n' | '\r' | "\r\n")
let blank = [' ' '\t']
let letter = ['a'-'z' 'A'-'Z']
let num = ['0'-'9']
let ident = (letter | '_') (letter | num | '_' | '\'')*
let int_lit =
    (('-')? num (num | '_')*) 
  | (('-')? ("0x"|"0X") (num | ['A'-'F'] ['a'-'f']) (num | ['A'-'F'] ['a'-'f'] | '_')*)
  | (('-')? ("0o"|"0O") (['0'-'7']) (['0'-'7'] | '_')*)
  | (('-')? ("0b"|"0B") (['0'-'1']) (['0'-'1'] | '_')*)
let float_lit =
  ('-')? num (num | '_')* ('.' (num | '_')*)? (("e"|"E") ('+'|'-')? num (num | '_')*)?
let regular_char = [^ '\'']
let escape_sequence = 
    '\\' ['\\' '\"' '\'' 'n' 't' 'b' 'r']
  | '\\' num num num
  | "\\x" (num | ['A'-'F'] | ['a'-'f']) (num | ['A'-'F'] | ['a'-'f'])
let char_lit = 
    '\'' regular_char '\''
  | '\'' escape_sequence '\''
let label = ['a'-'z'] (letter | num | '_' | '\'')*
let operator_char =  ['!' '$' '%' '&' '*' '+' '-' '.' '/' ':' '<' '=' '>' '?' '@' '^' '|' '~']
let infix_symbol = ['=' '<' '>' '@' '|' '&' '+' '-' '*' '/' '$' '%'] operator_char*
let prefix_symbol = ['!' '?' '~'] operator_char*
let keywords = 
  "and" | "as" | "assert" | "asr" | "begin" | "class"
  | "constraint" | "do" | "done" | "downto" | "else" | "end"
  | "exception" | "external" | "false" | "for" | "fun" | "function"
  | "functor" | "if" | "in" | "include" | "inherit" | "initializer"
  | "land" | "lazy" | "let" | "lor" | "lsl" | "lsr"
  | "lxor" | "match" | "method" | "mod" | "module" | "mutable"
  | "new" | "object" | "of" | "open" | "or" | "private"
  | "rec" | "sig" | "struct" | "then" | "to" | "true"
  | "try" | "type" | "val" | "virtual" | "when" | "while" | "with"
let puncts = 
    "!=" | "#" | "&" | "&&" | "\'" | "(" | ")" | "*" | "+" | "," | "-"
  | "-." | "->" | "." | ".." | ":" | "::" | ":=" | ":>" | ";" | ";;" | "<"
  | "<-" | "=" | ">" | ">]" | ">}" | "?" | "??" | "[" | "[<" | "[>" | "[|"
  | "]" | "_" | "`" | "{" | "{<" | "|" | "|]" | "}" | "~"
let camlp4_keywords = "parser"
let camlp4_puncts = 
    "<<" | "<:" | ">>" | "$" | "$$" | "$:"
let ocamlyacc_keywords = 
    "%token" | "%start" | "%type" | "%left" | "%right" | "%nonassoc" | "%prec"
let ocamlyacc_puncts =
    "%{" | "%}" | "%%"
let ocamlyacc_ident = "$" num+
let linenum_directive = '#' ' ' num+
                      | '#' ' ' num+ ' ' '\"' [^ '\"']* '\"'
let built_in_constants = "false" | "true" | "()" | "[]"

rule token = parse
  | newline
      {
	begin
	  inc_lnum();
	  token lexbuf;
	end
      }
  | blank +
      { token lexbuf }
  | linenum_directive {
      (get_pos lexbuf, Ttext, Lexing.lexeme lexbuf);
    }
  | keywords | camlp4_keywords | ocamlyacc_keywords {
      (get_pos lexbuf, Tkeyword, Lexing.lexeme lexbuf)
    }
  | built_in_constants {
      (get_pos lexbuf, Tkeyword, Lexing.lexeme lexbuf)
    }
  | "/*" { 
      let pos = get_pos lexbuf in
	(pos, Tcomment, ocamlyacc_comment 0 "/*" lexbuf);
    }
  | "(*" {
      let pos = get_pos lexbuf in
	(pos, Tcomment, comment 0 "(*" lexbuf)
    }
  | '\"' {
      let pos = get_pos lexbuf in
	(pos, Tstring, string "\"" lexbuf) }
  | puncts | camlp4_puncts | ocamlyacc_puncts {
      (get_pos lexbuf, Tpunct, Lexing.lexeme lexbuf)
    }
  | infix_symbol | prefix_symbol {
      (get_pos lexbuf, Tident, Lexing.lexeme lexbuf)
    }
  | ('~'|'?') label ':' {
      let s = Lexing.lexeme lexbuf in
      let name = String.sub s 1 (String.length s - 2) in
	(get_pos lexbuf, Tident, s)
    }
  | ident | ocamlyacc_ident {
      (get_pos lexbuf, Tident, Lexing.lexeme lexbuf)
    }
  | char_lit {
      (get_pos lexbuf, Tchar, Lexing.lexeme lexbuf)
    }
  | int_lit {
      (get_pos lexbuf, Tint, Lexing.lexeme lexbuf)
    }
  | float_lit {
      (get_pos lexbuf, Tfloat, Lexing.lexeme lexbuf)
    }
  | eof { raise EOF }
  | _
      { token lexbuf }

and comment lv acc = parse 
  | newline { 
      begin
	inc_lnum();
	comment lv (acc ^ "\\o") lexbuf;
      end
    }
  | "(*" {
      comment (lv+1) (acc ^ Lexing.lexeme lexbuf) lexbuf
    }
  | "*)" {
      if lv = 0
      then
	acc ^ "*)"
      else
	comment (lv-1) (acc ^ Lexing.lexeme lexbuf) lexbuf
    }
  | ([^ '\\'] as c1) "\"" {
      let s = string "\"" lexbuf in
	match !str_lexbuf with
	    Some lexbuf -> comment lv (acc ^ Printf.sprintf "%c" c1 ^ s) lexbuf
    }
  | char_lit {
      comment lv (acc ^ Lexing.lexeme lexbuf) lexbuf 
    }
  | _ {
      let s = Lexing.lexeme lexbuf in
	comment lv (acc^s) lexbuf
    }

and string acc = parse
  | newline {
      begin
	inc_lnum();
	string (acc ^ "\\o") lexbuf;
      end
    } 
  | '\"' {
      begin
	str_lexbuf := Some lexbuf;
	acc ^ "\"";
      end
      }
  | escape_sequence {
      string (acc ^ Lexing.lexeme lexbuf) lexbuf
    }
  | char_lit {
      string (acc ^ Lexing.lexeme lexbuf) lexbuf
    }
  | _ {
      let s = Lexing.lexeme lexbuf in
	string (acc^s) lexbuf
    }

and ocamlyacc_comment lv acc = parse 
  | newline { 
      begin
	inc_lnum();
	ocamlyacc_comment lv (acc ^ "\\o") lexbuf;
      end
    }
  | "/*" {
      ocamlyacc_comment (lv+1) (acc ^ Lexing.lexeme lexbuf) lexbuf
    }
  | "*/" {
      if lv = 0
      then
	acc ^ "*/"
      else
	ocamlyacc_comment (lv-1) (acc ^ Lexing.lexeme lexbuf) lexbuf
    }
  | "\"" {
      let s = string "\"" lexbuf in
	match !str_lexbuf with
	    Some lexbuf -> ocamlyacc_comment lv (acc ^ s) lexbuf
    }
  | char_lit {
      ocamlyacc_comment lv (acc ^ Lexing.lexeme lexbuf) lexbuf 
    }
  | _ {
      let s = Lexing.lexeme lexbuf in
	ocamlyacc_comment lv (acc^s) lexbuf
    }


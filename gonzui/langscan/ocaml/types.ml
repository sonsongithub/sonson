(*
  camlexer - Lexical Analyzer for Gonzui ocamlsupport

  Copyright (C) 2005 Soutaro Matsumoto <matsumoto@soutaro.com>
      All rights reserved.
      This is free software with ABSOLUTELY NO WARRANTY.

  You can redistribute it and/or modify it under the terms of
  the GNU General Public License version 2.
*)

(* $Id: types.ml,v 1.2 2005/05/26 09:15:07 soutaro Exp $ *)

type gonzui_type = Tident
		   | Tpunct
		   | Tfuncdef
		   | Ttext
		   | Tstring
		   | Tcomment
		   | Tkeyword
		   | Tchar
		   | Tint
		   | Tfloat

let to_string = function
    Tident -> "ident"
  | Tpunct -> "punct"
  | Tfuncdef -> "funcdef"
  | Ttext -> "text"
  | Tstring -> "string"
  | Tcomment -> "comment"
  | Tkeyword -> "keyword"
  | Tchar -> "character"
  | Tfloat -> "float"
  | Tint -> "integer"


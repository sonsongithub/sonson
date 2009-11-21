(*
  camlexer - Lexical Analyzer for Gonzui ocamlsupport

  Copyright (C) 2005 Soutaro Matsumoto <matsumoto@soutaro.com>
      All rights reserved.
      This is free software with ABSOLUTELY NO WARRANTY.

  You can redistribute it and/or modify it under the terms of
  the GNU General Public License version 2.
*)

(* $Id: camlexer.ml,v 1.2 2005/05/26 09:15:07 soutaro Exp $ *)

let main () = 
  try
    let lexbuf = Lexing.from_channel stdin in
      while true do
	let ((lnum,bnum),tname,lexed_str) = (Lexer.token lexbuf) in
	  begin
	    Printf.printf "%d:%d:%s:%s\n" lnum bnum (Types.to_string tname) lexed_str;
	    flush stdout;
	  end
      done
  with
      Lexer.EOF -> exit 0

let _ = main ()


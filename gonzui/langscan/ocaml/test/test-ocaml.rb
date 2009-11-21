require 'test/unit'
require 'langscan/ocaml'

module LangScan::OCaml
  class TestToken < Test::Unit::TestCase
    def test_int
      t = Tokenizer.new("123")
      f = t.get_token()
      
      assert_equal("123", f.text)
      assert_equal(:integer, f.type)
    end
    
    def test_comment
      t = Tokenizer.new("(* ... *)")
      f = t.get_token()
      assert_equal("(* ... *)", f.text)
      assert_equal(:comment, f.type)
      assert_equal(nil, t.get_token())

      t = Tokenizer.new("(* (* (* *) *) *)")
      f = t.get_token()      
      assert_equal("(* (* (* *) *) *)", f.text)
      assert_equal(:comment, f.type)
      assert_equal(nil, t.get_token())

      t = Tokenizer.new("(*\n*)")
      f = t.get_token()
      assert_equal("(*\n*)", f.text)
      assert_equal(:comment, f.type)
      assert_equal(nil, t.get_token())

      t = Tokenizer.new("(* \" \" *)")
      f = t.get_token()
      assert_equal("(* \" \" *)", f.text)
      assert_equal(:comment, f.type)
      assert_equal(nil, t.get_token())

      t = Tokenizer.new("(* \" *) (* \" *)")
      f = t.get_token()
      assert_equal("(* \" *) (* \" *)", f.text)
      assert_equal(:comment, f.type)
      assert_equal(nil, t.get_token())
    
    end
    
  end

end



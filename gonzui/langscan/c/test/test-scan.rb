require 'test/unit'
require 'langscan/c'

class TestScan < Test::Unit::TestCase
  def assert_yield(recv, meth, *args)
    yielded = false
    recv.__send__(meth, *args) {|*block_args|
      yielded = true
      yield(*block_args)
    }
    assert(yielded, "block not yielded")
  end

  def assert_not_yield(recv, meth, *args)
    yielded = false
    recv.__send__(meth, *args) {|*block_args|
      assert(false, "block yielded")
    }
  end

  def test_token_position
    assert_yield(LangScan::C, :scan, "a(1,2,3)") {|f|
      next if f.type != :funcall
      assert_equal(0, f.beg_byteno)
      #assert_equal(1, f.end_byteno)
    }
  end

  def assert_yield_any(recv, meth, *args)
    recv.__send__(meth, *args) {|*block_args|
      if yield(*block_args)
        assert(true)
        return
      end
    }
    assert(false, "no expected yields")
  end

  def assert_yield_all(recv, meth, *args)
    recv.__send__(meth, *args) {|*block_args|
      if !yield(*block_args)
        assert(false, "unexpected yields")
        return
      end
    }
    assert(true)
  end

  def test_name
    assert_yield_any(LangScan::C, :scan, "a()") {|f|
      f.type == :funcall && f.text == 'a'
    }
  end

  def test_macro
    assert_yield_any(LangScan::C, :scan, "#define a() b") {|f|
      f.type == :fundef
    }
    assert_yield_all(LangScan::C, :scan, "#define a () b") {|f|
      f.type != :fundef
    }
  end

  def test_funtype
    assert_yield_all(LangScan::C, :scan, "int fun(type (*)())") {|f|
      !(f.type == :fundef || f.type == :funcall || f.type == :fundecl) ||
      f.text == 'fun'
    }
  end

  def test_decl
    assert_yield_any(LangScan::C, :scan, "int f();") {|f|
      f.type == :fundecl && f.text == 'f'
    }
  end

  def test_preproc_defined
    assert_yield_all(LangScan::C, :scan, "#if defined(MACRO)\n") {|f|
      !(f.type == :funcall && f.text == 'defined')
    }
  end

  def test_fragment_and_function
    regions = {}
    LangScan::C.scan("a()") {|t|
      f = t
      f = f.name_token if f.respond_to? :name_token
      r = f.beg_byteno
      assert(!regions.include?(r), "duplicate token: #{regions[r].inspect} and #{t.inspect}")
      regions[r] = t
    }
  end

  def test_kandr_portability_fundecl
    src = "void rbuf_initialize PARAMS ((struct rbuf *, int));"
    result = []
    assert_yield(LangScan::C, :scan, src) {|f|
      if f.type == :fundecl && f.text == 'rbuf_initialize'
        result << :rbuf_initialize
      end
      if f.type == :funcall && f.text == 'PARAMS'
        result << :PARAMS
      end
    }
    assert_equal([:rbuf_initialize], result)
  end

  def test_funcdef
    [
      "int fun() {}",
      "int fun(void) {}",
      "int fun(int arg) {}",
      "int fun(arg) int arg; {}",
      "int fun(arg) struct tag *arg; {}",
      "int fun(arg) typedefed_ident arg; {}",
    ].each {|src|
      result = false
      assert_yield(LangScan::C, :scan, src) {|f|
        if f.type == :fundef && f.text == 'fun'
          result = true
        end
      }
      assert(result, src)
    }
  end

  def test_extern_c
    src = 'extern "C" { void fun(); }'
    assert_yield_any(LangScan::C, :scan, src) {|f|
      f.type == :fundecl && f.text == 'fun'
    }
  end

  def test_keyword
    assert_yield_all(LangScan::C, :scan, "int()") {|f|
      f.type != :funcall
    }
  end

  def test_toplevel_comma
    assert_yield(LangScan::C, :scan, ",") {|f|
      assert_equal(LangScan::Fragment, f.class)
      assert_equal(:punct, f.type)
      assert_equal(",", f.text)
    }
  end

  def test_funcall
    result = []
    LangScan::C.scan("f(){g();}") {|f|
      next unless f.type == :fundef || f.type == :funcall
      result << [f.type, f.text]
    }
    assert_equal([[:fundef, 'f'], [:funcall, 'g']], result)
  end

  # C++

  def assert_fragment_type(type, text, src)
    found = false
    LangScan::C.scan(src) {|f|
      if f.text == text
        if found
          raise "token #{text} occurred twice"
        else
          found = true
          assert_equal(type, f.type, "fragment type of #{text}")
        end
      end
    }
    unless found
      raise "token #{text} not found"
    end
  end

  def test_class
    assert_fragment_type(:classdef, 'c', "class c {};")
    assert_fragment_type(:classdef, 'c1', "class c1 : c2 {};")
    assert_fragment_type(:classref, 'c2', "class c1 : c2 {};") 
    assert_fragment_type(:classdecl, 'c3', "class c3;")
  end

  def test_struct
    assert_fragment_type(:classdef, 'c', "struct c {};")
    assert_fragment_type(:classdef, 'c1', "struct c1 : c2 {};")
    assert_fragment_type(:classref, 'c2', "struct c1 : c2 {};") 
    assert_fragment_type(:classdecl, 'c3', "struct c3;")
  end

  def test_struct_2
    src = 'void f(void) { struct s v; return; }'
    assert_fragment_type(:classref, 's', src)
    assert_fragment_type(:keyword, 'return', src)
  end

  def check_scan(src)
    LangScan::C.scan(src) {|f|
      assert_equal(f.text, src[f.beg_byteno...f.end_byteno])
    }
  end

  def test_sharp_in_non_initial_state
    check_scan("struct x\n#;")
  end

  def test_invalid_escape_sequence
    assert_fragment_type(:string, '"\w"', '"\w"')
    assert_fragment_type(:string, '"foo\bar.h"', '#include "foo\bar.h"')
  end

  def test_fundef_returns_user_defined_type
    assert_fragment_type(:fundef, 'foo', 'VALUE foo() {}')
  end
end

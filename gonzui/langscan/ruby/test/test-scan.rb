require 'test/unit'
require 'langscan/ruby'

class TestScan < Test::Unit::TestCase
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

  def test_class
    assert_yield_any(LangScan::Ruby, :scan, "class A\nend") {|f|
      f.type == :classdef && f.text == 'A'
    }
  end

  def test_module
    assert_yield_any(LangScan::Ruby, :scan, "module A\nend") {|f|
      f.type == :moduledef && f.text == 'A'
    }
  end

  def test_symbol
    assert_yield_any(LangScan::Ruby, :scan, ":aaa") {|f|
      f.type == :symbol && f.text == 'aaa'
    }
  end

  def test_const
    assert_yield_any(LangScan::Ruby, :scan, "ABC") {|f|
      f.type == :const && f.text == 'ABC'
    }
  end

end

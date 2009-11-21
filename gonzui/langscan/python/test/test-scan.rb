require 'test/unit'
require 'langscan/python'

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
  
  def test_classdef
    assert_yield_any(LangScan::Python, :scan, "class Bar:\n\tpass") {|f|
      f.type == :classdef && f.text == 'Bar'
    }
  end
  
  def test_fundef
    assert_yield_any(LangScan::Python, :scan, "def Foo:\n\tpass") {|f|
      f.type == :fundef && f.text == 'Foo'
    }
  end
  
  def test_funcall
    assert_yield_any(LangScan::Python, :scan, "hoge()") {|f|
      f.type == :funcall && f.text == 'hoge'
    }
  end
  
  def test_not_funcall
    assert_yield_any(LangScan::Python, :scan, "if (1)") {|f|
      f.type == :keyword && f.text == 'if'
    }
  end

  def test_string
    ['r"""'+"\n"+'hoge'+"\n"+'"""',
     'r"""hoge"""',
     "r'''\nhoge\n'''",
     "r'''hoge'''",
     'r"hoge"',
     "r'hoge'",
     "'hoge'",
     '"hoge"',
     '"hoge\nfuga"'].each do |src|
      assert_yield_any(LangScan::Python, :scan, src) {|f|
        f.type == :string
      }
    end
  end
  
  def test_comment
    [
      '# comment',
      "hoge.fuga() # comment"
    ].each do |src|
      assert_yield_any(LangScan::Python, :scan, src) {|f|
        f.type == :comment
      }
    end
  end
  
  def test_space
    [
      '3 + 2',
      "hoge( fuga)"
    ].each do |src|
      assert_yield_any(LangScan::Python, :scan, src) {|f|
        f.type == :space
      }
    end
  end
end


$LOAD_PATH << "../../.." unless $LOAD_PATH.include?("../../..")
require 'test/unit'
require 'langscan/javascript'

class TestJavaScript < Test::Unit::TestCase
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

  def test_funcall
    assert_yield_any(LangScan::JavaScript, :scan, "a()") {|f|
      f.type == :funcall && f.text == 'a'
    }
  end

  def test_fundef
    assert_yield_any(LangScan::JavaScript, :scan, "a(){}") {|f|
      f.type == :fundef && f.text == 'a'
    }
  end
end

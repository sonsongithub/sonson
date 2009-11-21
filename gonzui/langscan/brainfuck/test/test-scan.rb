require 'test/unit'
require 'langscan/brainfuck'

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
  
  def test_scan
  	assert_yield_all(LangScan::Brainfuck, :scan, "+-.,<>[]") {|f|
		f.type == :ident && f.text.length==1
	}
  	assert_yield_all(LangScan::Brainfuck, :scan, "+++") {|f|
		f.type == :ident && f.text.length==1
	}
  	assert_yield_all(LangScan::Brainfuck, :scan, "I love you") {|f|
		f.type == :comment
	}
  end
end


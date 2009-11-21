$LOAD_PATH << "../../.." unless $LOAD_PATH.include?("../../..")
require 'test/unit'
require 'langscan/rpmspec'

class TestRPMSpec < Test::Unit::TestCase
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

  def test_preamble
    assert_yield_any(LangScan::RPMSpec, :scan, "\nName: gonzui") {|f|
      f.type == :keyword && f.text == 'Name'
    }
  end

  def test_part
    assert_yield_any(LangScan::RPMSpec, :scan, "\n%description devel") {|f|
      f.type == :keyword && f.text == '%description'
    }
  end

  def test_comment
    assert_yield_any(LangScan::RPMSpec, :scan, "\n# comment") {|f|
      f.type == :comment && f.text == '# comment'
    }
  end

  def test_string
    assert_yield_any(LangScan::RPMSpec, :scan, "\nCFLAGS=\"$RPM_OPT_FLAGS -Wall\"") {|f|
      f.type == :string && f.text == '"$RPM_OPT_FLAGS -Wall"'
    }
  end
end

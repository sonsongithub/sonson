require 'test/unit'
require 'langscan/php'

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
    assert_yield_any(LangScan::PHP, :scan, "<?php class foo{} ?>") {|f|
      f.type == :classdef && f.text == 'foo'
    }
  end
  
  def test_fundef
    assert_yield_any(LangScan::PHP, :scan, "<?php function foo1() {} ?>") {|f|
      f.type == :fundef && f.text == 'foo1'
    }
  end

  def test_funcall
    assert_yield_any(LangScan::PHP, :scan, "<?php hoge(); ?>") {|f|
      f.type == :funcall && f.text == 'hoge'
    }
    assert_yield_all(LangScan::PHP, :scan, "<?php if(true); ?>") {|f|
      f.type != :funcall
    }
  end

  def test_string
    [
      "'hoge'",
      '"hoge"',
      '"hoge\nfuga"'
    ].each do |src|
      assert_yield_any(LangScan::PHP, :scan, "<?php #{src} ?>") {|f|
        f.type == :string
      }
    end
  end

  def test_comment
    [
      '# comment',
      "# comment\n",
      "fuga(); # comment\nhoga();",
      "fuga(); # comment",
    ].each do |src|
      assert_yield_any(LangScan::PHP, :scan, "<?php #{src} ?>") {|f|
        f.type == :comment
      }
      assert_yield_any(LangScan::PHP, :scan, "<?php #{src} ?>") {|f|
        f.type == :ident and f.text == "?>"
      }
    end
  end

  def test_space
    [
      '3 + 2',
      "hoge( fuga)"
    ].each do |src|
      assert_yield_any(LangScan::PHP, :scan, "<?php #{src} ?>") {|f|
        f.type == :space
      }
    end
  end

  def test_heredoc
    [
      "echo <<<EOS\r\nfoo\nEOS;\n",
      "echo <<<EOS\r\nE\rEOS;\n",
      "echo <<<EOS\rHOGE;\nEOS\n",
      "echo <<<  EODA\nHGE;\rEODA\n",
      "echo <<<\tE\nF\nE\r",
      "echo <<<EOS\r\nm\rEOS\n",
      "echo <<<EO#{'S'*1000}\r\nEOS;\nEO#{'S'*1000}\n",
    ].each do |src|
      pat = "<?php #{src} ?>"
      assert_yield_any(LangScan::PHP, :scan, pat) {|f|
        f.type == :string
      }
      assert_yield_any(LangScan::PHP, :scan, pat) {|f|
        f.type == :ident and f.text == "?>"
      }
    end
  end

  def test_scriptregion
    [
      '<?php "hoge" ?>',
      '<%= "hoge" %>',
      '<% "hoge" %>',
      '<script language="php"> "hoge" </script>',
      '<? "hoge" ?>',
      '<?= "hoge" ?>',
    ].each do |src|
      assert_yield_any(LangScan::PHP, :scan, src) {|f|
        f.type == :string and f.text == '"hoge"'
      }
    end
  end
end


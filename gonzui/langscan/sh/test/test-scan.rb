require 'test/unit'
require 'langscan/sh'

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
  
  def test_fundef
    [
      {:str => "foo()", :text => "foo"},
      {:str => "foo ()", :text => "foo"},
      {:str => "foo\t( )", :text => "foo"},
      {:str => "foo-bar()", :text => "foo-bar"},
      {:str => "foo.bar()", :text => "foo.bar"},
      {:str => "1234()", :text => "1234"},
      {:str => "function foo", :text => "foo"},
      {:str => "function foo ()", :text => "foo"}
    ].each {|src|
      assert_yield_any(LangScan::Shell, :scan, src[:str]) {|f|
        f.type == :fundef && f.text == src[:text]
      }
    }
  end
  
  def test_string
    [
      '"foo"',
      "'foo'",
      "'foo\nbar'",
      "'foo\"bar'",
      "'foo\\'",
    ].each { |src|
      assert_yield_any(LangScan::Shell, :scan, src) {|f|
        f.type == :string
      }
    }
  end
  
  def test_heredoc
    [
      "<<EOF\nfoo bar\nEOF",
      "<<'EOF'\nfoo bar\nEOF",
      "<<\"EOF\"\nfoo bar\nEOF"
    ].each { |src|
      tokenlist = [:punct, :ident, :space, :string, :space, :ident]
      LangScan::Shell.scan(src) {|t|
        assert_equal(tokenlist.shift, t.type)
      }
    }

    tokenlist = [:punct, :ident, :space, :string, :space, :space, :ident]
    LangScan::Shell.scan("<<-EOF\n\tfoo bar\n\tEOF") {|t|
      assert_equal(tokenlist.shift, t.type)
    }
  end

  def test_doublequote
    [
      {:str => %!"foo"!, :tlist => [:punct, :string, :punct]},
      {:str => %!"$foo"!, :tlist => [:punct, :punct, :ident, :punct]},
      {:str => %!"${foo}bar"!, :tlist => [:punct, :punct, :ident, :punct, :string, :punct]},
      {:str => %!"\\$foo"!, :tlist => [:punct, :string, :punct]},
      {:str => %!"''"!, :tlist => [:punct, :string, :punct]},
      {:str => %!"\\\\"!, :tlist => [:punct, :string, :punct]}
    ].each {|src|
      LangScan::Shell.scan(src[:str]) {|t|
        assert_equal(src[:tlist].shift, t.type)
      }
    }
  end

  def test_variable
    [
      {:str => '$FOO', :text => 'FOO'},
      {:str => '${1}', :text => '1'},
      {:str => '"$FOO"', :text => 'FOO'},
      {:str => '"${FOO}"', :text => 'FOO'},
      {:str => '$#', :text => '#'},
      {:str => '${#}', :text => '#'}
    ].each {|src|
      assert_yield_any(LangScan::Shell, :scan, src[:str]) {|f|
        f.type == :ident && f.text == src[:text]
      }
    }
  end

  def test_comment
    [
      '# comment',
      "foo bar # comment"
    ].each { |src|
      assert_yield_any(LangScan::Shell, :scan, src) {|f|
        f.type == :comment
      }
    }
  end
  
  def test_space
    [
      '\  ',
      "' 'foo bar"
    ].each { |src|
      assert_yield_any(LangScan::Shell, :scan, src) {|f|
        f.type == :space
      }
    }
  end
end

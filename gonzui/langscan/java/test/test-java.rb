require 'test/unit'
require 'langscan/java'

class TestJava < Test::Unit::TestCase
  def test_duplicated
    fs = {}
    LangScan::Java.scan("a()") {|f|
      assert(!fs[f.beg_byteno], "duplicated fragment: #{f.inspect}")
      fs[f.beg_byteno] = f
    }
  end

  def test_fundef
    fragments = scan("int foo() {}")
    fundef = fragments.find_all {|f| f.type == :fundef}
    assert_equal(1, fundef.size, fragments.join("\n"))
    assert_equal("foo", fundef[0].text)
    assert_equal(4, fundef[0].beg_byteno)
    assert_equal(1, fundef[0].beg_lineno)
  end

  def test_fundef
    fragments = scan("int\nfoo()\n{}")
    fundef = fragments.find_all {|f| f.type == :fundef}
    assert_equal(1, fundef.size, fragments.join("\n"))
    assert_equal("foo", fundef[0].text)
    assert_equal(4, fundef[0].beg_byteno)
    assert_equal(2, fundef[0].beg_lineno)
  end

  def test_fundef_arg
    fragments = scan("String getName(Object obj) {}")
    fundef = fragments.find_all {|f| f.type == :fundef}
    assert_equal(1, fundef.size, fragments.join("\n"))
    assert_equal("getName", fundef[0].text)
  end

  def test_fundef_comment
    fragments = scan("String getName(Object obj, /* (ok) */) {}")
    fundef = fragments.find_all {|f| f.type == :fundef}
    assert_equal(1, fundef.size, fragments.join("\n"))
    assert_equal("getName", fundef[0].text)
  end

  def test_fundef_comment2
    fragments = scan("public static final String getName(Object obj, // (ok)\n) {}")
    fundef = fragments.find_all {|f| f.type == :fundef}
    assert_equal(1, fundef.size, fragments.join("\n"))
    assert_equal("getName", fundef[0].text)
    assert_equal(27, fundef[0].beg_byteno)
    assert_equal(1, fundef[0].beg_lineno)
  end

  def test_fundef_throws
    fragments = scan("int foo() throws IOException {}")
    fundef = fragments.find_all {|f| f.type == :fundef}
    assert_equal(1, fundef.size, fragments.join("\n"))
    assert_equal("foo", fundef[0].text)
  end

  def test_fundef_throws2
    fragments = scan("int foo() throws IOException, GonzuiException {}")
    fundef = fragments.find_all {|f| f.type == :fundef}
    assert_equal(1, fundef.size, fragments.join("\n"))
    assert_equal("foo", fundef[0].text)
  end

  def scan(src)
    r = []
    LangScan::Java.scan(src) {|f| r << f }
    return r
  end
  private :scan
end

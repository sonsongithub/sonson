require 'test/unit'
require 'langscan/c'

class TestToken < Test::Unit::TestCase
  def test_comment
    t = LangScan::C::Tokenizer.new("/* * */")
    type, text = t.get_token
    assert_equal("/* * */", text)
    assert_equal(:comment, type)
    assert_equal(nil, t.get_token)

    t = LangScan::C::Tokenizer.new("/* **/")
    type, text = t.get_token
    assert_equal("/* **/", text)
    assert_equal(:comment, type)
    assert_equal(nil, t.get_token)
  end

  def test_c99_comment
    t = LangScan::C::Tokenizer.new("// abc")
    type, text = t.get_token
    assert_equal("// abc", text)
    assert_equal(:comment, type)
    assert_equal(nil, t.get_token)

    t = LangScan::C::Tokenizer.new("//")
    type, text = t.get_token
    assert_equal("//", text)
    assert_equal(:comment, type)
    assert_equal(nil, t.get_token)

    t = LangScan::C::Tokenizer.new("//def \n")
    type, text = t.get_token
    assert_equal("//def ", text)
    assert_equal(:comment, type)
    type, text = t.get_token
    assert_equal("\n", text)
    assert_equal(:space, type)
    assert_equal(nil, t.get_token)
  end
end

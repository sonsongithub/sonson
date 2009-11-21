$LOAD_PATH << "../../.." unless $LOAD_PATH.include?("../../..")
require 'test/unit'
require 'langscan/css'

class TestCSS < Test::Unit::TestCase
  def assert_fragments(expected, code)
    result = []
    LangScan::CSS.scan(code) {|f| result.push(f) }
    fragments = []
    result.each {|fragment|
      type, text = fragment.to_a
      unless type == :punct
	fragments << [type, text]
      end
    }
    assert_equal(expected, fragments)
  end

  def test_sample_css
    code = <<"End"
@import "another.css";

h1 {
  border: 1px solid #ccc;
}

div.day {
  font: medium bold sans-serif;
}
End
    expected = [[:keyword, "@import"],
      [:string, "\"another.css\""],
      [:fundef, "h1"],
      [:keyword, "border"],
      [:ident, "1px"],
      [:ident, "solid"],
      [:ident, "ccc"],
      [:fundef, "div"],
      [:fundef, "day"],
      [:keyword, "font"],
      [:ident, "medium"],
      [:ident, "bold"],
      [:ident, "sans-serif"]]
    assert_fragments(expected, code)
  end

  def test_comment
    assert_fragments([[:comment, "/*c*/"]], "/*c*/")
  end

  def test_string
    assert_fragments([[:keyword, "url"], [:string, "(a)"]], "url(a)")
  end

  def test_keyword
    assert_fragments([[:keyword, "@import"], [:string, "\"a.css\""]],
		     "@import \"a.css\";")
    assert_fragments([[:keyword, "!important"]], "!important")
    assert_fragments([[:keyword, "! important"]], "! important")
  end

  def test_selector
    assert_fragments([[:fundef, "p"]], "p{}")
    assert_fragments([[:fundef, "c"]], ".c{}")
    assert_fragments([[:fundef, "i"]], "#i{}")
    assert_fragments([[:fundef, "p"], [:fundef, "c"]], "p.c{}")
    assert_fragments([[:fundef, "p"], [:fundef, "b"]], "p b{}")
    assert_fragments([[:fundef, "h1"], [:fundef, "h2"]], "h1,h2{}")
    assert_fragments([[:fundef, "p"], [:fundef, "b"]], "p>b{}")
    assert_fragments([[:fundef, "a"], [:fundef, "active"]], "a:active{}")
  end

  def test_property
    assert_fragments([[:fundef, "p"], [:keyword, "b"], [:ident, "a"]],
		     "p{b:a}")
    assert_fragments([[:fundef, "p"], [:keyword, "border"], [:ident, "0"]],
		     "p{border:0;}")
  end
end

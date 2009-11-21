#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui/webapp/xmlformatter'
require 'test-util'
include Gonzui

class XMLFormatterTest < Test::Unit::TestCase
  def test_format_xml
    html = [:html]
    head = [:head, [:title, "foo"]]
    body = [:body, [:h1, [:a, {:href => 'foo<&">.html'}, 'foo<&">']]]
    body.push([:p, "hello"])
    html.push(head)
    html.push(body)
    formatter = XMLFormatter.new
    result = formatter.format(html)
    assert_equal("<html\n><head\n><title\n>foo</title\n></head\n><body\n><h1\n><a href=\"foo&lt;&amp;&quot;&gt;.html\"\n>foo&lt;&amp;&quot;&gt;</a\n></h1\n><p\n>hello</p\n></body\n></html\n>",
                 result)
  end
end

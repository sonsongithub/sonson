#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require "test-util"
require 'langscan'

class TestEasyScanner < Test::Unit::TestCase
  Pattern = [[:comment, "//.*"],
             [:comment, "/\\*", "\\*/"],
             [:string, "\"", "[^\\\\]\""],
             [:integer, "\\d+"],
             [:ident, "\\w+"]]

  Types = %w(
    int char short long float double unsigned signed
  )
  
  Keywords = %w(
    if else switch case break continue return void
  )

  Text = <<"End"
/*
 * sample code
 */
int foo(int x)
{
  // sample comment
  char buff[256];
  sprintf(buff, "x = \\"%d\\"\\n", x);
  return bar(buff);
}  
End

  def test_scan
    expected = [
      [:comment, "/*\n * sample code\n */", 0, 0],
      [:type, "int", 3, 22],
      [:ident, "foo", 3, 26],
      [:type, "int", 3, 30],
      [:ident, "x", 3, 34],
      [:comment, "// sample comment", 5, 41],
      [:type, "char", 6, 61],
      [:ident, "buff", 6, 66],
      [:integer, "256", 6, 71],
      [:ident, "sprintf", 7, 79],
      [:ident, "buff", 7, 87],
      [:string, "\"x = \\\"%d\\\"\\n\"", 7, 93],
      [:ident, "x", 7, 109],
      [:keyword, "return", 8, 115],
      [:ident, "bar", 8, 122],
      [:ident, "buff", 8, 126],
    ]
    result = []
    scanner = LangScan::EasyScanner.new(Pattern, Types, Keywords)
    scanner.scan(Text) {|x| result.push(x)}
    for i in 0..expected.size-1
      assert_equal(expected[i], result[i].to_a)
    end
  end
end

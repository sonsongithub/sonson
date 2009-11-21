#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'

include Gonzui

class QueryTest < Test::Unit::TestCase
  def test_query
    config = Gonzui::Config.new
    [ 
      ['foo bar',           [["foo", nil], ["bar", nil]]],
      ['fundef:foo bar',    [["foo", :fundef], ["bar", nil]]],
      ['"foo bar" baz',     [["foo bar", nil], ["baz", nil]]]
    ].each {|query_string, parts|
      query = SearchQuery.new(config, query_string)
      query.each {|item| 
        assert(item.is_a?(QueryItem))
        part = parts.shift
        if item.phrase?
          assert_equal(part.first, item.value.join(" "))
        else
          assert_equal(part.first, item.value)
        end
        assert_equal(part.last, item.property)
      }
    }
  end
end


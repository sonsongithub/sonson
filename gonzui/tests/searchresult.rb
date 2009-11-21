#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'

include Gonzui

class SearchResultTest < Test::Unit::TestCase
  include TestUtil

  def _test_basic(result)
    i = 0
    result.each {|item| i += 1}
    assert_equal(result.length, i)
    result.length.times {|i| assert(result[i].is_a?(WordInfo)) }

    assert_equal(result[0], result.first)
    assert_equal(result[result.length - 1], result.last)
  end

  def _test_clear(result)
    result.clear
    assert(result.empty?)
    assert(result.length == 0)
  end

  def search(config, key)
    result = SearchResult.new
    DBM.open(config) {|dbm|
      dbm.find_all(key).each {|info| result.push(info) }
    }
    return result
  end

  def test_search_result
    config = Gonzui::Config.new
    make_db(config)

    result = search(config, "foo")
    _test_basic(result)
    _test_clear(result)

    remove_db(config)
  end
end


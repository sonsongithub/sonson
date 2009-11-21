#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'

include Gonzui

class SearcherTest < Test::Unit::TestCase
  include TestUtil

  def test_searcher
    config = Gonzui::Config.new
    make_db(config)
    dbm = DBM.open(config)
    search_query = SearchQuery.new(config, "foo")
    searcher = Searcher.new(dbm, search_query, 100)
    result = searcher.search
    assert(result.is_a?(SearchResult))
    assert(result.length > 0)

    search_query = SearchQuery.new(config, "205438967we9tn8we09asf")
    searcher = Searcher.new(dbm, search_query, 100)
    result = searcher.search
    assert_equal(0, result.length)

    dbm.close
  end
end


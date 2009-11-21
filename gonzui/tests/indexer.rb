#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'
include Gonzui

class IndexerTest < Test::Unit::TestCase
  include TestUtil

  def test_index
    config   = Config.new
    remove_db(config)
    dbm = DBM.open(config)
    path = "foo/foo.c"
    url = URI.from_path(File.expand_path(path))
    content = Content.new(File.read(path), File.mtime(path))
    source_url = URI.parse("file:///foo")
    indexer = Indexer.new(config, dbm, source_url, path, content)
    indexer.index
    dbm.flush_cache
    assert_equal(1, dbm.get_ncontents)
    assert(dbm.has_package?("foo"))
    assert(dbm.has_word?("main"))
    assert(dbm.consistent?)
  end
end

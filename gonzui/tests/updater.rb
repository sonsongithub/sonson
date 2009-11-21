#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'
require 'fileutils'

include Gonzui

class UpdaterTest < Test::Unit::TestCase
  include TestUtil

  def test_update
    config   = Config.new
    remove_db(config)
    tmp_dir = File.expand_path("tmp.update")
    FileUtils.rm_rf(tmp_dir)
    FileUtils.mkdir(tmp_dir)
    tmp_file1 = File.join(tmp_dir, "foo.txt")
    tmp_file2 = File.join(tmp_dir, "bar.txt")
    File.open(tmp_file1, "w") {|f| f.puts("foo") }

    dbm = DBM.open(config)
    url = URI.from_path(File.expand_path(tmp_file1))
    content = Content.new(File.read(tmp_file1), File.mtime(tmp_file1))
    source_url = URI.parse(sprintf("file://%s", tmp_dir))
    indexer = Indexer.new(config, dbm, source_url, tmp_file1, content)
    indexer.index
    dbm.flush_cache
    assert_equal(1, dbm.get_ncontents)
    assert(dbm.has_word?("foo"))
    assert_equal(false, dbm.has_word?("bar"))
    assert(dbm.consistent?)

    File.open(tmp_file1, "w") {|f| f.puts("bar") }
    updater = Updater.new(config)
    updater.update
    dbm.flush_cache
    assert_equal(1, dbm.get_npackages)
    assert_equal(1, dbm.get_ncontents)
    assert_equal(1, dbm.get_nwords)
    assert_equal(false, dbm.has_word?("foo"))
    assert(dbm.has_word?("bar"))
    assert(dbm.consistent?)

    File.open(tmp_file2, "w") {|f| f.puts("baz") }
    updater = Updater.new(config)
    updater.update
    dbm.flush_cache
    assert_equal(1, dbm.get_npackages)
    assert_equal(2, dbm.get_ncontents)
    assert_equal(2, dbm.get_nwords)
    assert(dbm.has_word?("bar"))
    assert(dbm.has_word?("baz"))
    assert(dbm.consistent?)

    FileUtils.rm_rf(tmp_file1)
    FileUtils.rm_rf(tmp_file2)
    updater = Updater.new(config)
    updater.update
    dbm.flush_cache
    assert_equal(0, dbm.get_npackages)
    assert_equal(0, dbm.get_ncontents)
    assert_equal(0, dbm.get_nwords)
    assert_equal(false, dbm.has_word?("foo"))
    assert_equal(false, dbm.has_word?("bar"))
    assert_equal(false, dbm.has_word?("baz"))
    assert(dbm.consistent?)
    
    FileUtils.rm_rf(tmp_dir)
  end
end


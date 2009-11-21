#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'gonzui/webapp'
require 'test-util'
include Gonzui

class TextBeautifierTest < Test::Unit::TestCase
  include TestUtil

  def init_dbm(config)
    remove_db(config)
    make_archives
    add_package(config)
    dbm = DBM.open(config)
    return dbm
  end

  def test_beautify
    config = Gonzui::Config.new
    dbm = init_dbm(config)
    path_id = dbm.get_path_id("foo-0.1/foo.c")
    assert(path_id.is_a?(Fixnum))
    content = dbm.get_content(path_id)
    digest  = dbm.get_digest(path_id)
    beautifier = TextBeautifier.new(content, digest, [], "search?q=")
    html = beautifier.beautify
    assert(html.is_a?(Array))
    assert(html.flatten.include?(:span))
    remove_db(config)
  end
end

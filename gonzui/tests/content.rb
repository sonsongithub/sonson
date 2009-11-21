#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'

include Gonzui

class ContentTest < Test::Unit::TestCase
  def test_content
    text = "foo"
    mtime = Time.now
    content = Content.new(text, mtime)
    assert_equal(text, content.text)
    assert_equal(text.length, content.length)
    assert_equal(mtime, content.mtime)
  end
end


#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'
include Gonzui
require 'pp'

class ConfigTest < Test::Unit::TestCase
  def test_config
    config = Config.new
    assert_not_nil(config.temporary_directory)
    assert_not_nil(config.db_directory)

    config.temporary_directory = "foo"
    assert_equal("foo", config.temporary_directory)
    config.db_directory = "bar"
    assert_equal("bar", config.db_directory)

    config.http_port = 12345
    file_name = "tmp.gonzuirc"
    File.open(file_name, "w") {|f|
      config.dump(f)
    }
    assert(File.exist?(file_name))
    config.http_port = 0
    assert_equal(0, config.http_port)
    config.load(file_name)
    assert_equal(12345, config.http_port)
    File.unlink(file_name)
  end
end

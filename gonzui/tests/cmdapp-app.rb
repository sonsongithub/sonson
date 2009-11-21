#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'gonzui/cmdapp'
require 'test-util'
include Gonzui

class CommandLineApplicationTest < Test::Unit::TestCase
  class TestApplication < CommandLineApplication
    def parse_options
      option_table = []
      return parse_options_to_hash(option_table)
    end

    def start
      parse_options
      return @config
    end
  end


  def test_app
    app = TestApplication.new
    config = app.start
    assert(config.is_a?(Config))

    original_stdout = STDOUT.dup
    assert(STDOUT.tty?)
    app.be_quiet
    assert_equal(false, STDOUT.tty?)
    STDOUT.reopen(original_stdout)
    assert(STDOUT.tty?)
  end
end

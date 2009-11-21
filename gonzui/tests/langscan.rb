#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require "test-util"
require 'langscan'

Dir.glob("../langscan/*/test/test-*.rb") {|filename|
  load filename
}

class TestLangScan < Test::Unit::TestCase
  def test_choose
    LangScan.modules.each {|m|
      m.extnames.each {|extname|
        mm = LangScan.choose("foo" + extname)
        assert_equal(m, mm)
      }
    }
  end
end

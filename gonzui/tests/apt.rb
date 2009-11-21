#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'
include Gonzui

class AptTest < Test::Unit::TestCase
  def _test_apt_get_temporary_directory(aptget)
    assert(File.directory?(aptget.temporary_directory))
    aptget.clean
    assert_equal(false, File.directory?(aptget.temporary_directory))
  end

  def test_apt_get
    return unless AptGet.available?
    apt_type = AptGet.get_apt_type
    assert((apt_type == :rpm or apt_type == :deb))
    config = Config.new
    aptget = AptGet.new(config, "portmap")

    directory = aptget.extract
    assert(File.directory?(directory))

    _test_apt_get_temporary_directory(aptget)
  end

  def test_apt_get_nonexisting
    return unless AptGet.available?
    apt_type = AptGet.get_apt_type
    assert((apt_type == :rpm or apt_type == :deb))
    config = Config.new
    aptget = AptGet.new(config, "qpewrguiniquegnoqwiu")
    begin
      aptget.extract
      assert(false)
    rescue AptGetError => e
      assert(true)
    end

    _test_apt_get_temporary_directory(aptget)
  end
end

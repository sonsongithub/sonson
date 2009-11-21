#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'ftools'
require 'fileutils'
require 'gonzui'
require 'test-util'
include FileUtils
include Gonzui
include Gonzui::Util

class UtilTest < Test::Unit::TestCase
  def test_string_methods
    assert_equal("oo", "foo".prechop)
    assert_equal("", "".prechop)
    assert_equal(0...3, "foo\nbar\nbaz\n".line_range(0))
    assert_equal(0...3, "foo\nbar\nbaz\n".line_range(2))
    assert_equal(4...7, "foo\nbar\nbaz\n".line_range(4))

    "foo\nbar\nbaz\n".each_line_range(4, 1) {|lineno_offset, range|
      case lineno_offset
      when -1
        assert_equal(0...3, range)
      when 0
        assert_equal(4...7, range)
      when 1
        assert_equal(8...11, range)
      else
        assert(false)
      end
    }
  end

  def test_dir_methods
    rm_rf("t")
    File.mkpath("t")
    assert_equal([], Dir.entries_without_dots("t"))

    touch(["t/a", "t/b"])
    assert_equal(["a", "b"], Dir.entries_without_dots("t"))

    File.mkpath("t/t")
    assert_equal(["a", "b", "t"], Dir.entries_without_dots("t"))

    touch(["t/t/c"])
    assert_equal(["t/a", "t/b", "t/t/c", ], Dir.all_files("t"))
    rm_rf("t")
  end

  def test_file_methods
    assert_equal("bar", File.relative_path("/foo/bar", "/foo"))
    assert_equal("foo", File.relative_path("/foo", "/"))
    assert_equal("", File.relative_path("/foo", "/foo"))
    assert(File.any_exist?("/"))
  end

  def test_command_operations
    unless windows?
      assert(command_exist?("sh")) 
      assert(require_command("sh"))
    end
  end

  def test_shell_escape
    assert_equal('"foo"', shell_escape('foo'))
    assert_equal('"\\$foo"', shell_escape('$foo'))
    assert_equal('"\\`foo\\`"', shell_escape('`foo`'))
    assert_equal('"foo\\\\bar"', shell_escape('foo\\bar'))
  end

  def test_commify
    assert_equal("1",         commify(1))
    assert_equal("12",        commify(12))
    assert_equal("123",       commify(123))
    assert_equal("1,234",     commify(1234))
    assert_equal("12,345",    commify(12345))
    assert_equal("123,456",   commify(123456))
    assert_equal("1,234,567", commify(1234567))
  end

  def test_temporary_directory_util
    foo = Object.new
    foo.extend(TemporaryDirectoryUtil)
    foo.set_temporary_directory(".")
    foo.prepare_temporary_directory
    begin
      foo.prepare_temporary_directory
      assert(false)
    rescue
      assert(true)
    end
    assert(File.directory?(foo.temporary_directory))
    foo.clean_temporary_directory
    assert_equal(false, File.exist?(foo.temporary_directory))
  end

  def test_utf8
    str, name = UTF8.to_utf8("foo")
    assert_equal("foo", str)
    assert_equal("us-ascii", name)


    utf8 = "日本語です"
    ["shift_jis", "euc-jp", "iso-2022-jp"].each {|name|
      str = Iconv.conv(name, "utf8", utf8)
      s, n = UTF8.to_utf8(str)
      assert_equal(name, n)
      assert_equal(utf8, s)
    }
  end
end


#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'

include Gonzui

class FetcherTest < Test::Unit::TestCase
  include TestUtil

  def validate_foo_files(fetcher, paths)
    paths.each {|path|
      FOO_FILES.include?(File.basename(path))
      content = fetcher.fetch(path)
      tmp = File.read(File.join("foo", FOO_PACKAGE, path))
      assert_equal(tmp, content.text)
    }
  end

  def test_file
    config = Config.new
    make_dist_tree
    uri = URI.parse(sprintf("file://%s/foo/%s", Dir.pwd, FOO_PACKAGE))
    fetcher = Fetcher.new(config, uri)
    paths = fetcher.collect
    assert_equal(false, paths.empty?)
    validate_foo_files(fetcher, paths)
    fetcher.finish
  end

  def test_http
    config = Config.new
    uri = URI.parse("http://gonzui.sourceforge.net/archives/gonzui-0.1.tar.gz")
    fetcher = Fetcher.new(config, uri)
    paths = fetcher.collect
    assert_equal(false, paths.empty?)
    paths.each {|path|
      content = fetcher.fetch(path)
      assert(content.text.is_a?(String))
    }
    fetcher.finish
  end

  def test_cvs
    config = Config.new
    config.quiet = true
    remove_db(config)
    make_cvs
    uri = URI.for_cvs(cvsroot, "foo")
    fetcher = Fetcher.new(config, uri)
    paths = fetcher.collect
    assert_equal(false, paths.empty?)
    validate_foo_files(fetcher, paths)
    remove_cvs
  end

  def test_svn
    config = Config.new
    config.quiet = true
    remove_db(config)
    make_svn
    uri = URI.for_svn("file://" + svnroot, "foo")
    fetcher = Fetcher.new(config, uri)
    paths = fetcher.collect
    assert_equal(false, paths.empty?)
    validate_foo_files(fetcher, paths)
    remove_svn
  end
end

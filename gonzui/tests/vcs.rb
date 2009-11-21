#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'ftools'
require 'test-util'

include Gonzui

class VCSTest < Test::Unit::TestCase
  include Util
  include TestUtil

  def prepare
    make_dist_tree
    config = Config.new
    config.quiet = true
    remove_db(config)
    return config
  end

  def test_cvs
    config = prepare
    make_cvs
    cvs = CVS.new(config, cvsroot, "foo")
    cvs.extract
    cached_foo = File.join(config.cache_directory, "foo")
    entries = Dir.entries_without_dots(cached_foo)
    FOO_FILES.each {|base_name|
      assert(entries.include?(base_name))
    }
    remove_cvs
  end

  def test_svn
    config = prepare
    svnroot_uri = make_svn
    svn = Subversion.new(config, svnroot_uri, "foo")
    svn.extract
    cached_foo = File.join(config.cache_directory, "foo")
    entries = Dir.entries_without_dots(cached_foo)
    FOO_FILES.each {|base_name|
      assert(entries.include?(base_name))
    }
    remove_svn
  end
end

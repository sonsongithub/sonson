#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'
include Gonzui

class ExtractorTest < Test::Unit::TestCase
  include Util
  include TestUtil

  def test_supported_archive
    supported_files = {}
    supported_files["foo.zip"] = ".zip" if command_exist?("unzip")
    supported_files["foo.tar.gz"] = ".tar.gz" if
      command_exist?("tar") and command_exist?("gunzip")
    supported_files["foo.tar.bz2"] = ".tar.bz2" if 
      command_exist?("tar") and command_exist?("bunzip2")
    supported_files["foo.src.rpm"] = ".src.rpm" if 
      command_exist?("rpm2cpio") and command_exist?("cpio")

    supported_files.each {|file_name, extname|
      assert_equal(extname, Extractor.get_archive_extname(file_name))
      assert(Extractor.supported_file?(file_name))
      assert_equal(file_name,
                    Extractor.suppress_archive_extname(file_name) + extname)
    }
  end

  def test_unsupported_archive
    unsupported_files = {
      "foo.rpm"     => ".rpm",
    }
    unsupported_files.each {|file_name, extname|
      assert_equal(nil, Extractor.get_archive_extname(file_name))
      assert_equal(false, Extractor.supported_file?(file_name))
    }
  end

  def _test_extract(file_name)
    config = Config.new
    extractor = Extractor.new(config, file_name)
    directory = extractor.extract
    assert(File.directory?(directory))
    package_name = File.basename(directory)
    source_url = URI.from_path(directory)
    fetcher = Fetcher.new(config, source_url)
    relative_paths = fetcher.collect
    FOO_FILES.each {|base_name|
      assert(relative_paths.include?(base_name))
    }
    
    assert(File.directory?(extractor.temporary_directory))
    extractor.clean
    assert_equal(false, File.directory?(extractor.temporary_directory))
  end

  def test_extract
    make_archives

    good_archives = [
      "foo-0.1.tar.gz",
      "foo-0.1.tar.bz2",
      "foo-0.1.zip",
      "foo-0.1-1.src.rpm",
    ].map {|x| File.join("foo", x) }
    good_archives = good_archives.find_all {|x| File.file?(x) }

    poor_archives = [
      "foo-0.1p.tar.gz",
      "foo-0.1p.tar.bz2",
      "foo-0.1p.zip",
    ].map {|x| File.join("foo", x) }
    poor_archives = poor_archives.find_all {|x| File.file?(x) }

    good_archives.each {|file_name| _test_extract(file_name) }
    poor_archives.each {|file_name| _test_extract(file_name) }
  end
end


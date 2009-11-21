require 'gonzui'
require 'fileutils'
include FileUtils

def gnu_make?
  message = IO.popen("make --version").read
  /^GNU/.match(message)
end

module TestUtil
  FOO_FILES   = ["bar.c", "bar.h", "foo.c", "Makefile" ].sort
  FOO_C_FILES = FOO_FILES.find_all {|x| /\.[ch]$/.match(x) }
  FOO_SYMBOLS = ["bar", "foo", "main", "printf"]
  FOO_PACKAGE = "foo-0.1"
  FOO_TGZ     = File.join("foo", FOO_PACKAGE + ".tar.gz")

  @@make_options = if gnu_make?
                     "--quiet --no-print-directory"
                   else
                     ""
                   end

  def add_package(config)
    importer = Importer.new(config)
    url = URI.from_path(FOO_TGZ)
    importer.import(url)
    importer.finish
  end

  def make_db(config)
    remove_db(config)
    make_archives
    importer = Gonzui::Importer.new(config)
    url = URI.from_path(FOO_TGZ)
    importer.import(url)
    importer.finish
  end

  def remove_db(config)
    rm_rf(config.db_directory)
  end

  def make_dist_tree
    system("cd foo; make #{@@make_options} -f Makefile.foo dist-tree")
  end

  def make_clean
    system("cd foo; make #{@@make_options} -f Makefile.foo clean")
  end

  def make_archives
    Util.require_command("zip")
    Util.require_command("tar")
    Util.require_command("gzip")
    Util.require_command("bzip2")
    system("cd foo; make #{@@make_options} -f Makefile.foo dist")
    system("cd foo; make #{@@make_options} -f Makefile.foo dist-poor")
  end

  def cvsroot
    File.expand_path("tmp.cvsroot")
  end

  def make_cvs
    remove_cvs
    make_dist_tree
    assert(Util.command_exist?("cvs"))
    Dir.mkdir(cvsroot)
    system("cvs -d #{cvsroot} init")
    command_line = "cd foo/#{FOO_PACKAGE};"
    command_line << "cvs -Qd #{cvsroot} import -m '' foo gonzui-test test"
    system(command_line)
  end

  def remove_cvs
    FileUtils.rm_rf(cvsroot)
  end

  def svnroot
    File.expand_path("tmp.svnroot")
  end

  def make_svn
    remove_svn
    make_dist_tree
    assert(Util.command_exist?("svn"))
    assert(Util.command_exist?("svnadmin"))
    svnroot_uri = sprintf("file://%s", svnroot)
    Dir.mkdir(svnroot)
    system("svnadmin create #{svnroot}")
    command_line = "cd foo/#{FOO_PACKAGE};"
    command_line << "svn -q import -m '' #{svnroot_uri}"
    system(command_line)
    return svnroot_uri
  end

  def remove_svn
    FileUtils.rm_rf(svnroot)
  end
end

if ENV['MAKEFLAGS'] # be quiet in a make process.
  ARGV.unshift("--verbose=s")
end

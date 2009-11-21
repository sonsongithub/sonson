#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'stringio'
require 'gonzui'
require 'gonzui/cmdapp'
require 'test-util'

include Gonzui
include Gonzui::Util

class CommandLineSearcherTest < Test::Unit::TestCase
  include TestUtil

  def search(config, pattern, options = {})
    strio = StringIO.new
    options['out'] = strio
    searcher = CommandLineSearcher.new(config, options)
    searcher.search(pattern)
    begin
      if options['context']
        return strio.string.gsub(/^== .*\n/s, "")
      else
        return strio.string
      end
    ensure
      searcher.finish
    end
  end

  def grep(argument)
    ENV['GREP_OPTIONS'] = nil
    files = FOO_FILES.map {|basename| File.join(FOO_PACKAGE, basename) }
    tmp = IO.popen("cd foo; grep #{argument} #{files.join(' ')}").read
    return tmp.gsub(/\t/, " " * 8)
  end

  def grep_has_color_option?
    status = system("grep --help | grep -q color")
    return status
  end

  def test_result
    require_command('grep')
    config   = Config.new
    make_db(config)
    make_dist_tree

    by_gonzui = search(config, "foo")
    by_grep   = grep("-H 'foo'")
    assert_equal(by_grep, by_gonzui)

    by_gonzui = search(config, "foo", "type" => "fundef")
    by_grep   = grep("-H '^foo ('")
    assert_equal(by_grep, by_gonzui)

    by_gonzui = search(config, "foo", "line-number" => true)
    by_grep   = grep("-nH 'foo'")
    assert_equal(by_grep, by_gonzui)

    by_gonzui = search(config, "foo", "no-filename" => true)
    by_grep   = grep("-h 'foo'")
    assert_equal(by_grep, by_gonzui)

    by_gonzui = search(config, "mai", "prefix" => true)
    by_grep   = grep("-H 'mai'")
    assert_equal(by_grep, by_gonzui)

    by_gonzui = search(config, "f.o", "regexp" => true)
    by_grep   = grep("-H 'f.o'")
    assert_equal(by_grep, by_gonzui)

    by_gonzui = search(config, "foo", "type" => "funcall")
    by_grep   = grep("-H ' foo(1, 2)'")
    assert_equal(by_grep, by_gonzui)

    (1..10).each {|i|
      by_gonzui = search(config, "foo", "type" => "fundef",
                         "context" => i)
      by_grep   = grep("-hC#{i} '^foo ('")
      assert_equal(by_grep, by_gonzui)
    }

    if grep_has_color_option?
      by_gonzui = search(config, "main", 
                         "line-number" => true, "color" => true)
      ENV["GREP_COLOR"] = nil
      by_grep   = grep("-nH --color=always 'main'")
      assert_equal(by_grep, by_gonzui)
    end
  end
end

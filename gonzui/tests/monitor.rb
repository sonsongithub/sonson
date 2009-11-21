#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'
include Gonzui

class MonitorTest < Test::Unit::TestCase
  include TestUtil

  def foo
    1
  end

  def test_monitor
    monitor = PerformanceMonitor.new
    assert(monitor.empty?)
    assert_equal("", monitor.format([MonitorTest, :foo]))
    monitor.profile(self, :foo)
    assert(!monitor.empty?)
    summary = monitor.format([MonitorTest, :foo],
                             [MonitorTest, :foo])
    assert(summary.is_a?(String))
    
  end
end

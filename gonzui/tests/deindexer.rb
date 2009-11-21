#! /usr/bin/env ruby
$LOAD_PATH.unshift("..")
require 'test/unit'
require 'gonzui'
require 'test-util'
include Gonzui

class DeindexerTest < Test::Unit::TestCase
  include TestUtil

  def _test_removed_clearly?(dbm)
    exclude_dbs = [
      :seq, :stat, :type_typeid, :typeid_type, :version,
    ]
    dbm.each_db_name {|db_name|
      next if exclude_dbs.include?(db_name.intern)
      assert(dbm.send(db_name).empty?)
    }
  end

  def test_deindex
    config   = Config.new
    remove_db(config)
    make_db(config)
    dbm = DBM.open(config)

    package_id = dbm.get_package_id(FOO_PACKAGE)
    assert_equal(0, package_id)
    dbm.get_path_ids(package_id).each {|path_id|
      normalized_path = dbm.get_path(path_id)
      deindexer = Deindexer.new(config, dbm, normalized_path)
      deindexer.deindex
    }
    assert(!dbm.has_package?(FOO_PACKAGE))
    assert_equal(0, dbm.get_ncontents)
    assert_equal(0, dbm.get_nwords)
    assert(dbm.consistent?)
    _test_removed_clearly?(dbm)
  end
end

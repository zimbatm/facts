require 'test/unit'
require 'facts'

module FactsHelper
  def s(*stack); Facts.new(stack);end
  def ev(str); s(str).eval; end
end

class StackManipTests < Test::Unit::TestCase
  include FactsHelper

  def test_dup
    assert_equal([3, 3], s(3).dup)
  end

  def test_drop
    assert_equal([:sym], s(:sym, :bol).drop)
  end

  def test_over
    assert_equal([:a, :b, :a], s(:a, :b).over)
  end

  def test_swap
    assert_equal([:b, :a], s(:a, :b).swap)
  end

  def test_nip
    assert_equal([:b], s(:a, :b).nip)
  end

end

class BaseArithTests < Test::Unit::TestCase
  include FactsHelper

  def test_add
    assert_equal([3], s(1,2).add)
    assert_equal([3], ev("1 2 add"))
    assert_equal([-1], s(1,-2).add)
    assert_equal([-1], ev("1 -2 add"))
  end

  def test_not
    assert_equal([false], s(true).not)
    assert_equal([false], ev("1 not"))
  end

  def test_and
    assert_equal([1], s(7,9).and)
    assert_equal([1], ev("7 9 and"))
  end

  def test_or
    assert_equal([15], s(7,9).or)
  end

  def test_xor
    assert_equal([14], s(7,9).xor)
  end

  def test_rshift1
    assert_equal([2], s(4).rshift1)
  end
end

class WordOperationsTests < Test::Unit::TestCase
  include FactsHelper

  def test_parse
    assert_equal([[6, :add]], s("6 add").parse)
  end

  def test_recurse_parent_match
    md = /\((?:[^()]*)\)/.match("zz ( a ( b ( c ) b ) a ) zz z")
    assert_equal(3, md)
  end

  def test_set
    ss = s("6 add", "add6")
    assert_equal([], ss.set)
    assert_equal([11], ss.push(5).add6)
  end

  def test_wp
    # TODO
  end

  def test_call
    assert_equal([13], s([7, 6, :add]).call)
  end

end

class ConditionsTests < Test::Unit::TestCase
  include FactsHelper

  def test_if
    assert_equal(["ok"], ev('"ok" 1 if'))
    assert_equal([], ev('6 1 not if'))
  end
end


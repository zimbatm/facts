require 'test/unit'
require 'facts'

module FactsHelper
  def s(*arr)
    @s = Facts.new(arr)
  end
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
    assert_equal([-1], s(1,-2).add)
  end

  def test_not
    assert_equal([false], s(true).not)
  end

  def test_and
    assert_equal([1], s(7,9).and)
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

  def test_def_set_with_lambda
    l = lambda{ push(6); add }
    ss = s(l, "add6")
    assert_equal([], ss.def_set)
    assert_equal([11], ss.push(5).add6)
  end

  def test_def_set_with_string
    ss = s("6 add", "add6")
    assert_equal([], ss.def_set)
    assert_equal([11], ss.push(5).add6)
  end

  def test_def_get_with_lambda
    l = lambda{ push(6); add }
    ss = s(l, "add6")
    assert_equal([], ss.def_set)
    assert_equal([l], ss.push("add6").def_get)
  end

  def test_def_get_with_string
    ss = s("6 add", "add6")
    assert_equal([], ss.def_set)
    assert_equal([["6", "add"]], ss.push("add6").def_get)
  end

end

class KernelMethodsTests < Test::Unit::TestCase
  def test_Facts
    assert_equal([3,4,5], Facts(3, 4, 5))
  end
end


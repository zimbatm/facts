$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'facts'

module FactsHelper
  def f(*stack)
    f = Facts::Interp.new
    f.__send__ :instance_variable_set, "@stack", stack
    f
  end
  def assert_stack(stack, str)
    case str
    when String
      str = f.eval(str)
    end
    s2 = str.stack
    assert_equal(stack, s2)
  end
end

class StackManipTests < Test::Unit::TestCase
  include FactsHelper

  def test_dup
    assert_stack ["a", "a"], "'a dup"
  end

  def test_drop
    assert_stack ["a"], "'a 'b drop"
  end

  def test_over
    assert_stack ["a", "b", "a"], "'a 'b over"
  end

  def test_swap
    assert_stack ["b", "a"], "'a 'b swap"
  end

  def test_nip
    assert_stack ["b"] , "'a 'b nip"
  end

end

class BaseArithTests < Test::Unit::TestCase
  include FactsHelper

  def test_add
    assert_stack [3] , "1 2 add"
    assert_stack [-1], "1 -2 add"
  end

  def test_not
    assert_stack [false] , "true not"
    assert_stack [false] , "1 not"
  end

  def test_and
    assert_stack [1] , "7 9 and"
  end

  def test_or
    assert_stack [15] , "7 9 or"
  end

  def test_xor
    assert_stack [14], "7 9 xor"
  end

  def test_rshift1
    assert_stack [2], "4 rshift1"
  end
end

class WordOperationsTests < Test::Unit::TestCase
  include FactsHelper
  WORD_COUNT = Facts::Interp.words.size

  def test_parse
    assert_stack [6, "6", 6], "6 [6] 6"
  end

  def test_recurse_parent_match
    assert_stack [" some [rec [ urs [ ive ] ] ] stack "], "[ some [rec [ urs [ ive ] ] ] stack ] "
  end

  def test_def
    x = f()
    x.eval "[add] '+ def"
    assert x.words.include?("+")

    x.eval " 3 2 + "
    assert_stack [5], x
  end

  #def test_call
  #  assert_equal([13], s([7, 6, :add]).call)
  #end

  def test_no_side_effects
    assert_equal 0, Facts::Interp.stack.size
    assert_equal WORD_COUNT, Facts::Interp.words.size
  end

end

class ConditionsTests < Test::Unit::TestCase
  include FactsHelper

  #def test_if
  #  assert_equal(["ok"], ev('"ok" 1 if'))
  #  assert_equal([], ev('6 1 not if'))
  #end
end


class RubyChainingTests < Test::Unit::TestCase
  include FactsHelper

  def test_simple_case
    assert_stack [6], f["3"]["3"].add
  end

end


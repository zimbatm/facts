
=begin facts notes

Data types are the same as ruby's for now, except for the quote

=end

module Facts
  # All errors inherit from this
  class Error < StandardError; end

  class AxiomError < Error; end
  class StackUnderflow < Error; end
  class StackOverflow < Error; end
  class WordNotFound < Error; end
  class ParseError < Error; end

  # Simple syntax : quotes or symbols
  class Tokenizer
    EOF = -1

    def initialize(str)
      @str = str
      @pos = -1
    end

    def next
      type = nil
      start = 0
      while @pos <= @str.length
        @pos += 1

        if @pos == @str.length
          c = EOF
        else
          c = @str[@pos..@pos]
        end

        case type
        when nil # undef
          case c
          when EOF: return nil
          when /\s/: next
          when "[": 
            type = :quote
            par_count = 1
          else
            type = :symbol
          end
          start = @pos
        when :quote
          case c
          when EOF                  
            raise ParseError, "Quote starting at #{start} never terminated"
          when "["
            par_count += 1
          when "]"
            par_count -= 1
            return [:quote, @str[start .. @pos].strip] if par_count == 0
          end
        when :symbol
          if c == EOF || c =~ /\s/
            return [:symbol, @str[start .. @pos].strip]
          end
        end
      end

      return nil
    end
  end

  # Prototype style
  Interp = Object.new
  Interp.__send__ :instance_variable_set, "@dict", {} # Hash holding the words
  Interp.__send__ :instance_variable_set, "@stack", [] # Array representing the stack

  # intepreter interface with Ruby
  class << Interp
    # Hide public methods
    private( *public_instance_methods.reject{|m| m=~/^__/} )

    # Adds `*a` to the stack
    def push(*a) # utility
      @stack.push(*a); self
    end

    # Removes an item from the stack
    def pop # utility
      @stack.pop
    end

    # Returns a list of defined words
    def words # utility
      @dict.keys.sort
    end

    # Gives the stack
    attr_reader :stack
    attr_reader :dict

    # Calls an interpreter word with the given arguments
    def call(name) # motor
      #name = name.to_s
      if w = @dict[name]
        w.call(self)
      else # other lookups
        case name
        when /^\[.*\]$/ # quote
          push(name[1..-2])
        when /^'/ # single quote
          push(name[1..-1])
        when /^[+-]?\d+$/ # integer
          push(name.to_i)
        when /^[+-]?\d+\.\d+$/ # float
          push(name.to_f)
        # TODO: add hooks for extensible types / macros
        else
          raise WordNotFound, "word `#{name}` does not exist in dictionary"
        end
      end
      self
    end
    private :call

    # (str -- *)
    # parses and calls.
    #
    # this is the motor
    def eval(str) # motor
      t = Tokenizer.new(str.to_s)
      while tok = t.next
         call(tok[1])
      end
      self
    end
    alias [] eval
    alias method_missing eval

    # Used to define new axioms for the intepreter.
    #
    # The block arity is used to verify the input stack effect
    #
    # The block must return an array representing the resulting output stack
    def axiom(name, &block)
      raise ArgumentError, "block arity must be positive" if block.arity < 0
      @dict[name.to_s] = proc do |i|
        _ar = block.arity
        args = []
        if _ar > 0
          _ar -= 1
          raise StackUnderflow, "got #{i.stack.size} in #{_ar} for `#{name}`" if i.stack.size < _ar
          _ar.times { args.unshift i.pop }
	      end

        ret = block.call(i, *args)

        ret.each{|e| i.push(e) }
      end 
    end
 
    # Creates a new interpreter
    def new
      n = clone
      n.__send__ :instance_variable_set, "@dict", @dict.clone
      n.__send__ :instance_variable_set, "@stack", @stack.clone
      n
    end

    # Shows the stack and defined words in IRB for example, when using that object
    remove_method :inspect
    def inspect; "<s:#{@stack.inspect}, w:[#{words.map{|w| w.to_s}.join(' ')}]>" end
  end

  # Define axioms
  Interp.__send__(:instance_eval) do

## Word operations:

    # Defines a new word
    # TODO: put a warning if a word is redefined ?
    # FIXME: dict not working ?
    # NOTE: It seems like different dicts are used in different places
    axiom :def do |i,quot,name|
      i.dict[name.to_s] = proc do |i| i.eval(quot) end
      []
    end

    axiom :eval do |i,quot|
      i.eval(quot)
      []
    end

    axiom :words do |_|
      [words]
    end

    axiom :print do |_,a|
      puts a
      []
    end

## Stack manipulation:

    # (a -- a a)
    axiom :dup do |_,a|
      [a,a]
    end

    # (a --)
    axiom :drop do |_,a| [] end

    # (a b -- a b a)
    axiom :over do |_,a,b|
      [a,b,a]
    end

    # (a b -- b a)
    axiom :swap do |_,a,b|
      [b,a]
    end

    # (a b -- b)
    axiom :nip do |_,a,b|
      [b]
    end

## Arithmetic:

    # (a b -- (a+b) )
    axiom :add do |_,a,b|
      [a+b]
    end

    # (a -- ~a)
    axiom :not do |_,a|
      [!a]
    end

    # (a b -- (a&b) )
    axiom :and do |_,a,b|
      [a & b]
    end

    # (a b -- (a|b) )
    axiom :or do |_,a,b|
      [a | b]
    end

    # (a b -- (a^b) )
    axiom :xor do |_,a,b|
      [a^b]
    end

    # (a -- (a>>1) )
    axiom :rshift1 do |_,a|
      [ a >> 1 ]
    end

    axiom :true do |_|
      [ true ]
    end

    axiom :false do |_|
      [ false ]
    end

    axiom :nil do |_|
      [ nil ]
    end
    
    axiom :import do |i,path|
      i.eval File.read(path)
      [ ]
    end

## Flow control:
  
    # blk cond -- blk
    axiom :if do |i,cond,quot_t,quot_f| # FIXME
      i.eval(cond ? quot_t : quot_f)
      []
    end

## Other words:
    
    #eval "[drop] '# def" # is a comment, like [some comment]#

  end # Interp.instance_eval &b

end

if __FILE__ == $0 # Run tests
  require 'test/unit'

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

    def test_if
      assert_stack ["ok"], "1 ['ok] [[not ok]] if"
    end
  end


  class RubyChainingTests < Test::Unit::TestCase
    include FactsHelper

    def test_simple_case
      assert_stack [6], f["3"]["3"].add
    end

  end

end

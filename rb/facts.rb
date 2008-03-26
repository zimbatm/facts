
# All Forth methods must take no arguments
# and return self.
#
# Forth is also the data stack
class Facts < Array
  # All Forth errors inherit from this
  class ForthError < StandardError; end

  class StackUnderflow < ForthError; end
  class StackOverflow < ForthError; end

  # Non-factor utility methods
  UTIL_METH = %w[push pop inspect]

  unless @been_here_before
    # Hide public methods
    private(*public_instance_methods.reject{|m| m=~/^__/ || UTIL_METH.include?(m)})
    @been_here_before = true
  end

  def assert_in(_size)
    size < _size ? raise(StackUnderflow, "got #{size} in #{_size}") : self
  end
  private :assert_in

  # Forwards zero-arguments methods to the Forth interp.
  def method_missing(word, *a, &blk)
    if a.size == 0
      push(word).call
      self
    else
      super
    end
  end
  private :method_missing

  # Preparing the environment.
  def initialize(init_stack = [])
    super(init_stack)

    # @rstack or return stack is delegated to Ruby's call stack

    # initial dictionnary
    @dict = {}
  end
  
## Stack manipulation:

  # (a -- a a)
  def dup; assert_in(1)
    push(last)
  self end

  # (a --)
  def drop; assert_in(1)
    pop
  self end

  # (a b -- a b a)
  def over; assert_in(2)
    x2 = pop; x1 = pop;
    push(x1); push(x2); push(x1)
  self end

  # (a b -- b a)
  def swap; assert_in(2)
    x2 = pop; x1 = pop
    push(x2); push(x1)
  self end

  # (a b -- b)
  def nip; assert_in(2)
    x2 = pop; pop; push(x2)
  self end

## Arithmetic:

  # (a b -- (a+b) )
  def add; assert_in(2)
    swap; push(pop + pop)
  self end

  # (a -- ~a)
  def not; assert_in(1)
    push(!pop)
  self end

  # (a b -- (a&b) )
  def and; assert_in(2)
    swap; push(pop & pop)
  self end

  # (a b -- (a|b) )
  def or; assert_in(2)
    swap; push(pop | pop)
  self end

  # (a b -- (a^b) )
  def xor; assert_in(2)
    swap; push(pop ^ pop)
  self end

  # (a -- (a>>1) )
  def rshift1; assert_in(1)
    push( pop >> 1 )
  self end

## Word operations:

  # (str -- blk)
  # FIXME: Add closures, detect litterals
  def parse; assert_in(1)
    push(pop.split(/\s+/).map do |term|
      case term
      when /^\"(.*)\"$/
        $1
      when /^[+-]?\d+$/
        term.to_i
      when /^[+-]?(\d+\.\d+)$/
        term.to_f
      else
        term.to_sym
      end
    end)
  self end

  # ( blk/numeric/word -- * )
  def call; assert_in(1)
    word = pop
    case word
    when Array
      word.each{|w| push(w); call}
    when Numeric, String
      push word
    when Symbol
      if wdef = @dict[word.to_s]
        push(wdef).call
      else
        meth = method(word) rescue nil
        if meth && meth.arity == 0
          meth.call
        else
          raise NoMethodError, "undefined method `#{word}' for #{self.inspect}"
        end
      end
    else
      raise NotImplementedError
    end
  self end

  # (str -- *)
  # parses and evals
  def eval; assert_in(1)
    parse; call
  self end

  # (def word -- )
  # sets a definition to a word
  def set; assert_in(2)
    swap; parse; swap
    @dict[pop] = pop
  self end

  # ( -- )
  # print defined words
  def wp
    puts((public_methods(false).reject{|m| m=~/^__/ || UTIL_METH.include?(m)} + @dict.keys).sort.inspect)
  self end

## Flow control:
  
  # blk cond -- blk
  def if; assert_in(2)
    cond = pop
    call if cond
  self end

end

if __FILE__ == $0

module Kernel
  def l; load __FILE__ end
  def s(*stack); Facts.new(stack);end
  def ev(str); s(str).eval; end
end

require 'irb'
require 'irb/completion'
IRB.start
end

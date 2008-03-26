
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

  # (def word -- )
  def def_set; assert_in(2)
    w=pop; @dict[w] = (x=pop)
  self end

  # (word -- def)
  def def_get; assert_in(1)
    word = pop
    if wdef = (@dict[word] || public_methods(word) rescue nil)
      push(wdef)
    else
      push(nil)
    end
  self end

  # ( -- )
  # print defined words
  def wp
    puts((public_methods.reject{|m| m=~/^__/ || UTIL_METH.include?(m)} + @dict.keys).sort.inspect)
  self end

  ## Flow control:

  # ( blk -- * )
  def call; assert_in(1)
    word = pop
    case word
    when Proc
      word.call
    when Array
      word.each{|w| push(w); call}
    when Numeric
      push word
    when /^[+-]?(\d+)$/ # integer litteral
      push word.to_i
    when /^[+-]?(\d+\.\d+)$/ # float litteral
      push word.to_f
    else
      word = word.to_s
      if wdef = @dict[word]
        if wdef.kind_of?(Array)
          push(wdef).call
        # methods with n-args are considered as forth methods and don't need
        # popping / pushing
        elsif wdef.arity < 0
          wdef.call
        elsif wdef.arity == 0
          push(wdef.call)
        elsif size < wdef.arity
          raise StackUnderflow
        else
          push(wdef.call(slice!(-wdef.arity, wdef.arity)))
        end
      else # litteral number ?
        raise NoMethodError, "undefined method `#{word}' for #{self.inspect}"
      end
    end
  self end

  # blk cond -- blk
  def call_if; assert_in(2)
    cond = pop
    call if cond
  self end

  # (str -- blk)
  # FIXME: Add closures
  def parse; assert_in(1)
    push(pop.split(" "))
  self end

  # (str -- result)
  def eval; assert_in(1)
    parse; call
  self end

end

module Kernel
  # Initializes a stack object with the given stack items
  def Facts(*init_stack)
    ::Facts.new(init_stack)
  end
end


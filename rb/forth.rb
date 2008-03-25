
# All Forth methods must take no arguments
# and return self.
#
# Forth is also the data stack
class Forth < Array
  # All Forth errors inherit from this
  class ForthError < StandardError; end

  class StackUnderflow < ForthError; end
  class StackOverflow < ForthError; end

  # Preparing the environment.
  def initialize(init_stack = [], init_dict = nil)
    super(init_stack || [])

    # @rstack or return stack is delegated to Ruby's call stack

    # initial dictionnary
    @dict = init_dict || {
      # Stack manipulation:

      # a -- a a
      "dup" => lambda{ x = pop; push(x); push(x) },
      # a --
      "drop" => lambda{ pop },
      # a b -- a b a
      "over" => lambda{ x2 = pop; x1 = pop; push(x1); push(x2); push(x1) },
      # a b -- b a
      "swap" => lambda{ x2 = pop; x1 = pop; push(x2); push(x1) },
      # a b -- b
      "nip" => lambda{ x2 = pop; pop; push(x2) },

      # Arithmetic:

      # a b -- (a+b)
      "add" => lambda{ swap; push(pop + pop) },
      # a -- ~a
      "not" => lambda{ push(!pop) },
      # a b -- (a&b)
      "and" => lambda{ swap; push(pop & pop) },
      # a b -- (a|b)
      "or" => lambda{ swap; push(pop | pop) },
      # a b -- (a^b)
      "xor" => lambda{ swap; push(pop ^ pop) },
      # a -- (a>>1)
      "rshift1" => lambda{ push( pop >> 1 ) },

      # Environment:

      # blk word-name -- blk
      "def" => lambda{ w=pop; @dict[w] = (x=pop); push(x) },
      "wp" => lambda{ puts(@dict.inspect) },
      "sp" => lambda{ puts(inspect) },

      # Flow control

      # blk -- blk ??
      "call" => lambda do
        wob = pop
        push(wob)
        if wob.kind_of?(Proc)
          wob.call
        elsif x = (@dict[wob.to_s] || method(wob.to_s) rescue nil)
          # methods with n-args are considered as forth methods and don't need
          # popping / pushing
          if x.arity < 0
            x.call
          elsif x.arity == 0
            push(x.call)
          elsif size < x.arity
            raise StackUnderflow
          else
            push(x.call(slice!(-x.arity, x.arity)))
          end
        else # litteral number ?
          raise NoMethodError
        end
      end,

      # blk cond -- blk
      "call-if" => lambda do
        cond = pop
        call if cond
      end
    }
  end

  # Forwards zero-arguments methods to the Forth interp.
  def method_missing(word, *a, &blk)
    if (m = @dict[word.to_s.gsub("_", "-")]) && a.size == 0
      m.call
      self
    else
      super
    end
  end

  def push(*obj, &blk)
    block_given? ? super(blk) : super
  end

  def pop
    (size == 0) ? raise(StackUnderflow) : super
  end

end


=begin facts notes

Data types are the same as ruby's for now, except for the quote

=end

module Facts
  # All errors inherit from this
  class Error < StandardError; end

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
        instance_eval(&w)
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
        # TODO: add hooks for extensible types
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
      @dict[name.to_s] = proc do
        _ar = block.arity
        raise(StackUnderflow, "got #{@stack.size} in #{_ar} for `#{name}`") if @stack.size < _ar

        args = []
        _ar.times { args.unshift pop } if _ar > 0
        ret = block.call(*args)

        ret.each{|e| push(e) }
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
    axiom :def do |quot,name|
      @dict[name.to_s] = proc do eval(quot) end
      []
    end

    axiom :eval do |quot|
      eval(quot)
      []
    end

    axiom :words do ||
      [words]
    end

    axiom :print do |a|
      puts a
      []
    end

## Stack manipulation:

    # (a -- a a)
    axiom :dup do |a|
      [a,a]
    end

    # (a --)
    axiom :drop do |a| [] end

    # (a b -- a b a)
    axiom :over do |a,b|
      [a,b,a]
    end

    # (a b -- b a)
    axiom :swap do |a,b|
      [b,a]
    end

    # (a b -- b)
    axiom :nip do |a,b|
      [b]
    end

## Arithmetic:

    # (a b -- (a+b) )
    axiom :add do |a,b|
      [a+b]
    end

    # (a -- ~a)
    axiom :not do |a|
      [!a]
    end

    # (a b -- (a&b) )
    axiom :and do |a,b|
      [a & b]
    end

    # (a b -- (a|b) )
    axiom :or do |a,b|
      [a | b]
    end

    # (a b -- (a^b) )
    axiom :xor do |a,b|
      [a^b]
    end

    # (a -- (a>>1) )
    axiom :rshift1 do |a|
      [ a >> 1 ]
    end

    axiom :true do ||
      [ true ]
    end

    axiom :false do ||
      [ false ]
    end

    axiom :nil do ||
      [ nil ]
    end

## Flow control:
  
    # blk cond -- blk
    axiom :if do |quot_f,quot_t,quot_cond| # FIXME
      eval quot_cond
      eval(pop ? quot_t : quot_f)
      []
    end

## Other words:
    
    eval "[drop] '# def" # is a comment, like [some comment]#

  end # Interp.instance_eval &b

end

if __FILE__ == $0

# REPL
$i = Facts::Interp.new

$i.axiom :exit do || exit end

# Welcome
puts "Use Ctrl+d or the `exit` word to exit"

loop do
begin
   putc ">"
   putc " "
   line = gets
   exit unless line
   $i.eval line
rescue Facts::Error => ex
   puts "*** #{ex.class.name.gsub(/.*::/,'')}: #{ex.message}"
ensure
   puts "words: #{$i.words.join ' '}"
   puts "stack: #{$i.stack.inspect}"
end
end

#module Kernel
#  def l; load __FILE__ end
#  def ev(str); $i.eval(str); end
#end
#require 'irb'
#require 'irb/completion'
#IRB.start
end

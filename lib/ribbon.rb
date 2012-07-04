%w(

ribbon/gem
ribbon/options
ribbon/raw

).each { |file| require file }

# Ribbons are essentially hashes that use method names as keys.
#
#   r = Ribbon.new
#   r.key = :value
#
# If you access a property that hasn't been set, a new ribbon will be returned.
# This allows you to easily work with nested structures:
#
#   r.a.b.c = 10
#
# You can also assign properties by passing an argument to the method:
#
#   r.a.b.c 20
#
# If you pass a block, the value will be yielded:
#
#   r.a do |a|
#     a.b do |b|
#       b.c 30
#     end
#   end
#
# If the block passed takes no arguments, it will be <tt>instance_eval</tt>uated
# in the context of the value instead:
#
#   r.a do
#     b do
#       c 40
#     end
#   end
#
# Appending a bang (<tt>!</tt>) to the end of the property sets the value and
# returns the receiver:
#
#   Ribbon.new.x!(10).y!(20).z!(30)
#    => {x: 10, y: 20, z: 30}
#
# Appending a question mark (<tt>?</tt>) to the end of the property returns the
# contents of the property without creating a new ribbon if it is missing:
#
#   r.unknown_property?
#    => nil
#
# You can use any object as key with the <tt>[]</tt> and <tt>[]=</tt> operators:
#
#   r['/some/path'].entries = []
#
# @author Matheus Afonso Martins Moreira
# @since 0.1.0
# @see Ribbon::Raw
class Ribbon

  # The wrapped Ribbon.
  #
  # @return [Ribbon::Raw] the ribbon wrapped by this instance
  # @since 0.8.0
  def raw
    @raw ||= Ribbon::Raw.new
  end

  # Sets this Ribbon's raw ribbon.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] object the hash-like object
  # @return [Ribbon::Raw] the raw ribbon
  # @since 0.8.0
  def raw=(object)
    @raw = Ribbon.extract_raw_from object
  end

  # Initializes a new Ribbon with the given values
  #
  # If given a block, the ribbon will be yielded to it. If the block doesn't
  # take any arguments, it will be evaluated in the context of the ribbon.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] initial_values the initial values
  # @see #ribbon=
  # @see Ribbon#initialize
  def initialize(initial_values = Ribbon::Raw.new, &block)
    self.raw = initial_values
    __yield_or_eval__ &block
  end

  # The hash used by the wrapped Ribbon.
  #
  # @return [Hash] the internal hash of the Ribbon wrapped by this instance
  # @since 0.5.0
  def internal_hash
    raw.__hash__
  end

  # Forwards the method, arguments and block to the wrapped Ribbon's hash, if
  # it responds to the method, or to the ribbon itself otherwise.
  def method_missing(method, *arguments, &block)
    if (hash = internal_hash).respond_to? method then hash
    else raw end.__send__ method, *arguments, &block
  end

  # Merges everything inside this ribbon with everything inside the given
  # ribbon, creating a new instance in the process.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] ribbon the ribbon with new values
  # @return [Ribbon] a new ribbon containing the results of the deep merge
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from this wrapped Ribbon
  # @yieldparam new_value the value from the given ribbon
  # @yieldreturn the object that will be used as the new value
  # @since 0.4.5
  # @see #deep_merge!
  # @see Ribbon.deep_merge
  def deep_merge(ribbon, &block)
    Ribbon.new Ribbon::Raw.deep_merge(self, ribbon, &block)
  end

  # Merges everything inside this ribbon with the given ribbon in place.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] ribbon the ribbon with new values
  # @return [self] this ribbon
  # @yieldparam key the key which identifies both values
  # @yieldparam old_value the value from this wrapped Ribbon
  # @yieldparam new_value the value from the given ribbon
  # @yieldreturn the object that will be used as the new value
  # @since 0.4.5
  # @see #deep_merge
  # @see Ribbon.deep_merge!
  def deep_merge!(ribbon, &block)
    Ribbon::Raw.deep_merge! self, ribbon, &block
  end

  # Converts this ribbon and all ribbons inside into hashes.
  #
  # @return [Hash] the converted contents of this wrapped ribbon
  def to_hash
    to_hash_recursive
  end

  # Converts this ribbon to a hash and serializes it with YAML.
  #
  # @return [String] the YAML string that represents this ribbon
  # @see from_yaml
  def to_yaml
    to_hash.to_yaml
  end

  # Delegates to the raw ribbon.
  #
  # @return [String] the string representation of this ribbon
  # @see Ribbon::Raw#to_s
  def to_s
    raw.to_s
  end

  private

  # Converts this ribbon and all ribbons inside into hashes using recursion.
  #
  # @return [Hash] the converted contents of this ribbon
  def to_hash_recursive(raw_ribbon = self.raw)
    {}.tap do |hash|
      raw_ribbon.__hash__.each do |key, value|
        hash[key] = case value
          when Ribbon then to_hash_recursive value.raw
          when Ribbon::Raw then to_hash_recursive value
          else value
        end
      end
    end
  end

end

class << Ribbon

  alias [] new

  # Deserializes the hash from the string using YAML and uses it to construct a
  # new ribbon.
  #
  # @return [Ribbon] a new ribbon
  # @since 0.4.4
  # @see #to_yaml
  def from_yaml(string)
    Ribbon.new YAML.load string
  end

  # Whether the given object is a {Ribbon::Raw raw ribbon}.
  #
  # @param object the object to be tested
  # @return [true, false] whether the object is a raw ribbon
  # @since 0.8.0
  def raw?(object)
    Ribbon::Raw === object
  end

  alias instance? ===

  # Extracts the hash of a ribbon. Will attempt to convert other objects.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] object the object to convert
  # @return [Hash] the resulting hash
  # @since 0.2.1
  def extract_hash_from(object)
    case object
      when Ribbon, Ribbon::Raw then object.__hash__
      else object.to_hash
    end
  end

  # Extracts a {Ribbon::Raw raw ribbon} from the given object.
  #
  # @param [Ribbon, Ribbon::Raw, #to_hash] object the hash-like object
  # @return [Ribbon::Raw] the raw ribbon
  # @since 0.8.0
  def extract_raw_from(object)
    case object
      when Ribbon then object.raw
      when Ribbon::Raw then object
      else Ribbon::Raw.new object.to_hash
    end
  end

  # Deserializes the hash from the string using YAML and uses it to construct a
  # new ribbon.
  #
  # @param [String] string a valid YAML string
  # @return [Ribbon] a new Ribbon
  # @since 0.4.7
  def from_yaml(string)
    Ribbon.new YAML.load(string)
  end

end

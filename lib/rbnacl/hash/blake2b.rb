# encoding: binary
# frozen_string_literal: true

module RbNaCl
  module Hash
    # The Blake2b hash function
    #
    # Blake2b is based on Blake, a SHA3 finalist which was snubbed in favor of
    # Keccak, a much slower hash function but one sufficiently different from
    # SHA2 to let the SHA3 judges panel sleep easy. Back in the real world,
    # it'd be great if we can calculate hashes quickly if possible.
    #
    # Blake2b provides for up to 64-bit digests and also supports a keyed mode
    # similar to HMAC
    class Blake2b
      extend Sodium

      sodium_type :generichash
      sodium_primitive :blake2b
      sodium_constant :BYTES_MIN
      sodium_constant :BYTES_MAX
      sodium_constant :KEYBYTES_MIN
      sodium_constant :KEYBYTES_MAX
      sodium_constant  :SALTBYTES
      sodium_constant  :PERSONALBYTES

      sodium_function  :generichash_blake2b,
                       :crypto_generichash_blake2b_salt_personal,
                       [:pointer, :size_t, :pointer, :ulong_long, :pointer, :size_t, :pointer, :pointer]

      EMPTY_PERSONAL = ("\0" * PERSONALBYTES).freeze
      EMPTY_SALT     = ("\0" * SALTBYTES).freeze

      # Create a new Blake2b hash object
      #
      # @param [Hash] opts Blake2b configuration
      # @option opts [String]  :key for Blake2b keyed mode
      # @option opts [Integer] :digest_size size of output digest in bytes
      # @option opts [String]  :salt  Provide a salt to support randomised hashing.
      #                               This is mixed into the parameters block to start the hashing.
      # @option opts [Personal] :personal Provide personalisation string to allow pinning a hash for a particular purpose.
      #                                   This is mixed into the parameters block to start the hashing
      #
      # @raise [RbNaCl::LengthError] Invalid length specified for one or more options
      #
      # @return [RbNaCl::Hash::Blake2b] A Blake2b hasher object
      def initialize(opts = {})
        @key = opts.fetch(:key, nil)

        if @key
          @key_size = @key.bytesize
          raise LengthError, "key too short" if @key_size < KEYBYTES_MIN
          raise LengthError, "key too long"  if @key_size > KEYBYTES_MAX
        else
          @key_size = 0
        end

        @digest_size = opts.fetch(:digest_size, BYTES_MAX)
        raise LengthError, "digest size too short" if @digest_size < BYTES_MIN
        raise LengthError, "digest size too long"  if @digest_size > BYTES_MAX

        @personal = opts.fetch(:personal, EMPTY_PERSONAL)
        @personal = Util.zero_pad(PERSONALBYTES, @personal)

        @salt     = opts.fetch(:salt, EMPTY_SALT)
        @salt     = Util.zero_pad(SALTBYTES, @salt)
      end

      # Calculate a Blake2b digest
      #
      # @param [String] message Message to be hashed
      #
      # @return [String] Blake2b digest of the string as raw bytes
      def digest(message)
        digest = Util.zeros(@digest_size)
        self.class.generichash_blake2b(digest, @digest_size, message, message.bytesize, @key, @key_size, @salt, @personal) ||
          raise(CryptoError, "Hashing failed!")
        digest
      end
    end
  end
end

if /(mswin|mingw)/ =~ RUBY_PLATFORM
  /(\d+\.\d+)/ =~ RUBY_VERSION
  ver = $1
  require "#{ver}/lz4ruby.so"
elsif RUBY_PLATFORM == 'java'
  require 'lz4-jruby'
else
  require 'lz4ruby'
end

class LZ4
  def self.compress(input, in_size = nil)
    return _compress(input, in_size, false)
  end

  def self.compressHC(input, in_size = nil)
    return _compress(input, in_size, true)
  end
  
  def self.decompress(input, in_size = nil, encoding = nil)
    in_size = input.bytesize if in_size == nil
    out_size, varbyte_len = decode_varbyte(input)

    if out_size < 0 || varbyte_len < 0
      raise "Compressed data is maybe corrupted"
    end
    
    result = LZ4Internal::uncompress(input, in_size, varbyte_len, out_size)
    result.force_encoding(encoding) if encoding != nil

    return result
  end

  # @deprecated Use {#decompress} and will be removed.
  def self.uncompress(input, in_size = nil)
    return decompress(input, in_size)
  end

  private
  def self._compress(input, in_size, high_compression)
    in_size = input.bytesize if in_size == nil
    header = encode_varbyte(in_size)

    if high_compression
      return LZ4Internal.compressHC(header, input, in_size)
    else
      return LZ4Internal.compress(header, input, in_size)
    end
  end

  private
  def self.encode_varbyte(val)
    varbytes = []

    loop do
      byte = val & 0x7f
      val >>= 7

      if val == 0
        varbytes.push(byte)
        break
      else
        varbytes.push(byte | 0x80)
      end
    end

    return varbytes.pack("C*")
  end

  private
  def self.decode_varbyte(text)
    len = [text.bytesize, 5].min
    bytes = text[0, len].unpack("C*")

    varbyte_len = 0
    val = 0
    bytes.each do |b|
      val |= (b & 0x7f) << (7 * varbyte_len)
      varbyte_len += 1
      return val, varbyte_len if b & 0x80 == 0
    end

    return -1, -1
  end

  # Handles LZ4 native data stream (without any additional headers).
  class Raw
    # Compresses `source` string.
    #
    # @param [String] source string to be compressed
    # @param [Hash] options
    # @option options [Fixnum] :input_size byte size of source to compress (must be less than or equal to `source.bytesize`)
    # @option options [String] :dest output buffer which will receive compressed string
    # @option options [Fixnum] :max_output_size acceptable maximum output size
    # @return [String, Fixnum] compressed string and its length.
    def self.compress(source, options = {})
      return _compress(source, false, options)
    end

    # Compresses `source` string using High Compress Mode.
    #
    # @param [String] source string to be compressed
    # @param [Hash] options
    # @option options [Fixnum] :input_size byte size of source to compress (must be less than or equal to `source.bytesize`)
    # @option options [String] :dest output buffer which will receive compressed string
    # @option options [Fixnum] :max_output_size acceptable maximum output size
    # @return [String, Fixnum] compressed string and its length.
    def self.compressHC(source, options = {})
      return _compress(source, true, options)
    end

    private
    def self._compress(source, high_compression, options = {})
      input_size = options[:input_size]
      if input_size == nil
        input_size = source.bytesize

      else
        if source.bytesize < input_size
          raise ArgumentError, "`:input_size` (#{input_size}) must be less than or equal `source.bytesize` (#{source.bytesize})"
        end
      end

      dest = options[:dest]

      max_output_size = options[:max_output_size]
      if max_output_size == nil
        if dest != nil
          max_output_size = dest.bytesize
        else
          max_output_size = input_size + (input_size / 255) + 16 if dest == nil
        end

      else
        if dest != nil && dest.bytesize < max_output_size
          raise ArgumentError, "`:dest` buffer size (#{dest.bytesize}) must be greater than or equal `:max_output_size` (#{max_output_size})"
        end
      end

      result = nil
      if high_compression
        result = LZ4Internal.compressHC_raw(source, input_size, dest, max_output_size)
      else
        result = LZ4Internal.compress_raw(source, input_size, dest, max_output_size)
      end

      if result[1] <= 0
        raise LZ4Error, "compression failed"
      end

      return result[0], result[1]
    end

    # Decompresses `source` compressed string.
    #
    # @param [String] source
    # @param [Fixnum] max_output_size
    # @param [Hash] options
    # @option options [Fixnum] :input_size byte size of source to decompress (must be less than or equal to `source.bytesize`)
    # @option options [String] :dest output buffer which will receive decompressed string
    # @return [String, Fixnum] decompressed string and its length.
    def self.decompress(source, max_output_size, options = {})
      input_size = options[:input_size]
      if input_size == nil
        input_size = source.bytesize

      else
        if source.bytesize < input_size
          raise ArgumentError, "`:input_size` (#{input_size}) must be less than or equal `source.bytesize` (#{source.bytesize})"
        end
      end

      dest = options[:dest]

      if dest != nil && dest.bytesize < max_output_size
        raise ArgumentError, "`:dest` buffer size (#{dest.bytesize}) must be greater than or equal `max_output_size` (#{max_output_size})"
      end

      result = LZ4Internal.decompress_raw(source, input_size, dest, max_output_size)

      if result[1] <= 0
        return "", 0 if source == "\x00"
        raise LZ4Error, "decompression failed"
      end

      return result[0], result[1]
    end
  end
end

class LZ4Error < StandardError
end

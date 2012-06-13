if /(mswin|mingw)/ =~ RUBY_PLATFORM
  /(\d+\.\d+)/ =~ RUBY_VERSION
  ver = $1
  require "#{ver}/lz4ruby.so"
else
  require 'lz4ruby'
end

class LZ4
  def self.compress(source, src_size = nil)
    src_size = source.length if src_size == nil
    return LZ4Native::compress(source, src_size)
  end

  def self.compressHC(source, src_size = nil)
    src_size = source.length if src_size == nil
    return LZ4Native::compressHC(source, src_size)
  end

  def self.uncompress(source)
    return LZ4Native::uncompress(source)
  end
end

#!/usr/bin/env ruby

require './compressor.rb'

class LZOCompressor < Compressor
  def require_libs
    require 'lzoruby'
  end

  def compress_text(text)
    return LZO.compress(text)
  end

  def uncompress_text(compressed)
    return LZO.decompress(compressed)
  end
end

def create_compressor(chunk_size)
  return LZOCompressor.new(chunk_size)
end

if $0 == __FILE__
  Compressor.unit_driver() { |chunk_size| LZOCompressor.new(chunk_size) }
end

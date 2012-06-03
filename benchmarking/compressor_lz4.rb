#!/usr/bin/env ruby

require './compressor.rb'

class LZ4Compressor < Compressor
  def require_libs
    require 'lz4-ruby'
  end

  def compress_text(text)
    return LZ4::compress(text)
  end

  def uncompress_text(compressed)
    return LZ4::uncompress(compressed)
  end
end

def create_compressor(chunk_size)
  return LZ4Compressor.new(chunk_size)
end

if $0 == __FILE__
  Compressor.unit_driver() { |chunk_size| LZ4Compressor.new(chunk_size) }
end

#!/usr/bin/env ruby

require './compressor.rb'

class SnappyCompressor < Compressor
  def require_libs
    require 'snappy'
  end

  def compress_text(text)
    return Snappy.deflate(text)
  end

  def uncompress_text(compressed)
    return Snappy.inflate(compressed)
  end
end

def create_compressor(chunk_size)
  return SnappyCompressor.new(chunk_size)
end

if $0 == __FILE__
  Compressor.unit_driver() { |chunk_size| SnappyCompressor.new(chunk_size) }
end

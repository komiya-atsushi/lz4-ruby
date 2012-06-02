require 'lz4ruby'

class LZ4
  def self.compress(source)
    return LZ4Native::compress(source)
  end

  def self.uncompress(source)
    return LZ4Native::uncompress(source)
  end
end

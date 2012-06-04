require 'helper'

class TestLz4Ruby < Test::Unit::TestCase
  context "LZ4::compress" do
    257.times do |t|
      len = t + 1
      text = "a" * len

      should "text of #{len} \"a\"'s" do
        compressed = LZ4::compress(text)
        uncompressed = LZ4::uncompress(compressed)
        assert_equal(text, uncompressed)
      end
    end
  end
end

require 'helper'

class TestLz4Ruby < Test::Unit::TestCase
  LOOP_COUNT = 257
  
  @@random = Random.new(123)

  context "LZ4::compress" do
    should "empty text" do
      compressed = LZ4::compress("")
      uncompressed = LZ4::uncompress(compressed)
      assert_empty("", uncompressed)
    end
    
    LOOP_COUNT.times do |t|
      len = t + 1
      text = "a" * len

      should "text of #{len} \"a\"'s" do
        compressed = LZ4::compress(text)
        uncompressed = LZ4::uncompress(compressed)
        assert_equal(text, uncompressed)
      end
    end

    LOOP_COUNT.times do |t|
      len = t + 1
      text = @@random.bytes(len)
      
      should "random text of #{len} bytes" do
        compressed = LZ4::compress(text)
        uncompressed = LZ4::uncompress(compressed)
        assert_equal(text, uncompressed)
      end
    end

    text = "b" * LOOP_COUNT
    LOOP_COUNT.times do |t|
      len = t + 1
      should "#{len} bytes substring of #{LOOP_COUNT} bytes \"b\"'s" do
        compressed = LZ4::compress(text, len)
        uncompressed = LZ4::uncompress(compressed)
        assert_equal(text[0, len], uncompressed)
      end
    end
  end

  context "LZ4::compressHC" do
    should "empty text" do
      compressed = LZ4::compressHC("")
      uncompressed = LZ4::uncompress(compressed)
      assert_empty("", uncompressed)
    end
    
    LOOP_COUNT.times do |t|
      len = t + 1
      text = "a" * len

      should "text of #{len} \"a\"'s" do
        compressed = LZ4::compressHC(text)
        uncompressed = LZ4::uncompress(compressed)
        assert_equal(text, uncompressed)
      end
    end

    LOOP_COUNT.times do |t|
      len = t + 1
      text = @@random.bytes(len)
      
      should "random text of #{len} bytes" do
        compressed = LZ4::compressHC(text)
        uncompressed = LZ4::uncompress(compressed)
        assert_equal(text, uncompressed)
      end
    end
    
    text = "b" * LOOP_COUNT
    LOOP_COUNT.times do |t|
      len = t + 1
      should "#{len} bytes substring of #{LOOP_COUNT} bytes \"b\"'s" do
        compressed = LZ4::compressHC(text, len)
        uncompressed = LZ4::uncompress(compressed)
        assert_equal(text[0, len], uncompressed)
      end
    end
  end
end

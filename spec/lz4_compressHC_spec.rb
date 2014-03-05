require './spec/helper'

describe "LZ4::compress" do
  LOOP_COUNT = 257

  context "give empty text" do
    compressed = LZ4.compressHC("")
    uncompressed = LZ4.uncompress(compressed)

    it "should be able to uncompress" do
      expect(uncompressed).to eql("")
    end
  end

  context "give long text" do
    text = "a" * 131073
    compressed = LZ4.compressHC(text)
    uncompressed = LZ4.uncompress(compressed)

    it "should compress smaller than original text" do
      expect(compressed.size).to be < text.length
    end

    it "should be able to uncompress" do
      expect(uncompressed).to eql(text)
    end
  end

  LOOP_COUNT.times do |t|
    len = t + 1
    text = "a" * len

    context "give text of #{len} \"a\"'s" do
      compressed = LZ4.compressHC(text)
      uncompressed = LZ4.uncompress(compressed)
      it "should be able to uncompress" do
        expect(uncompressed).to eql(text)
      end
    end
  end  

  LOOP_COUNT.times do |t|
    len = t + 1
    text = generate_random_bytes(len)

    context "give text of #{len} bytes" do
      compressed = LZ4.compressHC(text)
      uncompressed = LZ4.uncompress(compressed)
      it "should be able to uncompress" do
        expect(uncompressed).to eql(text)
      end
    end
  end  
end

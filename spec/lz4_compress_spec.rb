# -*- coding: utf-8 -*-

require './spec/helper'

describe "LZ4::compress" do
  LOOP_COUNT = 257

  context "give empty text" do
    compressed = LZ4.compress("")
    decompressed = LZ4.decompress(compressed)

    it "should be able to decompress" do
      expect(decompressed).to eql("")
    end
  end

  context "give long text" do
    text = "a" * 131073
    compressed = LZ4.compress(text)
    decompressed = LZ4.decompress(compressed)

    it "should be compressed length less than original text" do
      expect(compressed.size).to be < text.length
    end

    it "should be able to decompress" do
      expect(decompressed).to eql(text)
    end
  end

  LOOP_COUNT.times do |t|
    len = t + 1
    text = "a" * len

    context "give text of #{len} \"a\"'s" do
      compressed = LZ4.compress(text)
      decompressed = LZ4.decompress(compressed)
      it "should be able to decompress" do
        expect(decompressed).to eql(text)
      end
    end
  end  

  LOOP_COUNT.times do |t|
    len = t + 1
    text = generate_random_bytes(len)

    context "give text of #{len} bytes" do
      compressed = LZ4.compress(text)
      decompressed = LZ4.decompress(compressed)
      it "should be able to decompress" do
        expect(decompressed).to eql(text)
      end
    end
  end  

  context "give UTF-8 text" do
    text = "いろはにほへと"
    compressed = LZ4.compress(text)
    decompressed = LZ4.decompress(compressed, compressed.bytesize, "UTF-8")
    it "should be able to decompress" do
      expect(decompressed).to eql(text)
    end
  end
end

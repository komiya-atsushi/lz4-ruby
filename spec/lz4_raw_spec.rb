require './spec/helper'

describe "LZ4::Raw compressibility" do
  context "give 'lz4-ruby.rb' file" do
    filename = "./lib/lz4-ruby.rb"
    text = IO.readlines(filename).join("\n")

    compressed, comp_size = LZ4::Raw.compress(text)
    compressedHC, compHC_size = LZ4::Raw.compressHC(text)

    decompressed, decomp_size = LZ4::Raw.decompress(compressed, text.length)
    decompressedHC, decompHC_size = LZ4::Raw.decompress(compressedHC, text.length)

    it "should be able to comprese smaller than original text" do
      expect(comp_size).to be < text.length
    end

    it "should be able to compressHC smaller than original text" do
      expect(compHC_size).to be < text.length
    end

    it "should be able to compressHC smaller than compress" do
      expect(compHC_size).to be < comp_size
    end

    it "should be able to decompress from compressed text" do
      expect(decompressed).to eql(text)
    end
    
    it "should be able to decompress from compressHCed text" do
      expect(decompressedHC).to eql(text)
    end
  end
end

require './spec/helper'

describe "LZ4::Raw::compress" do
  context "give empty text" do
    compressed, size = LZ4::Raw.compress("")

    expected = [0x00]

    it "should be compressed to length #{expected.size}" do
      expect(size).to eql(expected.size)
      expect(compressed.size).to eql(expected.size)
    end

    it "should be compressed into '#{expected}'" do
      expect(compressed).to eql(expected.pack("C*"))
    end
  end

  text = "aaaaaaaaaaaaaaaaaaaa"
  context "give text #{text}" do
    expected = [0x1a, 0x61, 0x01, 0x00, 0x50, 0x61, 0x61, 0x61, 0x61, 0x61]

    context "without output buffer" do
      compressed, size = LZ4::Raw.compress(text)

      it "should be compressed to length #{expected.size}" do
        expect(size).to eql(expected.size)
        expect(compressed.size).to eql(expected.size)
      end

      it "should be compressed into '#{expected}'" do
        expect(compressed).to eql(expected.pack("C*"))
      end
    end
    
    context "with output buffer" do
      out_buf = " " * 10

      context "enough buffer size (#{out_buf.size})" do
        compressed, size = LZ4::Raw.compress(text, :dest => out_buf)

        it "should be compressed to length #{expected.size}" do
          expect(size).to eql(expected.size)
        end

        it "should be compressed into '#{expected}'" do
          expect(compressed[0, size]).to eql(expected.pack("C*"))
        end
      end

      out_buf = " " * 3

      context "poor buffer size (#{out_buf.size})" do
        it "shoud be thrown LZ4Error" do
          expect {
            compressed, size = LZ4::Raw.compress(text, :dest => out_buf)
          }.to raise_error(LZ4Error, "compression failed")
        end
      end
    end

    context "with max_output_size" do
      max_output_size = 10
      context "enough max_output_size #{max_output_size}" do
        compressed, size = LZ4::Raw.compress(text, :max_output_size => max_output_size)

        it "should be compressed to length #{expected.size}" do
          expect(size).to eql(expected.size)
        end

        it "should be compressed into '#{expected}'" do
          expect(compressed[0, size]).to eql(expected.pack("C*"))
        end
      end

      max_output_size = 3
      context "poor max_output_size #{max_output_size}" do
        it "shoud be thrown LZ4Error" do
          expect {
            compressed, size = LZ4::Raw.compress(text, :max_output_size => max_output_size)
          }.to raise_error(LZ4Error, "compression failed")
        end
      end
    end

    context "with output buffer and max_output_size" do
      context "when size of output buffer less than max_output_size " do
        it "should be thrown ArgumentError" do
          # TODO
#          expect {
#          }.to raise_error(ArgumentError)
        end
      end
    end
  end
end

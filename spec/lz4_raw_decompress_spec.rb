require './spec/helper'

describe "LZ4::Raw.decompress" do
  context "give compressed empty text" do
    decompressed, size = LZ4::Raw.decompress([0x00].pack("C*"), 0)

    it "should be decompressed to length zero" do
      expect(size).to eql(0)
      expect(decompressed.size).to eql(0)
      expect(decompressed).to eql("")
    end
  end

  context "give compressed text '#{compressed = [0x1a, 0x61, 0x01, 0x00, 0x50, 0x61, 0x61, 0x61, 0x61, 0x61]}'" do
    expected = "aaaaaaaaaaaaaaaaaaaa"

    context "with enough max_output_size" do
      decompressed, size = LZ4::Raw.decompress(compressed.pack("C*"), 30)

      it "should be decompressed to length #{expected.size}" do
        expect(size).to eql(expected.size)
        expect(decompressed.size).to eql(expected.size)
      end

      it "should be decompressed into '#{expected}'" do
        expect(decompressed).to eql(expected)
      end
    end

    context "with poor max_output_size" do
      it "should be thrown LZ4Error" do
        expect {
          decompressed, size = LZ4::Raw.decompress(compressed.pack("C*"), 10)
        }.to raise_error LZ4Error, "decompression failed"
      end
    end

    context "with input_size" do
      context "#{compressed.length}, which is equal to compressed text length" do
        decompressed, size = LZ4::Raw.decompress(compressed.pack("C*") + "     ", 30, :input_size => compressed.size)

        it "should be decompressed to length #{expected.size}" do
          expect(size).to eql(expected.size)
          expect(decompressed.size).to eql(expected.size)
        end

        it "should be decompressed into '#{expected}'" do
          expect(decompressed).to eql(expected)
        end
      end

      context "20 which is greater than compressed text length (#{compressed.length})" do
        input_size = 20

        it "should be thrown ArgumentError" do
          expect {
            decompressed, size = LZ4::Raw.decompress(compressed.pack("C*"), 30, :input_size => input_size)
          }.to raise_error ArgumentError, "`:input_size` (20) must be less than or equal `source.bytesize` (#{compressed.length})"
        end
      end
    end

    context "with output buffer" do
      context "enough buffer size: 30" do
        out_buf_size = 30
        out_buf = " " * out_buf_size

        decompressed, size = LZ4::Raw.decompress(compressed.pack("C*"), out_buf_size, :dest => out_buf)

        it "should be decompressed to length #{expected.size}" do
          expect(size).to eql(expected.size)
        end

        it "should be unchanged output buffer size" do
          expect(decompressed.size).to eql(out_buf_size)
        end

        it "should be decompressed into '#{expected}'" do
          expect(decompressed[0, size]).to eql(expected)
        end

        it "should be used output buffer" do
          expect(decompressed).to eql(out_buf)
        end
      end

      context "poor buffer size: 19" do
        out_buf_size = 19
        out_buf = " " * out_buf_size

        it "should be thrown LZ4Error" do
          expect {
            decompressed, size = LZ4::Raw.decompress(compressed.pack("C*"), out_buf_size, :dest => out_buf)
          }.to raise_error LZ4Error, "decompression failed"
        end
      end
    end

    context "with output buffer and max_output_size" do
      context "when size of output buffer: 30, which is greater than max_output_size: 20" do
        out_buf_size = 30
        max_output_size = 20
        out_buf = " " * out_buf_size

        decompressed, size = LZ4::Raw.decompress(compressed.pack("C*"), max_output_size, :dest => out_buf)

        it "should be decompressed to length #{expected.size}" do
          expect(size).to eql(expected.size)
        end

        it "should be decompressed into '#{expected}'" do
          expect(decompressed[0, size]).to eql(expected)
        end
      end

      context "when size of output buffer: 10, which is less than max_output_size: 20" do
        out_buf_size = 10
        max_output_size = 20
        out_buf = " " * out_buf_size

        it "should be thrown ArgumentError" do
          expect {
            decompressed, size = LZ4::Raw.decompress(compressed.pack("C*"), max_output_size, :dest => out_buf)
          }.to raise_error ArgumentError, "`:dest` buffer size (10) must be greater than or equal `max_output_size` (20)"
        end
      end
    end
  end
end

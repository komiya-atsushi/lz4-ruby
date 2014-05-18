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

  context "give text #{text = "aaaaaaaaaaaaaaaaaaaa"}" do
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
    
    context "with input_size" do
      context "(3) which is less than input text length (#{text.length})" do
        input_size = 3
        compressed, size = LZ4::Raw.compress(text, :input_size => input_size)

        aaa_ex = [0x30, 0x61, 0x61, 0x61]

        it "should be compressed to length #{aaa_ex.size}" do
          expect(size).to eql(aaa_ex.size)
          expect(compressed.size).to eql(aaa_ex.size)
        end

        it "should be compressed into #{aaa_ex}" do
          expect(compressed).to eql(aaa_ex.pack("C*"))
        end
      end

      context "(30) which is greater than input text length (#{text.length})" do
        input_size = 30
        it "should be thrown ArgumentError" do
          expect {
            compressed, size = LZ4::Raw.compress(text, :input_size => input_size)
          }.to raise_error(ArgumentError, "`:input_size` (30) must be less than or equal `source.bytesize` (20)")
        end
      end
    end

    context "with output buffer" do
      context "enough buffer size: 10" do
        out_buf_size = 10
        out_buf = " " * out_buf_size

        compressed, size = LZ4::Raw.compress(text, :dest => out_buf)

        it "should be compressed to length #{expected.size}" do
          expect(size).to eql(expected.size)
        end

        it "should be unchanged output buffer size" do
          expect(compressed.size).to eql(out_buf_size)
        end

        it "should be compressed into '#{expected}'" do
          expect(compressed[0, size]).to eql(expected.pack("C*"))
        end

        it "should be used output buffer" do
          expect(compressed).to eql(out_buf)
        end
      end

      context "poor buffer size: 3" do
        out_buf_size = 3
        out_buf = " " * out_buf_size

        it "shoud be thrown LZ4Error" do
          expect {
            compressed, size = LZ4::Raw.compress(text, :dest => out_buf)
          }.to raise_error(LZ4Error, "compression failed")
        end
      end
    end

    context "with max_output_size" do
      context "enough max_output_size: 10" do
        max_output_size = 10
        compressed, size = LZ4::Raw.compress(text, :max_output_size => max_output_size)

        it "should be compressed to length #{expected.size}" do
          expect(size).to eql(expected.size)
        end

        it "should be compressed into '#{expected}'" do
          expect(compressed[0, size]).to eql(expected.pack("C*"))
        end
      end

      context "poor max_output_size: 3" do
        max_output_size = 3
        it "shoud be thrown LZ4Error" do
          expect {
            compressed, size = LZ4::Raw.compress(text, :max_output_size => max_output_size)
          }.to raise_error(LZ4Error, "compression failed")
        end
      end
    end

    context "with output buffer and max_output_size" do
      context "when size of output buffer: 30, which is greater than max_output_size: 20" do
        out_buf_size = 30
        max_output_size = 20
        out_buf = " " * out_buf_size

        compressed, size = LZ4::Raw.compress(text, :dest => out_buf, :max_output_size => max_output_size)

        it "should be compressed to length #{expected.size}" do
          expect(size).to eql(expected.size)
        end

        it "should be compressed into '#{expected}'" do
          expect(compressed[0, size]).to eql(expected.pack("C*"))
        end
      end

      context "when size of output buffer: 10, which is less than max_output_size: 20" do
        out_buf_size = 10
        max_output_size = 20
        out_buf = " " * out_buf_size

        it "should be thrown ArgumentError" do
          expect {
            compressed, size = LZ4::Raw.compress(text, :dest => out_buf, :max_output_size => max_output_size)
          }.to raise_error(ArgumentError, "`:dest` buffer size (10) must be greater than or equal `:max_output_size` (20)")
        end
      end
    end
  end
end

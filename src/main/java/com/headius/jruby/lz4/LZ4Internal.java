package com.headius.jruby.lz4;

import net.jpountz.lz4.LZ4Compressor;
import net.jpountz.lz4.LZ4Exception;
import net.jpountz.lz4.LZ4Factory;
import org.jruby.RubyArray;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

import java.util.Arrays;

@SuppressWarnings("UnusedParameters")
public class LZ4Internal {
    private static final LZ4Factory FACTORY = LZ4Factory.fastestInstance();

    private static RubyArray compressInternal(
            ThreadContext context,
            LZ4Compressor compressor,
            IRubyObject _header,
            IRubyObject _input,
            IRubyObject _inputSize,
            IRubyObject _outputBuffer,
            IRubyObject _maxOutputSize) {

        byte[] headerBytes = {};
        int headerSize = 0;
        if (isNotNil(_header)) {
            ByteList header = _header.convertToString().getByteList();
            headerBytes = header.getUnsafeBytes();
            headerSize = header.getRealSize();
        }

        int inputSize = intFrom(_inputSize);
        ByteOutput output;
        if (isNotNil(_outputBuffer)) {
            output = new ByteOutput(_outputBuffer, _maxOutputSize);

        } else if (isNotNil(_maxOutputSize)) {
            int maxOutputSize = intFrom(_maxOutputSize) + headerSize;
            output = new ByteOutput(maxOutputSize);

        } else {
            int maxOutputSize = compressor.maxCompressedLength(inputSize) + headerSize;
            output = new ByteOutput(maxOutputSize);
        }

        System.arraycopy(
                headerBytes, 0,
                output.unsafeBytes, 0,
                headerSize);

        ByteInput input = new ByteInput(_input);
        try {
            int compressedSize = compressor.compress(
                    input.unsafeBytes, input.offset, inputSize,
                    output.unsafeBytes, output.offset + headerSize, output.bufferSize - headerSize);

            return RubyArray.newArray(context.runtime, Arrays.asList(
                    output.toRubyString(context, compressedSize + headerSize),
                    RubyInteger.int2fix(context.runtime, compressedSize)));

        } catch (LZ4Exception ignore) {
            return RubyArray.newArray(context.runtime, Arrays.asList(
                    null,
                    RubyInteger.int2fix(context.runtime, -1)));
        }
    }

    private static RubyArray decompressInternal(
            ThreadContext context,
            IRubyObject _offset,
            IRubyObject _input,
            IRubyObject _inputSize,
            IRubyObject _outputBuffer,
            IRubyObject _maxOutputSize) {

        int offset = 0;
        if (isNotNil(_offset)) {
            offset = intFrom(_offset);
        }

        ByteOutput output;
        if (isNotNil(_outputBuffer)) {
            output = new ByteOutput(_outputBuffer, _maxOutputSize);

        } else {
            output = new ByteOutput(intFrom(_maxOutputSize));
        }

        ByteInput input = new ByteInput(_input);
        try {
            int decompressedSize = FACTORY.unknwonSizeDecompressor()
                    .decompress(
                            input.unsafeBytes, input.offset + offset, intFrom(_inputSize) - offset,
                            output.unsafeBytes, output.offset, output.bufferSize);

            return RubyArray.newArray(context.runtime, Arrays.asList(
                    output.toRubyString(context, decompressedSize),
                    RubyInteger.int2fix(context.runtime, decompressedSize)));

        } catch (LZ4Exception ignore) {
            return RubyArray.newArray(context.runtime, Arrays.asList(
                    null,
                    RubyInteger.int2fix(context.runtime, -1)));
        }
    }

    @JRubyMethod(module = true)
    public static IRubyObject compress(ThreadContext context, IRubyObject self, IRubyObject _header, IRubyObject _input, IRubyObject _in_size) {
        RubyArray array = compressInternal(context,
                FACTORY.fastCompressor(),
                _header,
                _input,
                _in_size,
                null,
                null);
        return array.first();
    }

    @JRubyMethod(module = true)
    public static IRubyObject compressHC(ThreadContext context, IRubyObject self, IRubyObject _header, IRubyObject _input, IRubyObject _in_size) {
        RubyArray array = compressInternal(context,
                FACTORY.highCompressor(),
                _header,
                _input,
                _in_size,
                null,
                null);
        return array.first();
    }

    @JRubyMethod(required = 4, module = true)
    public static IRubyObject uncompress(ThreadContext context, IRubyObject self, IRubyObject[] args) {
        RubyString input = args[0].convertToString();
        RubyInteger in_size = args[1].convertToInteger();
        RubyInteger header_size = args[2].convertToInteger();
        RubyInteger buf_size = args[3].convertToInteger();

        RubyArray array = decompressInternal(context,
                header_size,
                input,
                in_size,
                null,
                buf_size);
        return array.first();
    }

    @JRubyMethod(required = 4, module = true)
    public static IRubyObject compress_raw(
            ThreadContext context,
            IRubyObject self,
            IRubyObject[] args) {

        IRubyObject _input = args[0];
        IRubyObject _inputSize = args[1];
        IRubyObject _outputBuffer = args[2];
        IRubyObject _maxOutputSize = args[3];

        return compressInternal(context,
                FACTORY.fastCompressor(),
                null,
                _input,
                _inputSize,
                _outputBuffer,
                _maxOutputSize);
    }

    @JRubyMethod(required = 4, module = true)
    public static IRubyObject compressHC_raw(
            ThreadContext context,
            IRubyObject self,
            IRubyObject[] args) {

        IRubyObject _input = args[0];
        IRubyObject _inputSize = args[1];
        IRubyObject _outputBuffer = args[2];
        IRubyObject _maxOutputSize = args[3];

        return compressInternal(context,
                FACTORY.highCompressor(),
                null,
                _input,
                _inputSize,
                _outputBuffer,
                _maxOutputSize);
    }

    @JRubyMethod(required = 4, module = true)
    public static IRubyObject decompress_raw(
            ThreadContext context,
            IRubyObject self,
            IRubyObject[] args) {

        IRubyObject _input = args[0];
        IRubyObject _inputSize = args[1];
        IRubyObject _outputBuffer = args[2];
        IRubyObject _maxOutputSize = args[3];

        return decompressInternal(
                context,
                null,
                _input,
                _inputSize,
                _outputBuffer,
                _maxOutputSize);
    }

    static class ByteInput {
        public final RubyString rubyString;
        public final ByteList byteList;
        public final byte[] unsafeBytes;
        public final int offset;
        public final int realSize;

        public ByteInput(IRubyObject buffer) {
            rubyString = buffer.convertToString();
            byteList = rubyString.getByteList();
            unsafeBytes = byteList.getUnsafeBytes();
            offset = byteList.getBegin();
            realSize = byteList.getRealSize();
        }
    }

    static class ByteOutput {
        public final RubyString rubyString;
        public final ByteList byteList;
        public final byte[] unsafeBytes;
        public final int offset;
        public final int bufferSize;

        public ByteOutput(IRubyObject buffer, IRubyObject size) {
            bufferSize = intFrom(size);
            rubyString = buffer.convertToString();
            byteList = rubyString.getByteList();
            unsafeBytes = byteList.getUnsafeBytes();
            offset = byteList.getBegin();
        }

        public ByteOutput(int size) {
            bufferSize = size;
            rubyString = null;
            byteList = null;
            unsafeBytes = new byte[bufferSize];
            offset = 0;
        }

        RubyString toRubyString(ThreadContext context, int length) {
            if (rubyString != null) {
                return rubyString;
            }

            return RubyString.newString(context.runtime, unsafeBytes, 0, length);
        }
    }

    /**
     * Test if specified IRubyObject is not null / nil.
     *
     * @param obj
     * @return
     */
    private static boolean isNotNil(IRubyObject obj) {
        return obj != null && !obj.isNil();
    }

    /**
     * Returns a integer value from specified IRubyObject.
     *
     * @param obj
     * @return
     */
    private static int intFrom(IRubyObject obj) {
        RubyInteger rubyInt = obj.convertToInteger();
        return (int) rubyInt.getLongValue();
    }
}

package com.headius.jruby.lz4;

import net.jpountz.lz4.LZ4Compressor;
import net.jpountz.lz4.LZ4Factory;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

public class LZ4Internal {
    private static final LZ4Factory FACTORY = LZ4Factory.fastestInstance();
    
    public static IRubyObject compress_internal(ThreadContext context, LZ4Compressor compressor, IRubyObject _header, IRubyObject _input, IRubyObject _in_size) {
        RubyString input = _input.convertToString();
        RubyString header = _header.convertToString();
        RubyInteger in_size = _in_size.convertToInteger();
        
        ByteList inputBL = input.getByteList();
        int srcSize = (int)in_size.getLongValue();
        
        ByteList headerBL = header.getByteList();
        int headerSize = headerBL.getRealSize();
        
        int bufSize = compressor.maxCompressedLength(srcSize);
        byte[] buf = new byte[bufSize + headerSize];
        
        System.arraycopy(headerBL.getUnsafeBytes(), headerBL.getBegin(), buf, 0, headerSize);
        
        compressor.compress(inputBL.getUnsafeBytes(), inputBL.getBegin(), srcSize, buf, headerSize);
        
        return RubyString.newStringNoCopy(context.runtime, buf);
    }
    
    @JRubyMethod(module = true)
    public static IRubyObject compress(ThreadContext context, IRubyObject self, IRubyObject _header, IRubyObject _input, IRubyObject _in_size) {
        return compress_internal(context, FACTORY.fastCompressor(), _header, _input, _in_size);
    }
    
    @JRubyMethod(module = true)
    public static IRubyObject compressHC(ThreadContext context, IRubyObject self, IRubyObject _header, IRubyObject _input, IRubyObject _in_size) {
        return compress_internal(context, FACTORY.highCompressor(), _header, _input, _in_size);
    }
    
    @JRubyMethod(required = 4, module = true)
    public static IRubyObject uncompress(ThreadContext context, IRubyObject self, IRubyObject[] args) {
        RubyString input = args[0].convertToString();
        RubyInteger in_size = args[1].convertToInteger();
        RubyInteger header_size = args[2].convertToInteger();
        RubyInteger buf_size = args[3].convertToInteger();
        
        ByteList inputBL = input.getByteList();
        int inSize = (int)in_size.getLongValue();
        int headerSize = (int)header_size.getLongValue();
        int bufSize = (int)buf_size.getLongValue();
        
        byte[] buf = new byte[bufSize];
        
        FACTORY.decompressor().decompress(inputBL.getUnsafeBytes(), inputBL.getBegin() + headerSize, buf, 0, buf.length);
        
        return RubyString.newStringNoCopy(context.runtime, buf);
    }
}

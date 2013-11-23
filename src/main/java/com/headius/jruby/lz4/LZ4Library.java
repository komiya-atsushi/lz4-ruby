package com.headius.jruby.lz4;

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.runtime.load.Library;

public class LZ4Library implements Library {

    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule lz4Internal = runtime.defineModule("LZ4Internal");
        
        lz4Internal.defineAnnotatedMethods(LZ4Internal.class);
        
        lz4Internal.defineClassUnder("Error", runtime.getStandardError(), runtime.getStandardError().getAllocator());
    }
    
}

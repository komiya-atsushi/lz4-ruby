class Compressor
  DEFAULT_CHUNK_SIZE = 8 << 20
  
  def initialize(chunk_size)
    if chunk_size == nil
      @chunk_size = DEFAULT_CHUNK_SIZE
    else
      @chunk_size = chunk_size
    end
    
    require_libs()
  end

  def compress(infile, outfile)
    loop do
      text = infile.read(@chunk_size)
      break if text == nil || text.length == 0

      compressed = compress_text(text)
      comp_size = compressed.length

      outfile.write([comp_size].pack("L"))
      outfile.write(compressed)
    end
  end

  def uncompress(infile, outfile)
    loop do
      comp_size = infile.read(4)
      break if comp_size == nil || comp_size.length == 0

      comp_size = comp_size.unpack("L")[0]
      compressed = infile.read(comp_size)

      text = uncompress_text(compressed)

      outfile.write(text)
    end
  end

  def self.unit_driver()
    if !(ARGV.length == 1) && !(ARGV.length == 2 && ARGV[0] == 'c')
      puts <<EOS
Compress:
    ./#{$0} c <infile >outfile

Uncompress:
    ./#{$0} u <infile >outfile
EOS
      exit 1
    end
  
    require 'rubygems'

    case ARGV[0]
    when 'c'
      chunk_size = nil
      chunk_size = ARGV[1].to_i if ARGV.length == 2
      compressor = create_compressor(chunk_size)
      compressor.compress($stdin, $stdout)
    
    when 'u'
      compressor = create_compressor(nil)
      compressor.uncompress($stdin, $stdout)

    else
      puts "Error: illegal argument '#{ARGV[0]}'"
      exit 1
    end
  end
end

require 'benchmark'
require 'rubygems'

CHUNK_SIZE = 8 << 20
NUM_LOOP = 10

class DevNullIO
  def write(arg)
    # Do nothing
  end
end

class StringIO
  def initialize(text)
    @text = text
    @len = text.length
    @pos = 0
  end

  def read(length)
    return nil if @pos == @len

    length = @len - @pos if @pos + length > @len
    
    result = @text[@pos, length]
    @pos += length
    
    return result
  end
end

class CompressorBenchmark
  USAGE = <<EOS
Usage:
    ruby #{$0} compressor testdata

Compressor:
    lz4
    snappy
    lzo
EOS

  def initialize(args)
    if args.length != 2
      puts USAGE
      exit 1
    end

    @signature = args[0]
    @compressor_rb = "compressor_#{@signature}.rb"
    
    if !File.file?(@compressor_rb)
      puts "Error: Compressor '#{@compressor_rb}' is not found."
      puts USAGE
      exit 1
    end

    @testdata_filename = args[1]
    if !File.file?(@testdata_filename)
      puts "Error: testdata `#{@testdata_filename}` is not found."
      puts USAGE
      exit 1
    end

    @compressed_filename = "#{@testdata_filename}.#{@signature}.compressed"
    
    require "./#{@compressor_rb}"
    @compressor = create_compressor(CHUNK_SIZE)
  end

  def setup_compressed
    `ruby #{@compressor_rb} c #{CHUNK_SIZE} <#{@testdata_filename} >#{@compressed_filename}`
  end

  def benchmark_compression
    data = nil
    File.open(@testdata_filename) do |file|
      data = file.read(File.size(@testdata_filename))
    end

    devnull = DevNullIO.new

    # warm up
    @compressor.compress(StringIO.new(data), devnull)

    result = Benchmark.measure {
      NUM_LOOP.times { |t| @compressor.compress(StringIO.new(data), devnull) }
    }

    return result
  end
  
  def benchmark_uncompression
    data = nil
    File.open(@compressed_filename) do |file|
      data = file.read(File.size(@compressed_filename))
    end

    devnull = DevNullIO.new

    # warm up
    @compressor.uncompress(StringIO.new(data), devnull)

    result = Benchmark.measure {
      NUM_LOOP.times { |t| @compressor.uncompress(StringIO.new(data), devnull) }
    }

    return result
  end

  def show_result(result_comp, result_uncomp)
    orig_size = File.size(@testdata_filename)
    comp_size = File.size(@compressed_filename)
    
    ratio = comp_size * 8.0 / orig_size
    comp_time = result_comp.real * 1000.0 / NUM_LOOP
    uncomp_time = result_uncomp.real * 1000.0 / NUM_LOOP

    puts "method\tratio(bpc)\tcomp.time(ms)\tuncomp.time(ms)"
    puts "-------------------------------------------------------"
    puts "%s\t%.3f\t\t%.2f\t\t%.2f" % [@signature, ratio, comp_time, uncomp_time]
  end

  def do_benchmark
    setup_compressed()

    result_comp = benchmark_compression()
    result_uncomp = benchmark_uncompression()

    show_result(result_comp, result_uncomp)
  end
end

if $0 == __FILE__
  CompressorBenchmark.new(ARGV).do_benchmark
end


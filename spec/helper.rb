require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'ext/lz4ruby'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

build_native = <<EOS
cd ext/lz4ruby
ruby extconf.rb
make clean
make
EOS
`#{build_native}`

require 'lz4-ruby'

def generate_random_bytes(len)
  result = []
  len.times do |t|
    result << rand(256)
  end
  return result.pack("C*")
end


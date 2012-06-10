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
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'ext/lz4-ruby'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

build_native = <<EOS
cd ext/lz4-ruby
ruby extconf.rb
make clean
make
EOS
`#{build_native}`

require 'lz4-ruby'

class Test::Unit::TestCase
end

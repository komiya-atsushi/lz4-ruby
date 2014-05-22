# -*- mode: ruby -*-
# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
jeweler_tasks = Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "lz4-ruby"
  gem.homepage = "http://github.com/komiya-atsushi/lz4-ruby"
  gem.license = "MIT"
  gem.summary = %Q{Ruby bindings for LZ4 (Extremely Fast Compression algorithm).}
  gem.description = %Q{Ruby bindings for LZ4. LZ4 is a very fast lossless compression algorithm.}
  gem.email = "komiya.atsushi@gmail.com"
  gem.authors = ["KOMIYA Atsushi"]
  gem.extensions = ["ext/lz4ruby/extconf.rb"]
  
  gem.files.exclude("*.sh")
  
  gem.files.include("ext/lz4ruby/*.c")
  gem.files.include("ext/lz4ruby/*.h")

  gem.required_ruby_version = '>= 1.9'
  
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

$gemspec = jeweler_tasks.gemspec
$gemspec.version = jeweler_tasks.jeweler.version

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "lz4-ruby #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rake/extensiontask'
Rake::ExtensionTask.new("lz4ruby", $gemspec) do |ext|
  ext.cross_compile = true
  ext.cross_platform = ["x86-mingw32"]
end

Rake::Task.tasks.each do |task_name|
  case task_name.to_s
  when /^native/
    task_name.prerequisites.unshift('fix_rake_compiler_gemspec_dump')
  end
end

task :fix_rake_compiler_gemspec_dump do
  %w{files extra_rdoc_files test_files}.each do |accessor|
    $gemspec.send(accessor).instance_eval {
      @exclude_procs = Array.new
    }
  end
end

task :gems do
  sh "rake clean build:cross"
  sh "rake clean build"
end

task "build:cross" => [:modify_gemspec_for_windows, :build] do
  file = "pkg/lz4-ruby-#{get_version}.gem"
end

task "build:jruby" => [:modify_gemspec_for_jruby, :compile_jruby, :build]

task :modify_gemspec_for_windows do
  $gemspec.extensions = []
  $gemspec.files.include("lib/?.?/*.so")
  $gemspec.platform = "x86-mingw32"
end

task :modify_gemspec_for_jruby do
  $gemspec.extensions = []
  $gemspec.files.include("lib/*.jar")
  $gemspec.platform = "java"
end

task :compile_jruby do
  system 'mvn package'
end

def get_version
  `cat VERSION`.chomp
end

#!/usr/bin/env bash

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

rm -rf tmp/*
rm -rf pkg/*

rm -rf lib/1.8 lib/1.9

# compile 1.8.7 native extensions for MinGW
rvm use 1.8.7 --default
rvm gemset use lz4-ruby
bundle exec rake cross compile RUBY_CC_VERSION=1.8.7

# compile 1.9.3 native extensions for MinGW
rvm use 1.9.3 --default
rvm gemset use lz4-ruby
bundle exec rake cross compile RUBY_CC_VERSION=1.9.3

# copy native extensions -> lib/1.x
rvm use 1.8.7 --default
rvm gemset use lz4-ruby
bundle exec rake cross compile RUBY_CC_VERSION=1.8.7:1.9.3

rm lib/lz4ruby.so

# build pre-compiled gem for MinGW
bundle exec rake build:cross

# build "Compile-It-Yourself" gem
rm -rf lib/1.8 lib/1.9
bundle exec rake build

#!/usr/bin/env bash

# Requirements:
#   mingw32 (# sudo aptitude install mingw32 )
#   rvm (# curl -L get.rvm.io | bash -s stable )

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

rvm install 1.8.7
rvm use 1.8.7 --default
rvm gemset create lz4-ruby
rvm gemset use lz4-ruby
gem install bundler -v 1.0.22
bundle install
bundle exec rake-compiler cross-ruby VERSION=1.8.7-p358 EXTS=--without-extensions

rvm install 1.9.3
rvm use 1.9.3 --default
rvm gemset create lz4-ruby
rvm gemset use lz4-ruby
gem install bundler -v 1.0.22
bundle install
bundle exec rake-compiler cross-ruby VERSION=1.9.3-p194 EXTS=--without-extensions


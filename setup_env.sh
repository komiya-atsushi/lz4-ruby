#!/usr/bin/env bash

# Requirements:
#   mingw32 (# sudo aptitude install mingw32 )
#   rvm (# curl -L get.rvm.io | bash -s stable )

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

function setup_ruby_env() {
    VER=$1

    rvm install ${VER}
    rvm use ${VER} --default
    rvm gemset create lz4-ruby
    rvm gemset use lz4-ruby
    gem install bundler
    bundle install
}

VER_MRI_18=`rvm list known_strings | grep 1.8.7-p | sed -e s/ruby-//`
VER_MRI_19=`rvm list known_strings | grep 1.9.3-p | sed -e s/ruby-//`
VER_JRUBY=`rvm list known_strings | grep jruby-1.7.8`

setup_ruby_env ${VER_MRI_18}
bundle exec rake-compiler cross-ruby VERSION=${VER_MRI_18} EXTS=--without-extensions
setup_ruby_env ${VER_MRI_19}
bundle exec rake-compiler cross-ruby VERSION=${VER_MRI_19} EXTS=--without-extensions
setup_ruby_env ${VER_JRUBY}

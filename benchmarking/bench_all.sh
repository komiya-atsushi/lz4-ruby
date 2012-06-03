#!/bin/sh

ruby bench.rb lz4 $1
ruby bench.rb snappy $1 | tail -n 1
ruby bench.rb lzo $1 | tail -n 1

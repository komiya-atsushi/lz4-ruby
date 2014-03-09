require 'mkmf'

$CFLAGS += " -Wall -std=c99 "

create_makefile('lz4ruby')


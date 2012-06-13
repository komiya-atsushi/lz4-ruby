require 'mkmf'

LZ4_REV_NO = 66

URL = "http://lz4.googlecode.com/svn-history/r#{LZ4_REV_NO}/trunk/"

def download_from_web(file)
  File.delete(file) if File.file?(file)
  `wget #{URL}/#{file}`
  
  if $?.exitstatus != 0
    return false
  end
  
  return true
end

[ "lz4.c",
  "lz4.h",
  "lz4hc.c",
  "lz4hc.h" ].each do |filename|
#  exit if !download_from_web(filename)
end

$CFLAGS += " -Wall "

create_makefile('lz4ruby')


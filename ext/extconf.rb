require 'mkmf'

LZ4_REV_NO = 66

URL = "http://lz4.googlecode.com/svn-history/r#{LZ4_REV_NO}/trunk/"

def download_from_web(url)
  `wget #{url}`
  
  if $?.exitstatus != 0
    return false
  end
  
  return true
end

return if !download_from_web("#{URL}/lz4.c")
return if !download_from_web("#{URL}/lz4.h")
return if !download_from_web("#{URL}/lz4hc.c")
return if !download_from_web("#{URL}/lz4hc.h")

$CFLAGS += " -Wall "

create_makefile('lz4ruby')


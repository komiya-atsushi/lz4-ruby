#include <ruby.h>
#include "lz4.h"
#include "lz4hc.h"

typedef int (*CompressFunc)(const char *source, char *dest, int isize);

static VALUE lz4;
static VALUE lz4_error;

static VALUE compress(CompressFunc compressor, VALUE self, VALUE source) {
  const char *src_p = NULL;
  char *buf = NULL;
  VALUE result;
  int src_size;
  int buf_size;
  int comp_size;

  Check_Type(source, T_STRING);
  src_p = RSTRING_PTR(source);
  src_size = RSTRING_LEN(source);
  buf_size = LZ4_compressBound(src_size);

  result = rb_str_new(NULL, buf_size + 4);
  buf = RSTRING_PTR(result);

  buf[0] = (char)((src_size >> 24) & 0xff);
  buf[1] = (char)((src_size >> 16) & 0xff);
  buf[2] = (char)((src_size >> 8) & 0xff);
  buf[3] = (char)(src_size & 0xff);

  comp_size = compressor(src_p, buf + 4, src_size);
  rb_str_resize(result, comp_size + 4);

  return result;
}

static VALUE lz4_ruby_compress(VALUE self, VALUE source) {
  return compress(LZ4_compress, self, source);
}

static VALUE lz4_ruby_compressHC(VALUE self, VALUE source) {
  return compress(LZ4_compressHC, self, source);
}

static VALUE lz4_ruby_uncompress(VALUE self, VALUE source) {
  const char *src_p = NULL;
  char *buf = NULL;
  VALUE result;
  int src_size;
  int buf_size;
  int read_bytes;

  Check_Type(source, T_STRING);
  src_p = RSTRING_PTR(source);
  src_size = RSTRING_LEN(source);

  buf_size = ((src_p[0] & 0xffU) << 24)
    | ((src_p[1] & 0xffU) << 16)
    | ((src_p[2] & 0xffU) << 8)
    | (src_p[3] & 0xffU);

  result = rb_str_new(NULL, buf_size + 1);
  buf = RSTRING_PTR(result);

  read_bytes = LZ4_uncompress(src_p + 4, buf, buf_size);
  if (read_bytes < 0) {
    rb_raise(lz4_error, "Compressed data is maybe corrupted.");
  }

  buf[buf_size] = '\0';

  return result;
}

void Init_lz4ruby(void) {
  lz4 = rb_define_module("LZ4Native");

  rb_define_module_function(lz4, "compress", lz4_ruby_compress, 1);
  rb_define_module_function(lz4, "compressHC", lz4_ruby_compressHC, 1);
  rb_define_module_function(lz4, "uncompress", lz4_ruby_uncompress, 1);

  lz4_error = rb_define_class_under(lz4, "Error", rb_eStandardError);
}

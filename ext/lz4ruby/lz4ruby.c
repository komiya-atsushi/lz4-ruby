#include <ruby.h>
#include "lz4.h"
#include "lz4hc.h"

typedef int (*CompressFunc)(const char *source, char *dest, int isize);

static VALUE lz4internal;
static VALUE lz4_error;

/**
 * LZ4Internal functions.
 */
static VALUE compress_internal(CompressFunc compressor, VALUE header, VALUE input, VALUE in_size) {
  const char *src_p;
  int src_size;

  const char *header_p;
  int header_size;

  VALUE result;
  char *buf;
  int buf_size;

  int comp_size;

  Check_Type(input, T_STRING);
  src_p = RSTRING_PTR(input);
  src_size = NUM2INT(in_size);
  buf_size = LZ4_compressBound(src_size);

  Check_Type(header, T_STRING);
  header_p = RSTRING_PTR(header);
  header_size = RSTRING_LEN(header);

  result = rb_str_new(NULL, buf_size + header_size);
  buf = RSTRING_PTR(result);

  memcpy(buf, header_p, header_size);

  comp_size = compressor(src_p, buf + header_size, src_size);
  rb_str_resize(result, comp_size + header_size);

  return result;
}

static VALUE lz4internal_compress(VALUE self, VALUE header, VALUE input, VALUE in_size) {
  return compress_internal(LZ4_compress, header, input, in_size);
}

static VALUE lz4internal_compressHC(VALUE self, VALUE header, VALUE input, VALUE in_size) {
  return compress_internal(LZ4_compressHC, header, input, in_size);
}

static VALUE lz4internal_uncompress(VALUE self, VALUE input, VALUE in_size, VALUE offset, VALUE out_size) {
  const char *src_p;
  int src_size;

  int header_size;

  VALUE result;
  char *buf;
  int buf_size;

  int read_bytes;

  Check_Type(input, T_STRING);
  src_p = RSTRING_PTR(input);
  src_size = NUM2INT(in_size);

  header_size = NUM2INT(offset);
  buf_size = NUM2INT(out_size);

  result = rb_str_new(NULL, buf_size);
  buf = RSTRING_PTR(result);

  read_bytes = LZ4_uncompress_unknownOutputSize(src_p + header_size, buf, src_size - header_size, buf_size);
  if (read_bytes < 0) {
    rb_raise(lz4_error, "Compressed data is maybe corrupted.");
  }

  return result;
}

void Init_lz4ruby(void) {
  lz4internal = rb_define_module("LZ4Internal");

  rb_define_module_function(lz4internal, "compress", lz4internal_compress, 3);
  rb_define_module_function(lz4internal, "compressHC", lz4internal_compressHC, 3);
  rb_define_module_function(lz4internal, "uncompress", lz4internal_uncompress, 4);

  lz4_error = rb_define_class_under(lz4internal, "Error", rb_eStandardError);
}

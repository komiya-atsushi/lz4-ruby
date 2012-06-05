#include <ruby.h>
#include "lz4.h"
#include "lz4hc.h"

typedef int (*CompressFunc)(const char *source, char *dest, int isize);

static VALUE lz4;
static VALUE lz4_error;

static int encode_varbyte(int value, char *buf) {
  buf[0] = value & 0x7f; value >>= 7;
  if (value == 0) { return 1; }
  buf[0] |= 0x80;
  
  buf[1] = value & 0x7f; value >>= 7;
  if (value == 0) { return 2; }
  buf[1] |= 0x80;
  
  buf[2] = value & 0x7f; value >>= 7;
  if (value == 0) { return 3; }
  buf[2] |= 0x80;
  
  buf[3] = value & 0x7f; value >>= 7;
  if (value == 0) { return 4; }
  buf[3] |= 0x80;

  buf[4] = value & 0x7f;
  return 5;
}

static int decode_varbyte(const char *src, int len, int *value) {
  if (len < 1) { return -1; }

  *value = src[0] & 0x7f;
  if ((src[0] & 0x80) == 0) { return 1; }
  if (len < 2) { return -1; }

  *value |= (src[1] & 0x7f) << 7;
  if ((src[1] & 0x80) == 0) { return 2; }
  if (len < 3) { return -1; }

  *value |= (src[2] & 0x7f) << 14;
  if ((src[2] & 0x80) == 0) { return 3; }
  if (len < 4) { return -1; }

  *value |= (src[3] & 0x7f) << 21;
  if ((src[3] & 0x80) == 0) { return 4; }
  if (len < 5) { return -1; }

  *value |= (src[4] & 0x7f) << 28;

  return 5;
}

static VALUE compress(CompressFunc compressor, VALUE self, VALUE source) {
  const char *src_p = NULL;
  char varbyte[5];
  char *buf = NULL;
  VALUE result;
  int src_size;
  int varbyte_len;
  int buf_size;
  int comp_size;

  Check_Type(source, T_STRING);
  src_p = RSTRING_PTR(source);
  src_size = RSTRING_LEN(source);
  buf_size = LZ4_compressBound(src_size);

  varbyte_len = encode_varbyte(src_size, varbyte);

  result = rb_str_new(NULL, buf_size + varbyte_len);
  buf = RSTRING_PTR(result);

  memcpy(buf, varbyte, varbyte_len);

  comp_size = compressor(src_p, buf + varbyte_len, src_size);
  rb_str_resize(result, comp_size + varbyte_len);

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
  int varbyte_len;
  int buf_size = 0;
  int read_bytes;

  Check_Type(source, T_STRING);
  src_p = RSTRING_PTR(source);
  src_size = RSTRING_LEN(source);

  varbyte_len = decode_varbyte(src_p, src_size, &buf_size);

  result = rb_str_new(NULL, buf_size);
  buf = RSTRING_PTR(result);

  read_bytes = LZ4_uncompress(src_p + varbyte_len, buf, buf_size);
  if (read_bytes < 0) {
    rb_raise(lz4_error, "Compressed data is maybe corrupted.");
  }

  return result;
}

void Init_lz4ruby(void) {
  lz4 = rb_define_module("LZ4Native");

  rb_define_module_function(lz4, "compress", lz4_ruby_compress, 1);
  rb_define_module_function(lz4, "compressHC", lz4_ruby_compressHC, 1);
  rb_define_module_function(lz4, "uncompress", lz4_ruby_uncompress, 1);

  lz4_error = rb_define_class_under(lz4, "Error", rb_eStandardError);
}

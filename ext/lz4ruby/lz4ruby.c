#include <ruby.h>
#include "lz4.h"
#include "lz4hc.h"

typedef int (*CompressFunc)(const char *source, char *dest, int isize);
typedef int (*CompressLimitedOutputFunc)(const char* source, char* dest, int inputSize, int maxOutputSize);

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

static VALUE compress_raw_internal(
    CompressLimitedOutputFunc compressor,
    VALUE _input,
    VALUE _input_size,
    VALUE _output_buffer,
    VALUE _max_output_size) {

  const char *src_p;
  int src_size;

  int needs_resize;
  char *buf_p;

  int max_output_size;

  int comp_size;


  Check_Type(_input, T_STRING);
  src_p = RSTRING_PTR(_input);
  src_size = NUM2INT(_input_size);

  if (NIL_P(_output_buffer)) {
    needs_resize = 1;
    _output_buffer = rb_str_new(NULL, _max_output_size);

  } else {
    needs_resize = 0;
  }

  buf_p = RSTRING_PTR(_output_buffer);

  max_output_size = NUM2INT(_max_output_size);

  comp_size = compressor(src_p, buf_p, src_size, max_output_size);

  if (comp_size > 0 && needs_resize) {
    rb_str_resize(_output_buffer, comp_size);
  }

  return rb_ary_new3(2, _output_buffer, INT2NUM(comp_size));
}

static VALUE lz4internal_compress_raw(
    VALUE self,
    VALUE _input,
    VALUE _input_size,
    VALUE _output_buffer,
    VALUE _max_output_size)
  {
    return compress_raw_internal(
        LZ4_compress_limitedOutput,
	_input,
	_input_size,
	_output_buffer,
	_max_output_size);
}

static VALUE lz4internal_compressHC_raw(
    VALUE self,
    VALUE _input,
    VALUE _input_size,
    VALUE _output_buffer,
    VALUE _max_output_size)
  {
    return compress_raw_internal(
        LZ4_compressHC_limitedOutput,
	_input,
	_input_size,
	_output_buffer,
	_max_output_size);
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

  read_bytes = LZ4_decompress_safe(src_p + header_size, buf, src_size - header_size, buf_size);
  if (read_bytes < 0) {
    rb_raise(lz4_error, "Compressed data is maybe corrupted.");
  }

  return result;
}

static VALUE lz4internal_decompress_raw(
    VALUE self,
    VALUE _input,
    VALUE _input_size,
    VALUE _output_buffer,
    VALUE _max_output_size) {

  const char *src_p;
  int src_size;

  int max_output_size;

  int needs_resize;
  char *buf_p;

  int decomp_size;

  Check_Type(_input, T_STRING);
  src_p = RSTRING_PTR(_input);
  src_size = NUM2INT(_input_size);

  max_output_size = NUM2INT(_max_output_size);

  if (NIL_P(_output_buffer)) {
    needs_resize = 1;
    _output_buffer = rb_str_new(NULL, max_output_size);

  } else {
    needs_resize = 0;
  }

  buf_p = RSTRING_PTR(_output_buffer);
  decomp_size = LZ4_decompress_safe(src_p, buf_p, src_size, max_output_size);

  if (decomp_size > 0 && needs_resize) {
    rb_str_resize(_output_buffer, decomp_size);
  }

  return rb_ary_new3(2, _output_buffer, INT2NUM(decomp_size));
}

#if 0

static inline void lz4internal_raw_compress_scanargs(int argc, VALUE *argv, VALUE *src, VALUE *dest, size_t *srcsize, size_t *maxsize) {
  switch (argc) {
  case 1:
    *src = argv[0];
    Check_Type(*src, RUBY_T_STRING);
    *srcsize = RSTRING_LEN(*src);
    *dest = rb_str_buf_new(0);
    *maxsize = LZ4_compressBound(*srcsize);
    break;
  case 2:
    *src = argv[0];
    Check_Type(*src, RUBY_T_STRING);
    *srcsize = RSTRING_LEN(*src);
    if (TYPE(argv[1]) == T_STRING) {
      *dest = argv[1];
      *maxsize = LZ4_compressBound(*srcsize);
    } else {
      *dest = rb_str_buf_new(0);
      *maxsize = NUM2SIZET(argv[1]);
    }
    break;
  case 3:
    *src = argv[0];
    Check_Type(*src, RUBY_T_STRING);
    *srcsize = RSTRING_LEN(*src);
    *dest = argv[1];
    Check_Type(*dest, RUBY_T_STRING);
    *maxsize = NUM2SIZET(argv[2]);
    break;
  default:
    //rb_error_arity(argc, 1, 3);
    rb_scan_args(argc, argv, "12", NULL, NULL, NULL);
    // the following code is used to eliminate compiler warnings.
    *src = *dest = 0;
    *srcsize = *maxsize = 0;
  }
}

static inline VALUE lz4internal_raw_compress_common(int argc, VALUE *argv, VALUE lz4, CompressLimitedOutputFunc compressor) {
  VALUE src, dest;
  size_t srcsize;
  size_t maxsize;

  lz4internal_raw_compress_scanargs(argc, argv, &src, &dest, &srcsize, &maxsize);

  if (srcsize > LZ4_MAX_INPUT_SIZE) {
    rb_raise(lz4_error,
             "input size is too big for lz4 compress (max %u bytes)",
             LZ4_MAX_INPUT_SIZE);
  }
  rb_str_modify(dest);
  rb_str_resize(dest, maxsize);
  rb_str_set_len(dest, 0);

  int size = compressor(RSTRING_PTR(src), RSTRING_PTR(dest), srcsize, maxsize);
  if (size < 0) {
    rb_raise(lz4_error, "failed LZ4 raw compress");
  }

  rb_str_resize(dest, size);
  rb_str_set_len(dest, size);

  return dest;
}

/*
 * call-seq:
 *  (compressed string data)  raw_compress(src)
 *  (compressed string data)  raw_compress(src, max_dest_size)
 *  (dest with compressed string data)  raw_compress(src, dest)
 *  (dest with compressed string data)  raw_compress(src, dest, max_dest_size)
 */
static VALUE lz4internal_raw_compress(int argc, VALUE *argv, VALUE lz4i) {
  return lz4internal_raw_compress_common(argc, argv, lz4i, LZ4_compress_limitedOutput);
}

/*
 * call-seq:
 *  (compressed string data)  raw_compressHC(src)
 *  (compressed string data)  raw_compressHC(src, max_dest_size)
 *  (dest with compressed string data)  raw_compressHC(src, dest)
 *  (dest with compressed string data)  raw_compressHC(src, dest, max_dest_size)
 */
static VALUE lz4internal_raw_compressHC(int argc, VALUE *argv, VALUE lz4i) {
  return lz4internal_raw_compress_common(argc, argv, lz4i, LZ4_compressHC_limitedOutput);
}

enum {
  LZ4RUBY_UNCOMPRESS_MAXSIZE = 1 << 24, // tentative value
};

static inline void lz4internal_raw_uncompress_scanargs(int argc, VALUE *argv, VALUE *src, VALUE *dest, size_t *maxsize) {
  switch (argc) {
  case 1:
    *src = argv[0];
    Check_Type(*src, RUBY_T_STRING);
    *dest = rb_str_buf_new(0);
    *maxsize = LZ4RUBY_UNCOMPRESS_MAXSIZE;
    break;
  case 2:
    *src = argv[0];
    Check_Type(*src, RUBY_T_STRING);
    *dest = argv[1];
    if (TYPE(*dest) == T_STRING) {
      *maxsize = LZ4RUBY_UNCOMPRESS_MAXSIZE;
    } else {
      *maxsize = NUM2SIZET(*dest);
      *dest = rb_str_buf_new(0);
    }
    break;
  case 3:
    *src = argv[0];
    Check_Type(*src, RUBY_T_STRING);
    *dest = argv[1];
    Check_Type(*dest, RUBY_T_STRING);
    *maxsize = NUM2SIZET(argv[2]);
    break;
  default:
    //rb_error_arity(argc, 2, 3);
    rb_scan_args(argc, argv, "21", NULL, NULL, NULL);
    // the following code is used to eliminate compiler warnings.
    *src = *dest = 0;
    *maxsize = 0;
  }
}

/*
 * call-seq:
 *  (uncompressed string data)  raw_uncompress(src, max_dest_size = 1 << 24)
 *  (dest for uncompressed string data)  raw_uncompress(src, dest, max_dest_size = 1 << 24)
 */
static VALUE lz4internal_raw_uncompress(int argc, VALUE *argv, VALUE lz4i) {
  VALUE src, dest;
  size_t maxsize;
  lz4internal_raw_uncompress_scanargs(argc, argv, &src, &dest, &maxsize);

  rb_str_modify(dest);
  rb_str_resize(dest, maxsize);
  rb_str_set_len(dest, 0);

  int size = LZ4_decompress_safe(RSTRING_PTR(src), RSTRING_PTR(dest), RSTRING_LEN(src), maxsize);
  if (size < 0) {
    rb_raise(lz4_error, "failed LZ4 raw uncompress at %d", -size);
  }

  rb_str_resize(dest, size);
  rb_str_set_len(dest, size);

  return dest;
}

#endif

void Init_lz4ruby(void) {
  lz4internal = rb_define_module("LZ4Internal");

  rb_define_module_function(lz4internal, "compress", lz4internal_compress, 3);
  rb_define_module_function(lz4internal, "compressHC", lz4internal_compressHC, 3);
  rb_define_module_function(lz4internal, "uncompress", lz4internal_uncompress, 4);

  //rb_define_module_function(lz4internal, "raw_compress", lz4internal_raw_compress, -1);
  //rb_define_module_function(lz4internal, "raw_compressHC", lz4internal_raw_compressHC, -1);
  //rb_define_module_function(lz4internal, "raw_uncompress", lz4internal_raw_uncompress, -1);

  rb_define_module_function(lz4internal, "compress_raw", lz4internal_compress_raw, 4);
  rb_define_module_function(lz4internal, "compressHC_raw", lz4internal_compressHC_raw, 4);
  rb_define_module_function(lz4internal, "decompress_raw", lz4internal_decompress_raw, 4);

  lz4_error = rb_define_class_under(lz4internal, "Error", rb_eStandardError);
}

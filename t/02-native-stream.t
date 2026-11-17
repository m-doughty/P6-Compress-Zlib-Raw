use v6;
use Test;
use NativeCall;
use Compress::Zlib::Raw;

is zlibVersion(), '1.4', 'native runtime is the bundled release';
is nativesizeof(z_stream), nativesizeof(long) == 8 ?? 112 !! 88,
	'z_stream has the platform C layout';
my $flags = zlibCompileFlags();
is $flags +& 3, 1, 'zlib unsigned int is 32 bits';
is ($flags +> 2) +& 3, nativesizeof(long) == 8 ?? 2 !! 1,
	'zlib unsigned long matches NativeCall long width';
is ($flags +> 4) +& 3, 2, 'zlib pointers are 64 bits';

my $input = Buf.new((^16385).map({ ($_ * 17) % 256 }));
my $compressed = Buf.new;
$compressed[compressBound($input.bytes) - 1] = 0;
my $compressor = z_stream.new;
is deflateInit2($compressor, 6, Compress::Zlib::Raw::Z_DEFLATED, 15, 8,
	Compress::Zlib::Raw::Z_DEFAULT_STRATEGY), Compress::Zlib::Raw::Z_OK,
	'deflate initialization accepts the version and structure';
$compressor.set-input($input);
$compressor.set-output($compressed);
is deflate($compressor, Compress::Zlib::Raw::Z_FINISH),
	Compress::Zlib::Raw::Z_STREAM_END, 'compression reaches stream end';
is $compressor.avail-in, 0, 'compression consumes the whole input';
is $compressor.total-in, $input.bytes, 'native input counter is exact';
my $compressed-size = $compressor.total-out;
is deflateEnd($compressor), Compress::Zlib::Raw::Z_OK,
	'compression native state is released';

my $output = Buf.new;
$output[$input.bytes - 1] = 0;
my $compressed-input = $compressed.subbuf(0, $compressed-size);
my $decompressor = z_stream.new;
is inflateInit2($decompressor, 15), Compress::Zlib::Raw::Z_OK,
	'inflate initialization accepts the version and structure';
$decompressor.set-input($compressed-input);
$decompressor.set-output($output);
is inflate($decompressor, Compress::Zlib::Raw::Z_FINISH),
	Compress::Zlib::Raw::Z_STREAM_END, 'decompression reaches stream end';
is $decompressor.total-out, $input.bytes, 'native output counter is exact';
is-deeply $output, $input, 'multi-buffer-sized binary content roundtrips';
is inflateEnd($decompressor), Compress::Zlib::Raw::Z_OK,
	'decompression native state is released';

# A fixed external zlib stream protects against matching encoder/decoder bugs.
my $fixture = Buf.new(<78 9c cb 48 cd c9 c9 57 28 cf 2f ca 49 01 00 1a 0b 04 5d>.map({ :16($_) }));
my $plain = Buf.new(0 xx 32);
my $size = CArray[long].new;
$size[0] = $plain.bytes;
is uncompress($plain, $size, $fixture, $fixture.bytes),
	Compress::Zlib::Raw::Z_OK, 'independent zlib fixture decompresses';
is $plain.subbuf(0, $size[0]).decode, 'hello world', 'fixture output is exact';

$fixture[*-1] +^= 1;
$size[0] = $plain.bytes;
is uncompress($plain, $size, $fixture, $fixture.bytes),
	Compress::Zlib::Raw::Z_DATA_ERROR, 'corrupt checksum returns a native data error';
$size[0] = 1;
is compress($plain, $size, $input, $input.bytes),
	Compress::Zlib::Raw::Z_BUF_ERROR, 'undersized destination returns a native buffer error';

done-testing;

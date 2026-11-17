use v6;
use Test;

my $root = $*PROGRAM.parent.parent.absolute.IO;
my $lib = $root.add('lib');

sub loader-error(Str:D $body) {
	my $process = run $*EXECUTABLE, "-I$lib", '-e', $body, :out, :err;
	my $stdout = $process.out.slurp(:close);
	my $stderr = $process.err.slurp(:close);
	($process.exitcode, $stdout, $stderr);
}

my ($os-exit, $os-out, $os-error) = loader-error(q:to/PROGRAM/);
use Compress::Zlib::Raw;
my $*KERNEL = class {
	method name { 'unsupported-test' }
	method hardware { 'x86_64' }
}.new;
say zlibVersion();
PROGRAM
isnt $os-exit, 0, 'unsupported operating system fails';
is $os-out, '', 'unsupported operating system does not load system zlib';
like $os-error, /'has no bundled zlib for operating system'/,
	'unsupported operating system has a useful diagnostic';

my ($arch-exit, $arch-out, $arch-error) = loader-error(q:to/PROGRAM/);
use Compress::Zlib::Raw;
my $*KERNEL = class {
	method name { 'darwin' }
	method hardware { 'sparc64' }
}.new;
say zlibVersion();
PROGRAM
isnt $arch-exit, 0, 'unsupported architecture fails';
is $arch-out, '', 'unsupported architecture does not load system zlib';
like $arch-error, /'has no bundled zlib for architecture'/,
	'unsupported architecture has a useful diagnostic';

# An intact module/metadata copy without native resources must not find system zlib.
my $scratch = $*TMPDIR.add("zlib-raw-missing-resources-$*PID-{now.Int}");
$scratch.mkdir;
$scratch.add('lib').mkdir;
$scratch.add('lib/Compress').mkdir;
$scratch.add('lib/Compress/Zlib').mkdir;
my $source = $scratch.add('lib/Compress/Zlib/Raw.pm6');
my $metadata = $scratch.add('META6.json');
$root.add('lib/Compress/Zlib/Raw.pm6').copy($source);
$root.add('META6.json').copy($metadata);
LEAVE {
	$source.unlink if $source.e;
	$metadata.unlink if $metadata.e;
	# Precompilation is disabled below, so only these owned directories exist.
	$scratch.add('lib/Compress/Zlib').rmdir;
	$scratch.add('lib/Compress').rmdir;
	$scratch.add('lib').rmdir;
	$scratch.rmdir;
}
my %*ENV = %*ENV;
%*ENV<RAKUDO_NO_PRECOMPILATION> = '1';
my $process = run $*EXECUTABLE, "-I{$scratch.add('lib')}", '-e',
	'use Compress::Zlib::Raw; say zlibVersion()', :out, :err;
my $stdout = $process.out.slurp(:close);
my $stderr = $process.err.slurp(:close);
isnt $process.exitcode, 0, 'missing bundled library fails';
is $stdout, '', 'missing bundled library does not load system zlib';
like $stderr, /'missing bundled zlib resource'/, 'missing library has a useful diagnostic';

done-testing;

[![Actions Status](https://github.com/m-doughty/P6-Compress-Zlib-Raw/actions/workflows/test.yml/badge.svg)](https://github.com/m-doughty/P6-Compress-Zlib-Raw/actions)

NAME
====

Compress::Zlib::Raw - Low-level NativeCall bindings to zlib

DESCRIPTION
===========

Low-level NativeCall bindings to zlib, with bundled zlib 1.4 libraries.

The package loads its own library from distribution resources. It does not use a system zlib, download libraries, or compile code during installation. Missing resources and unsupported platforms produce an error.

SUPPORTED PLATFORMS
===================

<table class="pod-table">
<thead><tr>
<th>Platform</th> <th>Architectures</th> <th>Minimum runtime</th>
</tr></thead>
<tbody>
<tr> <td>macOS</td> <td>x86-64, ARM64</td> <td>macOS 11</td> </tr> <tr> <td>Windows</td> <td>x86-64, ARM64</td> <td>Windows with the Universal C Runtime</td> </tr> <tr> <td>Linux with glibc</td> <td>x86-64</td> <td>glibc 2.14</td> </tr> <tr> <td>Linux with glibc</td> <td>ARM64</td> <td>glibc 2.17</td> </tr> <tr> <td>Linux with musl</td> <td>x86-64, ARM64</td> <td>See the bundled artifact manifest</td> </tr>
</tbody>
</table>

Linux selects its libc variant from the running process's mapped loader. It requires access to `/proc/self/maps`. Only 64-bit processes are supported.

Artifact origins, checksums, and build details are recorded in [resources/native-manifest.json](resources/native-manifest.json). The zlib license is included in [resources/licenses/zlib.txt](resources/licenses/zlib.txt).

EXAMPLE
=======

```raku
use v6;
use Compress::Zlib::Raw;
use NativeCall;

my $to-compress = 'test'.encode;
my $return-buf-len = CArray[long].new;
$return-buf-len[0] = 128;

my $return-buf = buf8.new;
$return-buf[127] = 0;

my $result = compress($return-buf, $return-buf-len, $to-compress, 4);
die if $result != Compress::Zlib::Raw::Z_OK;

my $orig-buf = buf8.new;
$orig-buf[127] = 1;

my $orig-size = CArray[long].new;
$orig-size[0] = 128;

$result = uncompress($orig-buf, $orig-size, $return-buf, $return-buf-len[0]);
die if $result != Compress::Zlib::Raw::Z_OK;
say $orig-buf.subbuf(0, $orig-size[0]).decode; # test
```

AUTHORS AND MAINTAINERS
=======================

Originally written by Andrew Egeler (retupmoca), [https://github.com/retupmoca/](https://github.com/retupmoca/). Maintained in this fork by Matt Doughty.

LICENSE AND COPYRIGHT
=====================

The Raku bindings use the MIT License. Bundled zlib libraries use the zlib license; their notice is preserved in `resources/licenses/zlib.txt`.


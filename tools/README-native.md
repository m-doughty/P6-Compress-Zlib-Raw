# Updating bundled zlib

The distribution ships standalone zlib 1.4 shared libraries in `resources/lib`.
Installation does not download or compile native code. Do not copy libraries
from an arbitrary machine or use an unpinned latest URL.

`resources/native-manifest.json` records each archive URL and SHA-256,
archive member, modification, final resource SHA-256, and platform requirements.
`resources/licenses/zlib.txt` contains upstream's unchanged license notice.

## Prebuilt binaries

Download the exact archive named in the manifest, verify its SHA-256, and
extract the specified member into its resource path:

- Windows: MSYS2 UCRT64 for x86-64, CLANGARM64 for ARM64. Use `libz-1.dll`,
  the normal C ABI library, renamed to `zlib.dll`. Do not substitute the
  `libzlibwapi.dll` ABI or the contrib `zlib1.dll` build.
- Linux glibc: Homebrew bottles. Public GHCR downloads accept the anonymous
  header `Authorization: Bearer QQ==`. Remove the package-manager search paths
  with `patchelf --remove-rpath libz.so.1` (0.18.0 used here). Check that no
  RPATH/RUNPATH remains and only system libraries appear in DT_NEEDED.
- Linux musl: Alpine's `zlib-1.4-r0.apk`. The manifest pins the whole package
  SHA-256. During initial import its compressed control stream's SHA-1 also
  matched APKINDEX's Q1 checksum, and its compressed data stream's SHA-256
  matched `.PKGINFO`'s `datahash`. These checks used HTTPS package metadata;
  this import did not independently verify an Alpine signing key.

The glibc binaries require symbols through GLIBC_2.14 on x86-64 and
GLIBC_2.17 on ARM64. This is a symbol inspection, not an exhaustive test
against every older distribution. The musl binaries were built on Alpine edge;
a minimum compatible musl version has not been established.

Inspect architecture, exported C symbols and runtime dependencies with
`llvm-objdump -p` or equivalent. Windows binaries must not introduce an MSYS2
runtime dependency. Keep any future non-system dependencies explicit.

## macOS binaries

Use two clean extractions of the upstream source archive pinned in the
manifest. Build each independently with the Apple Command Line Tools:

```sh
CC='clang -arch arm64' \
CFLAGS='-O2 -mmacosx-version-min=11.0' \
LDFLAGS='-arch arm64 -mmacosx-version-min=11.0' ./configure
make -j4
make test
```

Repeat in the other source directory, replacing `arm64` with `x86_64`.
On the build Mac, Rosetta ran the x86-64 upstream static and shared tests.
Copy `libz.1.4.dylib` to the corresponding `resources/lib/macos-*/libz.dylib`.
For each copied library, set the relocatable install name and refresh its
ad-hoc signature:

```sh
install_name_tool -id @rpath/libz.1.dylib path/to/libz.dylib
codesign --force --sign - path/to/libz.dylib
```

Confirm both architectures and the macOS 11.0 minimum using `otool -l`.
`otool -L` should show only the library's own ID and `/usr/lib/libSystem.B.dylib`.
The original builds used Apple clang 21.0.0 and SDK 26.4; build metadata is
in the manifest. Regenerated output hashes may differ with toolchain changes.

## Release verification

Update input and output hashes after reviewing any intentional changes.
Verify final resource hashes before packaging:

```sh
python3 - <<'PYVERIFY'
import hashlib, json
from pathlib import Path
root = Path('resources')
manifest = json.loads((root / 'native-manifest.json').read_text())
for artifact in manifest['artifacts']:
    path = root / artifact['resource']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == artifact['sha256'], path
print('All bundled resource hashes match')
PYVERIFY
```

Run the Raku tests serially on the supported native platforms, including an
installed distribution test so resource filename rewriting is exercised.
Check `zlibVersion()` is exactly the bundled version. Run downstream archive
and PNG tests after installing the updated distributions. Foreign binary
inspection alone does not count as a successful runtime test.

module detector

/**
	@file
	This file is tricky. It *also* lists Compilers but
	exclusively cross-compilers.
	Most noteably:
	- o64-/o32-clang and -gcc: macOS cross compiler
	- x86_64-w64-mingw32-gcc: 64bit MinGW
	Very specific:
	- arm-vita-eabi-gcc/-g++: PlayStation Vita via VITASDK
	  * arm-dolce-eabi-gcc/-g++: DOLCESDK variant.
	- ee-gcc/-g++: PlayStation 2 Emotion Engine
	- iop-gcc/-g++: PlayStation 2 IOP
	- dvp-gcc/-g++: PlayStation 2 DVP
	- powerpc64-ps3-elf-gcc/-g++: PlayStation 3
	  * ppu-/spu-(gcc|g++): PPU/SPU specific targeting
	- psp-gcc/-g++: PlayStation Portable
	- psx-gcc/-g++: PlayStation 1 (psn00b SDK)
	  * mipsel-unknown-elf-gcc/-g++: Also technically PSX but not very specific.
	
	So far, I am missing:
	- Wine based GCC/Clang
	- RISC-V
	- GB, GBC, GBA, GC, Wii, NDS, N3DS, Switch (NX)
	- Others...

	My goal with this file is to create a generous list of common cross compilers that are easy to find and use.
	Most of these are probably not gonna matter too much - BUT some toolchains just might end up using them.
	Therefore I decided to keep them in. You never know. :)

	Besides, there are a lot of multi-target compilers like SDCC that cover a lot
	of ground - and some other variants of GCC based TCs that are not even
	available on Windows and would require a temporary environment.

	I.e.: The required toolchain would have to be installed into
		$deps_dir/env
	On Linux, this would just contain your bin, lib, include folders.
	On windows, this would probably be MSYS2 or Cygwin based.
	On a Linux-Wine based cross compile (i.e. Series 60 compilers), this would
	have to include a wineroot.
	
	IceTea should be able to set them up - but, this will not be part of this
	specific file. The Detector API is only for finding and configuring, meaning
	that it should be independent of toolchains and friends.

	Instead, a toolchain might be able to predefine a set of already-known values
	to Detector to speed things up. I.e.: The VitaSDK includes <curl.h>. So,
	c.header("curl.h") should immediately return true when vita-gcc is used, since
	the header is already inside the sysroot per default.
*/

const known_x_macos = []

const known_x_win32 = []

const known_x_ps1 = []

const known_x_ps2 = []

const known_x_ps3 = []

const known_x_psp = []

const known_x_psv = []
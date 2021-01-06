module detector

/**
	@file
	This provides the structs to build the basics of knowledge about compilers.
	The interfaces defined here are later used for sanity checks and making sure things work as they should.
 */

struct CompilerIdentity {
	// GNU, ARM, Intel, ...
	vendor string = "[unknown]"

	// Could use the semver module?
	version string = "[unknown]"

	// target triples a-la: x64_86-apple-darwin13
	targets []string = []

	// c, c++, objc, objc++, swift, js, ts, v, go, rust, php, ...
	// GCC can be configured with multiple languages - Clang too, in ways.
	// The Compiler struct's .languages only serves as a "theoretical" thing.
	supported_languages []string = []
}

enum CompilerType {
	// Compilers of this type want to know all files in advance.
	// To compare, GCC doesn't care when using "-c" - but compilers
	// like [JS++](https://www.onux.com/jspp/) want to know the entire
	// source tree in advance - so, you can not compile "incrementaly".
	Nonincremental

	// Compilers of this type can take one file at a time, a-la `gcc -c`.
	// This is especially important due to workflow creation.
	// It is important to know if a compile needs all inputs at once,
	// or only one at a time - or even a hybrid.
	// You can do both: gcc -c file1.c file2.c -o myobj.o
	// and: gcc -c file1.c -o file1.o; gcc file2.c -o file2.o
	// But other compilers can not do this.
	Incremental

	// This is the type that can accept both but behave different in both approaches.
	Hybrid
}

interface Compiler {
	find() bool
	verify() bool
	get_version() string
	identify() CompilerIdentity
	is_cross() bool

	supports_flag(string) bool

	compile_single(inFile string, outFile string) bool
	compile_multi(inFiles []string, outfile string) bool
	link_single(inFile string, outBin string) bool
	link_multi(inFiles []string, outBin string) bool
}

interface CompilerFlags {
	add_warning() bool
	add_define() bool

	add_include_dir() bool
	add_include_file() bool
	add_library() bool
	add_library_dir() bool
	add_sysroot() bool
	add_include_sysroot() bool

	// macOS/GNUstep/ObjFW - Objective-C/C++ in general
	add_framework() bool
	add_framework_dir() bool
	set_objc_runtime(string) bool
}

struct Compiler {
	bin_name string
	//alt_names string // i.e. clang-11. Should be a glob-ish pattern
	full_name string

	// An environment variable that could provide a hint for the location.
	// i.e.: CC, CXX, JAVAC, ...
	env_hint string = "-none-"

	paths_unix []string
	paths_win32 []string

	compiler_type CompilerType

	languages []string

mut:
	found_at string
	id CompilerIdentity
}

struct Linker {
	bin_name string
	full_name string
	//flags LinkerFlags
}

struct Archiver {
	bin_name string
	full_name string
	//flags ArchiverFlags
}

/**
	All the flags a compiler would need/use.
	The examples in post-statement comments
	are against LLVM Clang.

	Not all compilers implement all flags - especially more
	smaller compilers or other languages. This is just a broad
	spectrum of flags that SHOULD cover the most obvious ones.
	There are methods to add custom flags as well. For instance,
	Emscripten uses "-s" for features.
 */
struct CompilerFlags {
	output_flag string				// -o
	object_flag string				// -c
	define_flag string				// -D
	undefine_flag string			// -U
	include_dir string				// -I
	include_file string				// -include
	include_lib_dir string			// -L
	include_framework_dir string	// -F
	sysroot_flag string				// -sysroot
	include_sysroot_flag string		// -isysroot
	link_lib string					// -l
	link_framework string			// -framework
	warning_flag string				// -W
	feature_flag string				// -f
	option_flag string				// -s (Emscripten)
	architecture_flag string		// -m
	target_flag string				// -target
	langstd_flag string				// -std=
	makedeps_flag string			// -MD
	response_file_flag string		// @

	// Special and unique flags.
	start_linker_flags string		// /link: (MSVC specific, but there is -Xl,...)
	shared_lib_flag string			// -shared
}

/*
	This is a struct specifically for linkers.
	There aren't many - mainly GCC's ld, llvm-ld and link.exe
	that I am really aware of.

	Most people use their CC to link - but sometimes, it might be
	more beneficial to interact with a linker directly, especially
	on smaller devices. For instance, you need to call a linker
	when linking a Gameboy program.
*/
struct LinkerFlags {}

/*
	These flags are for archive generators - and I don't
	mean Zip, TarGz and alike, but object archives - those,
	that will turn into static libraries.

	I only know ar, llvm-ar and lib.exe
*/
struct ArchiveFlags {}


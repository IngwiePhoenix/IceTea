module detector

/**
	@file
	This provides the structs to build the basics of knowledge about compilers.
	The interfaces defined here are later used for sanity checks and making sure things work as they should.
 */

/**
	An enum to pick some basic, often used, common languages.
	Mainly used for internally provided presets that a user
	might end up overwriting anyway.
	Those presets only exist to get you started - not to
	actually be used in bigger projects. More dedicated
	options and settings might be needed for each of those
	languages.
 */
enum CommonLanguage {
	ALL // pseudo index to target all languages.
	ASM
	C
	CXX
	OBJC
	OBJCXX
	JAVA
	SWIFT
	RUST
	GO
	D
	V
}

// TODO
enum Architecture {
	arm
	x86
	x64
	amd64
	riscv
}

struct CompilerIdentity {
	// GNU, ARM, Intel, ...
	vendor string [required]

	// Could use the semver module?
	version string [required]

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

/**
	This interface represents a compiler.
	You might want to implement other types of compilers - but
	you can still pass them to IceTea as long as your declaration
	implements this interface.
 */
interface Compiler {
	// The name used when looking up $PATH
	// This is not ment to autodetect clang-11 over clang-10!
	// Rather, this should be set via the environment variables.
	prog_name string

	// A full name of a compiler
	// This just serves as fancy stuff used to display to the user.
	// The real information comes through CompilerIdentity
	full_name string

	// An environment variable that could provide a hint for the location.
	// i.e.: CC, CXX, JAVAC, ...
	env_hints []string

	// Paths where to look for this compiler.
	// Always has $bin_name appended during lookup
	// but no trailing / or \ is needed.
	paths_unix []string
	paths_win32 []string

	// Mainly used to determine if this compiler should be passed all files,
	// or just a single at a time.
	compiler_type CompilerType

	// What languages are supported? Mostly useful during lookup.
	languages []CommonLanguage

	// Where was it found?
	found_at string

	// Identity of the compiler
	id CompilerIdentity

	// Find the compiler on the system
	find() bool

	// Verify that this compiler works.
	verify() bool

	// Get version
	// TODO: maybe use semver?
	get_version() string

	// Get detailed information about a compiler
	identify() CompilerIdentity

	// See if we are cross compiling.
	// Toolchains specifically targeting cross compiling might
	// want to immediately return true.
	is_cross() bool

	// Some systems might need a dedicated linker. But in most
	// cases, the C/C++ compiler can also link.
	// If true, use the compiler instead of a specific system linker.
	can_link() bool

	// Test a single, simple flag.
	supports_flag(string) bool

	// Basic compilation.

	// Compile a single file (gcc -c file.c)
	compile_single(input string, output string) bool

	// compile multiple files (gcc -c file1.c file2.c)
	compile_multi(input []string, output string) bool

	// Link a single file (gcc file.o -o file)
	link_single(input string, output string) bool

	// Link multiple files (gcc file1.o file2.o -o file)
	link_multi(inFiles []string, outBin string) bool
}

/**
	A basic interface to help aiding in managing compiler flags.
	This one has the C/C++ compilers in mind.
 */
interface CompilerFlags {
	// meta methods
	// TODO: or maybe just str()string ?
	cmd_str() string

	// General settings
	set_language(string) bool		// -X {c|c++|objc|objc++}
	get_language() string

	set_target(string) bool			// -target
	get_target() string
	del_target() bool

	set_arch(string) bool			// -march=
	get_arch() string
	del_arch() bool

	set_tune(string) bool			// -mtune=
	get_tune() string
	del_tune() bool

	// Standards and standard libs
	set_standard(string) bool		// -std=
	get_standard() string
	del_standard() bool
	
	set_stdlib(string) bool			// -stdlib=
	get_stdlib() string
	del_stdlib() bool

	set_nostdlib() bool				// TODO
	get_nostdlib() bool

	std_includes_off() bool			// -nostdinc++
	std_includes_on() bool
	set_std_includes(bool) bool
	get_std_includes() bool

	// Standard flags
	add_warning(string) bool 		// -W
	del_warning(string) bool
	has_warning(string) bool
	get_warnings() []string

	add_define(string,string) bool	// -Dkey=value
	del_define(string) bool
	has_define(string) bool
	get_defines() map[string]string

	add_undefine(string) bool		// -Ukey
	del_undefine(string) bool
	has_undefine(string) bool
	get_undefines() []string

	add_include_dir(string) bool 	// -I
	del_include_dir(string) bool
	has_include_dir(string) bool
	get_include_dirs() []string

	add_include_file(string) bool	// -include
	del_include_file(string) bool
	has_include_file(string) bool
	get_include_files() []string

	add_library(string) bool		// -l
	del_library(string) bool
	has_library(string) bool
	get_librarys() []string // I know - librarIES. But eh.

	add_library_dir(string) bool	// -L
	del_library_dir(string) bool
	has_library_dir(string) bool
	get_library_dirs() []string

	set_sysroot(string) bool		// -sysroot
	unset_sysroot() bool
	get_sysroot() string

	add_isysroot(string) bool		// -isysroot
	del_isysroot(string) bool
	has_isysroot(string) bool
	get_isysroots() []string

	// macOS/GNUstep/ObjFW - Objective-C/C++ in general
	add_framework(string) bool		// -framework
	del_framework(string) bool
	has_framework(string) bool
	get_frameworks() []string

	add_framework_dir(string) bool	// -F
	del_framework_dir(string) bool
	has_framework_dir(string) bool
	get_framework_dirs() []string

	set_objc_runtime(string) bool	// -fobjc-runtime= (clang exclusive)
	get_objc_runtime() string
	del_objc_runtime() bool

	// Misc
	add_feature(string,string) bool	// -fkey=value
	del_feature(string) bool
	get_features() []string

	add_tool_flag(string,string) bool // -Xtool value
	del_tool_flag(string) bool
	del_all_tool_flags(string,string) bool
	has_tool_flag(string,string) bool
	get_tool_flags(string) []string
	get_all_tool_flags() map[string][]string

	add_custom(string) bool
	del_custom(string) bool
	has_custom(string) bool
	get_customs() []string
}

// TODOs
interface AssemblerFlags {}
interface LinkerFlags {}
interface ArchiverFlags {}

/**
	For the cases that a specific Linker is to be used,
	this struct is ment to describe it and make it findable.

	Big TODO here: Need more experience with llvm-ld and GNU ld
	as well as link.exe ...
 */
struct Linker {
	bin_name string
	full_name string
	//flags LinkerFlags
}

/**
	An archiver used to build an archive of objects and their symbols.
	A static library, really. I need to study the GNU ar manpage and
	the lib.exe docs.
 */
struct Archiver {
	bin_name string
	full_name string
	//flags ArchiverFlags
}
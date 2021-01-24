/**
	@file
	This file gives the whole Detector API more knowledge about LLVM's toolchain.

	This is vastly different from GCC as Clang is a one-to-all compiler,
	as cross-compiling is baked in and thus behaves slightly differently
	in some aspects. Whilst accepting most GCC flags, it is quite different in
	other scenarios.
 */

struct LLVMCompiler {
	prog_name string = "clang"
	desc_name string = "LLVM C Language Frontend"
	env_hints []string = ["CC", "CXX"]
	unix_paths []string = [
		"/usr/bin"
		"/usr/local/bin"
		"/usr/local/opt/clang/bin/clang"
	]
	win32_paths []string = [
		"C:\\Program Files\\LLVM\\bin\\"
	]
	compiler_type CompilerType = .hybrid
	languages []CommonLanguage = [C, CXX, OBJC, OBJCXX]
	flags LLVMCompilerFlags

mut:
	found_at string
	info CompilerInfo
}

fn(cc LLVMCompiler) find() bool {}
fn(cc LLVMCompiler) verify() bool {}
fn(cc LLVMCompiler) get_version() string {}
fn(cc LLVMCompiler) id() string { return "clang" }
fn(cc LLVMCompiler) info() CompilerInfo {}
fn(cc LLVMCompiler) is_cross() bool {}
fn(cc LLVMCompiler) can_link() bool {}
fn(cc LLVMCompiler) supports_flag(flag string) bool {}
fn(cc LLVMCompiler) compile_single(input string, output string) {}
fn(cc LLVMCompiler) compile_multi(input []string, output) {}
fn(cc LLVMCompiler) link_single(input string, output string) {}
fn(cc LLVMCompiler) link_multi(input []string, output) {}

struct LLVMCompilerFlags {
mut:
	lang string
	target string
	arch string
	tune string

	standard string
	stdlib string
	nostdlib bool
	stdinc bool

	warnings []string
	defines map[string]string
	undefines []string
	include_dirs []string
	include_files []string
	libraries []string
	library_dirs []string
	sysroot string
	isysroots []string

	frameworks []string
	framework_dirs []string
	objc_rt string

	features map[string]string
	tool_args map[string][]string

	customs []string
}

/**
	Generates a command line friendly string that can be passed to the compiler directly.
	TODO: This is such a mess... I need a cleaner way.
 */
fn(f LLVMCompilerFlags) cmd_str() string {
	ret := []string{}

	ret << str_prefix_nonempty("-X ", f.get_language(), '"')
	ret << str_prefix_nonempty("-target ", f.get_target(), '"')
	ret << str_prefix_nonempty("-march ", f.get_arch(), '"')
	ret << str_prefix_nonempty("-mtune ", f.get_tune(), '"')
	ret << str_prefix_nonempty("-std=", f.get_standard(), '"')
	ret << str_prefix_nonempty("-stdlib=", f.get_stdlib(), '"')
	ret << if f.get_std_includes() { "-nodstdinc++" } else { "" }
	ret << str_prefix_nonempty("-fobjc-runtime=", f.get_objc_runtime(), '"')

	ret << str_prefix_nonempty("-sysroot ", f.get_sysroot(), '"')
	ret << str_array_each_prefix("-isysroot ", f.get_isysroots(), '"')

	ret << str_array_each_prefix("-U", f.get_undefines(), '"')
	ret << str_map_each_prefix("-D", f.get_defines(), '"')

	ret << str_array_each_prefix("-w", f.get_warnings(), '"')

	ret << str_array_each_prefix("-I", f.get_include_dirs(), '"')
	ret << str_array_each_prefix("-L", f.get_library_dirs(), '"')
	ret << str_array_each_prefix("-F", f.get_framework_dirs(), '"')

	ret << str_array_each_prefix("-include ", f.get_include_files(), '"')
	ret << str_array_each_prefix("-l", f.get_librarys(), '"')
	ret << str_array_each_prefix("-framework", f.get_frameworks(), '"')

	ret << str_array_each_prefix("-f", f.get_features(), '"')
	for tool, flags in f.get_all_tool_flags() {
		ret << str_array_each_prefix("-X$tool ", flags, '"')
	}
	ret << str_array_each_prefix("", f.get_customs(), '"')

	return ret.join(" ")
}

fn(mut f LLVMCompilerFlags) set_language(lang string) bool {
	languages := ["c", "c++", "objc", "objective-c", "objc++", "objective-c++"]
	lang := lang.to_upper()
	if lang in languages {
		f.language = lang
		return true
	} else {
		return false
	}
}
fn(f LLVMCompilerFlags) get_language() string {
	return f.language
}

fn(mut f LLVMCompilerFlags) set_target(target string) bool {
	// TODO: Sanity check if it's a valid target or not.
	f.target = target
	return true
}
fn(f LLVMCompilerFlags) get_target() string {
	return f.target
}
fn(mut f LLVMCompilerFlags) del_target() bool {
	f.target = string("")
	return true
}

fn(mut f LLVMCompilerFlags) set_arch(arch string) bool {
	// TODO: use llvm-ld to verify if this arch is supported.
	f.arch = arch
	return true
}
fn(f LLVMCompilerFlags) get_arch() string {
	return f.arch
}
fn(f LLVMCompilerFlags) del_arch() bool {
	f.arch = string("")
}

fn(mut f LLVMCompilerFlags) set_tune(tune string) bool {
	// TODO: use llvm-ld to pick up the CPU tuning
	f.tune = tune
	return true
}
fn(f LLVMCompilerFlags) get_tune() string {
	return f.tune
}
fn(mut f LLVMCompilerFlags) del_tune() bool {
	f.tune = string("")
	return true
}

// Standards and standard libs
fn(mut f LLVMCompilerFlags) set_standard(std string) bool {
	// TODO: verify std against a list of known and supported ones
	f.standard = std
	return true
}
fn(f LLVMCompilerFlags) get_standard() string {
	return f.standard
}
fn(mut f LLVMCompilerFlags) del_standard() bool {
	f.standard = string("")
	return true
}

fn(mut f LLVMCompilerFlags) set_stdlib(stdlib string) bool	{
	// TODO: Which stdlibs does clang actually support?
	f.stdlib = stdlib
	return true
}
fn(f LLVMCompilerFlags) get_stdlib() string {
	return f.stdlib
}
fn(mut f LLVMCompilerFlags) del_stdlib() bool {
	f.stdlib = string("")
	return true
}

fn(f LLVMCompilerFlags) set_nostdlib() bool	{}
fn(f LLVMCompilerFlags) get_nostdlib() bool {}

fn(mut f LLVMCompilerFlags) std_includes_off() bool	{
	f.stdinc = true
	return true
}
fn(mut f LLVMCompilerFlags) std_includes_on() bool {
	f.stdinc = false
	return true
}
fn(mut f LLVMCompilerFlags) set_std_includes(stdinc bool) bool {
	f.stdinc = stdinc
	return true
}
fn(f LLVMCompilerFlags) get_std_includes() bool {
	return f.stdinc
}

fn(mut f LLVMCompilerFlags) add_warning(warning string) bool {
	// TODO: Find - and use - a warnings catalog.
	// Might be useful to use $embed_file() for this!
	return str_array_add_verify(warning, mut f.warnings)
}
fn(mut f LLVMCompilerFlags) del_warning(warning string) bool {
	return str_array_del_verify(warning, mut f.warnings)
}
fn(f LLVMCompilerFlags) has_warning(warning string) bool {
	return warning in f.warnings
}
fn(f LLVMCompilerFlags) get_warnings() []string {
	return f.warnings
}

fn(mut f LLVMCompilerFlags) add_define(key string, value string) bool {
	// TODO: Sanitize value. Not everything goes!
	return str_map_add_verify(key, value, mut f.defines)
}
fn(mut f LLVMCompilerFlags) del_define(key string) bool {
	return str_map_del_verify(key, value, mut f.defines)
}
fn(f LLVMCompilerFlags) has_define(key string) bool {
	return key in f.defines
}
fn(f LLVMCompilerFlags) get_defines() map[string]string {
	return f.defines
}

fn(mut f LLVMCompilerFlags) add_undefine(undef string) bool {
	return str_array_add_verify(undef, mut f.undefines)
}
fn(mut f LLVMCompilerFlags) del_undefine(undef string) bool {
	return str_array_del_verify(undef, mut f.undefines)
}
fn(f LLVMCompilerFlags) has_undefine(undef string) bool {
	return undef in f.undefines
}
fn(f LLVMCompilerFlags) get_undefines() []string {
	return f.undefines
}

fn(mut f LLVMCompilerFlags) add_include_dir(path string) bool {
	// TODO: Check if folder exists
	// And, if possible, add the absolute path instead.
	// That way, de-duplication is possible.
	return str_array_add_verify(path, mut f.include_dirs)
}
fn(mut f LLVMCompilerFlags) del_include_dir(path string) bool {
	return str_array_del_verify(path, mut f.include_dirs)
}
fn(f LLVMCompilerFlags) has_include_dir(path string) bool {
	return path in f.include_dirs
}
fn(f LLVMCompilerFlags) get_include_dirs() []string {
	return f.include_dirs
}

fn(mut f LLVMCompilerFlags) add_include_file(path string) bool {
	// TODO: Verify that file exists and use absolute path
	// However! since "-include stdio.h" is legal, I might have
	// to skip that... hm. o.o
	return str_array_add_verify(path, mut f.include_files)
}
fn(mut f LLVMCompilerFlags) del_include_file(path string) bool {
	return str_array_del_verify(path, mut f.include_files)
}
fn(f LLVMCompilerFlags) has_include_file(path string) bool {
	return path in f.include_files
}
fn(f LLVMCompilerFlags) get_include_files() []string {
	return f.include_files
}

fn(mut f LLVMCompilerFlags) add_library(lib string) bool {
	// Tricky. Both, -lname and -lpath/to/lib.a are valid.
	// However, both libs might have the same symbols, so it should work.
	// A bit tricky, but I'll skip path validation here
	return str_array_add_verify(lib, mut f.libraries)
}
fn(mut f LLVMCompilerFlags) del_library(lib string) bool {
	return str_array_del_verify(lib, mut f.libraries)
}
fn(f LLVMCompilerFlags) has_library(lib string) bool {
	return lib in f.libraries
}
fn(f LLVMCompilerFlags) get_librarys() []string {
	return f.libraries
}

fn(mut f LLVMCompilerFlags) add_library_dir(path string) bool {
	// TODO: Verify path and make absolute
	return str_array_add_verify(path, mut f.library_dirs)
}
fn(mut f LLVMCompilerFlags) del_library_dir(path string) bool {
	return str_array_del_verify(path, mut f.library_dirs)
}
fn(f LLVMCompilerFlags) has_library_dir(path string) bool {
	return path in f.library_dirs
}
fn(f LLVMCompilerFlags) get_library_dirs() []string {
	return f.library_dirs
}

fn(mut f LLVMCompilerFlags) set_sysroot(sysroot string) bool {
	// TODO: Make absolute path
	f.sysroot = sysroot
	return true
}
fn(mut f LLVMCompilerFlags) unset_sysroot() bool {
	f.sysroot = string("")
	return true
}
fn(f LLVMCompilerFlags) get_sysroot() string {
	return f.sysroot
}

fn(mut f LLVMCompilerFlags) add_isysroot(path string) bool {
	// TODO: Verify and make absolute
	return str_array_add_verify(path, mut f.isysroots)
}
fn(mut f LLVMCompilerFlags) del_isysroot(path string) bool {
	return str_array_del_verify(path, mut f.isysroots)
}
fn(f LLVMCompilerFlags) has_isysroot(path string) bool {
	return path in f.isysroots
}
fn(f LLVMCompilerFlags) get_isysroots() []string {
	return f.isysroots
}

fn(mut f LLVMCompilerFlags) add_framework(fw string) bool {
	// TODO: Frameworks behave like libraries - in a LOT of ways
	// but not all. For instance: Foo.framework can contain multiple versions.
	// Sooo... Like libraries, I have to be faithful here with the compiler
	// and hope it knows how to pick up the right one.
	return str_array_add_verify(fw, mut fw.frameworks)
}
fn(f LLVMCompilerFlags) del_framework(fw string) bool {
	return str_array_del_verify(fw, mut f.frameworks)
}
fn(f LLVMCompilerFlags) has_framework(fw string) bool {
	return fw in f.frameworks
}
fn(f LLVMCompilerFlags) get_frameworks() []string {
	return f.frameworks
}

fn(mut f LLVMCompilerFlags) add_framework_dir(fw string) bool {
	// TODO: make absolute
	return str_array_add_verify(fw, mut f.framework_dirs)
}
fn(mut f LLVMCompilerFlags) del_framework_dir(fw string) bool {
	return str_array_del_verify(fw, mut f.framework_dirs)
}
fn(f LLVMCompilerFlags) has_framework_dir(fw string) bool {
	return fw in f.framework_dirs
}
fn(f LLVMCompilerFlags) get_framework_dirs() []string {
	return f.framework_dirs
}

fn(mut f LLVMCompilerFlags) set_objc_runtime(rt string) bool {
	rt = rt.to_lower()
	if rt in ["apple", "gnustep", "objfw"] {
		f.objc_rt = rt
		return true
	} else {
		// Should definitively panic.
		return false
	}
}
fn(f LLVMCompilerFlags) get_objc_runtime() string {
	return f.objc_rt
}
fn(mut f LLVMCompilerFlags) del_objc_runtime() bool {
	f.objc_rt = string("")
	return true
}

fn(mut f LLVMCompilerFlags) add_feature(key string, value string) bool	{
	return str_map_add_verify(key, value, mut f.features)
}
fn(mut f LLVMCompilerFlags) del_feature(key string) bool {
	return str_map_del_verify(key, mut f.features)
}
fn(f LLVMCompilerFlags) get_features() map[string]string {
	return f.features
}

fn(mut f LLVMCompilerFlags) add_tool_flag(tool string, flag string) bool {
	// Tool flags like -Xassembler or -Xclang are kinda special.
	// Therefore they get a treatment where each flag itself is
	// treated as unique, whereas tools themselves are not.
	if tool !in f.tool_args {
		f.tool_args[tool] = [flag]
		return true
	} else if flag !in f.tool_args[tool] {
		f.tool_args[tool].push(flag)
		return true
	} else {
		return false
	}
}
fn(mut f LLVMCompilerFlags) del_tool_flag(tool string, flag string) bool {
	if tool in f.tool_args && flag in f.tool_args[tool] {
		mut flags := f.tool_args[tool]
		idx := flags.index(flag)
		flags.delete(idx)
		return true
	} else {
		return false
	}
}
fn(mut f LLVMCompilerFlags) del_all_tool_flags(key string) []string {
	if key in f.tool_args {
		f.tool_args.delete(key)
		return true
	} else {
		return false
	}
}
fn(f LLVMCompilerFlags) has_tool_flag(tool string, flag string) bool {
	return tool in f.tool_args && flag in f.tool_args[tool]
}
fn(f LLVMCompilerFlags) get_tool_flags(tool string) []string {
	if tool in f.tool_args {
		return f.tool_args[tool]
	} else {
		return []string{}
	}
}
fn(f LLVMCompilerFlags) get_tool_flags_all() map[string][]string {
	return f.tool_args
}

fn(mut f LLVMCompilerFlags) add_custom(flag string) bool {
	return str_array_add_verify(flag, mut f.customs)
}
fn(mut f LLVMCompilerFlags) del_custom(flag string) bool {
	return str_array_del_verify(flag, mut f.customs)
}
fn(f LLVMCompilerFlags) has_customs(flag string) []string {
	return flag in f.customs
}
fn(f LLVMCompilerFlags) get_customs() []string {
	return f.customs
}

// TODO
struct LLVMLinker {}

struct LLVMLinkerFlags {}

struct LLVMArchiver {}

struct LLVMArchiverFlags {}
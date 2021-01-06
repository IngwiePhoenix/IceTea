/**
	@file
	This is basically a database of known compilers, where they are found at.
	and what they are capable of.
	This is purely for finding them - this does NOT provide their syntax.
 */

const known_CC = [
	Compiler {
		bin_name: "gcc"
		full_name: "GNU Compiler Collection",
		paths_unix: [
			"gcc" // Assume in $PATH
			"/usr/bin/gcc"
			"/usr/local/bin/gcc"
			"/sw/bin/gcc" // macOS Fink
			"/usr/local/opt/gcc/bin/gcc" // macOS Homebrew
		]
		paths_win32: [
			// Oof... where in the world do people put GCC on Windows? O.o
			// FIXME: Need more usual Windows locations.
			"C:\\tools\\gcc\\bin\\gcc.exe"
		]
		compiler_type: .hybrid
		languages: ["c", "objc", "fortran", "ada", "java"]
		env_hint: "CC"
	},
	Compiler {
		bin_name: "clang"
		full_name: "LLVM C-language Frontend"
		paths_unix: [
			"clang" // in $PATH
			"/usr/bin/clang"
			"/usr/local/bin/clang"

			// macOS Homebrew - usually not linked because of Apple SDK
			"/usr/local/opt/clang/bin/clang"
		]
		paths_win32: [
			// FIXME: More windows locations
			"C:\\Program Files\\LLVM\\bin\\clang.exe"
		]
		compiler_type: .hybrid
		languages: ["c", "c++", "objc", "objc++"]
		env_hint: "CC"
	},
	Compiler {
		bin_name: "tcc"
		full_name: "Tiny C Compiler"

		// Most projects using TCC will relocate it anyway.
		// So... this is kinda hard to predict.
		paths_unix: ["tcc"]
		paths_win32: ["tcc.exe"]
		compiler_type: .hybrid
		languages: ["c"]
		env_hint: "CC"
	}
]

/*
	Missing:
	- Intel C Compiler "icc"
*/
const known_CXX = [
	Compiler {
		bin_name: "g++"
		full_name: "GNU Compiler Collection",
		paths_unix: [
			"/usr/bin/"
			"/usr/local/bin/"
			"/sw/bin/" // macOS Fink
			"/usr/local/opt/gcc/bin/" // macOS Homebrew
			"/usr/local/opt/g++/bin/" // macOS Homebrew - alternative
		]
		paths_win32: [
			// Oof... where in the world do people put GCC on Windows? O.o
			// FIXME: Need more usual Windows locations.
			"C:\\tools\\gcc\\bin"
		]
		compiler_type: .hybrid
		languages: ["c++", "objc++"]
		env_hint: "CXX"
	},
	Compiler {
		bin_name: "clang++"
		full_name: "LLVM C-language Frontend"
		paths_unix: [
			"/usr/bin"
			"/usr/local/bin"

			// macOS Homebrew - usually not linked because of Apple SDK
			"/usr/local/opt/clang/bin"
		]
		paths_win32: [
			// FIXME: More windows locations
			"C:\\Program Files\\LLVM\\bin"
		]
		compiler_type: .hybrid
		languages: ["c++", "objc++"]
		env_hint: "CXX"
	}
]

const known_mixed_C = {
	Compiler {
		bin_name: "cl"
		full_name: "Microsoft Windows C/C++ Compiler"
		paths_unix: []
		paths_win32: [
			// Many. I need to look up ALL MSVC install paths - and even then,
			// there are cases where this might not be at the default location.
			// For this case alone, a custom solver needs to be implemented
			// that looks at the windows registry or uses vswhere.exe
			// For now, huge FIXME.
		]
		languages: ["c", "c++"]
	}
}

const known_JAVAC = [
	Compiler {
		bin_name: "javac"
		full_name: "Java compiler"

		paths_unix: ["javac", "/usr/bin/javac"]
		// FIXME: Need to figure out where this one lives at...
		paths_win32: ["javac.exe"]
		env_hint: "JAVAC"
	}
]

// FIXME
const known_GO = []

// FIXME
const known_SWIFT = []

// FIXME
const known_RUST = [
	Compiler {
		bin_name: "rustc"
		full_name: "Rust"
		path_unix: [
			"@HOME/.local/bin" // rustup
			"/usr/bin"
			"/usr/local/bin"
			"/usr/local/opt/rust/bin" // macOS Homebrew
		]
		path_win32: [
			// FIXME
		]
	}
]
# IceTea

Right now, this is very much work in progress... But here is a list of what I want to do:

- Write a build tool that is small, well feature equipped, easy to pick up.
- Be completely cross-platform. V compiles to C99 - that should compile *possibly* everywhere.
- Allow the user to build this project themselves by providing an automated distribution featuring basic build scripts that can compile IceTea off of a single C file
- Implement a basic dependency management
- Allow the usage of modules so people can customize their build (i.e. toolchains for other platforms, package providers, ...)
- Provide a rich and functional baseline for C, C++, JavaScript and PHP projects - for now.
- Allow the easy extension of IceTea through modules - and internally.
- Write the library components with a low to no dependency on each other, so parts of this project can be used in parts by others.

## Why?
Easy:
- CMake's syntax is quirky, at best. It's CMake Policies have a tendency to break older code - and some of these changes are breaking to a point where they're hard to track.
    * IceTea should therefore provide a basic, hopefully rarely changing API.
- Aside from CMake, there is no "build/project configuration" tool for Windows. Autoconf is Linux only, premake is limited - and tools like scons barely have any.
    * Provide an extendable API that can do common tasks like looking for C headers or installed programs/tools.
- Package management in different languages can quickly get convoluted - and C/C++ has multiple, yet no default one.
    * To my knowledge: clib, CONAN, vcpkg
    * Git Modules ("hard dependencies") are one way to do it, but you'll pull in _everything_ every time...
- There is no cross-platform, tiny but featureful way of just scripting. Because IceTea will be written largely in V and JS, this can be solved now.
    * The idea is that you `cc icetea.c -o icetea` and then run your scripts.

## Deps used
- JerryScript: JavaScript engine supporting ES6. JS has become one of the defacto "top tier" languages for more than just the web. Most people know it, so it should be a great starting point.
- mbedTLS: It was a surprise that I couldn't find a single HTTP/S client that would *just work* in C99. They either were hard-focused on OpenSSL or way too modern for what I was hoping to go for. mbedTLS is supported by cURL and many others - and Mongoose, the library I ultimatively went with. It has a very readable source and great support! It also is ment to be on a small footprint, which is exactly what I want to achieve.
- Mongoose: All I needed was a HTTP/S client - but I found something possibly way too capable for what I want. It handles HTTP, HTTPS (via OpenSSL or mbedTLS), DNS, SNTP and MQTT. Oh, and WebSockets, too. IceTea is not actually ment to be used as a WebServer - but, hey. It's there so why not use it.
- Subprocess: A small cross-platform command launcher, watcher and overall observer. I needed a little more than just `execvp`, and this already existed. So why not use it?
- V: The language IceTea is to be written in.

## Why all the lib folders?
Currently, you may only see `v-lib`. There is also `js-lib` and `c-lib`. Those folders are ment to store the various wrappers and backend code that I intend to write. For instance, the `v-lib` folder will contain the wrappers I am writing around the C dependencies, whilst `c-lib` might be used to pre-wrap more expensive stuff (i.e. JerryScript internal symbol resolvers for modules) so they can be consumed by V code more easily.

The most important stuff will happen in `v-lib`, followed by the main program which will end up living in `src` eventually - written exclusively in V. However, things like compiler and linker information that will be part of the "Detector API" will be within `v-lib`, freely consumable by anyone who would love to use it, together with a dedicated submodule to make it available in JerryScript.

## Backed by C, written in V - but controlled by JS.
Whilst I could implement this purely and entirely with the C backend and V, not everyone just so happens to have a compiler around - so there needs to be an entry point that could be used for non-C projects (like JavaScript projects, that only need some tasks ran and files generated - but will never need a full blown 300+ megs of C tooling). I plan to make IceTea compliant to TCC so that it can, like V's `vlang/vc` repository, be bootstrapped with this alone. That would also mean that projects using V files for their build (V modules, for instance?) could just write their descriptions in V instead of JS - or even embed IceTea without the need of using JS at all, ever.

I see JS as a generic, common entry point. But I do not want to forget about providing an easily accessible and rich native interface. That is why the order of feature implementation is: C -> V -> JS. JerryScript native modules are written in V and always completely split from the main library to make them optional - effectively making JerryScript itself optional and IceTea an "almost" pure V project.

## TODO
- [x] Pinpoint the C dependencies to use.
    * They MUST be C99.
    * Go for as few sources as possible for easier packaging and distribution.
    * Look out for dependencies that have a very, very low footprint. This tool is not ment to be "the fastest" or "the best" - but rather "the one that works". A small footprint also has the benefit of not needing too much resources to run.
- [ ] Wrap the C deps in V
    * Structure:
        - `v-lib/$dep/api.c.v`: Declare all structs and functions with the `C.`-prefix.
        - `v-lib/$dep/lib.c.v`: Provide a V-wrapper with the proper typing, OO and overall structure. For instance, use Optionals instead of `NULL` and friends.
        - `v-lib/$dep/dep.inc`: A C file purely ment for inclusion that sets up `#define`s and other requirements. To be consumed by `api.c.v`. Optional.
- [ ] Detector API
    * Research, test and try a *lot* of compilers and document all features they have in common.
    * Put that research into `v-lib/Detector` and implement structs and methods to query and use this data.
    * Allow people to write their own Toolchain definitions (where is the C compiler, what flags to use, is it a cross compiler, ...)
    * Toolchains may be able to be written either for cross-compiling OR for use-cases. I.e.: PHP vs. HHVM, Node vs. Deno or even Python2 vs Python3
- [ ] Build API
    * Within `vlang/v/vlib/v/depgraph`, there is a good chunk of work done to sort dependencies within a build.
    * Use that and implement a multi-threaded process queue to run through a build as fast as possible.
        - Might be able to nap some ideas from ninja-build?
- [ ] Deploy API
    * Since Mongoose can do more than just fetch a bit of data but also upload a lot of them, why not also make a Deployment API?
    * Accumulate common tasks for deployment and allow people to create ready-to-distribute folders/archives.

## Way in the future...
- WASI based module loader
    * Load WASM files as "native" modules by using [wasm3](https://github.com/wasm3/wasm3)
    * Construct an easily accessible workflow via [wasi-sdk](https://github.com/WebAssembly/wasi-sdk) to compile WASM modules and make them ready to publish
        - Obviously, Detector will also know how to use both `emcc` and the WASI-SDK's tooling. But considering that WASI is essentially *the way to go*, I'd love to bank on that and become independent from Python and Node, which Emscripten needs the both of.
- Allow IceTea to just outright bootstrap an entire "private" toolchain for cross-compiling.
    * Think [crosstool-ng](https://crosstool-ng.github.io/) but thus implemented in pure JavaScript.
- Utilize V's ability to compile straight to JS to provide a NodeJS friendly tool
    * i.e.: Replace `node-gyp` with IceTea.
    * For that, V conveniently provides the `.js.v` files where the `JS.` prefix can be used.
    * This would mean, that all the `v-lib` deps would have to be adapted to fall back to NodeJS based APIs instead.
    * Alternatively, just use straight up WASM or Emscripten with compile-time adjustments.
    * V right now can not use `#ifdef EMSCRIPTEN` in the C backend for compile-time adjustments - so these will have to be done some other way...

# Build descriptors (`build.it`)
Here are three theoretical examples - from beginner, to educated, to expert:

```js
// beginner
targt("myprog", ["./src/*.c"])


// educated
target("myprog", {
    sources = [
        "./src/*.c"
    ]

    configure() {
        var cc = new Detector("c")
        cc.header("stdio.h")
        cc.lib("c")
    }
})

// expert
import poco from "poco";
import {library, cli} from "icetea";
import {rename} from "shell";

export const myLib = library("myLib", {
    dpes: [poco.net]
    sources: {
        "./lib/source1.c",
        "./lib/source2.c",
        "./lib/souce3.c.in": {
            cflags: "-Wall",
            placeholders: {
                "MYLIB_VERSION": cache => cache.hitOrGet("mylib.version", () => {
                    try {
                        return $("git rev-parse")
                    } catch(e) {
                        console.error(e)
                        return "-hash-not-obtainable-"
                    }
                })
            }
        }
    }

    init() {
        var cli = this.cli = new cli("My Library")
        cli.enable("my-feature", {
            desc: "This feature is optional",
            default: false
        })
        cli.with("something", {
            desc: "Add the path to something",
            default: false,
            required: false,
            type: "path"
        })
    }

    configure() {
        let c = new Detector("C")
        let cxx = new Detector("C++")

        let compiler = c.find()
        if(compiler.isGNU()) {
            this.settings.cflags.push("-fsome-feature")
        }

        Detector.doOrAbort([
            _ => cxx.std("c++11"),
            _ => cxx.feature("regex")
        ])

        Detector.check(
            "wether we can use .INCBIN in Assembly",
            res => {
                let asm = new Detector("asm")
                let {errorCode, launched, stderr} = asm.tryCompile([
                    `.INCBIN "${this.rootDir}/build.it"`
                ])
                if(errorCode && launched) {
                    res("works")
                } else {
                    res("no")
                    throw stderr
                }
            }
        )
    }

    postbuild() {
        rename(
            IceTea.buildRoot(this) + "/src/source3.c",
            IceTea.buildRoot(this) + "/src/source3.gen.c"
        )
    }
})
```

## Terminology
- Target: A goal to work towards to. Examples:
    * Compile all C files to build an executable.
    * Compress all PHP files into a PHAR
    * Execute these commands to result in a file
- Steps: Takes input A and turns it into output B
    * `cc a.c -o b`
    * `tar cvfz b.tar.gz a.txt`
    * `fltk-fluid my-ui.fluid -o my-ui.cxx`
    * `v ./mymodule -o mymodule.c`
    * Could also be a script that performs multiple actions at once to get from A to B.
    * A step might work with multiple files as the input as well.
- Workflow: A series of steps.
    * `*.c -> .o -> .exe`: C workflow for a binary
    * `*.cxx -> .o -> .exe` C++ workflow for a binary
    * `*.jsx -> .js -> .bundle.js`: JSX workflow from a single or multiple files to a bundled JavaScript file.
    * A workflow may also define alternatives for each part.
    * Workflows are the precursor to steps, so the C example splits into `.c -> .o` and `.o -> .exe`
- Action: A generic action, like a script, that does something.
    * Run tests on the output
    * Deploy to a server
    * Automatically make a git tag
- Tool: A function that represents exactly one purpose - whilst abstracting what actually happens.
    * The "CC" tool might invoke the previously found C compiler and act as a calling wrapper. Think of how `clang-cl` can handle both Clang and CL options.
    * A script that could be called as a plain program.
    * Most tools are build-time relevant or little utilities that are not primarily ment for distribution. If they are, they should be their own, standalone program instead that gets installed/published after the build.
- Toolchain: A set of tools that builds a specific environment.
    * The toolchain `mingw-w64` automatically sets the compilers and other programs even before configuration takes place, making `Detector("C").find()` already know the solution and return the proper identification.
    * A toolchain might also gap the bridge between `cp` on Linux and `xcopy`/`copy` on Windows.
    * A toolchain may just predefine specific versions and locations of tools.

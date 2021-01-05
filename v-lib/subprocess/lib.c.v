/**
 * @file
 * This module is a V interface to the single-header subprocess manager,
 * subprocess.h . Very simplistic, but gets the job done.
 *
 * Ontop of that, it can also work async!
 */
module subprocess

// FIXME: use vlib/bitfield instead?
struct SubprocessArgs {
	combine_stdout_stderr bool = false
	inherit_env bool = true
	enable_async bool = false
}
pub fn (args SubprocessArgs) toFlags() int {
	val := int(0)
	if(args.combine_stdout_stderr) {
		val |= .subprocess_option_combined_stdout_stderr
	}
	if(args.inherit_env) {
		val |= .subprocess_option_inherit_environment
	}
	if(args.enable_async) {
		val |= .subprocess_option_enable_async
	}
	return val
}

struct Subprocess {
	proc C.subprocess_s
	args SubprocessArgs
}

pub fn create(cmd []string, args SubprocessArgs) ?Subprocess {
	ctx := Subprocess{proc: C.NULL, args: args}

	ccmd := []charptr
	for c in cmd { ccmd << c.str }

	status := C.subprocess_create(cargs, args.toFlags(), &ctx.proc)

	if(status == 0) {
		return ctx
	} else {
		error("Subprocess couldn't be launched (status=${status})")
	}
}

// I need FILE* like buffers. eep.
pub fn (ctx Subprocess) stdin() &C.FILE {}
pub fn (ctx Subprocess) stdout() &C.FILE {}
pub fn (ctx Subprocess) stderr() &C.FILE {}

pub fn (ctx Subprocess) join(mut exitCode &int) int {
	return C.subprocess_join(&ctx.proc, exitCode)
}
pub fn (ctx Subprocess) destroy() int {
	return C.subprocess_destroy(&ctx.proc)
}
pub fn (ctx Subprocess) terminate() int {
	return C.subprocess_terminate(&ctx.proc)
}

pub fn (ctx Subprocess) read_stdout(mut outbuf &string, maxlen int) {
	outbuf := string("")
	unsafe {
		rawbuf := charptr(0)
		C.subprocess_read_stdout(&ctx.proc, rawbuf, maxlen)
		outbuf = vstring_from_cstring(rawbuf)
	}
}
pub fn (ctx Subprocess) read_stderr(mut outbuf &string, maxlen int) {
	outbuf := string("")
	unsafe {
		rawbuf := charptr(0)
		C.subprocess_read_stderr(&ctx.proc, rawbuf, maxlen)
		outbuf = vstring_from_cstring(rawbuf)
	}
}
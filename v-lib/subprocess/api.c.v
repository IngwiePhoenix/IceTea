module subprocess

#flag -I @VROOT/subprocess-git
#include subprocess.h

enum subprocess_option_e {
	subprocess_option_combined_stdout_stderr = 0x1
	subprocess_option_inherit_environment = 0x2
	subprocess_option_enable_async = 0x4
}

struct C.subprocess_s {
	stdin_file &C.FILE
	stdout_file &C.FILE
	stderr_file &C.FILE

	$if windows {
		hProcess voidptr
		hStdInput voidptr
		hEventOutput voidptr
		hEventError voidptr
	} else {
		child any_int // Not gonna bother getting this one right, right now.
	}
}

fn C.subprocess_create([]charptr, int, mut &C.subprocess_s) int

fn C.subprocess_stdin(&C.subprocess_s) &C.FILE
fn C.subprocess_stdout(&C.subprocess_s) &C.FILE
fn C.subprocess_stderr(&C.subprocess_s) &C.FILE

fn C.subprocess_join(&C.subprocess_s, mut &int) int
fn C.subprocess_destroy(&C.subprocess_s) int
fn C.subprocess_terminate(&C.subprocess_s) int

fn C.subprocess_read_stdout(&C.subprocess_s, mut charptr, u32)
fn C.subprocess_read_stderr(&C.subprocess_s, mut charptr, u32)


package odwm

import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:os"

/* "MACROS" */

max :: proc(a, b: $T) -> T {
	if a > b do return a
	return b
}

min :: proc(a, b: $T) -> T {
	if a < b do return a
	return b
}

between :: proc(x, a, b: $T) -> bool {
	return a <= x && x <= b
}

length :: proc(arr: $T) -> int {
	return len(arr)
}

/* die */

// FIXME: consider using panic
die :: proc(fmt_str: cstring, va: ..any) {
	saved_errno := libc.errno()
	fmt.eprintf(string(fmt_str), ..va)
	if fmt_str != nil {
		s := string(fmt_str)
		if len(s) > 0 && s[len(s)-1] == ':' {
			err_str := libc.strerror(saved_errno^)
			fmt.eprintf(" %s", err_str)
		}
	}
	fmt.eprintln("")
	os.exit(1)
}

/* ecalloc */

// FIXME: run through the code and use make instead
//        also you should rethink pointers usage, since in C it was the best way to do things, but now there are better ways
ecalloc :: proc(nmemb: c.size_t, size: c.size_t) -> rawptr {
	p := libc.calloc(nmemb, size)
	if p == nil {
		die("calloc:")
	}
	return p
}

package odwm

import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:os"

// -------------------------------------
// Macros → Odin equivalents
// -------------------------------------

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

// LENGTH(X) → returns element count of a static array
length :: proc(arr: $T) -> int {
    return len(arr)
}

// -------------------------------------
// die(fmt, ...)
// -------------------------------------

die :: proc(fmt_str: cstring, va: ..any) {
    // Save errno early
    saved_errno := libc.errno()

    // Print formatted message (same as vfprintf(stderr, fmt, ap))
    fmt.eprintf(string(fmt_str), ..va)

    // If fmt ends with ':' → append strerror(saved_errno)
    if fmt_str != nil {
        s := string(fmt_str)
        if len(s) > 0 && s[len(s)-1] == ':' {
            err_str := libc.strerror(saved_errno^)
            fmt.eprintf(" %s", err_str)
        }
    }

    // Add final newline
    fmt.eprintln("")

    os.exit(1)
}

// -------------------------------------
// ecalloc
// -------------------------------------

ecalloc :: proc(nmemb: c.size_t, size: c.size_t) -> rawptr {
    p := libc.calloc(nmemb, size)
    if p == nil {
        die("calloc:")
    }
    return p
}

package x

// handmade bindings: don't use them, I am skill issued

import "core:c"
import "../../bindings/x11/xlib"

XftFont :: struct {
	ascent  : i32,
	descent : i32,
	height  : i32,
	max_advance_width : i32,
	charset : ^FcCharSet,
	pattern : ^FcPattern
}

XftColor :: struct {
	pixel : c.ulong,
	color : RenderColor,
}

RenderColor :: struct {
	red   : c.ushort,
	green : c.ushort,
	blue  : c.ushort,
	alpha : c.ushort,
}

FcCharSet :: distinct rawptr
FcPattern :: distinct rawptr

foreign import xft "system:Xft"
@(default_calling_convention="c")
foreign xft {
	XftFontOpenName    :: proc (display: ^xlib.Display, screen: i32, name: ^cstring) -> ^XftFont ---
	XftFontOpenPattern :: proc (display: ^xlib.Display, pattern: ^FcPattern)         -> ^XftFont ---
	XftFontClose       :: proc (display: ^xlib.Display, pub: ^XftFont)                           ---
}

FcChar8  :: distinct c.uchar
FcChar16 :: distinct c.ushort
FcChar32 :: distinct c.uint
FcBool   :: distinct c.int


foreign import fc  "system:fontconfig"
@(default_calling_convention="c")
foreign fc {
	FcNameParse :: proc (name: ^FcChar8) -> ^FcPattern ---
}

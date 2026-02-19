package odwm

import x "../bindings/x11/xlib"

Cur :: struct {
	cursor : x.Cursor
}

// TODO: write bindings for commented ones

Fnt :: struct {
	dpy     : ^x.Display,
	h       : u32,
	// xfont   : ^x.XftFont,
	// pattern : ^x.FcPattern,
	next    : ^Fnt,
}

ClrScheme :: enum { ColFg, ColBg, ColBorder }

Drw :: struct {
	w, h     : i32,
	dpy      : ^x.Display,
	screen   : i32,
	root     : x.Window,
	drawable : x.Drawable,
	gc       : x.GC,
	// scheme   : ^x.XftColor,
	// fonts    : ^x.Fnt,
}

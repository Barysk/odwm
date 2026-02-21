package odwm

import fmt  "core:fmt"
import xlib "../bindings/x11/xlib"
import x    "../bindings/x"
import c    "core:c/libc"

Cur :: struct {
	cursor : xlib.Cursor
}

Fnt :: struct {
	dpy     : ^xlib.Display,
	h       : u32,
	xfont   : ^x.XftFont,
	pattern : ^x.FcPattern,
	next    : ^Fnt,
}

ClrScheme :: enum { ColFg, ColBg, ColBorder }

Drw :: struct {
	w, h     : u32,
	dpy      : ^xlib.Display,
	screen   : i32,
	root     : xlib.Window,
	drawable : xlib.Drawable,
	gc       : xlib.GC,
	scheme   : ^x.XftColor,
	fonts    : ^Fnt,
}

Clr :: distinct x.XftColor

drw_create :: proc (dpy: ^xlib.Display, screen: i32, win: xlib.Window, w: u32, h: u32) -> ^Drw {
	drw: ^Drw = cast(^Drw)(ecalloc(1, size_of(Drw)))

	drw.dpy      = dpy
	drw.screen   = screen
	drw.root     = root
	drw.w        = w
	drw.h        = h
	drw.drawable = xlib.CreatePixmap(dpy, root, w, h, u32(xlib.DefaultDepth(dpy, screen)))
	drw.gc       = xlib.CreateGC(dpy, root, { .GCFunction }, nil)
	xlib.SetLineAttributes(dpy, drw.gc, 1, .LineSolid, .CapButt, .JoinMiter)

	return drw
}

drw_cur_create :: proc (drw: ^Drw, shape: xlib.CursorShape) -> ^Cur {
	cur: ^Cur

	cur = cast(^Cur)ecalloc(1, size_of(Cur))
	if drw == nil || cur == nil {
		return nil }

	cur.cursor = xlib.CreateFontCursor(drw.dpy, shape)

	return cur
}

drw_scm_create :: proc (drw: ^Drw, clrnames: []cstring, clrcount: c.size_t) -> []Clr {
	i: c.size_t
	ret: []Clr

	/* need at least two colors for a scheme */
	// ret = cast(^Clr)ecalloc(clrcount, size_of(Clr))
	ret = make([]Clr, size_of(Clr))
	for drw == nil || clrnames == nil || clrcount < 2 || ret == nil {
		return nil }

	for clr, i in 0..<clrcount {
		drw_clr_create(drw, &ret[i], clrnames[i])}
	return ret

}

drw_clr_create :: proc (drw: ^Drw, dest: ^Clr, clrname: cstring) {
	if drw == nil || dest == nil || clrname == nil {
		return }
	
	if !x.XftColorAllocName(drw.dpy, xlib.DefaultVisual(drw.dpy, drw.screen), xlib.DefaultColormap(drw.dpy, drw.screen), clrname, cast(^x.XftColor)dest) {
		die("error, cannot allocate color", clrname)}
}

drw_fontset_create :: proc (dpy: ^Drw, fonts: []cstring, fontcount: c.size_t) -> ^Fnt {
	cur: ^Fnt = nil
	ret: ^Fnt = nil
	i: c.size_t

	if (drw == nil || fonts == nil) { return nil }

	for &font in fonts {
		cur = xfont_create(drw, &font, nil) 
		if cur != nil {
			cur.next = ret
			ret = cur
		}
	}

	drw.fonts = ret
	return drw.fonts
}

xfont_create :: proc (drw: ^Drw, fontname: ^cstring, fontpattern: ^x.FcPattern) -> ^Fnt {
	font    : ^Fnt
	xfont   : ^x.XftFont   = nil
	pattern : ^x.FcPattern = nil

	if fontname != nil {
		/* Using the pattern found at font->xfont->pattern does not yield the
		 * same substitution results as using the pattern returned by
		 * FcNameParse; using the latter results in the desired fallback
		 * behaviour whereas the former just results in missing-character
		 * rectangles being drawn, at least with some fonts. */
		xfont = x.XftFontOpenName(drw.dpy, drw.screen, fontname^)
		if xfont == nil {
			fmt.printf("error, cannot load font from name: ", fontname)
			return nil
		}
		pattern = x.FcNameParse(cast(^x.FcChar8)fontname)
		if pattern == nil {
			fmt.printf("error, cannot parse font name to pattern: ", fontname)
			x.XftFontClose(drw.dpy, xfont)
			return nil
		}
	} else if fontpattern != nil {
		xfont = x.XftFontOpenPattern(drw.dpy, fontpattern)
		if xfont == nil {
			fmt.printf("error, cannot load font from pattern.\n")
			return nil
		}
	} else {
		die("no font specified")
	}

	font = cast(^Fnt)ecalloc(1, size_of(Fnt))
	font.xfont = xfont
	font.pattern = pattern
	font.h = u32(xfont.ascent + xfont.descent)
	font.dpy = drw.dpy

	return font
}

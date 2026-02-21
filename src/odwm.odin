package odwm

///////////////
// CONSTANTS //
///////////////

WM_NAME      :: "odwm"
VERSION      :: "0.1inf"
NEXT_WINDOW  :: "NEXT_WINDOW"
PREV_WINDOW  :: "PREVIOUS_WINDOW"
// EXIT_FAILURE :: 0
// EXIT_SUCCESS :: 1

/////////////
// IMPORTS //
/////////////

import rt   "base:runtime"
import xlib "../bindings/x11/xlib"
import psx  "../bindings/posix"
import c     "core:c"
import libc "core:c/libc"
import os   "core:os"
import fmt  "core:fmt"

///////////
// ENUMS //
///////////

EnCur :: enum { Normal, Resize, Move, Last } /* cursor */
EnScheme :: enum { Norm, Sel } /* color schemes */
EnNet :: enum {
	Supported, WMName, WMState, WMCheck,
	WMFullscreen, ActiveWindow, WMWindowType,
	WMWindowTypeDialog, ClientList, Last } /* EWMH atoms */
EnWM :: enum { Protocols, Delete, State, TakeFocus, Last } /* default atoms */
EnClk :: enum {
	TagBar, LtSymbol, StatusText, WinTitle,
	ClientWin, RootWin, Last } /* clicks */

///////////////
// VARIABLES //
///////////////

xerrorxlib : proc "c" (^xlib.Display, ^xlib.XErrorEvent) -> i32 = nil;
screen     : i32
sw, sh     : i32 /* screen geometry */
bh         : i32 /* bar height */
lrpad      : i32
wmatom     : [EnWM.Last]xlib.Atom
netatom    : [EnNet.Last]xlib.Atom
running    : i32
cursor     : ^[EnCur.Last]Cur
scheme     : [][]Clr
dpy        : ^xlib.Display
drw        : ^Drw
mons, selmon     : ^Monitor
root, wmcheckwin : xlib.Window

////////////
// MACROS //
////////////

INTERSECT :: proc(x, y, w, h: i32, m: ^Monitor) -> i32 {
	x_overlap := max(i32(0), min(x + w, m.wx + m.ww) - max(x, m.wx))
	y_overlap := max(i32(0), min(y + h, m.wy + m.wh) - max(y, m.wy))
	return x_overlap * y_overlap
}

/////////////
// STRUCTS //
/////////////

Client :: struct {
	name       : [256]c.char,
	mina, maxa : f32,
	x, y, w, h : i32,
	oldx, oldy, oldw, oldh: i32,
	basew, baseh, incw, inch, maxw, maxh, minw, minh, hintsvalid: i32,
	bw, oldbw  : i32,
	tags       : u32,
	isfixed, isfloating, isurgent, neverfocus, oldstate, isfullscreen: i32,
	next  : ^Client,
	snext : ^Client,
	mon   : ^Monitor,
	win   : xlib.Window,
}

Layout :: struct {
	symbol  : cstring,
	arrange : proc(monitor: ^Monitor)
}

Monitor :: struct {
	ltsymbol : [16]c.char,
	mfact    : f32,
	nmaster  : i32,
	num      : i32,
	by       : i32,
	mx, my, mw, mh : i32,
	wx, wy, ww, wh : i32,
	seltags  : u32,
	sellt    : u32,
	tagset   : [2]u32,
	showbar  : i32,
	topbar   : i32,
	clients  : ^Client,
	sel      : ^Client,
	stack    : ^Client,
	next     : ^Monitor,
	barwin   : ^xlib.Window,
	lt       : ^[2]Layout,
}


///////////
// LOGIC //
///////////

// die :: proc(msg: string) {
// 	fmt.eprintln(msg)
// 	os.exit(1)
// }

main :: proc () {
	args := os.args

	if len(args) == 2 && args[1] == "-v" {
		die(WM_NAME + "-" + VERSION)
	} else if len(args) != 1 {
		die("usage: " + WM_NAME + " [-v]")
	}
	if libc.setlocale(.CTYPE, "") == nil || !xlib.SupportsLocale() {   // FIXME: possible weak spot
		fmt.eprintln("warning: no locale support")
	}
	dpy = xlib.OpenDisplay(nil)
	if dpy == nil {
		die(WM_NAME + ": cannot open display")
	}

	checkotherwm() // DONE
	setup()
	// scan()
	// run()
	// cleanup()
	xlib.CloseDisplay(dpy)
}

checkotherwm :: proc () {
	xerrorxlib = xlib.SetErrorHandler(xerrorstart)
	// this causes an error if some other wm is running
	xlib.SelectInput(dpy, xlib.DefaultRootWindow(dpy), { .SubstructureRedirect })
	xlib.Sync(dpy, false)
	xlib.SetErrorHandler(xerror)
	xlib.Sync(dpy, false)
}

setup :: proc () {
	i          : i32
	wa         : xlib.XSetWindowAttributes
	utf8string : xlib.Atom
	sa         : psx.sigaction_t

	/* do not transform children into zombies when they terminate */
	psx.sigemptyset(&sa.sa_mask)
	sa.sa_flags = psx.SA_Flags{.NOCLDSTOP, .NOCLDWAIT, .SA_NODEFER}
	sa.sa_handler = cast(proc "c" (psx.Signal)) psx.SIG_IGN        // FIXME: possible weak spot
	psx.sigaction(psx.Signal(psx.SIGCHLD), &sa, nil)

	/* clean up any zombies (ingerited from .xinitrc etc) immediately */
	for psx.waitpid(-1, nil, psx.Wait_Flags{.NOHANG}) > 0 {}

	/* init screen */
	screen = xlib.DefaultScreen(dpy)
	sw     = xlib.DisplayWidth(dpy, screen)
	sh     = xlib.DisplayHeight(dpy, screen)
	root   = xlib.RootWindow(dpy, screen)
	drw    = drw_create(dpy, screen, root, u32(sw), u32(sh))
	if drw_fontset_create(drw, fonts, len(fonts)) == nil {
		die("no fonts could be loaded")
	}
	lrpad = i32(drw.fonts.h)
	bh = i32(drw.fonts.h) + 2
	updategeom()
	/* init atoms */
	utf8string = xlib.InternAtom(dpy, "UTF8_STRING", false)
	wmatom[EnWM.Protocols] = xlib.InternAtom(dpy, "WN_PROTOCOLS", false)
	wmatom[EnWM.Delete] = xlib.InternAtom(dpy, "WM_DELETE_WINDOW", false)
	wmatom[EnWM.State] = xlib.InternAtom(dpy, "WM_STATE", false)
	wmatom[EnWM.TakeFocus] = xlib.InternAtom(dpy, "WM_TAKE_FOCUS", false)
	netatom[EnNet.ActiveWindow] = xlib.InternAtom(dpy, "_NET_ACTIVE_WINDOW", false)
	netatom[EnNet.Supported] = xlib.InternAtom(dpy, "_NET_SUPPORTED", false)
	netatom[EnNet.WMName] = xlib.InternAtom(dpy, "_NET_WM_NAME", false)
	netatom[EnNet.WMState] = xlib.InternAtom(dpy, "_NET_WM_STATE", false)
	netatom[EnNet.WMCheck] = xlib.InternAtom(dpy, "_NET_SUPPORTING_WM_CHECK", false)
	netatom[EnNet.WMFullscreen] = xlib.InternAtom(dpy, "_NET_WM_STATE_FULLSCREEN", false)
	netatom[EnNet.WMWindowType] = xlib.InternAtom(dpy, "_NET_WM_WINDOW_TYPE", false)
	netatom[EnNet.WMWindowTypeDialog] = xlib.InternAtom(dpy, "_NET_WM_WINDOW_TYPE_DIALOG", false)
	netatom[EnNet.ClientList] = xlib.InternAtom(dpy, "_NET_CLIENT_LIST", false)
	/* init cursors */
	cursor[EnCur.Normal] = drw_cur_create(drw, xlib.CursorShape.XC_left_ptr)^  // FIXME: not sure why dereference there is required
	cursor[EnCur.Resize] = drw_cur_create(drw, xlib.CursorShape.XC_sizing)^
	cursor[EnCur.Move]   = drw_cur_create(drw, xlib.CursorShape.XC_fleur)^
	/* init appearance */
	// scheme = ecalloc(len(colors), size_of(^Clr))
	scheme = make([][]Clr, len(colors))
	for color, i in colors {
		scheme[i] = drw_scm_create(drw, color, 3) }


}

updategeom :: proc () -> i32 {
	dirty: i32 = 0
	// TODO: XINERMA SUPPORT HERE, NOW OMITTED
	{ /* Default monitor setup */
		if mons == nil {
			mons = createmon()
		}
		if mons.mw != sw || mons.mh != sh {
			dirty = 1
			mons.mw = sw
			mons.ww = sw
			mons.mh = sh
			mons.wh = sh
			updatebarpos(mons)
		}
	}
	if dirty != 0 {
		selmon = mons
		selmon = wintomon(root)
	}
	return dirty
}

wintomon :: proc (w: xlib.Window) -> ^Monitor {
	x, y : i32
	c : ^Client
	m : ^Monitor

	if (w == root) && getrootptr(&x, &y) {
		return recttomon(x, y, 1, 1)
	}
	for m = mons; m != nil; m = m.next {
		if w == m.barwin^ {
			return m
		}
	}
	c = wintoclient(w)
	if c != nil {
		return c.mon
	}
	return selmon
}

wintoclient :: proc (w: xlib.Window) -> ^Client {
	c: ^Client
	m: ^Monitor

	for m = mons; m != nil; m = m.next {
		for c = m.clients; c != nil; c = c.next {
			if (c.win == w) {
				return c
			}
		}
	}
	return nil
}

recttomon :: proc (x, y, w, h: i32) -> ^Monitor {
	m: ^Monitor
	r: ^Monitor = selmon
	a: i32
	area: i32 = 0

	for m = mons; m != nil; m = m.next {
		a = INTERSECT(x, y, w, h, m)
		if a > area {
			area = a
			r = m
		}
	}
	return r
}

getrootptr :: proc (x, y: ^i32) -> b32 {
	di: i32
	dui: xlib.KeyMask
	dummy: xlib.Window

	return xlib.QueryPointer(dpy, root, &dummy, &dummy, x, y, &di, &di, &dui)
}

updatebarpos :: proc (m: ^Monitor) {
	m.wy = m.my
	m.wh = m.mh
	if m.showbar != 0 {
		m.wh -= bh
		m.by = (m.topbar != 0) ? m.wy : m.wy + m.wh
		m.wy = (m.topbar != 0) ? m.wy + bh : m.wy
	} else {
		m.by = -bh
	}
}

createmon :: proc () -> ^Monitor {
	m: ^Monitor
	l:= layouts

	m = cast(^Monitor)ecalloc(1, size_of(Monitor))
	m.tagset[0] = 1
	m.tagset[1] = 1
	m.mfact     = mfact
	m.nmaster   = nmaster
	m.showbar   = showbar
	m.topbar    = topbar
	m.lt[0]     = l[0]
	m.lt[1]     = l[1 % len(l)]

	return m
}

xerror :: proc "c" (dpy: ^xlib.Display, ee: ^xlib.XErrorEvent) -> i32 {
	context = rt.default_context()
	if (ee.error_code   == u8(xlib.Status.BadWindow) \
	|| (ee.request_code == u8(xlib.RequesCodes.X_SetInputFocus)     && ee.error_code == u8(xlib.Status.BadMatch))     \
	|| (ee.request_code == u8(xlib.RequesCodes.X_PolyText8)         && ee.error_code == u8(xlib.Status.BadDrawable))  \
	|| (ee.request_code == u8(xlib.RequesCodes.X_PolyFillRectangle) && ee.error_code == u8(xlib.Status.BadDrawable))  \
	|| (ee.request_code == u8(xlib.RequesCodes.X_PolySegment)       && ee.error_code == u8(xlib.Status.BadDrawable))  \
	|| (ee.request_code == u8(xlib.RequesCodes.X_ConfigureWindow)   && ee.error_code == u8(xlib.Status.BadMatch))     \
	|| (ee.request_code == u8(xlib.RequesCodes.X_GrabButton)        && ee.error_code == u8(xlib.Status.BadAccess))    \
	|| (ee.request_code == u8(xlib.RequesCodes.X_GrabKey)           && ee.error_code == u8(xlib.Status.BadAccess))    \
	|| (ee.request_code == u8(xlib.RequesCodes.X_CopyArea)          && ee.error_code == u8(xlib.Status.BadDrawable))) {
		return 0
	}
	fmt.eprintfln("%s: fatal error: request code=%d, error code=%d", WM_NAME, ee.request_code, ee.error_code)
	return xerrorxlib(dpy, ee)
}

xerrorstart :: proc "c" (dpy: ^xlib.Display, ee: ^xlib.XErrorEvent) -> i32 {
	context = rt.default_context()
	die(WM_NAME + ": another window manager is already running")
	return -1
}


tile_proc :: proc(m: ^Monitor) { }

monocle_proc :: proc(m: ^Monitor) { }

////////////////////////
// TEMPLATE TERRITORY //
////////////////////////

// main :: proc () {
// 	context.logger = log.create_console_logger()
//
// 	display: ^xlib.Display
// 	window : xlib.Window
// 	event  : xlib.XEvent
//
// 	msg :: "Hellope!"
// 	s: i32
//
// 	// open connection to the server
// 	display = xlib.OpenDisplay(nil)
// 	if display == nil {
// 		log.fatal("Cannot open display")
// 		os.exit(1)
// 	}
//
// 	s = xlib.DefaultScreen(display)
//
// 	// create window
// 	window = xlib.CreateSimpleWindow(display, xlib.RootWindow(display, s), 10, 10, 200, 200, 1, xlib.BlackPixel(display, s), xlib.WhitePixel(display, s))
//
// 	// select kind of events we are interested in
// 	xlib.SelectInput(display, window, {.Exposure, .KeyPress})
//
// 	// map (show) the window
// 	xlib.MapWindow(display, window)
//
// 	// event loop
// 	for {
// 		xlib.NextEvent(display, &event)
//
// 		// draw or redraw the window
// 		if event.type == .Expose {
// 			xlib.FillRectangle(display, window, xlib.DefaultGC(display, s), 20, 20, 10, 10)
// 			// xlib.DrawString(display, window, xlib.DefaultGC(display, s), 50, 50, msg, libc.strlen(msg))
// 		}
// 		if event.type == .KeyPress {
// 			break
// 		}
// 	}
// 	xlib.CloseDisplay(display)
// }

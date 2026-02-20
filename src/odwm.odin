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

///////////////
// VARIABLES //
///////////////

dpy        : ^xlib.Display
xerrorxlib : proc "c" (^xlib.Display, ^xlib.XErrorEvent) -> i32 = nil;
screen     : i32
sw, sh     : i32 /* screen geometry */
bh         : i32 /* bar height */
drw        : ^Drw
root       : xlib.Window
wmcheckwin : xlib.Window



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
// [[ 1 ]] -- added binding for SupportsLocale
// @(default_calling_convention="c", link_prefix="X")
// foreign xlib {
// 	// Free data allocated by Xlib
// 	Free              :: proc(ptr: rawptr) ---
// 	// Opening/closing a display
// 	OpenDisplay       :: proc(name: cstring) -> ^Display ---
// 	CloseDisplay      :: proc(display: ^Display) ---
// +	SupportsLocale    :: proc() -> bool ---

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

	// TODO: complete drw bindings

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

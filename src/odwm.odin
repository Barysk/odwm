package odwm

///////////////
// CONSTANTS //
///////////////

WM_NAME      :: "odwm"
VERSION      :: "0.1inf"
NEXT_WINDOW  :: "NEXT_WINDOW"
PREV_WINDOW  :: "PREVIOUS_WINDOW"
EXIT_FAILURE :: 0
EXIT_SUCCESS :: 1

/////////////
// IMPORTS //
/////////////

import x    "../bindings/x11/xlib"
import c    "core:c"
import libc "core:c/libc"
import os   "core:os"
import fmt  "core:fmt"

///////////////
// VARIABLES //
///////////////

dpy        : ^x.Display
xerrorxlib : proc "c" (d: ^x.Display, e: ^x.XErrorEvent) -> i32;


///////////
// LOGIC //
///////////

die :: proc(msg: string) {
	fmt.eprintln(msg)
	os.exit(1)
}

main :: proc () -> i32 {
	args := os.args

	if len(args) == 2 && args[1] == "-v" {
		die(WM_NAME + "-" + VERSION)
	} else if len(args) != 1 {
		die("usage: " + WM_NAME + " [-v]")
	}
	if libc.setlocale(.CTYPE, "") == nil || !x.SupportsLocale() {
		fmt.eprintln("warning: no locale support")
	}
	dpy = x.OpenDisplay(nil)
	if dpy == nil {
		die(WM_NAME + ": cannot open display")
	}

	// checkotherwm()
	
	x.CloseDisplay(dpy)
	return EXIT_SUCCESS
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

// checkotherwm :: proc () {
// 	xerrorxlib = x.SetErrorHandler(xerrorstart)
// 	//...
//
// }
//
// xerrorstart :: proc "c" (dpy: ^x.Display, ee: ^x.XErrorEvent) -> i32 {
// 	die(WM_NAME + ": another window manager is already running")
// 	return -1
// }



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

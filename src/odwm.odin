package odwm

import xlib "vendor:x11/xlib"
import libc "core:c/libc"
import os   "core:os"
import log  "core:log"

NEXT_WINDOW :: "NEXT_WINDOW"
PREV_WINDOW :: "PREVIOUS_WINDOW"

WM_NAME :: "odwm"

main :: proc () {
	context.logger = log.create_console_logger()

	display: ^xlib.Display
	window : xlib.Window
	event  : xlib.XEvent

	msg :: "Hellope!"
	s: i32

	// open connection to the server
	display = xlib.OpenDisplay(nil)
	if display == nil {
		log.fatal("Cannot open display")
		os.exit(1)
	}

	s = xlib.DefaultScreen(display)

	// create window
	window = xlib.CreateSimpleWindow(display, xlib.RootWindow(display, s), 10, 10, 200, 200, 1, xlib.BlackPixel(display, s), xlib.WhitePixel(display, s))

	// select kind of events we are interested in
	xlib.SelectInput(display, window, {.Exposure, .KeyPress})

	// map (show) the window
	xlib.MapWindow(display, window)

	// event loop
	for {
		xlib.NextEvent(display, &event)

		// draw or redraw the window
		if event.type == .Expose {
			xlib.FillRectangle(display, window, xlib.DefaultGC(display, s), 20, 20, 10, 10)
			// xlib.DrawString(display, window, xlib.DefaultGC(display, s), 50, 50, msg, libc.strlen(msg))
		}
		if event.type == .KeyPress {
			break
		}
	}
	xlib.CloseDisplay(display)
}

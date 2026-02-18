const std = @import("std");

const c = @cImport({
	@cInclude("X11/Xlib.h");
	@cInclude("locale.h");
	@cInclude("string.h");
});

const WM_NAME = "zdwm";
const VERSION = "0.1inf";

// Simple replacement for die()
fn die(msg: []const u8) noreturn {
	const stderr = std.io.getStdErr().writer();
	// ignore error when printing because we are exiting
	_ = stderr.print("{s}\n", .{msg});
	std.process.exit(1);
}

fn main() !void {
	const args = std.os.argv;

	// argc == 2 && argv[1] == "-v"
	if (args.len == 2 and std.mem.eql(u8, std.mem.sliceTo(args[1], 0), "-v")) {
		die(WM_NAME ++ "-" ++ VERSION);
	} else if (args.len != 1) {
		die("usage: " ++ WM_NAME ++ " [-v]");
	}

	// locale check: setlocale(LC_CTYPE, "") && XSupportsLocale()
	if (c.setlocale(c.LC_CTYPE, "") == null or c.XSupportsLocale() == 0) {
		const stderr = std.io.getStdErr().writer();
		_ = stderr.print("warning: no locale support\n", .{});
	}

	// dpy = XOpenDisplay(NULL)
	const dpy = c.XOpenDisplay(null);
	if (dpy == null) {
		die(WM_NAME ++ ": cannot open display");
	}

	// Continue with rest of program...
}

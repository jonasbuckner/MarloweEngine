const std = @import("std");
const screen = @import("screen.zig");
const Location = screen.Location;
const Direction = screen.Direction;
const posix = std.posix;

// zig fmt: off
const CLEAR_SCREEN      = "\x1b[2J";
const HOME_POSITION     = "\x1b[1H";
const SAVE_CURSOR       = "\x1b7";
const RESTORE_CURSOR    = "\x1b8";
const MOVE_CURSOR_FMT   = "\x1b[{d};{d}H";
const MOVE_CURSOR_UP    = "\x1b[{d}A";
const MOVE_CURSOR_DOWN  = "\x1b[{d}B";
const MOVE_CURSOR_RIGHT = "\x1b[{d}C";
const MOVE_CURSOR_LEFT  = "\x1b[{d}D";
const MOVE_CURSOR_LFCR  = "\x1b[1E";
// zig fmt: on

pub const Tui = struct {
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();
    var saved_terminal_state: posix.termios = undefined;
    var tty: posix.fd_t = undefined;

    pub fn write(_: *const Tui, bytes: []const u8) !usize {
        return stdout.write(bytes);
    }

    pub fn writeByte(_: *const Tui, byte: u8) !usize {
        const byte_array: [1]u8 = .{byte};
        return stdout.write(@as([]const u8, &byte_array));
    }

    pub fn move_cursor(_: *const Tui, location: Location) !void {
        try stdout.writer().print(MOVE_CURSOR_FMT, .{ location.y, location.x });
    }

    pub fn save_cursor(_: *const Tui) !void {
        _ = try stdout.write(SAVE_CURSOR);
    }

    pub fn restore_cursor(_: *const Tui) !void {
        _ = try stdout.write(RESTORE_CURSOR);
    }

    pub fn move_cursor_direction(_: *const Tui, comptime direction: Direction, count: usize) !void {
        const fmt = comptime switch (direction) {
            .up => MOVE_CURSOR_UP,
            .down => MOVE_CURSOR_DOWN,
            .left => MOVE_CURSOR_LEFT,
            .right => MOVE_CURSOR_RIGHT,
        };

        _ = try stdout.writer().print(fmt, .{count});
    }

    pub fn clear_screen(self: *const Tui) !void {
        _ = try self.write(CLEAR_SCREEN);
    }

    pub fn move_cursor_home(self: *const Tui) !void {
        _ = try self.write(HOME_POSITION);
    }

    pub fn move_cursor_newline(self: *const Tui) !void {
        _ = try self.write(MOVE_CURSOR_LFCR);
    }

    pub fn print(_: *const Tui, comptime fmt: []const u8, args: anytype) anyerror!void {
        return std.fmt.format(stdout.writer(), fmt, args);
    }

    pub fn readByte(_: *const Tui) anyerror!u8 {
        return stdin.reader().readByte();
    }

    pub fn read(_: *const Tui, buffer: []u8) anyerror!usize {
        return stdin.reader().read(buffer);
    }
    // pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    //     return std.fmt.format(stdout.writer(), fmt, args);
    // }

    pub fn setup(self: *const Tui) !void {
        tty = posix.open("/dev/tty", .{ .ACCMODE = .RDWR }, 0) catch 0;
        if (tty == 0) {
            // TODO: Probably handle all the errors.
            // Not sure this is printing if tty failed to open;
            // Maybe should write to a log or something.
            _ = try self.write("Could not open tty\n");
            return;
        }
        try self.makeRaw();

        _ = try self.clear_screen();
        _ = try self.move_cursor_home();
    }

    pub fn teardown(_: *const Tui) !void {
        posix.tcsetattr(tty, .NOW, saved_terminal_state) catch {};
        posix.close(tty);
    }

    fn makeRaw(_: *const Tui) !void {
        saved_terminal_state = posix.tcgetattr(tty) catch |e| {
            return e;
        };
        var rawterm = saved_terminal_state;

        // zig fmt: off
        // see termios(3) under the section "Raw mode"
        // iflag is the input mode flags
        rawterm.iflag.IGNBRK = false; // Don't ignore BREAK
        rawterm.iflag.BRKINT = false; // BREAK reads as a null byte because IGNBRK and PARMRK are false
        rawterm.iflag.PARMRK = false; // Do not mark input bytes that have parity or framing errors with \377 and \0 when passed into the program
        rawterm.iflag.ISTRIP = false; // Don't strip off eighth bit
        rawterm.iflag.INLCR  = false; // Don't translate newline (NL) to carriage return (CR) on input
        rawterm.iflag.IGNCR  = false; // Don't ignore carriage return on input
        rawterm.iflag.ICRNL  = false; // Don't translate newline (NL) to carriage return (CR) on input
        rawterm.iflag.IXON   = false; // Enable XON/XOFF flow control on output (I think this is set -x)

        // oflag is the output mode flags
        rawterm.oflag.OPOST = false; // Disable implementation-defined output processing

        // lflag is the local mode flags
        rawterm.lflag.ECHO   = false; // Echo off. Don't echo input characters
        rawterm.lflag.ECHONL = false; // Do not echo newlines
        rawterm.lflag.ICANON = false; // Disable canonical mode
        rawterm.lflag.ISIG   = false; // Do not generate corresponding signals for INTR, QUIT, SUSP, or DPSUSP characters
        rawterm.lflag.IEXTEN = false; // Disable implementation-defined input processing like special control characters

        // cflag is the control mode flags
        rawterm.cflag.CSIZE  = .CS8;  // Character mask size
        rawterm.cflag.PARENB = false; // Disable parity generation on output and parity checking for input
        // zig fmt: on

        // special characters
        rawterm.cc[@intFromEnum(posix.V.MIN)] = 1;
        rawterm.cc[@intFromEnum(posix.V.TIME)] = 0;
        try posix.tcsetattr(tty, .NOW, rawterm);
    }
};

pub var instance = Tui{};

pub inline fn Bold() []const u8 {
    return "\x1b[1m";
}

pub inline fn Reset() []const u8 {
    return "\x1b[22m";
}

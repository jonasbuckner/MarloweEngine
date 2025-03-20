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
const CURSOR_POSITION   = "\x1b[6n";
const ERASE_EOL         = "\x1b[0K";
const ERASE_SOL         = "\x1b[1K";
const ERASE_ENTIRE_LINE = "\x1b[2K";
// zig fmt: on

const TuiErrorCodes = error{
    InvalidReturnCode,
};

pub const Tui = struct {
    const stdout = std.io.getStdOut();
    const stderr = std.io.getStdErr();
    const stdin = std.io.getStdIn();
    var saved_terminal_state: posix.termios = undefined;
    var tty: posix.fd_t = undefined;
    var tabstop: usize = 8;

    pub fn TabStop() usize {
        return tabstop;
    }

    pub fn write(_: *const Tui, bytes: []const u8) !usize {
        return stdout.write(bytes);
    }

    pub fn writeErr(_: *const Tui, bytes: []const u8) !usize {
        return stderr.write(bytes);
    }

    pub fn writeByte(_: *const Tui, byte: u8) !usize {
        const byte_array: [1]u8 = .{byte};
        return stdout.write(@as([]const u8, &byte_array));
    }

    pub fn moveCursor(_: *const Tui, location: Location) !void {
        try stdout.writer().print(MOVE_CURSOR_FMT, .{ location.y, location.x });
    }

    pub fn saveCursor(_: *const Tui) !void {
        _ = try stdout.write(SAVE_CURSOR);
    }

    pub fn restoreCursor(_: *const Tui) !void {
        _ = try stdout.write(RESTORE_CURSOR);
    }

    pub fn moveCursorDirection(_: *const Tui, comptime direction: Direction, count: usize) !void {
        const fmt = comptime switch (direction) {
            .up => MOVE_CURSOR_UP,
            .down => MOVE_CURSOR_DOWN,
            .left => MOVE_CURSOR_LEFT,
            .right => MOVE_CURSOR_RIGHT,
        };

        _ = try stdout.writer().print(fmt, .{count});
    }

    pub fn clearScreen(self: *const Tui) !void {
        _ = try self.write(CLEAR_SCREEN);
    }

    pub fn moveCursorHome(self: *const Tui) !void {
        _ = try self.write(HOME_POSITION);
    }

    pub fn moveCursorNewline(self: *const Tui) !void {
        _ = try self.write(MOVE_CURSOR_LFCR);
    }

    pub fn cursorPosition(self: *const Tui) !Location {
        try stdout.writer().writeAll(CURSOR_POSITION);

        // TODO: Investigate whether this would be better with a series of readBytes
        var pos_buff = std.mem.zeroes([10]u8);
        _ = try self.read(&pos_buff);

        var x: usize = 0;
        var y: usize = 0;

        var i: u8 = 0;
        if (std.ascii.isControl(pos_buff[i])) {
            i += 1; // ESC
        } else {
            return TuiErrorCodes.InvalidReturnCode;
        }
        if (pos_buff[i] == '[') {
            i += 1;
        } else {
            return TuiErrorCodes.InvalidReturnCode;
        }

        var x_buf = std.mem.zeroes([4]u8);
        var y_buf = std.mem.zeroes([4]u8);
        if (std.ascii.isDigit(pos_buff[i])) {
            var y_count: u8 = 0;
            while (pos_buff[i] != ';') {
                if (std.ascii.isDigit(pos_buff[i])) {
                    y_buf[y_count] = pos_buff[i];
                    y_count += 1;
                }
                i += 1;
            }
            const y_number = y_buf[0..y_count];
            y = try std.fmt.parseUnsigned(usize, y_number, 10);

            i += 1; // ';'

            var x_count: u8 = 0;
            while (pos_buff[i] != 'R') {
                if (std.ascii.isDigit(pos_buff[i])) {
                    x_buf[x_count] = pos_buff[i];
                    x_count += 1;
                }
                i += 1;
            }
            const x_number = x_buf[0..x_count];
            x = try std.fmt.parseUnsigned(usize, x_number, 10);
        } else {
            try self.print("| {s} {d} |", .{ pos_buff, i });
            return TuiErrorCodes.InvalidReturnCode;
        }

        return .{ .x = x, .y = y };
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

    pub fn eraseCharacterUnderCursor(self: *const Tui) !void {
        return self.writeByte(' ');
    }

    pub fn eraseToEndOfCurrentLine(self: *const Tui) !usize {
        return self.write(ERASE_EOL);
    }

    pub fn eraseToStartOfCurrentLine(self: *const Tui) !usize {
        return self.write(ERASE_SOL);
    }

    pub fn eraseEntireCurrentLine(self: *const Tui) !usize {
        return self.write(ERASE_ENTIRE_LINE);
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

        // Determine the width of a tab for this terminal
        _ = try self.clearScreen();
        _ = try self.moveCursorHome();
        const first_cursor_position = self.cursorPosition() catch Location.empty();
        _ = try self.writeByte('\t');
        const second_cursor_position = self.cursorPosition() catch Location.empty();
        tabstop = second_cursor_position.x - first_cursor_position.x;

        _ = try self.clearScreen();
        _ = try self.moveCursorHome();
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

const std = @import("std");
const Location = @import("location.zig").Location;

const CLEAR_SCREEN = "\x1b[2J";
const HOME_POSITION = "\x1b[1H";
const MOVE_CURSOR_FMT = "\x1b[{d};{d}H";

pub const Tui = struct {
    pub fn write(_: *const Tui, bytes: []const u8) !usize {
        return std.io.getStdOut().write(bytes);
    }

    pub fn move_cursor(_: *const Tui, location: Location) !void {
        try std.io.getStdOut().writer().print(MOVE_CURSOR_FMT, .{ location.y, location.x });
    }
};

pub var instance = Tui{};

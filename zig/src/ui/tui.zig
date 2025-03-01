const std = @import("std");
const Location = @import("location.zig").Location;

const CLEAR_SCREEN = "\x1b[2J";
const HOME_POSITION = "\x1b[1H";
const MOVE_CURSOR_FMT = "\x1b[{};{}H";

const Self = @This();
const Error = error{};
const stdout = std.io.getStdOut();
const stderr = std.io.getStdErr();

pub const Writer = std.io.Writer(*Self, Error, write);

var instance = Self{};

pub var stdout_writer: Writer = undefined;

pub fn init() void {
    stdout_writer = .{ .context = &instance };
}

pub fn write(self: *Self, bytes: []const u8) Error!usize {
    _ = self;
    return try stdout.write(bytes);
}

pub fn move_cursor(location: Location) !void {
    try stdout_writer.print(MOVE_CURSOR_FMT, .{ location.y, location.x });
}

// pub fn print_at_location(location: Location, text: *const []u8) !void {
//     try move_cursor(location);
//     _ = try Self.writer.write(text);
// }

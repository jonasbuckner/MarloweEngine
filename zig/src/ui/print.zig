const std = @import("std");
const Location = @import("location.zig").Location;

const Self = @This();
const Error = error{};

UIBackend: type,
writer: type = std.io.Writer(*Self, Error, write),

pub fn write(self: *Self, bytes: []const u8) Error!usize {
    return try self.UIBackend.write(bytes);
}

pub fn print_at_location(self: *const Self, location: Location, text: []const u8) !void {
    // move_cursor(location.x, location.y);
    try self.UIBackend.move_cursor(location);
    _ = text;
    // _ = try self.UIBackend.write(text);
}

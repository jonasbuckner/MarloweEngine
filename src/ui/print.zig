const std = @import("std");

const screen = @import("screen.zig");
const Location = screen.Location;
const Direction = screen.Direction;

// Generic printer that works with any frontend type
pub fn Printer(comptime Frontend: type) type {
    return struct {
        // Simply store a pointer to the frontend
        frontend: *const Frontend,

        const Self = @This();

        // Create a new printer with the given frontend instance
        pub fn init(frontend: *const Frontend) Self {
            return .{
                .frontend = frontend,
            };
        }

        pub fn setup(self: Self) !void {
            try self.frontend.setup();
        }

        pub fn teardown(self: Self) !void {
            try self.frontend.teardown();
        }

        // Forward write calls to the frontend
        pub fn write(self: Self, text: []const u8) !usize {
            return self.frontend.write(text);
        }

        pub fn writeByte(self: Self, byte: u8) !usize {
            return self.frontend.writeByte(byte);
        }

        // Forward print_at_location calls to the frontend
        pub fn print_at_location(self: Self, location: Location, text: []const u8) !usize {
            try self.frontend.move_cursor(location);
            return self.frontend.write(text);
        }

        pub fn print(self: Self, comptime fmt: []const u8, args: anytype) anyerror!void {
            return self.frontend.print(fmt, args);
        }

        pub fn move_cursor(self: Self, location: Location) !void {
            try self.frontend.move_cursor(location);
        }

        pub fn save_cursor(self: Self) !void {
            try self.frontend.save_cursor();
        }

        pub fn restore_cursor(self: Self) !void {
            try self.frontend.restore_cursor();
        }

        pub fn move_cursor_direction(self: Self, comptime direction: Direction, count: u16) !void {
            try self.frontend.move_cursor_direction(direction, count);
        }

        pub fn move_cursor_up(self: Self, count: usize) !void {
            try self.frontend.move_cursor_direction(Direction.up, count);
        }

        pub fn move_cursor_down(self: Self, count: usize) !void {
            try self.frontend.move_cursor_direction(Direction.down, count);
        }

        pub fn move_cursor_left(self: Self, count: usize) !void {
            try self.frontend.move_cursor_direction(Direction.left, count);
        }

        pub fn move_cursor_right(self: Self, count: usize) !void {
            try self.frontend.move_cursor_direction(Direction.right, count);
        }

        pub fn move_cursor_newline(self: Self) !void {
            try self.frontend.move_cursor_newline();
        }

        pub fn clear_to_end_of_current_line(self: Self) !void {
            _ = try self.save_cursor();
            _ = try self.write(" " ** 50);
            _ = try self.restore_cursor();
        }

        pub fn readByte(self: Self) anyerror!u8 {
            return self.frontend.readByte();
        }

        pub fn read(self: Self, buffer: []u8) anyerror!usize {
            return self.frontend.read(buffer);
        }

        pub fn format(
            self: @This(),
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = self;
            _ = fmt;
            _ = options;
            _ = writer;
        }
    };
}

// Helper function to create a printer with type inference
pub fn create_printer(frontend: anytype) Printer(@TypeOf(frontend.*)) {
    return Printer(@TypeOf(frontend.*)).init(frontend);
}

const std = @import("std");
const Location = @import("location.zig").Location;

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

        // Forward print_at_location calls to the frontend
        pub fn print_at_location(self: Self, location: Location, text: []const u8) !usize {
            try self.frontend.move_cursor(location);
            return self.frontend.write(text);
        }
    };
}

// Helper function to create a printer with type inference
pub fn create_printer(frontend: anytype) Printer(@TypeOf(frontend.*)) {
    return Printer(@TypeOf(frontend.*)).init(frontend);
}

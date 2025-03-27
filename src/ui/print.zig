const std = @import("std");

const screen = @import("screen.zig");
const Location = screen.Location;
const Direction = screen.Direction;
const Dimensions = screen.Dimensions;

pub const PrinterFace = @import("printer_face.zig");

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

        pub fn Screen(self: Self) Dimensions {
            return self.frontend.Screen();
        }

        pub fn setup(self: Self) !void {
            try self.frontend.setup();
        }

        pub fn teardown(self: Self) !void {
            try self.frontend.teardown();
        }

        pub fn TabStop(_: Self) usize {
            return Frontend.TabStop();
        }

        // Forward write calls to the frontend
        pub fn write(self: Self, text: []const u8) !usize {
            return self.frontend.write(text);
        }

        pub fn writeErr(self: Self, text: []const u8) !usize {
            return self.frontend.writeErr(text);
        }

        pub fn writeByte(self: Self, byte: u8) !usize {
            return self.frontend.writeByte(byte);
        }

        // Forward printAtLocation calls to the frontend
        pub fn printAtLocation(self: Self, location: Location, text: []const u8) !usize {
            try self.frontend.moveCursor(location);
            return self.frontend.write(text);
        }

        pub fn print(self: Self, comptime fmt: []const u8, args: anytype) anyerror!void {
            return self.frontend.print(fmt, args);
        }

        pub fn moveCursor(self: Self, location: Location) !void {
            try self.frontend.moveCursor(location);
        }

        pub fn saveCursor(self: Self) !void {
            try self.frontend.saveCursor();
        }

        pub fn restoreCursor(self: Self) !void {
            try self.frontend.restoreCursor();
        }

        pub fn cursorPosition(self: Self) !Location {
            return self.frontend.cursorPosition();
        }

        pub fn moveCursorDirection(self: Self, comptime direction: Direction, count: usize) !void {
            try self.frontend.moveCursorDirection(direction, count);
        }

        pub fn moveCursorUp(self: Self, count: usize) !void {
            try self.frontend.moveCursorDirection(Direction.up, count);
        }

        pub fn moveCursorDown(self: Self, count: usize) !void {
            try self.frontend.moveCursorDirection(Direction.down, count);
        }

        pub fn moveCursorLeft(self: Self, count: usize) !void {
            try self.frontend.moveCursorDirection(Direction.left, count);
        }

        pub fn moveCursorRight(self: Self, count: usize) !void {
            try self.frontend.moveCursorDirection(Direction.right, count);
        }

        pub fn moveCursorNewline(self: Self) !void {
            try self.frontend.moveCursorNewline();
        }

        pub fn readByte(self: Self) anyerror!u8 {
            return self.frontend.readByte();
        }

        pub fn read(self: Self, buffer: []u8) anyerror!usize {
            return self.frontend.read(buffer);
        }

        pub fn eraseCharacterUnderCursor(self: Self) !void {
            return self.frontend.eraseCharacterUnderCursor();
        }

        pub fn eraseToEndOfCurrentLine(self: Self) !usize {
            return self.frontend.eraseToEndOfCurrentLine();
        }

        pub fn eraseToStartOfCurrentLine(self: Self) !usize {
            return self.frontend.eraseToStartOfCurrentLine();
        }

        pub fn eraseEntireCurrentLine(self: Self) !usize {
            return self.frontend.eraseEntireCurrentLine();
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

        // Debug Helper Functions
        pub fn DEBUG_displayReadBuffer(self: Self, buffer: []u8, length: usize) !void {
            try self.saveCursor();
            try self.moveCursor(.{ .x = 30, .y = 2 });

            _ = try self.write(" " ** 50);
            try self.moveCursor(.{ .x = 30, .y = 2 });
            for (buffer[0..length]) |c| {
                if (c < 0x21) {
                    try self.print("0x{x} ", .{c});
                } else {
                    try self.print("{c}    ", .{c});
                }
            }
            try self.moveCursor(.{ .x = 30, .y = 3 });
            _ = try self.write(" " ** 50);
            try self.moveCursor(.{ .x = 30, .y = 3 });
            for (buffer[0..length]) |c| {
                try self.print("0x{x} ", .{c});
            }
            try self.restoreCursor();
        }
    };
}

// Helper function to create a printer with type inference
pub fn createPrinter(frontend: anytype) Printer(@TypeOf(frontend.*)) {
    return Printer(@TypeOf(frontend.*)).init(frontend);
}

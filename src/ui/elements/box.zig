const std = @import("std");
const Location = @import("../screen.zig").Location;
const Dimensions = @import("../screen.zig").Dimensions;
const PrinterFace = @import("../printer_face.zig").PrinterFace;

const HorizontalChar: u16 = 0x2550;
const TopHorizontal: u16 = 0x2566;
const VerticalChar: u16 = 0x2551;
const TopLeftChar: u16 = 0x2554;
const TopRightChar: u16 = 0x2557;
const BottomLeftChar: u16 = 0x255A;
const BottomRightChar: u16 = 0x255D;
const BrailleEight: u16 = 0x28FF;
const BrailleBotFour: u16 = 0x28E4;
const BrailleTopFour: u16 = 0x281B;

pub const Box = struct {
    position_on_display: Location,
    rect: struct {
        upper_left: Location,
        dimensions: Dimensions,
    },

    printer: *const PrinterFace,
    allocator: std.mem.Allocator,

    pub fn init(position: Location, dimensions: Dimensions, allocator: std.mem.Allocator, printer: *const PrinterFace) Box {
        var real_position = position;
        var real_dimensions = dimensions;
        if (position.x <= 0 or position.y <= 0) {
            std.debug.print("Rows and Columns are 1-based, defaulting to 1", .{});
            real_position.x = @max(1, position.x);
            real_position.y = @max(1, position.y);
        }

        const window_dimensions = printer.Screen();
        const right = position.x + dimensions.width + 2;
        const bottom = position.y + dimensions.height + 2;

        if (right > window_dimensions.width or bottom > window_dimensions.height) {
            const new_right = window_dimensions.width - position.x - 1;
            const new_bottom = window_dimensions.height - position.y - 1;

            std.debug.print("Requested rectangle overflows screen, defaulting to {d}:{d}", .{ new_right, new_bottom });

            real_dimensions.width = @min(new_right, right);
            real_dimensions.height = @min(new_bottom, bottom);
        }

        const result = Box{
            .position_on_display = real_position,
            .rect = .{
                .upper_left = real_position,
                .dimensions = real_dimensions,
            },
            .printer = printer,
            .allocator = allocator,
        };
        // DEBUG_printDimensions(@constCast(&result), window_dimensions, real_position, real_dimensions, right, bottom);
        return result;
    }

    pub fn render(self: *Box) !void {
        try self.printer.saveCursor();

        try self.printer.moveCursor(self.rect.upper_left);

        _ = try self.printer.print("{u}", .{TopLeftChar});
        for (0..self.rect.dimensions.width) |_| {
            _ = try self.printer.print("{u}", .{HorizontalChar});
        }
        _ = try self.printer.print("{u}", .{TopRightChar});

        try self.printer.moveCursor(self.rect.upper_left);
        try self.printer.moveCursorDown(1);

        for (0..self.rect.dimensions.height) |_| {
            _ = try self.printer.print("{u}", .{VerticalChar});
            try self.printer.moveCursorRight(self.rect.dimensions.width);
            _ = try self.printer.print("{u}", .{VerticalChar});
            try self.printer.moveCursorLeft(self.rect.dimensions.width + 2); // +2 for 2 printed chars
            try self.printer.moveCursorDown(1);
        }

        _ = try self.printer.print("{u}", .{BottomLeftChar});
        for (0..self.rect.dimensions.width) |_| {
            _ = try self.printer.print("{u}", .{HorizontalChar});
        }
        _ = try self.printer.print("{u}", .{BottomRightChar});
        try self.printer.moveCursor(self.rect.upper_left);
        try self.printer.moveCursorDown(1);

        try self.printer.restoreCursor();
    }

    pub fn DEBUG_printDimensions(self: *Box, window_dimensions: Dimensions, real_position: Location, real_dimensions: Dimensions, right: usize, bottom: usize) void {
        self.printer.saveCursor() catch {};
        self.printer.moveCursor(.{ .x = window_dimensions.width - 20, .y = window_dimensions.height - 5 }) catch {};
        self.printer.print("r:b = {d}:{d}", .{ right, bottom }) catch {};
        self.printer.moveCursor(.{ .x = window_dimensions.width - 20, .y = window_dimensions.height - 4 }) catch {};
        self.printer.print("w:h = {d}:{d}", .{ window_dimensions.width, window_dimensions.height }) catch {};
        self.printer.moveCursor(.{ .x = window_dimensions.width - 20, .y = window_dimensions.height - 3 }) catch {};
        self.printer.print("w:h = {d}:{d}", .{ real_dimensions.width, real_dimensions.height }) catch {};
        self.printer.moveCursor(.{ .x = window_dimensions.width - 20, .y = window_dimensions.height - 2 }) catch {};
        self.printer.print("x:y = {d}:{d}", .{ real_position.x, real_position.y }) catch {};
        self.printer.moveCursor(.{ .x = real_dimensions.width, .y = real_dimensions.height }) catch {};
        self.printer.print("*", .{}) catch {};
        self.printer.moveCursor(.{ .x = real_position.x, .y = real_position.y }) catch {};
        self.printer.print("*", .{}) catch {};
        self.printer.restoreCursor() catch {};
    }
};

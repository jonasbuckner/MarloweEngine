// In printer_face.zig
const std = @import("std");
const Location = @import("screen.zig").Location;
const Direction = @import("screen.zig").Direction;
const Dimensions = @import("screen.zig").Dimensions;

pub const PrinterFace = struct {
    // Function pointers for the interface
    setupFn: *const fn (ctx: *const anyopaque) anyerror!void,
    teardownFn: *const fn (ctx: *const anyopaque) anyerror!void,
    writeFn: *const fn (ctx: *const anyopaque, text: []const u8) anyerror!usize,
    writeErrFn: *const fn (ctx: *const anyopaque, text: []const u8) anyerror!usize,
    writeByteFn: *const fn (ctx: *const anyopaque, byte: u8) anyerror!usize,
    moveCursorFn: *const fn (ctx: *const anyopaque, location: Location) anyerror!void,
    saveCursorFn: *const fn (ctx: *const anyopaque) anyerror!void,
    restoreCursorFn: *const fn (ctx: *const anyopaque) anyerror!void,
    cursorPositionFn: *const fn (ctx: *const anyopaque) anyerror!Location,

    // Separate functions for each direction instead of a generic one with comptime
    moveCursorUpFn: *const fn (ctx: *const anyopaque, count: usize) anyerror!void,
    moveCursorDownFn: *const fn (ctx: *const anyopaque, count: usize) anyerror!void,
    moveCursorLeftFn: *const fn (ctx: *const anyopaque, count: usize) anyerror!void,
    moveCursorRightFn: *const fn (ctx: *const anyopaque, count: usize) anyerror!void,

    eraseToEndOfCurrentLineFn: *const fn (ctx: *const anyopaque) anyerror!usize,
    readByteFn: *const fn (ctx: *const anyopaque) anyerror!u8,
    readFn: *const fn (ctx: *const anyopaque, buffer: []u8) anyerror!usize,
    tabStopFn: *const fn (ctx: *const anyopaque) usize, // TabStop now takes ctx parameter

    ScreenFn: *const fn (ctx: *const anyopaque) Dimensions,
    // Instance pointer (similar to 'this' or 'self')
    ctx: *const anyopaque,

    // Wrapper methods that call through function pointers
    pub fn setup(self: *const PrinterFace) !void {
        return self.setupFn(self.ctx);
    }

    pub fn teardown(self: *const PrinterFace) !void {
        return self.teardownFn(self.ctx);
    }

    pub fn write(self: *const PrinterFace, text: []const u8) !usize {
        return self.writeFn(self.ctx, text);
    }

    pub fn writeErr(self: *const PrinterFace, text: []const u8) !usize {
        return self.writeErrFn(self.ctx, text);
    }

    pub fn writeByte(self: *const PrinterFace, byte: u8) !usize {
        return self.writeByteFn(self.ctx, byte);
    }

    pub fn moveCursor(self: *const PrinterFace, location: Location) !void {
        return self.moveCursorFn(self.ctx, location);
    }

    pub fn saveCursor(self: *const PrinterFace) !void {
        return self.saveCursorFn(self.ctx);
    }

    pub fn restoreCursor(self: *const PrinterFace) !void {
        return self.restoreCursorFn(self.ctx);
    }

    pub fn cursorPosition(self: *const PrinterFace) !Location {
        return self.cursorPositionFn(self.ctx);
    }

    // Handle the fmt as comptime parameter
    pub fn print(self: *const PrinterFace, comptime fmt: []const u8, args: anytype) !void {
        // Use a writer adapter to format the string first
        var buf: [1024]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        try std.fmt.format(fbs.writer(), fmt, args);
        _ = try self.write(fbs.getWritten());
    }

    pub fn eraseToEndOfCurrentLine(self: *const PrinterFace) !usize {
        return self.eraseToEndOfCurrentLineFn(self.ctx);
    }

    pub fn readByte(self: *const PrinterFace) !u8 {
        return self.readByteFn(self.ctx);
    }

    pub fn read(self: *const PrinterFace, buffer: []u8) !usize {
        return self.readFn(self.ctx, buffer);
    }

    pub fn TabStop(self: *const PrinterFace) usize {
        return self.tabStopFn(self.ctx);
    }

    // Direction-specific movement functions instead of generic one
    pub fn moveCursorUp(self: *const PrinterFace, count: usize) !void {
        return self.moveCursorUpFn(self.ctx, count);
    }

    pub fn moveCursorDown(self: *const PrinterFace, count: usize) !void {
        return self.moveCursorDownFn(self.ctx, count);
    }

    pub fn moveCursorLeft(self: *const PrinterFace, count: usize) !void {
        return self.moveCursorLeftFn(self.ctx, count);
    }

    pub fn moveCursorRight(self: *const PrinterFace, count: usize) !void {
        return self.moveCursorRightFn(self.ctx, count);
    }

    // Removed generic moveCursorDirection which had comptime parameter

    // Convenience methods built on the core interface
    pub fn printAtLocation(self: *const PrinterFace, location: Location, text: []const u8) !usize {
        try self.moveCursor(location);
        return self.write(text);
    }

    pub fn Screen(self: *const PrinterFace) Dimensions {
        return self.ScreenFn(self.ctx);
    }
};

// Helper function to create a PrinterFace from a Printer
pub fn createPrinterFace(printer: anytype) PrinterFace {
    const PtrType = @TypeOf(printer);

    // Use structs to capture the type
    const Impls = struct {
        // Static helper functions, updated to use const context
        pub fn setupImpl(ctx: *const anyopaque) anyerror!void {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.setup();
        }

        pub fn teardownImpl(ctx: *const anyopaque) anyerror!void {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.teardown();
        }

        pub fn writeImpl(ctx: *const anyopaque, text: []const u8) anyerror!usize {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.write(text);
        }

        pub fn writeErrImpl(ctx: *const anyopaque, text: []const u8) anyerror!usize {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.writeErr(text);
        }

        pub fn writeByteImpl(ctx: *const anyopaque, byte: u8) anyerror!usize {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.writeByte(byte);
        }

        pub fn moveCursorImpl(ctx: *const anyopaque, location: Location) anyerror!void {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.moveCursor(location);
        }

        pub fn saveCursorImpl(ctx: *const anyopaque) anyerror!void {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.saveCursor();
        }

        pub fn restoreCursorImpl(ctx: *const anyopaque) anyerror!void {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.restoreCursor();
        }

        pub fn cursorPositionImpl(ctx: *const anyopaque) anyerror!Location {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.cursorPosition();
        }

        // Direction-specific movement functions
        pub fn moveCursorUpImpl(ctx: *const anyopaque, count: usize) anyerror!void {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.moveCursorDirection(Direction.up, count);
        }

        pub fn moveCursorDownImpl(ctx: *const anyopaque, count: usize) anyerror!void {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.moveCursorDirection(Direction.down, count);
        }

        pub fn moveCursorLeftImpl(ctx: *const anyopaque, count: usize) anyerror!void {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.moveCursorDirection(Direction.left, count);
        }

        pub fn moveCursorRightImpl(ctx: *const anyopaque, count: usize) anyerror!void {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.moveCursorDirection(Direction.right, count);
        }

        pub fn eraseToEndOfCurrentLineImpl(ctx: *const anyopaque) anyerror!usize {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.eraseToEndOfCurrentLine();
        }

        pub fn readByteImpl(ctx: *const anyopaque) anyerror!u8 {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.readByte();
        }

        pub fn readImpl(ctx: *const anyopaque, buffer: []u8) anyerror!usize {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.read(buffer);
        }

        pub fn tabStopImpl(ctx: *const anyopaque) usize {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.TabStop();
        }

        pub fn ScreenImpl(ctx: *const anyopaque) Dimensions {
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.Screen();
        }
    };

    return PrinterFace{
        .setupFn = Impls.setupImpl,
        .teardownFn = Impls.teardownImpl,
        .writeFn = Impls.writeImpl,
        .writeErrFn = Impls.writeErrImpl,
        .writeByteFn = Impls.writeByteImpl,
        .moveCursorFn = Impls.moveCursorImpl,
        .saveCursorFn = Impls.saveCursorImpl,
        .restoreCursorFn = Impls.restoreCursorImpl,
        .cursorPositionFn = Impls.cursorPositionImpl,
        .moveCursorUpFn = Impls.moveCursorUpImpl,
        .moveCursorDownFn = Impls.moveCursorDownImpl,
        .moveCursorLeftFn = Impls.moveCursorLeftImpl,
        .moveCursorRightFn = Impls.moveCursorRightImpl,
        .eraseToEndOfCurrentLineFn = Impls.eraseToEndOfCurrentLineImpl,
        .readByteFn = Impls.readByteImpl,
        .readFn = Impls.readImpl,
        .tabStopFn = Impls.tabStopImpl,
        .ScreenFn = Impls.ScreenImpl,
        .ctx = @ptrCast(@alignCast(printer)),
    };
}

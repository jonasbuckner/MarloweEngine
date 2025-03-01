const std = @import("std");
const Location = @import("location.zig").Location;

const Self = @This();
const Error = error{};

pub const Printer = struct {
    UIBackend: type,

    backend_instance: *const anyopaque,

    // Methods that convert the opaque pointer to the correct backend type
    move_cursor_fn: *const fn (backend: *const anyopaque, location: Location) anyerror!void,
    write_fn: *const fn (backend: *const anyopaque, bytes: []const u8) anyerror!usize,

    pub fn init(comptime Backend: type, instance: *const anyopaque) Printer {
        return .{
            .UIBackend = Backend,
            .backend_instance = instance,
            .move_cursor_fn = struct {
                fn moveCursor(backend: *const anyopaque, location: Location) anyerror!void {
                    return @as(*const Backend, @ptrCast(@alignCast(backend))).*.move_cursor(location);
                }
            }.moveCursor,
            .write_fn = struct {
                fn writeBytes(backend: *const anyopaque, bytes: []const u8) anyerror!usize {
                    return @as(*const Backend, @ptrCast(@alignCast(backend))).*.write(bytes);
                }
            }.writeBytes,
        };
    }

    pub fn write(self: *const Printer, text: []const u8) !usize {
        return self.write_fn(self.backend_instance, text);
    }

    pub fn print_at_location(self: *const Printer, location: Location, text: []const u8) !usize {
        try self.move_cursor_fn(self.backend_instance, location);
        return self.write(text);
    }
};

pub fn create_printer(instance: anytype) Printer {
    const T = @TypeOf(instance);
    return Printer.init(T, instance);
}

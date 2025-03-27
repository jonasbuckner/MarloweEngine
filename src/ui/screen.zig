const std = @import("std");
pub const Direction = enum {
    up,
    down,
    left,
    right,
};

pub const Location = struct {
    x: usize,
    y: usize,

    pub fn empty() Location {
        return .{ .x = 0, .y = 0 };
    }
};

pub const Dimensions = struct {
    width: usize,
    height: usize,

    pub fn offset(self: *const Dimensions, comptime offsets: Offset) Dimensions {
        if ((std.math.maxInt(usize) << 2 - 1) < self.width or (std.math.maxInt(usize) << 2 - 1) < self.height) {
            @compileError("Cannot offset a if width or height is greater than half a maximum usize");
        }

        var off = offsets;
        if (offsets.x < 0 and @abs(offsets.x) > self.width) {
            off.x = @intCast(self.width); // clamp
            off.x *= -1;
        }
        if (offsets.y < 0 and @abs(offsets.y) > self.height) {
            off.y = @intCast(self.height);
            off.y *= -1;
        }

        const new_width = @addWithOverflow(@as(isize, @intCast(self.width)), off.x);
        const new_height = @addWithOverflow(@as(isize, @intCast(self.height)), off.y);

        if (new_width[1] == 1) {
            std.debug.print("Offset cannot cause Dimensions to overflow: negative x values should be < width and positive x values should be < MAX_INT of a usize over 2", .{});
        }
        if (new_height[1] == 1) {
            std.debug.print("Offset cannot cause Dimensions to overflow: negative y values should be < height and positive y values should be < MAX_INT of a usize over 2", .{});
        }

        const result: Dimensions = .{
            .width = @as(usize, @intCast(new_width[0])),
            .height = @as(usize, @intCast(new_height[0])),
        };
        return result;
    }
};

pub const Offset = struct {
    x: isize,
    y: isize,
};

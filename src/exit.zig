const std = @import("std");
const CommandProcessor = @import("command_processor.zig").CommandProcessor;
const Room = @import("room.zig").Room;

pub const Exit = struct {
    x: i8,
    y: i8,
    z: i8,
    hidden: bool = false,
    direction: CommandProcessor.commands,
    room: *const Room,

    const Self = @This();

    pub fn init(direction: CommandProcessor.commands, x: i8, y: i8, z: i8, hidden: ?bool) Exit {
        return Exit{
            .direction = direction,
            .x = x,
            .y = y,
            .z = z,
            .hidden = hidden orelse false,
            .room = undefined,
        };
    }

    pub fn empty() Exit {
        return Exit{
            .x = 0,
            .y = 0,
            .z = 0,
            .hidden = false,
        };
    }
};

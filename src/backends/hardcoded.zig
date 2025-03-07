const std = @import("std");
const CommandProcessor = @import("../command_processor.zig").CommandProcessor;
const Item = @import("../item.zig").Item;
const Exit = @import("../exit.zig").Exit;
const Room = @import("../room.zig").Room;

const ArrayList = std.ArrayList;

pub const Data = struct {
    allocator: *const std.mem.Allocator,
    rooms: ArrayList(Room),
    rooms_capacity: u16,

    pub fn init(allocator: *const std.mem.Allocator, capacity: ?u16) Data {
        return .{
            .allocator = allocator,
            .rooms = ArrayList(Room).init(allocator.*),
            .rooms_capacity = capacity orelse 256,
        };
    }

    pub fn getRooms(self: *Data) !ArrayList(Room) {
        _ = try self.rooms.ensureTotalCapacityPrecise(self.rooms_capacity);

        const south_room = Room{
            .title = "Die",
            .description = "You die.",
            .items = undefined,
            .exits = undefined,
        };
        const north_room = Room{
            .title = "Born",
            .description = "You are born.",
            .items = .{Item{ .name = "Raygun", .description = "Pew pew" }},
            .exits = undefined,
        };

        try self.rooms.append(north_room);
        try self.rooms.append(south_room);

        var North = Exit.init(CommandProcessor.commands.north, 0, 1, 0, false);
        North.room = &self.rooms.items[0];
        var South = Exit.init(CommandProcessor.commands.south, 0, -1, 0, false);
        South.room = &self.rooms.items[1];

        self.rooms.items[0].exits = .{South};
        self.rooms.items[1].exits = .{North};

        return self.rooms;
    }

    pub fn deleteRooms(self: *Data) !void {
        self.rooms.deinit();
    }
};

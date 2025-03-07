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

        // TODO: Maybe we rid ourselves of circular dependencies
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
        const west_room = Room{
            .title = "Married",
            .description = "You got Married.",
            .items = undefined,
            .exits = undefined,
        };

        try self.rooms.append(north_room);
        try self.rooms.append(south_room);
        try self.rooms.append(west_room);

        var North = Exit.init(CommandProcessor.commands.north, 0, 1, 0, false);
        North.room = &self.rooms.items[0];
        var South = Exit.init(CommandProcessor.commands.south, 0, -1, 0, false);
        South.room = &self.rooms.items[1];
        var West = Exit.init(CommandProcessor.commands.west, 0, 1, 0, false);
        West.room = &self.rooms.items[2];
        var East = Exit.init(CommandProcessor.commands.east, 0, 1, 0, false);
        East.room = &self.rooms.items[0];

        self.rooms.items[0].exits = .{ South, West };
        self.rooms.items[1].exits = .{ North, Exit.empty() };
        self.rooms.items[2].exits = .{ East, Exit.empty() };

        return self.rooms;
    }

    pub fn deleteRooms(self: *Data) !void {
        self.rooms.deinit();
    }
};

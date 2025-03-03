const std = @import("std");
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

        const North = Exit.init("north", 1, 0, 0, false);
        const south_room = Room{
            .title = "Die",
            .description = "You die.",
            .items = undefined,
            .exits = .{North},
        };
        const South = Exit.init("south", -1, 0, 0, false);
        const room = Room{
            .title = "Born",
            .description = "You are born.",
            .items = .{Item{ .name = "Raygun", .description = "Pew pew" }},
            .exits = .{South},
        };

        // const self.rooms: []Room = try allocator.alloc(Room, 2);
        try self.rooms.append(room);
        try self.rooms.append(south_room);

        return self.rooms;
    }

    pub fn deleteRooms(self: *Data) !void {
        self.rooms.deinit();
    }
};

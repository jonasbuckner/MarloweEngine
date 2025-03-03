const std = @import("std");
const Item = @import("../item.zig").Item;
const Exit = @import("../exit.zig").Exit;
const Room = @import("../room.zig").Room;

const ArrayList = std.ArrayList;

pub const Data = struct {
    var rooms: ArrayList(Room) = undefined;

    pub fn getRooms(_: *const Data, allocator: std.mem.Allocator) !ArrayList(Room) {
        rooms = ArrayList(Room).init(allocator);

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

        // const rooms: []Room = try allocator.alloc(Room, 2);
        try rooms.append(room);
        try rooms.append(south_room);

        return rooms;
    }

    pub fn deleteRooms(_: *const Data, allocator: std.mem.Allocator) !void {
        allocator.free(rooms);
    }
};

pub var instance = Data{};

const Item = @import("item.zig").Item;
const Exit = @import("exit.zig").Exit;

pub const Room = struct {
    title: []const u8 = "UNDEFINED ROOM TITLE - This is a bug.",
    description: []const u8 = "UNDEFINED ROOM DESCRIPTION - This is a bug.",
    items: [1]Item,
    exits: [1]Exit,

    pub fn init(title: []const u8, description: []const u8) Room {
        return Room{
            .title = title,
            .description = description,
            .items = .{Item{ .name = "Raygun", .description = "Pew pew" }},
            .exits = undefined,
        };
    }
};

// zig fmt: off
const std    = @import("std");
const sqlite = @import("sqlite");
const tui    = @import("ui/tui.zig");
const print  = @import("ui/print.zig");
// zig fmt: on

const Item = @import("item.zig").Item;
const Exit = @import("exit.zig").Exit;
const Room = @import("room.zig").Room;

const posix = std.posix;
const printer = print.create_printer(&tui.instance);
const master_writer = std.io.getStdOut().writer(); // TODO: remove when possible

const Character = struct {
    inventory: [1]Item,
    description: []u8,
    location: Room,
};

const Map = struct {
    title: []const u8,
    rooms: []Room,
};

const World = struct {
    map: Map,
};

fn print_current_room(player: Character) !void {
    _ = try printer.write(player.location.title);

    _ = try printer.print_at_location(.{ .x = 2, .y = 6 }, player.location.description);
    _ = try tui.instance.move_cursor(.{ .x = 2, .y = 8 });
    _ = try master_writer.print("Exits to the: {s}{s}{s}", .{ tui.Bold(), player.location.exits[0].name, tui.Reset() });
}

fn start_game(player: Character, world: World) !void {
    _ = try printer.print_at_location(.{ .x = 0, .y = 0 }, "MARLOWE");
    _ = try printer.print_at_location(.{ .x = 2, .y = 2 }, world.map.title);
    _ = try tui.instance.move_cursor(.{ .x = 2, .y = 4 });
    _ = try print_current_room(player);
    _ = try printer.print_at_location(.{ .x = 2, .y = 9 }, "# ");
}

pub fn main() !void {
    //std.c.setlocale(std.c.LC.CTYPE, "");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try printer.setup();
    defer printer.teardown() catch {};
    // errdefer printer.teardown();

    _ = try tui.instance.clear_screen();
    _ = try tui.instance.move_cursor_home();

    // const db = try sqlite.Db.init(.{
    //     .mode = sqlite.Db.Mode{ .File = "world.sqlite" },
    //     .open_flags = .{
    //         .write = true,
    //         .create = true,
    //     },
    //     .threading_mode = .Multithread,
    // });

    // const room_statement = db.prepare("SELECT * FROM room;");
    // defer room_statement.deinit();

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

    const rooms: []Room = try allocator.alloc(Room, 2);
    rooms[0] = room;
    rooms[1] = south_room;

    const overworld = Map{
        .title = "Overworld",
        .rooms = rooms,
    };
    const main_world = World{ .map = overworld };

    const player = Character{
        .inventory = [_]Item{
            Item{ .name = "Raygun", .description = "Raygun pew pew" },
        },
        .description = "",
        .location = room,
    };

    while (true) {
        try start_game(player, main_world);
        break;
    }
}

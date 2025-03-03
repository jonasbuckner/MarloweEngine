// zig fmt: off
const std     = @import("std");
const sqlite  = @import("sqlite");
const tui     = @import("ui/tui.zig");
const print   = @import("ui/print.zig");
const builder = @import("backends/backend.zig");
const data    = @import("backends/hardcoded.zig");
// zig fmt: on

const Item = @import("item.zig").Item;
const Exit = @import("exit.zig").Exit;
const Room = @import("room.zig").Room;

const posix = std.posix;
const printer = print.create_printer(&tui.instance);
const backend = builder.create_data_layer(&data.instance);
const master_writer = std.io.getStdOut().writer(); // TODO: remove when possible

const Character = struct {
    inventory: [1]Item,
    description: []u8,
    location: *Room,
};

const Map = struct {
    title: []const u8,
    rooms: std.ArrayList(Room),
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

    try printer.setup();
    defer printer.teardown() catch {};
    // errdefer printer.teardown();

    _ = try tui.instance.clear_screen();
    _ = try tui.instance.move_cursor_home();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const overworld = Map{
        .title = "Overworld",
        .rooms = try backend.backend.getRooms(allocator),
    };
    const main_world = World{ .map = overworld };

    const player = Character{
        .inventory = [_]Item{
            Item{ .name = "Raygun", .description = "Raygun pew pew" },
        },
        .description = "",
        .location = &overworld.rooms.items[0],
    };

    while (true) {
        try start_game(player, main_world);
        break;
    }
}

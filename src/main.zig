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
    _ = try printer.move_cursor(.{ .x = 2, .y = 8 });
    _ = try printer.print("Exits to the: {s}{s}{s}", .{ tui.Bold(), player.location.exits[0].name, tui.Reset() });
}

fn start_game(player: Character, world: World) !void {
    _ = try printer.print_at_location(.{ .x = 0, .y = 0 }, "MARLOWE");
    _ = try printer.print_at_location(.{ .x = 2, .y = 2 }, world.map.title);
    _ = try printer.move_cursor(.{ .x = 2, .y = 4 });
    _ = try print_current_room(player);
    _ = try printer.print_at_location(.{ .x = 2, .y = 9 }, "# ");
}

pub fn main() !void {
    //std.c.setlocale(std.c.LC.CTYPE, "");

    try printer.setup();
    defer printer.teardown() catch {};
    // errdefer printer.teardown();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var data_instance = data.Data.init(&allocator, 2);
    const backend = builder.create_data_layer(&data_instance);

    const overworld = Map{
        .title = "Overworld",
        .rooms = try backend.backend.getRooms(),
    };
    defer backend.backend.deleteRooms() catch {};
    const main_world = World{ .map = overworld };

    var player = Character{
        .inventory = [_]Item{
            Item{ .name = "Raygun", .description = "Raygun pew pew" },
        },
        .description = "",
        .location = &overworld.rooms.items[0],
    };

    const commands = enum { quit, north, south, nomatch };

    main_loop: while (true) {
        try start_game(player, main_world);

        var command_buffer = std.mem.zeroes([10]u8);
        var processed_buffer: []const u8 = undefined;

        var i: u8 = 0;
        while (command_buffer[i] != '\n') : (i += 1) {
            // _ = try printer.print("{d}", .{i});
            const x = try std.io.getStdIn().reader().readByte();
            command_buffer[i] = x;
            // _ = try printer.print_at_location(.{ .x = 30, .y = 9 }, @as([]const u8, &command_buffer));
            // _ = try printer.move_cursor(.{ .x = i + 5, .y = 9 });

            if (command_buffer[i] == '\x1b') {
                break :main_loop;
            } else if (command_buffer[i] == '\n' or command_buffer[i] == '\r') {
                // _ = try printer.print_at_location(.{ .x = 30, .y = 8 }, "newline");
                // _ = try printer.move_cursor(.{ .x = i + 5, .y = 9 });
                command_buffer[i] = 0;
                processed_buffer = command_buffer[0..i];
                // _ = try printer.print_at_location(.{ .x = 30, .y = 7 }, processed_buffer);
                break;
            } else {
                _ = try printer.writeByte(command_buffer[i]);
                // _ = try printer.print("{d}", .{i});
            }
        }

        // _ = try printer.print_at_location(.{ .x = 30, .y = 7 }, processed_buffer);
        const read_command = std.meta.stringToEnum(commands, processed_buffer) orelse .nomatch;
        // _ = try printer.move_cursor(.{ .x = 50, .y = 10 });
        // _ = try printer.print("{d}", .{@intFromEnum(read_command)});
        // _ = try printer.move_cursor(.{ .x = 4, .y = 11 });

        switch (read_command) {
            .quit => {
                break;
            },
            .north => {
                player.location = &overworld.rooms.items[0];
            },
            .south => {
                player.location = &overworld.rooms.items[1];
            },
            else => {
                _ = try printer.write("Command not found");
            },
        }
        std.posix.nanosleep(0, 16000);
    }
}

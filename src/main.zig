// zig fmt: off
const std     = @import("std");
const sqlite  = @import("sqlite");
const tui     = @import("ui/tui.zig");
const print   = @import("ui/print.zig");
const Screen  = @import("ui/screen.zig");
const builder = @import("backends/backend.zig");
const data    = @import("backends/hardcoded.zig");
const CommandProcessor = @import("command_processor.zig").CommandProcessor;
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
    try printer.clear_to_end_of_current_line();
    var last_len = try printer.write(player.location.*.title);

    try printer.move_cursor_down(2);
    try printer.move_cursor_left(last_len);
    try printer.clear_to_end_of_current_line();
    last_len = try printer.write(player.location.*.description);

    try printer.move_cursor_down(2);
    try printer.move_cursor_left(last_len);
    try printer.clear_to_end_of_current_line();
    _ = try printer.write("Exits to the: ");

    for (player.location.exits) |e| {
        _ = try printer.write(tui.Bold());
        _ = try printer.write(@tagName(e.direction));
        _ = try printer.write(tui.Reset());
        _ = try printer.writeByte(' ');
    }
}

fn start_game(player: Character, world: World) !void {
    _ = try printer.print_at_location(.{ .x = 1, .y = 1 }, "MARLOWE");
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

    const commands = CommandProcessor.commands;
    const BUFFER_LENGTH = 255;

    main_loop: while (true) {
        try start_game(player, main_world);
        var command_buffer = std.mem.zeroes([BUFFER_LENGTH]u8);
        var processed_buffer: []const u8 = undefined;

        var i: u8 = 0;
        while (command_buffer[i] != '\n') {
            const x = try printer.readByte();
            command_buffer[i] = x;

            if (command_buffer[i] == '\x1b') {
                _ = try printer.move_cursor_down(1);
                _ = try printer.move_cursor_newline();
                break :main_loop;
            } else if (command_buffer[i] == std.ascii.control_code.del) {
                if (i > 0) {
                    command_buffer[i] = 0;
                    try printer.move_cursor_left(1);
                    _ = try printer.writeByte(' ');
                    try printer.move_cursor_left(1);
                    i = i - 1;
                }
            } else if (command_buffer[i] == '\n' or command_buffer[i] == '\r') {
                _ = try printer.save_cursor();
                for (command_buffer, 0..) |c, j| {
                    command_buffer[j] = std.ascii.toLower(c);
                }
                processed_buffer = command_buffer[0..i];
                break;
            } else {
                if (i >= BUFFER_LENGTH) {
                    continue;
                }
                _ = try printer.writeByte(command_buffer[i]);
                i += 1;
            }
        }

        const read_command = std.meta.stringToEnum(commands, processed_buffer) orelse .nomatch;

        switch (read_command) {
            .quit => {
                _ = try printer.move_cursor_down(1);
                _ = try printer.move_cursor_newline();
                break;
            },
            .north, .south, .east, .west, .in, .out => {
                for (player.location.exits) |e| {
                    if (e.direction == read_command) {
                        player.location = @constCast(e.room);

                        try printer.move_cursor_left(i);
                        try printer.clear_to_end_of_current_line();
                        _ = try printer.move_cursor_down(1);
                        _ = try printer.move_cursor_newline();
                        try printer.clear_to_end_of_current_line();
                        break;
                    }
                } else {
                    _ = try printer.move_cursor_down(1);
                    _ = try printer.move_cursor_newline();
                    _ = try printer.write("No Exit in that direction");
                    _ = try printer.restore_cursor();
                }
            },
            else => {
                // _ = try printer.save_cursor();
                _ = try printer.move_cursor_down(1);
                _ = try printer.move_cursor_newline();
                _ = try printer.write("Command not found");
                _ = try printer.restore_cursor();
                // @memset(&command_buffer, 0);
            },
        }
        std.posix.nanosleep(0, 16000);
    }
}

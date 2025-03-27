// zig fmt: off
const std     = @import("std");
const sqlite  = @import("sqlite");
const tui     = @import("ui/tui.zig");
const print   = @import("ui/print.zig");
const Screen  = @import("ui/screen.zig");
const builder = @import("backends/backend.zig");
const data    = @import("backends/hardcoded.zig");
const CommandProcessor = @import("command_processor.zig").CommandProcessor;
const TextInput = @import("ui/elements/text_input.zig").TextInput;
const Box = @import("ui/elements/box.zig").Box;
// zig fmt: on

const Item = @import("item.zig").Item;
const Exit = @import("exit.zig").Exit;
const Room = @import("room.zig").Room;

const Location = Screen.Location;

const posix = std.posix;
const printer = print.createPrinter(&tui.instance);
const printerface = print.PrinterFace.createPrinterFace(&printer);

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
    _ = try printer.eraseToEndOfCurrentLine();
    var last_len = try printer.write(player.location.*.title);

    try printer.moveCursorDown(2);
    try printer.moveCursorLeft(last_len);
    _ = try printer.eraseToEndOfCurrentLine();
    last_len = try printer.write(player.location.*.description);

    try printer.moveCursorDown(2);
    try printer.moveCursorLeft(last_len);
    _ = try printer.eraseToEndOfCurrentLine();
    _ = try printer.write("Exits to the: ");

    for (player.location.exits) |e| {
        if (e.direction == CommandProcessor.commands.nomatch) {
            continue;
        }
        _ = try printer.write(tui.Bold());
        _ = try printer.write(@tagName(e.direction));
        _ = try printer.write(tui.Reset());
        _ = try printer.writeByte(' ');
    }
}

fn start_game(player: Character, world: World) !void {
    _ = try printer.printAtLocation(.{ .x = 1, .y = 1 }, "MARLOWE");
    _ = try printer.printAtLocation(.{ .x = 2, .y = 2 }, world.map.title);
    _ = try printer.moveCursor(.{ .x = 2, .y = 4 });
    _ = try print_current_room(player);
}

fn pack_u32(characters: [4]u32) u32 {
    var result: u32 = 0;
    result &= characters[3];
    result &= (characters[2] << 8);
    result &= (characters[1] << 16);
    result &= (characters[0] << 24);
    return result;
}

// zig fmt: off
// TODO: Move this somewhere and make it
//       generic for multiple input types
const ControlCodes = enum {
    escape,
    left,
    right,
    up,
    down,
    home,
    end,
    pgup,
    pgdn,
    del,
    ins,
    tab,
    bs,
    newline,
    nomatch,

    pub fn match(keycode: []const u8) ControlCodes {
        const keymap = std.StaticStringMap(ControlCodes).initComptime(.{
            .{"\x1b",    .escape },
            .{"\x1b[D",  .left   },
            .{"\x1b[C",  .right  },
            .{"\x1b[A",  .up     },
            .{"\x1b[B",  .down   },
            .{"\x1b[1~", .home   },
            .{"\x1b[4~", .end    },
            .{"\x1b[5~", .pgup   },
            .{"\x1b[6~", .pgdn   },
            .{"\x1b[3~", .del    },
            .{"\x1b[2~", .ins    },
            .{"\t",      .tab    },
            .{"\x7f",    .bs     },
            .{"\n",      .newline},
            .{"\r",      .newline},
        });

        return keymap.get(keycode) orelse .nomatch;
    }
};
// zig fmt: on;

const BUFFER_LENGTH = 255;

pub fn main() !void {
    //std.c.setlocale(std.c.LC.CTYPE, "");

    try printer.setup();
    defer printer.teardown() catch {};
    // errdefer printer.teardown();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var data_instance = data.Data.init(&allocator, 2);
    defer data_instance.deleteRooms() catch {};

    const backend = builder.createDataLayer(&data_instance);

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

    const window_dimensions = printer.Screen();
    var empty_box = Box.init(.{ .x = 1, .y = 1 }, window_dimensions, allocator, &printerface);

    const commands = CommandProcessor.commands;

    var processed_buffer: []u8 = undefined;

    var main_command_input = TextInput.init(allocator, 256, &printerface);
    main_command_input.movePosition(.{ .x = 4, .y = 9 });


    main_loop: while (true) {
        try start_game(player, main_world);
        try main_command_input.prompt();
        try empty_box.render();

        while (true) {
            var read_buffer = std.mem.zeroes([BUFFER_LENGTH]u8);
            const command_length = try printer.read(&read_buffer);

            const button = ControlCodes.match(read_buffer[0..command_length]);
            switch (button) {
                .escape => {
                    _ = try printer.moveCursorDown(1);
                    _ = try printer.moveCursorNewline();
                    break :main_loop;
                },
                .up => {
                    // pass/noop
                },
                .down => {
                    // pass/noop
                },
                .left => {
                    try main_command_input.moveCursorLeft(1);
                },
                .right => {
                    try main_command_input.moveCursorRight(1);
                },
                .tab => {
                    const tab: []u8 = @constCast("\t");
                    _ = try main_command_input.insertText(tab);
                },
                .home => {
                    try main_command_input.moveCursorHome();
                },
                .end => {
                    try main_command_input.moveCursorEnd();
                },
                .ins => {
                    try main_command_input.toggleInsertMode();
                },
                .bs => {
                    _ = try main_command_input.backspace();
                },
                .del => {
                    _ = try main_command_input.delete();
                },
                .newline => {
                    // _ = try printer.saveCursor();
                    processed_buffer = main_command_input.printable_char_buffer.items[0..];
                    for (processed_buffer[0..], 0..) |c, i| {
                        processed_buffer[i] = std.ascii.toLower(c);
                    }
                    break;
                },
                else => {
                    _ = try main_command_input.insertText(read_buffer[0..command_length]);
                },
            }
        }

        const trimmed_buffer: []const u8 = std.mem.trim(u8, processed_buffer, &std.ascii.whitespace);
        const read_command = std.meta.stringToEnum(commands, trimmed_buffer) orelse .nomatch;

        switch (read_command) {
            .quit => {
                _ = try printer.moveCursorDown(1);
                _ = try printer.moveCursorNewline();
                break;
            },
            .north, .south, .east, .west, .in, .out => {
                for (player.location.exits) |e| {
                    if (e.direction == read_command) {
                        player.location = @constCast(e.room);

                        try main_command_input.clear();

                        // Clear any previous errors
                        _ = try printer.saveCursor();
                        _ = try printer.moveCursorDown(1);
                        _ = try printer.moveCursorNewline();
                        _ = try printer.eraseToEndOfCurrentLine();
                        _ = try printer.restoreCursor();
                        break;
                    }
                } else {
                    _ = try printer.moveCursorDown(1);
                    _ = try printer.moveCursorNewline();
                    _ = try printer.write(" No Exit in that direction");
                    _ = try printer.restoreCursor();
                        try main_command_input.clear();
                }
            },
            else => {
                // empty_box.render() catch {};
                _ = try printer.moveCursorDown(1);
                _ = try printer.moveCursorNewline();
                _ = try printer.write(" Command not found");
                _ = try printer.restoreCursor();
                try main_command_input.clear();
            },
        }
        std.posix.nanosleep(0, 16000);
    }
}

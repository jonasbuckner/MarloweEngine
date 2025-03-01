// zig fmt: off
const std     = @import("std");
const sqlite  = @import("sqlite");
const tui     = @import("ui/tui.zig").init();
const printer = @import("ui/print.zig"){ .UIBackend = tui };
// zig fmt: on

const Item = @import("item.zig").Item;
const Exit = @import("exit.zig").Exit;
const Room = @import("room.zig").Room;

const posix = std.posix;

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

const CLEAR_SCREEN = "\x1b[2J";
const HOME_POSITION = "\x1b[1H";
const MOVE_CURSOR_FMT = "\x1b[{};{}H";
const master_writer = std.io.getStdOut().writer();

inline fn Bold() []const u8 {
    return "\x1b[1m";
}

inline fn Reset() []const u8 {
    return "\x1b[22m";
}

fn move_cursor(x: u32, y: u32) !void {
    try master_writer.print(MOVE_CURSOR_FMT, .{ y, x });
}

fn print_current_room(player: Character) !void {
    _ = try master_writer.write(player.location.title);
    // printer.print_at_location(.{ 2, 6 }, player.location.description);
    try move_cursor(2, 8);
    _ = try master_writer.print("Exits to the: {s}{s}{s}", .{ Bold(), player.location.exits[0].name, Reset() });
}

fn start_game(player: Character, world: World) !void {
    _ = player;
    _ = world;
    // try printer.print_at_location(.{ .x = 0, .y = 0 }, "MARLOWE");
    // try printer.print_at_location(.{ .x = 2, .y = 2 }, world.map.title);
    // try printer.print_at_location(.{ .x = 2, .y = 4 }, print_current_room(player));
    // try printer.print_at_location(.{ .x = 2, .y = 9 }, "# ");
}

fn makeRaw(tty: posix.fd_t) !posix.termios {
    const termstate = try posix.tcgetattr(tty);
    var rawterm = termstate;

    // zig fmt: off
    // see termios(3) under the section "Raw mode"
    // iflag is the input mode flags
    rawterm.iflag.IGNBRK = false; // Don't ignore BREAK
    rawterm.iflag.BRKINT = false; // BREAK reads as a null byte because IGNBRK and PARMRK are false
    rawterm.iflag.PARMRK = false; // Do not mark input bytes that have parity or framing errors with \377 and \0 when passed into the program
    rawterm.iflag.ISTRIP = false; // Don't strip off eighth bit
    rawterm.iflag.INLCR  = false; // Don't translate newline (NL) to carriage return (CR) on input
    rawterm.iflag.IGNCR  = false; // Don't ignore carriage return on input
    rawterm.iflag.ICRNL  = false; // Don't translate newline (NL) to carriage return (CR) on input
    rawterm.iflag.IXON   = false; // Enable XON/XOFF flow control on output (I think this is set -x)

    // oflag is the output mode flags
    rawterm.oflag.OPOST = false; // Disable implementation-defined output processing

    // lflag is the local mode flags
    rawterm.lflag.ECHO   = false; // Echo off. Don't echo input characters
    rawterm.lflag.ECHONL = false; // Do not echo newlines
    rawterm.lflag.ICANON = false; // Disable canonical mode
    rawterm.lflag.ISIG   = false; // Do not generate corresponding signals for INTR, QUIT, SUSP, or DPSUSP characters
    rawterm.lflag.IEXTEN = false; // Disable implementation-defined input processing like special control characters

    // cflag is the control mode flags
    rawterm.cflag.CSIZE  = .CS8;  // Character mask size
    rawterm.cflag.PARENB = false; // Disable parity generation on output and parity checking for input
    // zig fmt: on

    // special characters
    rawterm.cc[@intFromEnum(posix.V.MIN)] = 1;
    rawterm.cc[@intFromEnum(posix.V.TIME)] = 0;
    try posix.tcsetattr(tty, .NOW, rawterm);

    return termstate;
}

pub fn main() !void {
    //std.c.setlocale(std.c.LC.CTYPE, "");
    std.debug.print("{s}", .{@typeName(@TypeOf(std.io.getStdOut().writer()))});

    try printer.print_at_location(.{ .x = 0, .y = 0 }, "UUUA");

    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();
    //
    // const tty = try posix.open("/dev/tty", .{ .ACCMODE = .RDWR }, 0);
    // const termstate = try makeRaw(tty);
    // defer posix.tcsetattr(tty, .NOW, termstate) catch {};
    //
    // _ = try master_writer.write(CLEAR_SCREEN);
    // _ = try master_writer.write(HOME_POSITION);
    //
    // // const db = try sqlite.Db.init(.{
    // //     .mode = sqlite.Db.Mode{ .File = "world.sqlite" },
    // //     .open_flags = .{
    // //         .write = true,
    // //         .create = true,
    // //     },
    // //     .threading_mode = .Multithread,
    // // });
    //
    // // const room_statement = db.prepare("SELECT * FROM room;");
    // // defer room_statement.deinit();
    //
    // const North = Exit.init("north", 1, 0, 0, false);
    // const south_room = Room{
    //     .title = "Die",
    //     .description = "You die.",
    //     .items = undefined,
    //     .exits = .{North},
    // };
    // const South = Exit.init("south", -1, 0, 0, false);
    // const room = Room{
    //     .title = "Born",
    //     .description = "You are born.",
    //     .items = .{Item{ .name = "Raygun", .description = "Pew pew" }},
    //     .exits = .{South},
    // };
    //
    // const rooms: []Room = try allocator.alloc(Room, 2);
    // rooms[0] = room;
    // rooms[1] = south_room;
    //
    // const overworld = Map{
    //     .title = "Overworld",
    //     .rooms = rooms,
    // };
    // const main_world = World{ .map = overworld };
    //
    // const player = Character{
    //     .inventory = [_]Item{
    //         Item{ .name = "Raygun", .description = "Raygun pew pew" },
    //     },
    //     .description = "",
    //     .location = room,
    // };
    //
    // while (true) {
    //     try start_game(player, main_world);
    //     break;
    // }
}

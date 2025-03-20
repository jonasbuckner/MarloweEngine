const std = @import("std");
const Location = @import("../screen.zig").Location;
const PrinterFace = @import("../printer_face.zig").PrinterFace;

// zig fmt: off
pub const TextInput = struct {
    position_on_display: Location,
    cursor_position_on_display: Location,

    printable_char_buffer: std.ArrayList(u8),
    cursor_position_in_pcb: usize = 0,

    insert_mode: bool = true,

    character_mapping: std.ArrayList(DisplayMapping),

    printer: *const PrinterFace,

    allocator: std.mem.Allocator,

    const DisplayMapping = struct {
        pcb_index: usize,
        display_index: usize,
        character: u8,  // for debug
        character_width: usize,
    };

    pub fn init(allocator: std.mem.Allocator, capacity: usize, printer: *const PrinterFace) TextInput {
        const cursor_position = printer.cursorPosition() catch Location.empty();
        const result = TextInput {
            .position_on_display        = cursor_position,
            .cursor_position_on_display = cursor_position,
            .printable_char_buffer      = std.ArrayList(u8).initCapacity(allocator, capacity) catch std.ArrayList(u8).init(allocator),
            .cursor_position_in_pcb     = 0,
            .insert_mode                = true,
            .character_mapping          = std.ArrayList(DisplayMapping).initCapacity(allocator, capacity) catch std.ArrayList(DisplayMapping).init(allocator),
            .printer                    = @ptrCast(printer),
            .allocator                  = allocator,
        };
        return result;
    }

    pub fn deinit(self: *TextInput) void {
        self.printable_char_buffer.deinit();
        self.character_mapping.deinit();
    }

    pub fn appendText(self: *TextInput, text_buffer: []u8) !usize {
        try self.printable_char_buffer.appendSlice(text_buffer);
        const size = try self.printer.write(text_buffer);

        self.cursor_position_in_pcb += 1;
        self.cursor_position_on_display = try self.printer.cursorPosition();
        return size;
    }

    pub fn insertText(self: *TextInput, text_buffer: []u8) !usize {
        var size: usize = 0;
        if (self.printable_char_buffer.items.len <= self.cursor_position_in_pcb) {
            size = try self.appendText(text_buffer);
        } else {
            if (self.insert_mode) {
                try self.printable_char_buffer.insertSlice(self.cursor_position_in_pcb, text_buffer);
                self.movePcbRight();
                self.updateDisplayMapping();
                _ = try self.printer.eraseToEndOfCurrentLine();
                size = try self.printer.write(text_buffer);

                try self.printer.saveCursor();
                _ = try self.printer.write(self.printable_char_buffer.items[self.cursor_position_in_pcb..]);
                try self.printer.restoreCursor();

            } else { // Insert mode off
                try self.printable_char_buffer.replaceRange(self.cursor_position_in_pcb, text_buffer.len, text_buffer);

                self.movePcbRight();
                size = try self.printer.write(text_buffer);

                try self.printer.saveCursor();
                _ = try self.printWholeBuffer();
                try self.printer.restoreCursor();
            }
        }
        self.cursor_position_on_display = try self.printer.cursorPosition();
        self.updateDisplayMapping();

        return size;
    }

    pub fn updateDisplayMapping(self: *TextInput) void {
        if (self.printable_char_buffer.items.len == 0) return;

        self.character_mapping.clearRetainingCapacity();

        var x_position = self.position_on_display.x;
        const tabstop = self.printer.TabStop();

        var character_width: usize = 0;
        for (self.printable_char_buffer.items, 0..) |c, i| {
            character_width = if (c == '\t') tabstop - ((x_position - 1) % tabstop) else 1;

            self.character_mapping.append(.{
                .pcb_index = i,
                .display_index = x_position,
                .character = c,
                .character_width = character_width,
            }) catch |e| switch (e) {
                error.OutOfMemory => self.printer.print("{s}", .{ "character_mapping Out Of Memory" }) catch {},
            };

            x_position += character_width;
        }

        // End cap
        self.character_mapping.append(.{
            .pcb_index = self.printable_char_buffer.items.len,
            .display_index = x_position,
            .character = ' ',
            .character_width = 1,
        }) catch |e| switch (e) {
            error.OutOfMemory => self.printer.print("{s}", .{ "character_mapping Out Of Memory" }) catch {},
        };

    }

    pub fn getDisplayMapping(self: *TextInput, pcb_cursor: usize) !DisplayMapping {
        // TODO: Can we just use pcb_cursor as an index?
        for (self.character_mapping.items) |mapping| {
            if (mapping.pcb_index == pcb_cursor) {
                return mapping;
            }
        }

        // If we don't find it, update the mapping...
        self.updateDisplayMapping();

        // ...and try again.
        for (self.character_mapping.items) |mapping| {
            if (mapping.pcb_index == pcb_cursor) {
                return mapping;
            }
        }

        return error.DisplayMappingNotFound;
    }

    pub fn printWholeBuffer(self: *TextInput) !usize {
        _ = try self.printer.moveCursor(self.position_on_display);
        _ = try self.printer.eraseToEndOfCurrentLine();
        const size = try self.printer.write(self.printable_char_buffer.items[0..self.printable_char_buffer.items.len]);

        return size;
    }

    pub fn recalculatePcbCursor(self: *TextInput) !void {
        self.cursor_position_on_display = try self.printer.cursorPosition();

        for (self.character_mapping.items) |m| {
            if (m.display_index == self.cursor_position_on_display.x) {
                self.cursor_position_in_pcb = m.pcb_index;
                break;
            }
        } else {
            self.updateDisplayMapping();
            for (self.character_mapping.items) |m| {
                if (m.display_index == self.cursor_position_on_display.x) {
                    self.cursor_position_in_pcb = m.pcb_index;
                    break;
                }
            } else {
                self.cursor_position_in_pcb = 0;
                return error.DisplayMappingNotFound;
            }
        }
    }

    pub inline fn movePcbLeft(self: *TextInput) void {
        if (self.cursor_position_in_pcb == 0) return;

        self.cursor_position_in_pcb -= 1;
    }

    pub inline fn movePcbRight(self: *TextInput) void {
        if (self.cursor_position_in_pcb == self.printable_char_buffer.items.len) return;

        self.cursor_position_in_pcb += 1;
    }

    pub fn clear(self: *TextInput) !void {
        self.printable_char_buffer.clearRetainingCapacity();
        self.character_mapping.clearRetainingCapacity();
        self.cursor_position_in_pcb = 0;
        _ = try self.printer.moveCursor(self.position_on_display);
        _ = try self.printer.eraseToEndOfCurrentLine();
    }

    /////////////////////////////////
    ////                         ////
    ////     KEYCODE HANDLING    ////
    ////                         ////
    ////-------------------------////
    pub fn moveCursorLeft(self: *TextInput, _: usize) !void {
        if (self.cursor_position_in_pcb <= 0) return;

        const next_character = try self.getDisplayMapping(self.cursor_position_in_pcb - 1);
        const distance = next_character.character_width;
        self.movePcbLeft();

        try self.printer.moveCursorLeft(distance);

        self.cursor_position_on_display = try self.printer.cursorPosition();
    }

    pub fn moveCursorRight(self: *TextInput, _: usize) !void {
        if (self.cursor_position_in_pcb >= self.printable_char_buffer.items.len) return;

        const curr_character = try self.getDisplayMapping(self.cursor_position_in_pcb);
        const distance = curr_character.character_width;
        self.movePcbRight();

        try self.printer.moveCursorRight(distance);

        self.cursor_position_on_display = try self.printer.cursorPosition();
    }

    pub fn moveCursorHome(self: *TextInput) !void {
        if (self.cursor_position_in_pcb <= 0) return;

        self.cursor_position_in_pcb = 0;
        try self.printer.moveCursor(.{ .x = self.position_on_display.x, .y = self.position_on_display.y });
        self.cursor_position_on_display = self.position_on_display;
    }

    pub fn moveCursorEnd(self: *TextInput) !void {
        if (self.cursor_position_in_pcb >= self.printable_char_buffer.items.len) return;

        var display_distance: usize = 0;
        for (self.character_mapping.items[0..self.character_mapping.items.len-1]) |m| {
            display_distance += m.character_width;
        }

        self.cursor_position_in_pcb = self.printable_char_buffer.items.len;
        const new_position = Location { .x = self.position_on_display.x + display_distance, .y = self.position_on_display.y };
        try self.printer.moveCursor(new_position);
        self.cursor_position_on_display = self.printer.cursorPosition() catch new_position;
    }

    pub fn backspace(self: *TextInput) !void {
        if (self.cursor_position_in_pcb <= 0) return;

        self.movePcbLeft();

        const previous_char = try self.getDisplayMapping(self.cursor_position_in_pcb);
        const distance = previous_char.character_width;

        for (0..distance) |_| {
            _ = try self.printer.writeByte('\x08');
        }

        _ = self.printable_char_buffer.orderedRemove(self.cursor_position_in_pcb);
        self.cursor_position_on_display = try self.printer.cursorPosition();

        self.updateDisplayMapping();
        try self.printer.saveCursor();
        _ = try self.printWholeBuffer();
        try self.printer.restoreCursor();
    }

    pub fn delete(self: *TextInput) !void {
        if (self.cursor_position_in_pcb >= self.printable_char_buffer.items.len) return;

        const current_char = try self.getDisplayMapping(self.cursor_position_in_pcb);
        const distance = current_char.character_width;

        for (0..distance) |_| {
            _ = try self.printer.writeByte('\x7f');
        }

        _ = self.printable_char_buffer.orderedRemove(self.cursor_position_in_pcb);

        self.updateDisplayMapping();
        try self.printer.saveCursor();
        _ = try self.printWholeBuffer();
        try self.printer.restoreCursor();

        const new_cursor = try self.printer.cursorPosition();
        const cursor_moved_by = self.cursor_position_on_display.x - new_cursor.x;
        self.cursor_position_in_pcb -= @min(cursor_moved_by, self.cursor_position_in_pcb);
        self.cursor_position_on_display = new_cursor;
    }

    //////////////////////////////
    ////                      ////
    ////     DEBUG HELPERS    ////
    ////                      ////
    ////----------------------////
    pub fn DEBUG_serializeCharacterMapping(self: *TextInput) !void {
        var buf: [4096 * 50]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var json_string = std.ArrayList(u8).init(fba.allocator());
        defer json_string.deinit();

        const flags = std.fs.File.CreateFlags{};
        const FILENAME = "character_mapping.json";
        if (std.fs.cwd().access(FILENAME, .{})) {
            try std.fs.cwd().deleteFile(FILENAME);
        }
        const json_file = try std.fs.cwd().createFile(FILENAME, flags);
        defer json_file.close();

        try std.json.stringify(self.character_mapping.items, .{}, json_string.writer());
        try json_file.writer().writeAll(json_string.items);
    }

    fn DEBUG_printLowerRight(self: *TextInput, offset: usize, comptime fmt: []const u8, args: anytype) void {
        self.printer.saveCursor() catch {};
        _ = self.printer.moveCursor(.{ .x = 70, .y = 21+offset }) catch {};
        _ = self.printer.eraseToEndOfCurrentLine() catch {};
        self.printer.print(fmt, args) catch {};
        self.printer.restoreCursor() catch {};
    }

    pub fn DEBUG_printTextInput(self: *TextInput) !void {
        try self.printer.saveCursor();
        if (self.printable_char_buffer.items.len > 0) {
        _ = try self.printer.moveCursor(.{ .x = 50, .y = 1 });
        _ = try self.printer.eraseToEndOfCurrentLine();
        try self.printer.print("cursor_position_in_pcb: {d}\t0x{x}", .{ self.cursor_position_in_pcb, self.printable_char_buffer.items[self.cursor_position_in_pcb - 1] });
        }
        _ = try self.printer.moveCursor(.{ .x = 50, .y = 2 });
        _ = try self.printer.eraseToEndOfCurrentLine();
        try self.printer.print("char_buffer len: {d}", .{ self.printable_char_buffer.items.len });
        _ = try self.printer.moveCursor(.{ .x = 50, .y = 4 });
        _ = try self.printer.eraseToEndOfCurrentLine();
        try self.printer.print("position_on_display: {d}:{d}", .{ self.position_on_display.x, self.position_on_display.y });
        _ = try self.printer.moveCursor(.{ .x = 50, .y = 5 });
        _ = try self.printer.eraseToEndOfCurrentLine();
        try self.printer.print("cursor_position_on_display: {d}:{d}", .{ self.cursor_position_on_display.x, self.cursor_position_on_display.y });
        try self.printer.restoreCursor();
    }
};
// zig fmt: on

test "Should append char" {}

test "should correctly calcuate tab width" {}

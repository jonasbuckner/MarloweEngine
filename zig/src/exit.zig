pub const Exit = struct {
    x: i8,
    y: i8,
    z: i8,
    hidden: bool = false,
    name: []const u8 = "UNDEFINED EXIT NAME - This is a bug.",

    pub fn init(name: []const u8, x: i8, y: i8, z: i8, hidden: ?bool) Exit {
        return Exit{
            .name = name,
            .x = x,
            .y = y,
            .z = z,
            .hidden = hidden orelse false,
        };
    }

    pub fn empty() Exit {
        return Exit{
            .x = 0,
            .y = 0,
            .z = 0,
            .hidden = false,
        };
    }
};

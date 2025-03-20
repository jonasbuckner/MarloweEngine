pub const Direction = enum {
    up,
    down,
    left,
    right,
};

pub const Location = struct {
    x: usize,
    y: usize,

    pub fn empty() Location {
        return .{ .x = 0, .y = 0 };
    }
};

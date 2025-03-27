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

pub const Dimensions = struct {
    width: usize,
    height: usize,
};

pub const Offset = struct {
    x: isize,
    y: isize,
};

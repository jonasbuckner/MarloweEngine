pub const CommandProcessor = struct {
    pub const commands = enum {
        quit,
        north,
        south,
        east,
        west,
        in,
        out,
        read,
        unlock,
        nomatch,
    };
};

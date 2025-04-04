const std = @import("std");

pub fn DataBuilder(comptime Backend: type) type {
    return struct {
        backend: *Backend,

        const Self = @This();

        pub fn init(backend: *Backend) Self {
            return .{
                .backend = backend,
            };
        }
    };
}

pub fn createDataLayer(backend: anytype) DataBuilder(@TypeOf(backend.*)) {
    return DataBuilder(@TypeOf(backend.*)).init(backend);
}

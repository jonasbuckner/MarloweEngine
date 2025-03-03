const std = @import("std");

pub fn DataBuilder(comptime Backend: type) type {
    return struct {
        backend: *const Backend,

        const Self = @This();

        pub fn init(backend: *const Backend) Self {
            return .{
                .backend = backend,
            };
        }
    };
}

pub fn create_data_layer(backend: anytype) DataBuilder(@TypeOf(backend.*)) {
    return DataBuilder(@TypeOf(backend.*)).init(backend);
}

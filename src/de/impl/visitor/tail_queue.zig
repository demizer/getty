const std = @import("std");
const getty = @import("../../../lib.zig");

pub fn Visitor(comptime TailQueue: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace getty.de.Visitor(
            Self,
            Value,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            undefined,
            visitSeq,
            undefined,
            undefined,
            undefined,
        );

        const Value = TailQueue;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            var list = Value{};
            errdefer getty.de.free(allocator.?, list);

            const Child = std.meta.fieldInfo(Value.Node, .data).field_type;

            while (try seq.nextElement(allocator, Child)) |value| {
                var node = try allocator.?.create(Value.Node);
                node.* = .{ .data = value };
                list.append(node);
            }

            return list;
        }
    };
}

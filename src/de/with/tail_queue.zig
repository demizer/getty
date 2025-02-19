const std = @import("std");

const TailQueueVisitor = @import("../impl/visitor/tail_queue.zig").Visitor;

pub fn is(comptime T: type) bool {
    return comptime std.mem.startsWith(u8, @typeName(T), "std.linked_list.TailQueue");
}

pub fn Visitor(comptime T: type) type {
    return TailQueueVisitor(T);
}

pub fn deserialize(
    allocator: ?std.mem.Allocator,
    comptime _: type,
    deserializer: anytype,
    visitor: anytype,
) !@TypeOf(visitor).Value {
    return try deserializer.deserializeSeq(allocator, visitor);
}

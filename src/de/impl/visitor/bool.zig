const getty = @import("../../../lib.zig");

const Visitor = @This();
const impl = @"impl Visitor";

pub usingnamespace getty.de.Visitor(
    Visitor,
    impl.visitor.Value,
    impl.visitor.visitBool,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
);

const @"impl Visitor" = struct {
    pub const visitor = struct {
        pub const Value = bool;

        pub fn visitBool(_: Visitor, comptime Deserializer: type, input: bool) Deserializer.Error!Value {
            return input;
        }
    };
};

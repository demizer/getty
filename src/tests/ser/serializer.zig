const std = @import("std");

const getty = @import("getty");

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const Token = @import("common/token.zig").Token;

pub const Serializer = struct {
    tokens: []const Token,

    const Self = @This();

    pub fn init(tokens: []const Token) Self {
        return .{ .tokens = tokens };
    }

    pub fn remaining(self: Self) usize {
        return self.tokens.len;
    }

    pub fn nextTokenOpt(self: *Self) ?Token {
        switch (self.remaining()) {
            0 => return null,
            else => |len| {
                const first = self.tokens[0];
                self.tokens = if (len == 1) &[_]Token{} else self.tokens[1..];
                return first;
            },
        }
    }

    pub usingnamespace getty.Serializer(
        *Self,
        Ok,
        Error,
        getty.default_st,
        getty.default_st,
        Map,
        Seq,
        Struct,
        serializeBool,
        serializeEnum,
        serializeFloat,
        serializeInt,
        serializeMap,
        serializeNull,
        serializeSeq,
        serializeSome,
        serializeString,
        serializeStruct,
        serializeVoid,
    );

    const Ok = void;
    const Error = std.mem.Allocator.Error || error{TestExpectedEqual};

    fn serializeBool(self: *Self, v: bool) Error!Ok {
        try assertNextToken(self, Token{ .Bool = v });
    }

    fn serializeEnum(self: *Self, v: anytype) Error!Ok {
        try assertNextToken(self, Token{ .Enum = {} });
        try assertNextToken(self, Token{ .String = @tagName(v) });
    }

    fn serializeFloat(self: *Self, v: anytype) Error!Ok {
        var expected = switch (@typeInfo(@TypeOf(v))) {
            .ComptimeFloat => Token{ .ComptimeFloat = {} },
            .Float => |info| switch (info.bits) {
                16 => Token{ .F16 = v },
                32 => Token{ .F32 = v },
                64 => Token{ .F64 = v },
                128 => Token{ .F128 = v },
                else => @panic("unexpected float size"),
            },
            else => @panic("unexpected type"),
        };

        try assertNextToken(self, expected);
    }

    fn serializeInt(self: *Self, v: anytype) Error!Ok {
        var expected = switch (@typeInfo(@TypeOf(v))) {
            .ComptimeInt => Token{ .ComptimeInt = {} },
            .Int => |info| switch (info.signedness) {
                .signed => switch (info.bits) {
                    8 => Token{ .I8 = v },
                    16 => Token{ .I16 = v },
                    32 => Token{ .I32 = v },
                    64 => Token{ .I64 = v },
                    128 => Token{ .I128 = v },
                    else => @panic("unexpected integer size"),
                },
                .unsigned => switch (info.bits) {
                    8 => Token{ .U8 = v },
                    16 => Token{ .U16 = v },
                    32 => Token{ .U32 = v },
                    64 => Token{ .U64 = v },
                    128 => Token{ .U128 = v },
                    else => @panic("unexpected integer size"),
                },
            },
            else => @panic("unexpected type"),
        };

        try assertNextToken(self, expected);
    }

    fn serializeMap(self: *Self, length: ?usize) Error!Map {
        try assertNextToken(self, Token{ .Map = .{ .len = length } });

        return Map{ .ser = self };
    }

    fn serializeNull(self: *Self) Error!Ok {
        try assertNextToken(self, Token{ .Null = {} });
    }

    fn serializeSeq(self: *Self, length: ?usize) Error!Seq {
        try assertNextToken(self, Token{ .Seq = .{ .len = length } });
        return Seq{ .ser = self };
    }

    fn serializeSome(self: *Self, v: anytype) Error!Ok {
        try assertNextToken(self, Token{ .Some = {} });
        try getty.serialize(v, self.serializer());
    }

    fn serializeString(self: *Self, v: anytype) Error!Ok {
        try assertNextToken(self, Token{ .String = v });
    }

    fn serializeStruct(self: *Self, comptime name: []const u8, length: usize) Error!Struct {
        try assertNextToken(self, Token{ .Struct = .{ .name = name, .len = length } });
        return Struct{ .ser = self };
    }

    fn serializeVoid(self: *Self) Error!Ok {
        try assertNextToken(self, Token{ .Void = {} });
    }
};

const Map = struct {
    ser: *Serializer,

    const Self = @This();

    pub usingnamespace getty.ser.Map(
        *Self,
        Serializer.Ok,
        Serializer.Error,
        serializeKey,
        serializeValue,
        end,
    );

    fn serializeKey(self: *Self, key: anytype) Serializer.Error!void {
        try getty.serialize(key, self.ser.serializer());
    }

    fn serializeValue(self: *Self, value: anytype) Serializer.Error!void {
        try getty.serialize(value, self.ser.serializer());
    }

    fn end(self: *Self) Serializer.Error!Serializer.Ok {
        try assertNextToken(self.ser, Token{ .MapEnd = {} });
    }
};

const Seq = struct {
    ser: *Serializer,

    const Self = @This();

    pub usingnamespace getty.ser.Seq(
        *Self,
        Serializer.Ok,
        Serializer.Error,
        serializeElement,
        end,
    );

    fn serializeElement(self: *Self, value: anytype) Serializer.Error!void {
        try getty.serialize(value, self.ser.serializer());
    }

    fn end(self: *Self) Serializer.Error!Serializer.Ok {
        try assertNextToken(self.ser, Token{ .SeqEnd = {} });
    }
};

const Struct = struct {
    ser: *Serializer,

    const Self = @This();

    pub usingnamespace getty.ser.Structure(
        *Self,
        Serializer.Ok,
        Serializer.Error,
        serializeField,
        end,
    );

    fn serializeField(self: *Self, comptime key: []const u8, value: anytype) Serializer.Error!void {
        try assertNextToken(self.ser, Token{ .String = key });
        try getty.serialize(value, self.ser.serializer());
    }

    fn end(self: *Self) Serializer.Error!Serializer.Ok {
        try assertNextToken(self.ser, Token{ .StructEnd = {} });
    }
};

fn assertNextToken(ser: *Serializer, expected: Token) !void {
    if (ser.nextTokenOpt()) |token| {
        const token_tag = std.meta.activeTag(token);
        const expected_tag = std.meta.activeTag(expected);

        if (token_tag == expected_tag) {
            switch (token) {
                .Bool => try expectEqual(@field(token, "Bool"), @field(expected, "Bool")),
                .ComptimeFloat => try expectEqual(@field(token, "ComptimeFloat"), @field(expected, "ComptimeFloat")),
                .ComptimeInt => try expectEqual(@field(token, "ComptimeInt"), @field(expected, "ComptimeInt")),
                .Enum => try expectEqual(@field(token, "Enum"), @field(expected, "Enum")),
                .F16 => try expectEqual(@field(token, "F16"), @field(expected, "F16")),
                .F32 => try expectEqual(@field(token, "F32"), @field(expected, "F32")),
                .F64 => try expectEqual(@field(token, "F64"), @field(expected, "F64")),
                .F128 => try expectEqual(@field(token, "F128"), @field(expected, "F128")),
                .I8 => try expectEqual(@field(token, "I8"), @field(expected, "I8")),
                .I16 => try expectEqual(@field(token, "I16"), @field(expected, "I16")),
                .I32 => try expectEqual(@field(token, "I32"), @field(expected, "I32")),
                .I64 => try expectEqual(@field(token, "I64"), @field(expected, "I64")),
                .I128 => try expectEqual(@field(token, "I128"), @field(expected, "I128")),
                .Map => try expectEqual(@field(token, "Map"), @field(expected, "Map")),
                .MapEnd => try expectEqual(@field(token, "MapEnd"), @field(expected, "MapEnd")),
                .Null => try expectEqual(@field(token, "Null"), @field(expected, "Null")),
                .Seq => try expectEqual(@field(token, "Seq"), @field(expected, "Seq")),
                .SeqEnd => try expectEqual(@field(token, "SeqEnd"), @field(expected, "SeqEnd")),
                .Some => try expectEqual(@field(token, "Some"), @field(expected, "Some")),
                .String => try expectEqualSlices(u8, @field(token, "String"), @field(expected, "String")),
                .Struct => {
                    const t = @field(token, "Struct");
                    const e = @field(expected, "Struct");

                    try expectEqualSlices(u8, t.name, e.name);
                    try expectEqual(t.len, e.len);
                },
                .StructEnd => try expectEqual(@field(token, "StructEnd"), @field(expected, "StructEnd")),
                .U8 => try expectEqual(@field(token, "U8"), @field(expected, "U8")),
                .U16 => try expectEqual(@field(token, "U16"), @field(expected, "U16")),
                .U32 => try expectEqual(@field(token, "U32"), @field(expected, "U32")),
                .U64 => try expectEqual(@field(token, "U64"), @field(expected, "U64")),
                .U128 => try expectEqual(@field(token, "U128"), @field(expected, "U128")),
                .Void => try expectEqual(@field(token, "Void"), @field(expected, "Void")),
            }
        } else {
            @panic("expected Token::{} but serialized as {}");
        }
    } else {
        @panic("expected end of tokens, but {} was serialized");
    }
}

const std = @import("std");

pub const StringSplit = struct {
    list: std.ArrayList(String),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) StringSplit {
        return StringSplit{
            .list = std.ArrayList(String).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: StringSplit) void {
        for (self.list.items) |item| {
            item.deinit();
        }
        self.list.deinit();
    }

    pub fn toString(self: StringSplit) !String {
        var string = try String.init(self.allocator, "");
        try string.concat("[ ");
        for (self.list.items) |item| {
            try string.concat(item.buffer);
            try string.concat(", ");
        }
        try string.concat(" ]");
        return string;
    }
};

pub const String = struct {
    buffer: []u8,
    allocator: std.mem.Allocator,
    length: usize,

    pub fn init(allocator: std.mem.Allocator, value: []const u8) !String {
        const newString = String{
            .buffer = try allocator.alloc(u8, value.len),
            .allocator = allocator,
            .length = value.len,
        };
        @memcpy(newString.buffer, value);
        return newString;
    }

    pub fn concat(self: *String, value: []const u8) !void {
        const startingLength = self.buffer.len;
        const newBuffer = try self.allocator.alloc(u8, self.buffer.len + value.len);
        for (0..newBuffer.len) |idx| {
            if (idx < startingLength) {
                newBuffer[idx] = self.buffer[idx];
            } else {
                newBuffer[idx] = value[idx - startingLength];
            }
        }
        self.allocator.free(self.buffer);
        self.buffer = newBuffer;
    }

    pub fn split(self: String, onChar: u8) !StringSplit {
        var results = StringSplit.init(self.allocator);
        var splitStart: usize = 0;
        for (0.., self.buffer) |idx, element| {
            if (element == onChar) {
                const result = try init(self.allocator, self.buffer[splitStart..idx]);
                try results.list.append(result);
                splitStart = idx + 1;
            }

            if (idx == self.buffer.len - 1) {
                const result = try init(self.allocator, self.buffer[splitStart .. idx + 1]);
                try results.list.append(result);
            }
        }
        return results;
    }

    pub fn deinit(self: String) void {
        self.allocator.free(self.buffer);
    }

    pub fn append(self: String, value: []const u8) String {
        _ = value;
        return self;
    }
};

const expect = std.testing.expect;
test "test_concat" {
    var s = try String.init(std.testing.allocator, "ab;cd");
    defer s.deinit();
    try s.concat(";ef");
    const result = try String.init(std.testing.allocator, "ab;cd;ef");
    defer result.deinit();
    try expect(std.mem.eql(u8, s.buffer, result.buffer));
}

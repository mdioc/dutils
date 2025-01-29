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
        try string.concat("[ \"");
        for (0.., self.list.items) |index, item| {
            if (index != self.list.items.len - 1) {
                try string.concat(item.buffer);
                try string.concat("\", \"");
            } else {
                try string.concat(item.buffer);
            }
        }
        try string.concat("\" ]\n");
        return string;
    }
};

pub const StringFind = struct {
    list: std.ArrayList(String),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) StringFind {
        return StringFind{
            .list = std.ArrayList(String).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: StringFind) void {
        for (self.list.items) |item| {
            item.deinit();
        }
        self.list.deinit();
    }

    pub fn toString(self: StringFind) !String {
        var string = try String.init(self.allocator, "");
        try string.concat("[ \"");
        for (0.., self.list.items) |index, item| {
            if (index != self.list.items.len - 1) {
                try string.concat(item.buffer);
                try string.concat("\", \"");
            } else {
                try string.concat(item.buffer);
            }
        }
        try string.concat("\" ]\n");
        return string;
    }
};

pub const String = struct {
    buffer: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, value: []const u8) !String {
        const newString = String{
            .buffer = try allocator.alloc(u8, value.len),
            .allocator = allocator,
        };
        @memcpy(newString.buffer, value);
        return newString;
    }

    pub fn length(self: String) usize {
        self.buffer.len;
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

    pub fn split(self: String, onChar: u8, allocator: std.mem.Allocator) !StringSplit {
        var results = StringSplit.init(allocator);
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

    fn isWhitespace(self: String, index: usize) bool {
        return switch (self.buffer[index]) {
            '\n' => true,
            '\t' => true,
            ' ' => true,
            else => false,
        };
    }

    pub fn trimRight(self: *String) !void {
        var charIdx: usize = self.buffer.len - 1;
        while (charIdx >= 0) : (charIdx -= 1) {
            if (!isWhitespace(self.*, charIdx)) {
                const newBuffer = try self.allocator.alloc(u8, charIdx + 1);
                for (0..charIdx + 1) |index| {
                    newBuffer[index] = self.buffer[index];
                }
                self.allocator.free(self.buffer);
                self.buffer = newBuffer;
                return;
            }
        }
    }

    pub fn trimLeft(self: *String) !void {
        for (0..self.buffer.len) |charIdx| {
            if (!isWhitespace(self.*, charIdx)) {
                const newBuffer = try self.allocator.alloc(u8, self.buffer.len - (charIdx));
                for (charIdx..self.buffer.len) |index| {
                    newBuffer[index - charIdx] = self.buffer[index];
                }
                self.allocator.free(self.buffer);
                self.buffer = newBuffer;
                return;
            }
        }
    }

    pub fn equals(self: String, other: String) bool {
        return std.mem.eql(u8, self.buffer, other.buffer);
    }

    pub fn contains(self: String, text: []const u8) bool {
        var doesContain = false;
        for (0.., self.buffer) |index, item| {
            if (item == text[0]) {
                if (std.mem.eql(u8, self.buffer[index .. index + text.len], text)) {
                    doesContain = true;
                }
            }
        }
        return doesContain;
    }

    pub fn find(self: String, text: []const u8) !StringFind {
        var foundItems = StringFind.init(self.allocator);
        if (self.contains(text)) {
            for (0.., self.buffer) |index, item| {
                if (item == text[0]) {
                    if (std.mem.eql(u8, self.buffer[index .. index + text.len], text)) {
                        const stringItem = try init(self.allocator, text);
                        try foundItems.list.append(stringItem);
                    }
                }
            }
        }
        return foundItems;
    }

    pub fn countOccurrences(self: String, text: []const u8) !usize {
        var foundItems = try self.find(text);
        const count = foundItems.list.items.len;
        foundItems.deinit();
        return count;
    }

    pub fn uppercase(self: *String) void {
        for (0..self.buffer.len) |index| {
            self.buffer[index] = std.ascii.toUpper(self.buffer[index]);
        }
    }
};

const expect = std.testing.expect;
test "concat" {
    var s = try String.init(std.testing.allocator, "ab;cd");
    defer s.deinit();
    try s.concat(";ef");
    var result = try String.init(std.testing.allocator, "ab;cd;ef");
    defer result.deinit();
    try expect(s.equals(result));
}

test "split" {
    var s = try String.init(std.testing.allocator, "ab;cd");
    defer s.deinit();
    const split = try s.split(';', std.testing.allocator);
    defer split.deinit();
    var ss = StringSplit.init(std.testing.allocator);
    defer ss.deinit();
    try ss.list.append(try String.init(std.testing.allocator, "ab"));
    try ss.list.append(try String.init(std.testing.allocator, "cd"));
    for (0.., split.list.items) |index, item| {
        try expect(ss.list.items[index].equals(item));
    }
}

test "trimRight" {
    var s = try String.init(std.testing.allocator, "abcd\n  ");
    defer s.deinit();
    try s.trimRight();
    var result = try String.init(std.testing.allocator, "abcd");
    defer result.deinit();
    try expect(s.equals(result));
}

test "trimLeft" {
    var s = try String.init(std.testing.allocator, "\t\tabcd");
    defer s.deinit();
    try s.trimLeft();
    var result = try String.init(std.testing.allocator, "abcd");
    defer result.deinit();
    try expect(s.equals(result));
}

test "contains" {
    var s = try String.init(std.testing.allocator, "\t\tabcd");
    defer s.deinit();
    try expect(s.contains("abc"));
}

test "countOccurrences" {
    var s = try String.init(std.testing.allocator, "\t\tabad");
    defer s.deinit();
    try expect(try s.countOccurrences("a") == 2);
}

test "uppercase" {
    var s = try String.init(std.testing.allocator, "something");
    defer s.deinit();
    var u = try String.init(std.testing.allocator, "SOMETHING");
    defer u.deinit();
    s.uppercase();
    try expect(s.equals(u));
}

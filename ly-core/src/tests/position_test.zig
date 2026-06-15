const std = @import("std");
const testing = std.testing;

// Test position calculations
const Position = struct {
    x: usize,
    y: usize,

    pub fn init(x: usize, y: usize) @This() {
        return .{ .x = x, .y = y };
    }

    pub fn add(self: @This(), other: @This()) @This() {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn addX(self: @This(), dx: usize) @This() {
        return .{ .x = self.x + dx, .y = self.y };
    }

    pub fn addY(self: @This(), dy: usize) @This() {
        return .{ .x = self.x, .y = self.y + dy };
    }

    pub fn invertX(self: @This(), width: usize) @This() {
        return .{ .x = width - self.x, .y = self.y };
    }

    pub fn invertY(self: @This(), height: usize) @This() {
        return .{ .x = self.x, .y = height - self.y };
    }

    pub fn removeX(self: @This(), dx: usize) @This() {
        return .{ .x = self.x -| dx, .y = self.y };
    }

    pub fn removeY(self: @This(), dy: usize) @This() {
        return .{ .x = self.x, .y = self.y -| dy };
    }
};

test "Position init" {
    const pos = Position.init(10, 20);
    try testing.expectEqual(@as(usize, 10), pos.x);
    try testing.expectEqual(@as(usize, 20), pos.y);
}

test "Position add" {
    const pos1 = Position.init(10, 20);
    const pos2 = Position.init(5, 15);
    const result = pos1.add(pos2);
    try testing.expectEqual(@as(usize, 15), result.x);
    try testing.expectEqual(@as(usize, 35), result.y);
}

test "Position addX" {
    const pos = Position.init(10, 20);
    const result = pos.addX(5);
    try testing.expectEqual(@as(usize, 15), result.x);
    try testing.expectEqual(@as(usize, 20), result.y);
}

test "Position addY" {
    const pos = Position.init(10, 20);
    const result = pos.addY(5);
    try testing.expectEqual(@as(usize, 10), result.x);
    try testing.expectEqual(@as(usize, 25), result.y);
}

test "Position invertX" {
    const pos = Position.init(10, 20);
    const result = pos.invertX(80);
    try testing.expectEqual(@as(usize, 70), result.x);
    try testing.expectEqual(@as(usize, 20), result.y);
}

test "Position invertY" {
    const pos = Position.init(10, 20);
    const result = pos.invertY(50);
    try testing.expectEqual(@as(usize, 10), result.x);
    try testing.expectEqual(@as(usize, 30), result.y);
}

test "Position removeX" {
    const pos = Position.init(10, 20);
    const result = pos.removeX(5);
    try testing.expectEqual(@as(usize, 5), result.x);
    try testing.expectEqual(@as(usize, 20), result.y);
}

test "Position removeY" {
    const pos = Position.init(10, 20);
    const result = pos.removeY(5);
    try testing.expectEqual(@as(usize, 10), result.x);
    try testing.expectEqual(@as(usize, 15), result.y);
}

test "Position removeX saturating" {
    const pos = Position.init(3, 20);
    const result = pos.removeX(5);
    try testing.expectEqual(@as(usize, 0), result.x); // Saturates to 0
}

test "Position removeY saturating" {
    const pos = Position.init(10, 3);
    const result = pos.removeY(5);
    try testing.expectEqual(@as(usize, 0), result.y); // Saturates to 0
}

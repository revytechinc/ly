const std = @import("std");
const testing = std.testing;

// Test Input enum movement
const Input = enum {
    info_line,
    session,
    login,
    password,

    pub fn move(self: *Input, reverse: bool, wrap: bool) void {
        const maxNum = @typeInfo(Input).@"enum".fields.len - 1;
        const selfNum = @intFromEnum(self.*);
        if (reverse) {
            if (wrap) {
                self.* = @enumFromInt(selfNum -% 1);
            } else if (selfNum != 0) {
                self.* = @enumFromInt(selfNum - 1);
            }
        } else {
            if (wrap) {
                self.* = @enumFromInt(selfNum +% 1);
            } else if (selfNum != maxNum) {
                self.* = @enumFromInt(selfNum + 1);
            }
        }
    }
};

test "Input move forward" {
    var input: Input = .info_line;
    input.move(false, false);
    try testing.expect(input == .session);

    input.move(false, false);
    try testing.expect(input == .login);

    input.move(false, false);
    try testing.expect(input == .password);
}

test "Input move forward stops at end" {
    var input: Input = .password;
    input.move(false, false);
    try testing.expect(input == .password); // Should not move past end
}

test "Input move backward" {
    var input: Input = .password;
    input.move(true, false);
    try testing.expect(input == .login);

    input.move(true, false);
    try testing.expect(input == .session);

    input.move(true, false);
    try testing.expect(input == .info_line);
}

test "Input move backward stops at start" {
    var input: Input = .info_line;
    input.move(true, false);
    try testing.expect(input == .info_line); // Should not move past start
}

test "Input move forward with wrap" {
    var input: Input = .password;
    input.move(false, true);
    try testing.expect(input == .info_line); // Wraps to start
}

test "Input move backward with wrap" {
    var input: Input = .info_line;
    input.move(true, true);
    try testing.expect(input == .password); // Wraps to end
}

// Test Animation enum
const Animation = enum {
    none,
    doom,
    matrix,
    colormix,
    gameoflife,
    dur_file,
};

test "Animation enum values" {
    try testing.expectEqual(@as(u16, 0), @intFromEnum(Animation.none));
    try testing.expectEqual(@as(u16, 1), @intFromEnum(Animation.doom));
    try testing.expectEqual(@as(u16, 2), @intFromEnum(Animation.matrix));
    try testing.expectEqual(@as(u16, 3), @intFromEnum(Animation.colormix));
    try testing.expectEqual(@as(u16, 4), @intFromEnum(Animation.gameoflife));
    try testing.expectEqual(@as(u16, 5), @intFromEnum(Animation.dur_file));
}

// Test DisplayServer enum
const DisplayServer = enum {
    wayland,
    shell,
    xinitrc,
    x11,
    custom,
};

test "DisplayServer enum values" {
    try testing.expectEqual(@as(u16, 0), @intFromEnum(DisplayServer.wayland));
    try testing.expectEqual(@as(u16, 1), @intFromEnum(DisplayServer.shell));
    try testing.expectEqual(@as(u16, 2), @intFromEnum(DisplayServer.xinitrc));
    try testing.expectEqual(@as(u16, 3), @intFromEnum(DisplayServer.x11));
    try testing.expectEqual(@as(u16, 4), @intFromEnum(DisplayServer.custom));
}

// Test ViMode enum
const ViMode = enum {
    normal,
    insert,
};

test "ViMode enum values" {
    try testing.expectEqual(@as(u16, 0), @intFromEnum(ViMode.normal));
    try testing.expectEqual(@as(u16, 1), @intFromEnum(ViMode.insert));
}

// Test Bigclock enum
const Bigclock = enum {
    none,
    en,
    fa,
};

test "Bigclock enum values" {
    try testing.expectEqual(@as(u16, 0), @intFromEnum(Bigclock.none));
    try testing.expectEqual(@as(u16, 1), @intFromEnum(Bigclock.en));
    try testing.expectEqual(@as(u16, 2), @intFromEnum(Bigclock.fa));
}

// Test DurOffsetAlignment enum
const DurOffsetAlignment = enum {
    topleft,
    topcenter,
    topright,
    centerleft,
    center,
    centerright,
    bottomleft,
    bottomcenter,
    bottomright,
};

test "DurOffsetAlignment enum count" {
    const fieldCount = @typeInfo(DurOffsetAlignment).@"enum".fields.len;
    try testing.expectEqual(@as(u16, 9), fieldCount);
}

const std = @import("std");
const testing = std.testing;
const interop = @import("ly-core").interop;
const UidRange = @import("ly-core").UidRange;

test "UidRange default values" {
    const range = UidRange{};
    try testing.expectEqual(@as(std.posix.uid_t, 0), range.uid_min);
    try testing.expectEqual(@as(std.posix.uid_t, 0), range.uid_max);
}

test "UidRange custom values" {
    const range = UidRange{
        .uid_min = 1000,
        .uid_max = 60000,
    };
    try testing.expectEqual(@as(std.posix.uid_t, 1000), range.uid_min);
    try testing.expectEqual(@as(std.posix.uid_t, 60000), range.uid_max);
}

test "supportsUnicode on supported platforms" {
    const result = interop.supportsUnicode();
    switch (@import("builtin").os.tag) {
        .linux, .freebsd => try testing.expect(result),
        else => {}, // Other OSes may or may not support unicode
    }
}

test "isError with signed integers" {
    // For signed integers, isError returns true if result < 0
    try testing.expect(interop.isError(@as(i32, -1)));
    try testing.expect(interop.isError(@as(i32, -100)));
    try testing.expect(!interop.isError(@as(i32, 0)));
    try testing.expect(!interop.isError(@as(i32, 1)));
    try testing.expect(!interop.isError(@as(i32, 100)));
}

test "isError with c_int" {
    try testing.expect(interop.isError(@as(c_int, -1)));
    try testing.expect(!interop.isError(@as(c_int, 0)));
    try testing.expect(!interop.isError(@as(c_int, 1)));
}

test "TimeOfDay struct initialization" {
    const tod = interop.TimeOfDay{
        .seconds = 12345,
        .microseconds = 67890,
    };
    try testing.expectEqual(@as(i64, 12345), tod.seconds);
    try testing.expectEqual(@as(i64, 67890), tod.microseconds);
}

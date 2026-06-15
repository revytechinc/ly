const std = @import("std");
const testing = std.testing;
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

test "UidRange with FreeBSD defaults" {
    const range = UidRange{
        .uid_min = 1000,
        .uid_max = 32000,
    };
    try testing.expectEqual(@as(std.posix.uid_t, 1000), range.uid_min);
    try testing.expectEqual(@as(std.posix.uid_t, 32000), range.uid_max);
}

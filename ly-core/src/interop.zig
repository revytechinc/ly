const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const UidRange = @import("UidRange.zig");
const pwd = @import("pwd");
const stdlib = @import("stdlib");
const unistd = @import("unistd");
const grp = @import("grp");
const system_time = @import("system_time");
const time = @import("time");

pub const pam = @import("pam");
pub const utmp = @import("utmp");
// Exists for X11 support only
pub const xcb = @import("xcb");

// errno is only needed for FreeBSD's isError implementation
const errno = if (builtin.os.tag == .freebsd) @import("errno") else struct { pub fn errno() callconv(.c) u16 { return 0; } };

pub const TimeOfDay = struct {
    seconds: i64,
    microseconds: i64,
};

pub const LockState = struct {
    numlock: bool,
    capslock: bool,
};

pub const UsernameEntry = struct {
    username: ?[]const u8,
    uid: std.posix.uid_t,
    gid: std.posix.gid_t,
    home: ?[]const u8,
    shell: ?[]const u8,
    passwd_struct: [*c]pwd.passwd,
};

pub fn isError(result: anytype) bool {
    if (@typeInfo(@TypeOf(result)).int.signedness == .signed) {
        return result < 0;
    }
    return switch (builtin.os.tag) {
        .linux => std.os.linux.errno(result) != .SUCCESS,
        .freebsd => errno.errno() != 0,
        else => @compileError("interop.isError() not implemented for current target!"),
    };
}

pub fn supportsUnicode() bool {
    return builtin.os.tag == .linux or builtin.os.tag == .freebsd;
}

pub fn timeAsString(io: std.Io, buf: [:0]u8, format: [:0]const u8) []u8 {
    const timer: isize = @intCast(std.Io.Timestamp.now(io, .real).toSeconds());
    const tm_info = time.localtime(&timer);
    const len = time.strftime(buf, buf.len, format, tm_info);

    return buf[0..len];
}

pub fn getTimeOfDay() !TimeOfDay {
    var tv: system_time.timeval = undefined;
    const status = system_time.gettimeofday(&tv, null);

    if (status != 0) return error.FailedToGetTimeOfDay;

    return .{
        .seconds = @intCast(tv.tv_sec),
        .microseconds = @intCast(tv.tv_usec),
    };
}

pub fn getActiveTty(allocator: std.mem.Allocator, io: std.Io, use_kmscon_vt: bool) !u8 {
    return switch (builtin.os.tag) {
        .linux => linuxGetActiveTty(allocator, io, use_kmscon_vt),
        .freebsd => freebsdGetActiveTty(allocator, io, use_kmscon_vt),
        else => @compileError("Unsupported OS"),
    };
}

pub fn switchTty(tty: u8) !void {
    try switch (builtin.os.tag) {
        .linux => linuxActivateTty(tty),
        .freebsd => freebsdActivateTty(tty),
        else => @compileError("Unsupported OS"),
    };
    try switch (builtin.os.tag) {
        .linux => linuxWaitActiveTty(tty),
        .freebsd => freebsdWaitActiveTty(tty),
        else => @compileError("Unsupported OS"),
    };
}

pub fn getLockState() !LockState {
    return switch (builtin.os.tag) {
        .linux => linuxGetLockState(),
        .freebsd => freebsdGetLockState(),
        else => @compileError("Unsupported OS"),
    };
}

pub fn setNumlock(val: bool) !void {
    return switch (builtin.os.tag) {
        .linux => linuxSetNumlock(val),
        .freebsd => freebsdSetNumlock(val),
        else => @compileError("Unsupported OS"),
    };
}

pub fn setUserContext(allocator: std.mem.Allocator, entry: UsernameEntry) !void {
    return switch (builtin.os.tag) {
        .linux => linuxSetUserContext(allocator, entry),
        .freebsd => freebsdSetUserContext(allocator, entry),
        else => @compileError("Unsupported OS"),
    };
}

pub fn setUserShell(entry: *UsernameEntry) void {
    unistd.setusershell();

    const shell = unistd.getusershell();
    entry.shell = std.mem.span(shell);

    unistd.endusershell();
}

pub fn setEnvironmentVariable(allocator: std.mem.Allocator, name: []const u8, value: []const u8, replace: bool) !void {
    const name_z = try allocator.dupeZ(u8, name);
    defer allocator.free(name_z);

    const value_z = try allocator.dupeZ(u8, value);
    defer allocator.free(value_z);

    const status = stdlib.setenv(name_z.ptr, value_z.ptr, @intFromBool(replace));
    if (status != 0) return error.SetEnvironmentVariableFailed;
}

pub fn putEnvironmentVariable(name_and_value: [*c]u8) !void {
    const status = stdlib.putenv(name_and_value);
    if (status != 0) return error.PutEnvironmentVariableFailed;
}

pub fn getNextUsernameEntry() ?UsernameEntry {
    const entry = pwd.getpwent();
    if (entry == null) return null;

    return .{
        .username = if (entry.*.pw_name) |name| std.mem.span(name) else null,
        .uid = @intCast(entry.*.pw_uid),
        .gid = @intCast(entry.*.pw_gid),
        .home = if (entry.*.pw_dir) |dir| std.mem.span(dir) else null,
        .shell = if (entry.*.pw_shell) |shell| std.mem.span(shell) else null,
        .passwd_struct = entry,
    };
}

pub fn getUsernameEntry(username: [:0]const u8) ?UsernameEntry {
    const entry = pwd.getpwnam(username);
    if (entry == null) return null;

    return .{
        .username = if (entry.*.pw_name) |name| std.mem.span(name) else null,
        .uid = @intCast(entry.*.pw_uid),
        .gid = @intCast(entry.*.pw_gid),
        .home = if (entry.*.pw_dir) |dir| std.mem.span(dir) else null,
        .shell = if (entry.*.pw_shell) |shell| std.mem.span(shell) else null,
        .passwd_struct = entry,
    };
}

pub fn closePasswordDatabase() void {
    pwd.endpwent();
}

pub fn getUserIdRange(allocator: std.mem.Allocator, io: std.Io, file_path: []const u8) !UidRange {
    return switch (builtin.os.tag) {
        .linux => linuxGetUserIdRange(allocator, io, file_path),
        .freebsd => freebsdGetUserIdRange(allocator, io, file_path),
        else => @compileError("Unsupported OS"),
    };
}

// ============================================================================
// LINUX IMPLEMENTATIONS
// ============================================================================

comptime {
    if (builtin.os.tag == .linux) {
        // Import Linux-specific headers
        _ = @import("kd");
        _ = @import("vt");
    }
}

const kd = @import("kd");
const vt = @import("vt");

fn linuxActivateTty(tty: u8) !void {
    const status = std.c.ioctl(std.posix.STDIN_FILENO, vt.VT_ACTIVATE, tty);
    if (status != 0) return error.FailedToActivateTty;
}

fn linuxWaitActiveTty(tty: u8) !void {
    const status = std.c.ioctl(std.posix.STDIN_FILENO, vt.VT_WAITACTIVE, tty);
    if (status != 0) return error.FailedToWaitForActiveTty;
}

fn linuxGetLockState() !LockState {
    var led: c_char = undefined;
    const status = std.c.ioctl(std.posix.STDIN_FILENO, kd.KDGKBLED, &led);
    if (status != 0) return error.FailedToGetLockState;

    return .{
        .numlock = (led & kd.K_NUMLOCK) != 0,
        .capslock = (led & kd.K_CAPSLOCK) != 0,
    };
}

fn linuxSetNumlock(val: bool) !void {
    var led: c_char = undefined;
    var status = std.c.ioctl(std.posix.STDIN_FILENO, kd.KDGKBLED, &led);
    if (status != 0) return error.FailedToGetNumlock;

    const numlock = (led & kd.K_NUMLOCK) != 0;
    if (numlock != val) {
        status = std.c.ioctl(std.posix.STDIN_FILENO, kd.KDSETLED, led ^ kd.K_NUMLOCK);
        if (status != 0) return error.FailedToSetNumlock;
    }
}

fn linuxSetUserContext(allocator: std.mem.Allocator, entry: UsernameEntry) !void {
    const username_z = try allocator.dupeZ(u8, entry.username.?);
    defer allocator.free(username_z);

    const status = grp.initgroups(username_z.ptr, @intCast(entry.gid));
    if (status != 0) return error.GroupInitializationFailed;

    if (isError(std.posix.system.setgid(@intCast(entry.gid)))) return error.SetUserGidFailed;
    if (isError(std.posix.system.setuid(@intCast(entry.uid)))) return error.SetUserUidFailed;
}

fn linuxGetActiveTty(allocator: std.mem.Allocator, io: std.Io, use_kmscon_vt: bool) !u8 {
    var file_buffer: [256]u8 = undefined;

    if (use_kmscon_vt) {
        var file = try std.Io.Dir.openFileAbsolute(io, "/sys/class/tty/tty0/active", .{});
        defer file.close(io);

        var reader = file.reader(io, &file_buffer);
        var buffer: [16]u8 = undefined;
        const read = try linuxReadBuffer(&reader.interface, &buffer);

        const tty = buffer[0..(read - 1)];
        return std.fmt.parseInt(u8, tty["tty".len..], 10);
    }

    var tty_major: u16 = undefined;
    var tty_minor: u16 = undefined;

    {
        var file = try std.Io.Dir.openFileAbsolute(io, "/proc/self/stat", .{});
        defer file.close(io);

        var reader = file.reader(io, &file_buffer);
        var buffer: [1024]u8 = undefined;
        const read = try linuxReadBuffer(&reader.interface, &buffer);

        var iterator = std.mem.splitScalar(u8, buffer[0..read], ' ');
        var fields: [52][]const u8 = undefined;
        var index: usize = 0;

        while (iterator.next()) |field| {
            fields[index] = field;
            index += 1;
        }

        const tty_nr = try std.fmt.parseInt(u16, fields[6], 10);
        tty_major = tty_nr / 256;
        tty_minor = tty_nr % 256;
    }

    var directory = try std.Io.Dir.openDirAbsolute(io, "/sys/class/tty", .{ .iterate = true });
    defer directory.close(io);

    var iterator = directory.iterate();
    while (try iterator.next(io)) |entry| {
        const path = try std.fmt.allocPrint(allocator, "/sys/class/tty/{s}/dev", .{entry.name});
        defer allocator.free(path);

        var file = try std.Io.Dir.openFileAbsolute(io, path, .{});
        defer file.close(io);

        var reader = file.reader(io, &file_buffer);
        var buffer: [16]u8 = undefined;
        const read = try linuxReadBuffer(&reader.interface, &buffer);

        var device_iterator = std.mem.splitScalar(u8, buffer[0..(read - 1)], ':');
        const device_major_str = device_iterator.next() orelse continue;
        const device_minor_str = device_iterator.next() orelse continue;

        const device_major = try std.fmt.parseInt(u8, device_major_str, 10);
        const device_minor = try std.fmt.parseInt(u8, device_minor_str, 10);

        if (device_major == tty_major and device_minor == tty_minor) {
            const tty_id_str = entry.name["tty".len..];
            return try std.fmt.parseInt(u8, tty_id_str, 10);
        }
    }

    return error.NoTtyFound;
}

fn linuxReadBuffer(reader: *std.Io.Reader, buffer: []u8) !usize {
    var bytes_read: usize = 0;
    var byte: u8 = try reader.takeByte();

    while (byte != 0 and bytes_read < buffer.len) {
        buffer[bytes_read] = byte;
        bytes_read += 1;
        byte = reader.takeByte() catch break;
    }

    return bytes_read;
}

fn linuxGetUserIdRange(allocator: std.mem.Allocator, io: std.Io, file_path: []const u8) !UidRange {
    const login_defs_file = try std.Io.Dir.cwd().openFile(io, file_path, .{});
    defer login_defs_file.close(io);

    var buffer: [4096]u8 = undefined;
    var reader = login_defs_file.reader(io, &buffer);

    const login_defs_buffer = try reader.interface.allocRemaining(allocator, .unlimited);
    defer allocator.free(login_defs_buffer);

    var iterator = std.mem.splitScalar(u8, login_defs_buffer, '\n');
    var uid_range = UidRange{};
    var uid_min_Found = false;
    var uid_max_Found = false;

    while (iterator.next()) |line| {
        const trimmed_line = std.mem.trim(u8, line, " \n\r\t");

        if (std.mem.startsWith(u8, trimmed_line, "UID_MIN")) {
            uid_range.uid_min = try linuxParseValue(std.posix.uid_t, "UID_MIN", trimmed_line);
            uid_min_Found = true;
        } else if (std.mem.startsWith(u8, trimmed_line, "UID_MAX")) {
            uid_range.uid_max = try linuxParseValue(std.posix.uid_t, "UID_MAX", trimmed_line);
            uid_max_Found = true;
        }
    }

    if (!(uid_min_Found or uid_max_Found)) {
        return error.UidNameNotFound;
    }

    if (!uid_min_Found) {
        uid_range.uid_min = build_options.fallback_uid_min;
    }

    if (!uid_max_Found) {
        uid_range.uid_max = build_options.fallback_uid_max;
    }

    return uid_range;
}

fn linuxParseValue(comptime T: type, name: []const u8, buffer: []const u8) !T {
    var iterator = std.mem.splitAny(u8, buffer, " \t");
    var maybe_value: ?T = null;

    while (iterator.next()) |slice| {
        if (slice.len == 0 or std.mem.eql(u8, slice, name)) continue;
        maybe_value = std.fmt.parseInt(T, slice, 10) catch continue;
    }

    return maybe_value orelse error.ValueNotFound;
}

// ============================================================================
// FREEBSD IMPLEMENTATIONS
// ============================================================================

comptime {
    if (builtin.os.tag == .freebsd) {
        // Import FreeBSD-specific headers
        _ = @import("kbio");
        _ = @import("consio");
    }
}

const kbio = @import("kbio");
const consio = @import("consio");

const FREEBSD_UID_MIN = 1000;
const FREEBSD_UID_MAX = 32000;

fn freebsdActivateTty(tty: u8) !void {
    const status = std.c.ioctl(std.posix.STDIN_FILENO, consio.VT_ACTIVATE, tty);
    if (status != 0) return error.FailedToActivateTty;
}

fn freebsdWaitActiveTty(tty: u8) !void {
    const status = std.c.ioctl(std.posix.STDIN_FILENO, consio.VT_WAITACTIVE, tty);
    if (status != 0) return error.FailedToWaitForActiveTty;
}

fn freebsdGetLockState() !LockState {
    var led: c_int = undefined;
    const status = std.c.ioctl(std.posix.STDIN_FILENO, kbio.KDGETLED, &led);
    if (status != 0) return error.FailedToGetLockState;

    return .{
        .numlock = (led & kbio.LED_NUM) != 0,
        .capslock = (led & kbio.LED_CAP) != 0,
    };
}

fn freebsdSetNumlock(val: bool) !void {
    var led: c_int = undefined;
    var status = std.c.ioctl(std.posix.STDIN_FILENO, kbio.KDGETLED, &led);
    if (status != 0) return error.FailedToGetNumlock;

    const numlock = (led & kbio.LED_NUM) != 0;
    if (numlock != val) {
        status = std.c.ioctl(std.posix.STDIN_FILENO, kbio.KDSETLED, led ^ kbio.LED_NUM);
        if (status != 0) return error.FailedToSetNumlock;
    }
}

fn freebsdSetUserContext(allocator: std.mem.Allocator, entry: UsernameEntry) !void {
    const username_z = try allocator.dupeZ(u8, entry.username.?);
    defer allocator.free(username_z);

    const status = unistd.initgroups(username_z.ptr, @intCast(entry.gid));
    if (status != 0) return error.GroupInitializationFailed;

    const result = pwd.setusercontext(null, entry.passwd_struct, @intCast(entry.uid), pwd.LOGIN_SETALL);
    if (result != 0) return error.SetUserUidFailed;
}

fn freebsdGetActiveTty(_: std.mem.Allocator, _: std.Io, _: bool) !u8 {
    return error.FeatureUnimplemented;
}

fn freebsdGetUserIdRange(_: std.mem.Allocator, _: std.Io, _: []const u8) !UidRange {
    return .{
        .uid_min = FREEBSD_UID_MIN,
        .uid_max = FREEBSD_UID_MAX,
    };
}

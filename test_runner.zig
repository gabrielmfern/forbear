// Custom test runner for Forbear.
//
// Features:
//   - Real-time feedback as tests run
//   - Captured test output (std.debug.print / stderr) shown indented per test
//   - Pass/fail/skip/leak counts with color coding
//   - Per-test timing
//   - Slowest tests summary
//   - Memory leak detection via std.testing.allocator
//   - Custom panic handler that reports which test panicked
//   - Environment variable controls:
//       TEST_VERBOSE=true    (default) show each test name and timing
//       TEST_FAIL_FIRST=true stop after the first failure
//       TEST_FILTER=pattern  only run tests whose name contains the pattern
//
// Works on Linux, macOS, and Windows.

const std = @import("std");
const builtin = @import("builtin");
const native_os = builtin.os.tag;
const windows = std.os.windows;

const Allocator = std.mem.Allocator;
const File = std.fs.File;

const border = "=" ** 80;
const thinBorder = "-" ** 80;

/// Used by the custom panic handler to report which test panicked.
var currentTest: ?[]const u8 = null;

/// The real stderr, saved before any redirection.
var realStderr: ?File = null;

pub fn main() !void {
    var mem: [8192]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&mem);
    const allocator = fba.allocator();

    const env = Env.init(allocator);
    defer env.deinit(allocator);

    const numSlowestToTrack = 5;
    var slowest = SlowTracker.init(allocator, numSlowestToTrack);
    defer slowest.deinit();

    var pass: usize = 0;
    var fail: usize = 0;
    var skip: usize = 0;
    var leak: usize = 0;

    // Save the real stderr for later restoration.
    realStderr = StderrCapture.duplicateStderr();

    // Clear current line (write to real stderr)
    writeToRealStderr("\r\x1b[0K");

    // Phase 1: Run setup functions
    for (builtin.test_functions) |t| {
        if (isSetup(t)) {
            t.func() catch |err| {
                printToRealStderr("\nsetup \"{s}\" failed: {}\n", .{ t.name, err });
                return err;
            };
        }
    }

    // Phase 2: Run tests
    if (env.verbose) {
        writeToRealStderr("\n");
    }

    for (builtin.test_functions) |t| {
        if (isSetup(t) or isTeardown(t)) {
            continue;
        }

        const isUnnamedTest = isUnnamed(t);
        if (env.filter) |f| {
            if (!isUnnamedTest and std.mem.indexOf(u8, t.name, f) == null) {
                continue;
            }
        }

        const friendlyName = extractFriendlyName(t);
        const modulePath = extractModulePath(t);

        currentTest = friendlyName;
        std.testing.allocator_instance = .{};

        // Redirect stderr to capture test output
        const captureFile = StderrCapture.start();

        slowest.startTiming();
        const result = t.func();
        const nsTaken = slowest.endTiming(friendlyName);
        currentTest = null;

        // Restore stderr and read captured output
        var capturedBuf: [4096]u8 = undefined;
        const captured = StderrCapture.finish(captureFile, &capturedBuf);

        const ms = @as(f64, @floatFromInt(nsTaken)) / 1_000_000.0;

        const leaked = std.testing.allocator_instance.deinit() == .leak;
        if (leaked) {
            leak += 1;
        }

        var status = Status.pass;
        if (result) |_| {
            pass += 1;
        } else |err| switch (err) {
            error.SkipZigTest => {
                skip += 1;
                status = .skip;
            },
            else => {
                status = .fail;
                fail += 1;
            },
        }

        if (leaked and status != .fail) {
            status = .fail;
        }

        if (env.verbose) {
            // Print grouped output per test
            switch (status) {
                .pass => {
                    Printer.status(.pass, "  PASS ", .{});
                    Printer.raw("{s}", .{friendlyName});
                    if (modulePath) |path| {
                        Printer.dim("  ({s})", .{path});
                    }
                    Printer.dim("  {d:.2}ms", .{ms});
                    Printer.raw("\n", .{});
                    printCapturedOutput(captured);
                },
                .skip => {
                    Printer.status(.skip, "  SKIP ", .{});
                    Printer.raw("{s}", .{friendlyName});
                    if (modulePath) |path| {
                        Printer.dim("  ({s})", .{path});
                    }
                    Printer.raw("\n", .{});
                },
                .fail => {
                    Printer.raw("\n", .{});
                    Printer.status(.fail, "  FAIL ", .{});
                    Printer.raw("{s}", .{friendlyName});
                    if (modulePath) |path| {
                        Printer.dim("  ({s})", .{path});
                    }
                    Printer.dim("  {d:.2}ms", .{ms});
                    Printer.raw("\n", .{});

                    // Print failure details
                    if (leaked) {
                        Printer.status(.fail, "       Memory leak detected\n", .{});
                    }
                    if (result) |_| {} else |err| switch (err) {
                        error.SkipZigTest => {},
                        else => {
                            Printer.status(.fail, "       Error: {s}\n", .{@errorName(err)});
                            if (@errorReturnTrace()) |trace| {
                                std.debug.dumpStackTrace(trace.*);
                            }
                        },
                    }
                    printCapturedOutput(captured);
                    Printer.raw("\n", .{});
                },
                .text => {},
            }
        } else {
            // Compact dot mode
            Printer.status(status, ".", .{});
        }

        if (status == .fail and env.failFirst) {
            break;
        }
    }

    // Phase 3: Run teardown functions
    for (builtin.test_functions) |t| {
        if (isTeardown(t)) {
            t.func() catch |err| {
                printToRealStderr("\nteardown \"{s}\" failed: {}\n", .{ t.name, err });
                return err;
            };
        }
    }

    // Summary
    const totalTests = pass + fail + skip;
    const totalRan = pass + fail;
    const summaryStatus: Status = if (fail == 0) .pass else .fail;

    Printer.raw("\n{s}\n", .{thinBorder});

    if (fail == 0) {
        Printer.status(.pass, "  All {d} test{s} passed", .{ pass, if (pass != 1) @as([]const u8, "s") else "" });
    } else {
        Printer.status(.fail, "  {d} of {d} test{s} failed", .{ fail, totalRan, if (totalRan != 1) @as([]const u8, "s") else "" });
        Printer.raw("  |  ", .{});
        Printer.status(.pass, "{d} passed", .{pass});
    }

    if (skip > 0) {
        Printer.raw("  |  ", .{});
        Printer.status(.skip, "{d} skipped", .{skip});
    }
    if (leak > 0) {
        Printer.raw("  |  ", .{});
        Printer.status(.fail, "{d} leaked", .{leak});
    }

    Printer.dim("  ({d} total)\n", .{totalTests});
    Printer.raw("{s}\n", .{thinBorder});

    // Slowest tests
    Printer.raw("\n", .{});
    slowest.display();
    Printer.raw("\n", .{});

    std.posix.exit(if (summaryStatus == .pass) 0 else 1);
}

// ---------------------------------------------------------------------------
// Stderr capture via fd/handle redirection
// ---------------------------------------------------------------------------

const StderrCapture = struct {
    /// Duplicates the current stderr file descriptor / handle and returns it.
    fn duplicateStderr() ?File {
        if (native_os == .windows) {
            const stderr_handle = windows.peb().ProcessParameters.hStdError;
            var duplicated: windows.HANDLE = undefined;
            const current_process = windows.GetCurrentProcess();
            const DUPLICATE_SAME_ACCESS = 0x00000002;
            const rc = windows.kernel32.DuplicateHandle(
                current_process,
                stderr_handle,
                current_process,
                &duplicated,
                0,
                windows.FALSE,
                DUPLICATE_SAME_ACCESS,
            );
            if (rc == windows.FALSE) return null;
            return .{ .handle = duplicated };
        } else {
            const duped = std.posix.dup(std.posix.STDERR_FILENO) catch return null;
            return .{ .handle = duped };
        }
    }

    /// Redirects stderr to a temporary capture file and returns it (or null on failure).
    fn start() ?File {
        if (realStderr == null) return null;

        const captureFile = createCaptureFile() orelse return null;

        if (native_os == .windows) {
            // On Windows, std.debug.print reads hStdError from the PEB each time.
            // Swap it to point to our capture file.
            windows.peb().ProcessParameters.hStdError = captureFile.handle;
        } else {
            // On POSIX, redirect fd 2 to the capture file.
            std.posix.dup2(captureFile.handle, std.posix.STDERR_FILENO) catch {
                captureFile.close();
                return null;
            };
        }

        return captureFile;
    }

    /// Restores stderr and returns the captured content as a slice (or empty).
    fn finish(captureFile: ?File, buf: []u8) []const u8 {
        const file = captureFile orelse return "";
        const saved = realStderr orelse return "";

        // Restore the real stderr
        if (native_os == .windows) {
            windows.peb().ProcessParameters.hStdError = saved.handle;
        } else {
            std.posix.dup2(saved.handle, std.posix.STDERR_FILENO) catch {};
        }

        // Seek to beginning and read what was captured
        file.seekTo(0) catch {
            file.close();
            return "";
        };

        const bytesRead = file.read(buf) catch 0;
        file.close();

        return buf[0..bytesRead];
    }

    fn createCaptureFile() ?File {
        if (native_os == .linux) {
            // Anonymous in-memory file — ideal on Linux, avoids temp file I/O
            const fd = std.posix.memfd_create("test_capture", 0) catch return null;
            return .{ .handle = fd };
        }

        // Cross-platform fallback: create a temp file in .zig-cache/tmp/.
        // This directory is used by Zig's own test infrastructure and is
        // expected to exist during builds.
        const cwd = std.fs.cwd();
        var cache_dir = cwd.makeOpenPath(".zig-cache" ++ std.fs.path.sep_str ++ "tmp", .{}) catch return null;
        defer cache_dir.close();

        // Generate a unique filename using random bytes.
        var random_bytes: [8]u8 = undefined;
        std.crypto.random.bytes(&random_bytes);
        var name_buf: [24]u8 = undefined;
        const encoded = std.fs.base64_encoder.encode(&name_buf, &random_bytes);

        const file = cache_dir.createFile(encoded, .{ .read = true }) catch return null;

        // Delete the directory entry immediately; the file stays alive as long
        // as the handle is open. On Windows, deleteFile may fail (file is open),
        // but that's acceptable — the .zig-cache/tmp/ directory is ephemeral.
        cache_dir.deleteFile(encoded) catch {};

        return file;
    }
};

/// Prints captured test output, indented and dimmed, under the test line.
fn printCapturedOutput(captured: []const u8) void {
    const trimmed = std.mem.trimRight(u8, captured, " \t\n\r");
    if (trimmed.len == 0) return;

    var lineIt = std.mem.splitScalar(u8, trimmed, '\n');
    while (lineIt.next()) |line| {
        Printer.dim("       | {s}\n", .{line});
    }
}

// ---------------------------------------------------------------------------
// Printer — always writes to the *real* stderr
// ---------------------------------------------------------------------------

/// Formats and writes directly to the real stderr, bypassing any redirection.
fn printToRealStderr(comptime format: []const u8, args: anytype) void {
    var buf: [4096]u8 = undefined;
    const formatted = std.fmt.bufPrint(&buf, format, args) catch return;
    writeToRealStderr(formatted);
}

fn writeToRealStderr(msg: []const u8) void {
    const file = realStderr orelse File.stderr();
    _ = file.write(msg) catch {};
}

const Printer = struct {
    fn raw(comptime format: []const u8, args: anytype) void {
        printToRealStderr(format, args);
    }

    fn status(s: Status, comptime format: []const u8, args: anytype) void {
        const code = switch (s) {
            .pass => "\x1b[32m",
            .fail => "\x1b[31m",
            .skip => "\x1b[33m",
            .text => "",
        };
        if (code.len > 0) {
            writeToRealStderr(code);
        }
        printToRealStderr(format, args);
        if (code.len > 0) {
            writeToRealStderr("\x1b[0m");
        }
    }

    fn dim(comptime format: []const u8, args: anytype) void {
        writeToRealStderr("\x1b[2m");
        printToRealStderr(format, args);
        writeToRealStderr("\x1b[0m");
    }
};

const Status = enum {
    pass,
    fail,
    skip,
    text,
};

// ---------------------------------------------------------------------------
// Slow test tracker
// ---------------------------------------------------------------------------

const SlowTracker = struct {
    const SlowestQueue = std.PriorityDequeue(TestInfo, void, compareTiming);

    max: usize,
    slowest: SlowestQueue,
    timer: std.time.Timer,

    const TestInfo = struct {
        ns: u64,
        name: []const u8,
    };

    fn init(allocator: Allocator, count: u32) SlowTracker {
        const timer = std.time.Timer.start() catch @panic("failed to start timer");
        var queue = SlowestQueue.init(allocator, {});
        queue.ensureTotalCapacity(count) catch @panic("OOM");
        return .{
            .max = count,
            .timer = timer,
            .slowest = queue,
        };
    }

    fn deinit(self: SlowTracker) void {
        self.slowest.deinit();
    }

    fn startTiming(self: *SlowTracker) void {
        self.timer.reset();
    }

    fn endTiming(self: *SlowTracker, testName: []const u8) u64 {
        var timer = self.timer;
        const ns = timer.lap();
        var queue = &self.slowest;

        if (queue.count() < self.max) {
            queue.add(TestInfo{ .ns = ns, .name = testName }) catch @panic("failed to track test timing");
            return ns;
        }

        const fastestOfSlow = queue.peekMin() orelse unreachable;
        if (fastestOfSlow.ns > ns) {
            return ns;
        }

        _ = queue.removeMin();
        queue.add(TestInfo{ .ns = ns, .name = testName }) catch @panic("failed to track test timing");
        return ns;
    }

    fn display(self: *SlowTracker) void {
        var queue = self.slowest;
        const count = queue.count();

        Printer.dim("  Slowest {d} test{s}:\n", .{ count, if (count != 1) @as([]const u8, "s") else "" });

        while (queue.removeMinOrNull()) |info| {
            const ms = @as(f64, @floatFromInt(info.ns)) / 1_000_000.0;
            Printer.dim("    {d:.2}ms\t{s}\n", .{ ms, info.name });
        }
    }

    fn compareTiming(_: void, a: TestInfo, b: TestInfo) std.math.Order {
        return std.math.order(a.ns, b.ns);
    }
};

// ---------------------------------------------------------------------------
// Environment config
// ---------------------------------------------------------------------------

const Env = struct {
    verbose: bool,
    failFirst: bool,
    filter: ?[]const u8,

    fn init(allocator: Allocator) Env {
        return .{
            .verbose = readEnvBool(allocator, "TEST_VERBOSE", true),
            .failFirst = readEnvBool(allocator, "TEST_FAIL_FIRST", false),
            .filter = readEnv(allocator, "TEST_FILTER"),
        };
    }

    fn deinit(self: Env, allocator: Allocator) void {
        if (self.filter) |f| {
            allocator.free(f);
        }
    }

    fn readEnv(allocator: Allocator, key: []const u8) ?[]const u8 {
        return std.process.getEnvVarOwned(allocator, key) catch |err| {
            if (err == error.EnvironmentVariableNotFound) {
                return null;
            }
            std.log.warn("failed to get env var {s}: {}", .{ key, err });
            return null;
        };
    }

    fn readEnvBool(allocator: Allocator, key: []const u8, default: bool) bool {
        const value = readEnv(allocator, key) orelse return default;
        defer allocator.free(value);
        return std.ascii.eqlIgnoreCase(value, "true");
    }
};

// ---------------------------------------------------------------------------
// Panic handler
// ---------------------------------------------------------------------------

pub const panic = std.debug.FullPanic(struct {
    pub fn panicFn(msg: []const u8, firstTraceAddr: ?usize) noreturn {
        // Restore real stderr before panicking so output is visible
        if (realStderr) |saved| {
            if (native_os == .windows) {
                windows.peb().ProcessParameters.hStdError = saved.handle;
            } else {
                std.posix.dup2(saved.handle, std.posix.STDERR_FILENO) catch {};
            }
        }
        if (currentTest) |ct| {
            std.debug.print("\n\x1b[31m{s}\npanic running \"{s}\"\n{s}\x1b[0m\n", .{ border, ct, border });
        }
        std.debug.defaultPanic(msg, firstTraceAddr);
    }
}.panicFn);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn extractFriendlyName(t: std.builtin.TestFn) []const u8 {
    const name = t.name;
    var it = std.mem.splitScalar(u8, name, '.');
    while (it.next()) |value| {
        if (std.mem.eql(u8, value, "test")) {
            const rest = it.rest();
            if (rest.len > 0) return rest;
            break;
        }
    }
    return name;
}

fn extractModulePath(t: std.builtin.TestFn) ?[]const u8 {
    const name = t.name;
    const marker = std.mem.indexOf(u8, name, ".test") orelse return null;
    if (marker == 0) return null;
    return name[0..marker];
}

fn isUnnamed(t: std.builtin.TestFn) bool {
    const marker = ".test_";
    const testName = t.name;
    const index = std.mem.indexOf(u8, testName, marker) orelse return false;
    _ = std.fmt.parseInt(u32, testName[index + marker.len ..], 10) catch return false;
    return true;
}

fn isSetup(t: std.builtin.TestFn) bool {
    return std.mem.endsWith(u8, t.name, "tests:beforeAll");
}

fn isTeardown(t: std.builtin.TestFn) bool {
    return std.mem.endsWith(u8, t.name, "tests:afterAll");
}

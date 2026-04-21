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

// kernel32 exports removed from Zig 0.16 stdlib, declared here for Windows builds
const Win32 = if (native_os == .windows) struct {
    pub extern "kernel32" fn DuplicateHandle(
        hSourceProcessHandle: windows.HANDLE,
        hSourceHandle: windows.HANDLE,
        hTargetProcessHandle: windows.HANDLE,
        lpTargetHandle: *windows.HANDLE,
        dwDesiredAccess: u32,
        bInheritHandle: windows.BOOL,
        dwOptions: u32,
    ) callconv(.c) windows.BOOL;
    pub extern "kernel32" fn AddVectoredExceptionHandler(
        First: u32,
        Handler: *const fn (*windows.EXCEPTION_POINTERS) callconv(.winapi) c_long,
    ) callconv(.c) ?*anyopaque;
    pub extern "kernel32" fn WriteFile(
        hFile: windows.HANDLE,
        lpBuffer: [*]const u8,
        nNumberOfBytesToWrite: u32,
        lpNumberOfBytesWritten: ?*u32,
        lpOverlapped: ?*anyopaque,
    ) callconv(.c) windows.BOOL;
} else struct {};

const Allocator = std.mem.Allocator;
const File = std.Io.File;

const border = "=" ** 80;
const thinBorder = "-" ** 80;
const childTestEnv = "FORBEAR_TEST_RUNNER_CASE";
const childExitSkip: u8 = 10;
const childExitFail: u8 = 11;
const childExitLeak: u8 = 12;
const childExitFailLeak: u8 = 13;
const childMaxOutputBytes = 1024 * 1024;

/// Used by the custom panic handler to report which test panicked.
var currentTest: ?[]const u8 = null;

/// The real stderr, saved before any redirection.
var realStderr: ?File = null;

/// The segfault/exception handlers that Zig installed before we wrapped them.
var priorCrashHandlers: ?CrashOutput.PriorHandlers = null;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Save the real stderr for later restoration.
    realStderr = StderrCapture.duplicateStderr();

    const singleTest = if (std.c.getenv(childTestEnv)) |ptr| std.mem.sliceTo(ptr, 0) else null;

    const exitCode = if (singleTest) |testName| blk: {
        CrashOutput.install();
        break :blk try runSingleTestProcess(testName);
    } else try runParentProcess(allocator);

    std.process.exit(exitCode);
}

const Term = union(enum) {
    Exited: u8,
    Signal: u32,
    Stopped: u32,
    Unknown: u32,
};

const ChildOutcome = struct {
    status: Status,
    leaked: bool,
    output: []const u8,
    unexpectedTerm: ?Term,
};

fn runParentProcess(allocator: Allocator) !u8 {
    const env = Env.init(allocator);
    defer env.deinit(allocator);

    const numSlowestToTrack = 5;
    var slowest = SlowTracker.init(allocator, numSlowestToTrack);
    defer slowest.deinit(allocator);

    var pass: usize = 0;
    var fail: usize = 0;
    var skip: usize = 0;
    var leak: usize = 0;

    writeToRealStderr("\r\x1b[0K");

    if (env.verbose) {
        writeToRealStderr("\n");
    }

    for (builtin.test_functions) |t| {
        if (isSetup(t) or isTeardown(t)) {
            continue;
        }

        const isUnnamedTest = isUnnamed(t);
        if (env.filter) |f| {
            if (!isUnnamedTest and std.mem.indexOfPos(u8, t.name, 0, f) == null) {
                continue;
            }
        }

        const friendlyName = extractFriendlyName(t);
        const modulePath = extractModulePath(t);

        var shouldStop = false;
        {
            var testArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer testArena.deinit();
            const testAllocator = testArena.allocator();

            // Child env/output allocations live only for this test. Printing
            // happens inside this scope so the arena can reclaim everything at
            // once after the result has been rendered.
            slowest.startTiming();
            const outcome = try runTestInChildProcess(testAllocator, t.name);
            const nsTaken = slowest.endTiming(allocator, friendlyName);
            const ms = @as(f64, @floatFromInt(nsTaken)) / 1_000_000.0;

            if (outcome.leaked) {
                leak += 1;
            }

            switch (outcome.status) {
                .pass => pass += 1,
                .skip => skip += 1,
                .fail => fail += 1,
                .text => unreachable,
            }

            if (env.verbose) {
                switch (outcome.status) {
                    .pass => {
                        Printer.status(.pass, "  PASS ", .{});
                        Printer.raw("{s}", .{friendlyName});
                        if (modulePath) |path| {
                            Printer.dim("  ({s})", .{path});
                        }
                        Printer.dim("  {d:.2}ms", .{ms});
                        Printer.raw("\n", .{});
                        printCapturedOutput(outcome.output);
                    },
                    .skip => {
                        Printer.status(.skip, "  SKIP ", .{});
                        Printer.raw("{s}", .{friendlyName});
                        if (modulePath) |path| {
                            Printer.dim("  ({s})", .{path});
                        }
                        Printer.raw("\n", .{});
                        printCapturedOutput(outcome.output);
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

                        if (outcome.leaked) {
                            Printer.status(.fail, "       Memory leak detected\n", .{});
                        }
                        if (outcome.unexpectedTerm) |term| {
                            Printer.status(.fail, "       {s}\n", .{describeChildTerm(term)});
                        }
                        printCapturedOutput(outcome.output);
                        Printer.raw("\n", .{});
                    },
                    .text => unreachable,
                }
            } else {
                Printer.status(outcome.status, ".", .{});
            }

            shouldStop = outcome.status == .fail and env.failFirst;
        }

        if (shouldStop) {
            break;
        }
    }

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

    Printer.raw("\n", .{});
    slowest.display(allocator);
    Printer.raw("\n", .{});

    return if (summaryStatus == .pass) 0 else 1;
}

fn runSingleTestProcess(selectedTestName: []const u8) !u8 {
    for (builtin.test_functions) |t| {
        if (isSetup(t)) {
            t.func() catch |err| {
                std.debug.print("setup \"{s}\" failed: {}\n", .{ t.name, err });
                return childExitFail;
            };
        }
    }

    for (builtin.test_functions) |t| {
        if (isSetup(t) or isTeardown(t)) {
            continue;
        }
        if (!std.mem.eql(u8, t.name, selectedTestName)) {
            continue;
        }

        const friendlyName = extractFriendlyName(t);
        currentTest = friendlyName;
        std.testing.allocator_instance = .{};

        const result = t.func();
        currentTest = null;

        var failed = false;
        var skipped = false;
        const leaked = std.testing.allocator_instance.deinit() == .leak;

        if (result) |_| {} else |err| switch (err) {
            error.SkipZigTest => skipped = true,
            else => {
                failed = true;
                std.debug.print("Error: {s}\n", .{@errorName(err)});
                if (@errorReturnTrace()) |trace| {
                    std.debug.dumpStackTrace(&.{
                        .return_addresses = trace.instruction_addresses[0..trace.index],
                        .skipped = .none,
                    });
                }
            },
        }

        if (leaked) {
            std.debug.print("Memory leak detected\n", .{});
        }

        for (builtin.test_functions) |teardown| {
            if (isTeardown(teardown)) {
                teardown.func() catch |err| {
                    failed = true;
                    std.debug.print("teardown \"{s}\" failed: {}\n", .{ teardown.name, err });
                };
            }
        }

        if (failed) {
            return if (leaked) childExitFailLeak else childExitFail;
        }
        if (leaked) {
            return childExitLeak;
        }
        if (skipped) {
            return childExitSkip;
        }
        return 0;
    }

    std.debug.print("Test not found: {s}\n", .{selectedTestName});
    return childExitFail;
}

fn runTestInChildProcess(allocator: Allocator, testName: []const u8) !ChildOutcome {
    if (native_os == .windows) {
        return error.UnsupportedPlatform;
    }
    return runTestWithFork(allocator, testName);
}

fn runTestWithFork(allocator: Allocator, testName: []const u8) !ChildOutcome {
    var pipefd: [2]std.c.fd_t = undefined;
    if (std.c.pipe(&pipefd) != 0) return error.PipeCreationFailed;
    const readEnd = pipefd[0];
    const writeEnd = pipefd[1];

    const pid = std.c.fork();
    if (pid < 0) return error.ForkFailed;
    if (pid == 0) {
        // Child: wire both stdout and stderr into the pipe, then run the test.
        _ = std.c.close(readEnd);
        _ = std.c.dup2(writeEnd, std.c.STDOUT_FILENO);
        _ = std.c.dup2(writeEnd, std.c.STDERR_FILENO);
        _ = std.c.close(writeEnd);
        // Null out realStderr so the panic handler doesn't try to restore it;
        // fd 2 is already the pipe and that's where we want crash output.
        realStderr = null;
        CrashOutput.install();
        const code = runSingleTestProcess(testName) catch childExitFail;
        std.c._exit(code);
    }

    // Parent: close write end, drain child output, then reap the child.
    _ = std.c.close(writeEnd);

    var outputList: std.ArrayListUnmanaged(u8) = .empty;
    var chunk: [4096]u8 = undefined;
    while (true) {
        const n = std.c.read(readEnd, &chunk, chunk.len);
        if (n <= 0) break;
        outputList.appendSlice(allocator, chunk[0..@intCast(n)]) catch {};
    }
    _ = std.c.close(readEnd);

    var status: c_int = 0;
    if (std.c.waitpid(pid, &status, 0) < 0) return error.WaitpidFailed;
    const output = try outputList.toOwnedSlice(allocator);
    const s: u32 = @bitCast(status);

    if (std.c.W.IFEXITED(s)) {
        const code = std.c.W.EXITSTATUS(s);
        return switch (code) {
            0 => .{ .status = .pass, .leaked = false, .output = output, .unexpectedTerm = null },
            childExitSkip => .{ .status = .skip, .leaked = false, .output = output, .unexpectedTerm = null },
            childExitFail => .{ .status = .fail, .leaked = false, .output = output, .unexpectedTerm = null },
            childExitLeak => .{ .status = .fail, .leaked = true, .output = output, .unexpectedTerm = null },
            childExitFailLeak => .{ .status = .fail, .leaked = true, .output = output, .unexpectedTerm = null },
            else => .{ .status = .fail, .leaked = false, .output = output, .unexpectedTerm = .{ .Exited = code } },
        };
    }
    if (std.c.W.IFSIGNALED(s)) {
        return .{ .status = .fail, .leaked = false, .output = output, .unexpectedTerm = .{ .Signal = @intFromEnum(std.c.W.TERMSIG(s)) } };
    }
    return .{ .status = .fail, .leaked = false, .output = output, .unexpectedTerm = .{ .Unknown = 0 } };
}

fn joinChildOutput(allocator: Allocator, stdout: []const u8, stderr: []const u8) ![]const u8 {
    if (stdout.len == 0) return stderr;
    if (stderr.len == 0) return stdout;
    return std.fmt.allocPrint(allocator, "{s}\n{s}", .{ stdout, stderr });
}

fn describeChildTerm(term: Term) []const u8 {
    return switch (term) {
        .Exited => "Child process exited unexpectedly",
        .Signal => "Child process terminated by signal",
        .Stopped => "Child process was stopped",
        .Unknown => "Child process terminated unexpectedly",
    };
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
            const rc = Win32.DuplicateHandle(
                current_process,
                stderr_handle,
                current_process,
                &duplicated,
                0,
                windows.FALSE,
                DUPLICATE_SAME_ACCESS,
            );
            if (rc == windows.FALSE) return null;
            return .{ .handle = duplicated, .flags = .{ .nonblocking = false } };
        } else {
            const duped = std.c.dup(std.c.STDERR_FILENO);
            if (duped < 0) return null;
            return .{ .handle = duped, .flags = .{ .nonblocking = false } };
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
            if (std.c.dup2(captureFile.handle, std.c.STDERR_FILENO) < 0) {
                captureFile.close();
                return null;
            }
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
            _ = std.c.dup2(saved.handle, std.c.STDERR_FILENO);
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

const CrashOutput = struct {
    const PriorHandlers = switch (native_os) {
        .windows => void,
        else => struct {
            segv: std.c.Sigaction,
            ill: std.c.Sigaction,
            bus: std.c.Sigaction,
            fpe: std.c.Sigaction,
        },
    };

    fn install() void {
        if (realStderr == null) return;

        switch (native_os) {
            .windows => {
                _ = Win32.AddVectoredExceptionHandler(1, handleWindows);
            },
            .linux,
            .macos,
            .ios,
            .tvos,
            .watchos,
            .visionos,
            .freebsd,
            .openbsd,
            .netbsd,
            .illumos,
            => installPosix(),
            else => {},
        }
    }

    fn restoreRealStderr() void {
        if (realStderr) |saved| {
            if (native_os == .windows) {
                windows.peb().ProcessParameters.hStdError = saved.handle;
            } else {
                _ = std.c.dup2(saved.handle, std.c.STDERR_FILENO);
            }
        }
    }

    fn installPosix() void {
        var segv: std.c.Sigaction = undefined;
        var ill: std.c.Sigaction = undefined;
        var bus: std.c.Sigaction = undefined;
        var fpe: std.c.Sigaction = undefined;

        var mask: std.c.sigset_t = undefined;
        _ = std.c.sigemptyset(&mask);

        const act = std.c.Sigaction{
            .handler = .{ .sigaction = handlePosix },
            .mask = mask,
            .flags = std.c.SA.SIGINFO | std.c.SA.RESTART | std.c.SA.RESETHAND,
        };

        _ = std.c.sigaction(std.c.SIG.SEGV, &act, &segv);
        _ = std.c.sigaction(std.c.SIG.ILL, &act, &ill);
        _ = std.c.sigaction(std.c.SIG.BUS, &act, &bus);
        _ = std.c.sigaction(std.c.SIG.FPE, &act, &fpe);

        priorCrashHandlers = .{
            .segv = segv,
            .ill = ill,
            .bus = bus,
            .fpe = fpe,
        };
    }

    fn posixHandlerForSignal(sig: std.c.SIG) ?std.c.Sigaction {
        const previous = priorCrashHandlers orelse return null;
        return switch (sig) {
            .SEGV => previous.segv,
            .ILL => previous.ill,
            .BUS => previous.bus,
            .FPE => previous.fpe,
            else => null,
        };
    }

    fn handlePosix(sig: std.c.SIG, info: *const std.c.siginfo_t, ctx_ptr: ?*anyopaque) callconv(.c) void {
        restoreRealStderr();

        const previous = posixHandlerForSignal(sig) orelse {
            std.c.abort();
        };

        if (previous.handler.sigaction) |handler| {
            handler(sig, info, ctx_ptr);
            std.c.abort();
        }

        if (previous.handler.handler) |handler| {
            if (handler == std.c.SIG.DFL) {
                std.c.abort();
            }

            if (handler == std.c.SIG.IGN) {
                std.c.abort();
            }

            handler(sig);
        }

        std.c.abort();
    }

    fn handleWindows(info: *windows.EXCEPTION_POINTERS) callconv(.winapi) c_long {
        switch (info.ExceptionRecord.ExceptionCode) {
            windows.EXCEPTION_ACCESS_VIOLATION,
            windows.EXCEPTION_ILLEGAL_INSTRUCTION,
            windows.EXCEPTION_DATATYPE_MISALIGNMENT,
            windows.EXCEPTION_STACK_OVERFLOW,
            => restoreRealStderr(),
            else => {},
        }

        return windows.EXCEPTION_CONTINUE_SEARCH;
    }
};

/// Prints captured test output, indented and dimmed, under the test line.
fn printCapturedOutput(captured: []const u8) void {
    const trimmed = std.mem.trimEnd(u8, captured, " \t\n\r");
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
    if (native_os == .windows) {
        const handle = if (realStderr) |file| file.handle else windows.peb().ProcessParameters.hStdError;
        _ = Win32.WriteFile(handle, msg.ptr, @intCast(msg.len), null, null);
    } else {
        const fd = if (realStderr) |file| file.handle else std.c.STDERR_FILENO;
        _ = std.c.write(fd, msg.ptr, msg.len);
    }
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
    last_ns: u64,

    const TestInfo = struct {
        ns: u64,
        name: []const u8,
    };

    fn getNs() u64 {
        if (native_os == .windows) {
            return @intCast(std.time.nanoTimestamp());
        }
        var ts: std.c.timespec = undefined;
        _ = std.c.clock_gettime(std.c.CLOCK.MONOTONIC, &ts);
        return @as(u64, @intCast(ts.sec)) * 1_000_000_000 + @as(u64, @intCast(ts.nsec));
    }

    fn init(allocator: Allocator, count: u32) SlowTracker {
        var queue = SlowestQueue.initContext({});
        queue.ensureTotalCapacity(allocator, count) catch @panic("OOM");
        return .{
            .max = count,
            .last_ns = getNs(),
            .slowest = queue,
        };
    }

    fn deinit(self: *SlowTracker, allocator: Allocator) void {
        self.slowest.deinit(allocator);
    }

    fn startTiming(self: *SlowTracker) void {
        self.last_ns = getNs();
    }

    fn endTiming(self: *SlowTracker, allocator: Allocator, testName: []const u8) u64 {
        const now = getNs();
        const ns = now - self.last_ns;
        var queue = &self.slowest;

        if (queue.len < self.max) {
            queue.push(allocator, TestInfo{ .ns = ns, .name = testName }) catch @panic("failed to track test timing");
            return ns;
        }

        const fastestOfSlow = queue.peekMin() orelse unreachable;
        if (fastestOfSlow.ns > ns) {
            return ns;
        }

        _ = queue.popMin();
        queue.push(allocator, TestInfo{ .ns = ns, .name = testName }) catch @panic("failed to track test timing");
        return ns;
    }

    fn display(self: *SlowTracker, _: Allocator) void {
        var queue = self.slowest;
        const count = queue.len;

        Printer.dim("  Slowest {d} test{s}:\n", .{ count, if (count != 1) @as([]const u8, "s") else "" });

        while (queue.popMin()) |info| {
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
        const key_z = allocator.dupeZ(u8, key) catch return null;
        defer allocator.free(key_z);
        const ptr = std.c.getenv(key_z) orelse return null;
        const value = std.mem.sliceTo(ptr, 0);
        return allocator.dupe(u8, value) catch null;
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
        // Restore real stderr before panicking so output is visible.
        CrashOutput.restoreRealStderr();
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
    const marker = std.mem.indexOfPos(u8, name, 0, ".test") orelse return null;
    if (marker == 0) return null;
    return name[0..marker];
}

fn isUnnamed(t: std.builtin.TestFn) bool {
    const marker = ".test_";
    const testName = t.name;
    const index = std.mem.indexOfPos(u8, testName, 0, marker) orelse return false;
    _ = std.fmt.parseInt(u32, testName[index + marker.len ..], 10) catch return false;
    return true;
}

fn isSetup(t: std.builtin.TestFn) bool {
    return std.mem.endsWith(u8, t.name, "tests:beforeAll");
}

fn isTeardown(t: std.builtin.TestFn) bool {
    return std.mem.endsWith(u8, t.name, "tests:afterAll");
}

# Zig 0.15 Platform Notes

These notes collect the platform-specific Zig 0.15.2 details that are easy to forget but only matter for a narrower set of tasks, especially cross-platform file-handle work and the custom test runner.

## Cross-Platform File I/O

Use `std.fs.File` for cross-platform file operations. It wraps POSIX file descriptors on Unix and Windows `HANDLE` values on Windows behind one API.

```zig
const File = std.fs.File;
const stderr = File.stderr();
_ = try stderr.write("hello");
```

In Zig 0.15, `std.fs.File.writer()` takes a caller-provided buffer:

```zig
var buf: [256]u8 = undefined;
const writer = file.writer(&buf);
```

There is no free-standing `std.io.bufferedWriter()` helper in this version.

## POSIX APIs That Do Not Port To Windows

These `std.posix` calls only compile on POSIX targets:

- `std.posix.dup()`
- `std.posix.dup2()`
- `std.posix.STDERR_FILENO`
- `std.posix.memfd_create()`
- `std.posix.openZ()`
- `std.posix.unlinkZ()`
- `std.posix.getpid()`

These `std.posix` calls do dispatch to Windows implementations:

- `std.posix.exit()`
- `std.posix.lseek_SET()`
- `std.posix.read()`
- `std.posix.write()`
- `std.posix.close()`

When portability matters, prefer `std.fs.File` over raw `std.posix` calls.

## Windows Handle Duplication

Windows does not have `dup()`. Use `kernel32.DuplicateHandle()`:

```zig
const windows = std.os.windows;
var duplicated: windows.HANDLE = undefined;
const proc = windows.GetCurrentProcess();
const DUPLICATE_SAME_ACCESS = 0x00000002;
_ = windows.kernel32.DuplicateHandle(
    proc,
    handle,
    proc,
    &duplicated,
    0,
    windows.FALSE,
    DUPLICATE_SAME_ACCESS,
);
```

## Windows Stderr Redirection

`std.debug.print` reads `windows.peb().ProcessParameters.hStdError` on each call. That field is a non-optional `HANDLE`, so redirect stderr by overwriting it directly:

```zig
windows.peb().ProcessParameters.hStdError = new_handle;
```

On POSIX, use `dup2(new_fd, STDERR_FILENO)` instead.

## Temporary Files

- Linux-only anonymous temp file: `std.posix.memfd_create("name", 0)`
- Cross-platform temp file: `std.fs.Dir.createFile()` in a temp directory such as `.zig-cache/tmp/`

For unique names, generate random bytes and encode them with `std.fs.base64_encoder`.

## PEB Struct Fields

Do not confuse these two fields:

- `RTL_USER_PROCESS_PARAMETERS.hStdError` is `HANDLE`
- `STARTUPINFOW.hStdError` is `?HANDLE`

The PEB field does not need `orelse`.

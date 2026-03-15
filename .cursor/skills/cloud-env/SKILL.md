---
name: cloud-env
description: Cursor Cloud specific instructions for Forbear's Vulkan, Wayland, Weston, and lavapipe software rendering environment. Use when troubleshooting Wayland display access, graphical startup errors, or running GUI apps inside the cloud agent.
---

# Cursor Cloud Environment

- Cloud agents use `.cursor/environment.json` to install Vulkan, Wayland, and software-rendering dependencies.
- The checked-in environment expects Linux rendering to work through Wayland.
- On startup, `.cursor/environment.json` captures the output of `scripts/cursor_cloud_wayland_start.sh` and `eval`s the resulting `export` statements so the chosen `XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY` are available to later agent commands in the startup shell.
- `scripts/cursor_cloud_wayland_start.sh` first tries to reuse an already-running Wayland compositor from `/run/user/*/wayland-*`.
- If no compositor is available, the script creates a fresh `mktemp` runtime directory and starts `weston` there instead, so fallback Wayland state is unique to that cloud environment.
- When `DISPLAY` is available, the fallback compositor uses Weston on the X11 backend so GUI inspection can work in a visible nested window. Otherwise it uses Weston on the headless backend for terminal-driven agent runs.
- The startup script only reuses actual socket files under `/run/user/*/wayland-*`, writes the chosen `XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY` into shell startup files for bash and fish, and fails fast if Weston never creates the requested socket.
- The environment also forces Vulkan onto Mesa's CPU renderer (`lavapipe`/`llvmpipe`) through `VK_DRIVER_FILES`, `VK_ICD_FILENAMES`, `GALLIUM_DRIVER`, and `LIBGL_ALWAYS_SOFTWARE`.
- Quick cloud sanity checks:
  - `vulkaninfo --summary` should report `PHYSICAL_DEVICE_TYPE_CPU` and `DRIVER_ID_MESA_LLVMPIPE`.
  - `zig build check` should compile the repo.
  - `timeout 10s zig build run` should keep running until timeout rather than failing at Wayland/Vulkan startup.
- If a cloud run reports missing Wayland display access, inspect `echo $XDG_RUNTIME_DIR $WAYLAND_DISPLAY` and `/tmp/weston.log` before assuming the renderer is broken.
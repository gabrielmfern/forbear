#!/usr/bin/env bash
set -euo pipefail

state_dir="${HOME}/.cursor-cloud"
env_file="${state_dir}/wayland_env.sh"
profile_line='[ -f "$HOME/.cursor-cloud/wayland_env.sh" ] && . "$HOME/.cursor-cloud/wayland_env.sh"'
fish_dir="${HOME}/.config/fish/conf.d"
fish_file="${fish_dir}/cursor_wayland.fish"

mkdir -p "${state_dir}" "${fish_dir}"

existing_wayland_socket=""
if [[ -n "${XDG_RUNTIME_DIR:-}" && -n "${WAYLAND_DISPLAY:-}" && -S "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}" ]]; then
    existing_wayland_socket="${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}"
else
    existing_wayland_socket="$(ls /run/user/*/wayland-* 2>/dev/null | head -n 1 || true)"
fi

if [[ -n "${existing_wayland_socket}" ]]; then
    runtime_dir="$(dirname "${existing_wayland_socket}")"
    socket_name="$(basename "${existing_wayland_socket}")"
else
    runtime_dir="$(mktemp -d /tmp/cursor-wayland.XXXXXX)"
    chmod 700 "${runtime_dir}"
    socket_name="wayland-0"

    if [[ -n "${DISPLAY:-}" ]]; then
        weston_backend="x11-backend.so"
    else
        weston_backend="headless-backend.so"
    fi

    nohup weston \
        --backend="${weston_backend}" \
        --socket="${socket_name}" \
        --idle-time=0 \
        --width=1280 \
        --height=720 \
        > /tmp/weston.log 2>&1 &

    for _ in $(seq 1 50); do
        if [[ -S "${runtime_dir}/${socket_name}" ]]; then
            break
        fi
        sleep 0.1
    done

    if [[ ! -S "${runtime_dir}/${socket_name}" ]]; then
        echo "Weston did not create ${runtime_dir}/${socket_name}" >&2
        exit 1
    fi
fi

cat > "${env_file}" <<EOF
export XDG_RUNTIME_DIR='${runtime_dir}'
export WAYLAND_DISPLAY='${socket_name}'
EOF

cat > "${fish_file}" <<EOF
set -gx XDG_RUNTIME_DIR '${runtime_dir}'
set -gx WAYLAND_DISPLAY '${socket_name}'
EOF

for shell_rc in "${HOME}/.profile" "${HOME}/.bashrc"; do
    if [[ ! -f "${shell_rc}" ]] || ! grep -Fqx "${profile_line}" "${shell_rc}"; then
        printf '\n%s\n' "${profile_line}" >> "${shell_rc}"
    fi
done

export XDG_RUNTIME_DIR="${runtime_dir}"
export WAYLAND_DISPLAY="${socket_name}"

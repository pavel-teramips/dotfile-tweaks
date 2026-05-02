#!/bin/bash
set -euo pipefail

session_call() {
    gdbus call --session --dest "$1" --object-path "$2" --method "$3" "${@:4}"
}

extract_single_int() {
    sed -nE 's/^\(([0-9-]+),\)$/\1/p'
}

extract_single_string() {
    sed -nE "s/^\('([^']*)',\)$/\1/p"
}

list_child_nodes() {
    gdbus introspect --session --dest "$1" --object-path "$2" 2>/dev/null |
        sed -nE 's/^[[:space:]]*node ([0-9]+) \{$/\1/p'
}

js_escape_single_quoted() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e "s/'/\\'/g"
}

pid=${RAISE_KONSOLE_START_PID:-$$}
konsole_pid=""
ancestry=""
while [ "$pid" -gt 1 ]; do
    ancestry="$ancestry $pid"
    name=$(awk '/^Name:/ { print $2 }' "/proc/$pid/status" 2>/dev/null || true)
    if [ "$name" = "konsole" ]; then
        konsole_pid="$pid"
        break
    fi
    pid=$(awk '/^PPid:/ { print $2 }' "/proc/$pid/status" 2>/dev/null || true)
    [ -n "$pid" ] || break
done

[ -n "$konsole_pid" ] || exit 0

if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    export DBUS_SESSION_BUS_ADDRESS=$(
        tr '\0' '\n' <"/proc/$konsole_pid/environ" |
            sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | head -n1
    )
fi

if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
    export XDG_RUNTIME_DIR=$(
        tr '\0' '\n' <"/proc/$konsole_pid/environ" |
            sed -n 's/^XDG_RUNTIME_DIR=//p' | head -n1
    )
fi

service="org.kde.konsole-$konsole_pid"

in_ancestry() {
    case " $ancestry " in
        *" $1 "*) return 0 ;;
        *) return 1 ;;
    esac
}

target_session=""
for sid in $(list_child_nodes "$service" /Sessions); do
    fg_pid=$(session_call "$service" "/Sessions/$sid" org.kde.konsole.Session.foregroundProcessId 2>/dev/null | extract_single_int || true)
    if [ -n "$fg_pid" ] && in_ancestry "$fg_pid"; then
        target_session="$sid"
        break
    fi
done

if [ -z "$target_session" ]; then
    for sid in $(list_child_nodes "$service" /Sessions); do
        shell_pid=$(session_call "$service" "/Sessions/$sid" org.kde.konsole.Session.processId 2>/dev/null | extract_single_int || true)
        if [ -n "$shell_pid" ] && in_ancestry "$shell_pid"; then
            target_session="$sid"
            break
        fi
    done
fi

[ -n "$target_session" ] || exit 0

target_window=""
for wid in $(list_child_nodes "$service" /Windows); do
    if session_call "$service" "/Windows/$wid" org.kde.konsole.Window.sessionList 2>/dev/null | grep -q "'$target_session'"; then
        target_window="$wid"
        break
    fi
done

[ -n "$target_window" ] || exit 0

session_call "$service" "/Windows/$target_window" org.kde.konsole.Window.setCurrentSession "$target_session" >/dev/null 2>&1 || true

# Determine which MainWindow corresponds to target_window by sorted position.
# Windows are numbered internally (e.g. 1, 3) while MainWindows are sequential (1, 2, ...).
# The Nth window in sorted order corresponds to MainWindow_N.
window_index=1
for wid in $(list_child_nodes "$service" /Windows | sort -n); do
    [ "$wid" = "$target_window" ] && break
    window_index=$((window_index + 1))
done

mw_path="/konsole/MainWindow_$window_index"
mw_geometry=$(gdbus call --session --dest "$service" --object-path "$mw_path" \
    --method org.freedesktop.DBus.Properties.Get \
    "org.qtproject.Qt.QWidget" "frameGeometry" 2>/dev/null || true)
# Parse "(< (x, y, w, h) >,)" → extract w and h
target_width=$(echo "$mw_geometry"  | sed -nE 's/.*\([0-9]+, [0-9]+, ([0-9]+), [0-9]+\).*/\1/p')
target_height=$(echo "$mw_geometry" | sed -nE 's/.*\([0-9]+, [0-9]+, [0-9]+, ([0-9]+)\).*/\1/p')

plugin_name="raise-konsole-hook"
tmpdir=$(mktemp -d)
script_path="$tmpdir/activate-konsole-window.js"
trap 'rm -rf "$tmpdir"' EXIT

cat > "$script_path" <<EOF_JS
var targetPid = $konsole_pid;
var targetWidth = $target_width;
var targetHeight = $target_height;
var windows = workspace.windowList();
for (var i = 0; i < windows.length; ++i) {
    var w = windows[i];
    if (w.pid === targetPid && w.resourceClass === 'org.kde.konsole') {
        var dw = Math.abs(w.frameGeometry.width  - targetWidth);
        var dh = Math.abs(w.frameGeometry.height - targetHeight);
        if (dw < targetWidth * 0.1 && dh < targetHeight * 0.15) {
            if (w.minimized) w.minimized = false;
            workspace.activeWindow = w;
            break;
        }
    }
}
EOF_JS

# Reuse a stable plugin name so repeated hook invocations don't accumulate loaded scripts.
gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.unloadScript "$plugin_name" >/dev/null 2>&1 || true

script_id=$(gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.loadScript "$script_path" "$plugin_name" 2>/dev/null |
    sed -nE 's/^\(([0-9]+),\)$/\1/p')

if [ -n "$script_id" ]; then
    gdbus call --session --dest org.kde.KWin --object-path "/Scripting/Script$script_id" \
        --method org.kde.kwin.Script.run >/dev/null 2>&1 || true
    gdbus call --session --dest org.kde.KWin --object-path /Scripting \
        --method org.kde.kwin.Scripting.unloadScript "$plugin_name" >/dev/null 2>&1 || true
else
    gdbus call --session --dest "$service" --object-path /org/kde/konsole \
        --method org.freedesktop.Application.Activate '{}' >/dev/null 2>&1 || true
fi

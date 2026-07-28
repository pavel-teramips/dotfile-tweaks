# Useful Tweaks

## tuxiqoda — Unicode character picker

GTK app that searches Unicode characters by name (FTS5 SQLite), picks one,
and puts it on the clipboard. Press hotkey to launch, type to search, Enter to
copy, then Ctrl+V to paste.

Repo: https://github.com/pavel-teramips/tuxiqoda

Build:
```bash
git clone git@github.com:pavel-teramips/tuxiqoda.git
cd tuxiqoda
make        # downloads sqlite amalgamation on first build
make db     # generate the unicode.db
make install
```

Future: direct Wayland injection via `ydotool` or `zwp_input_method_v2`
(see `futureideas.md` in the repo).

---

## Random tint per Konsole window

Each new Konsole tab/window gets a random background tint so you can visually
distinguish multiple terminals at a glance.

### How it works

On shell startup, `.zshrc` picks a random profile from the tint list and applies it
to the current session via D-Bus. Each profile references a matching `.colorscheme`
file that is identical to Breeze Dark except for the `[Background]` color.

### Requirements

The snippet calls `qdbus6` to switch the active session's profile. On
Debian/Ubuntu with KDE Plasma 6:

```bash
sudo apt install qdbus-qt6
```

That package installs the binary as `/usr/lib/qt6/bin/qdbus`, not `qdbus6`,
so add a user-level symlink so the snippet finds it (`~/bin` is on `PATH`):

```bash
ln -s /usr/lib/qt6/bin/qdbus ~/bin/qdbus6
```

(Older KDE 5 systems use `qdbus` / `qdbus-qt5` — adjust the snippet if needed.)

### `~/.zshrc` snippet

```zsh
# Random tint for each new Konsole window.
# KONSOLE_TINT_APPLIED is exported so the choice survives `exec zsh` and is
# inherited by nested interactive shells — keeps the tint stable for the life
# of the Konsole session. A fresh window starts with no marker → fresh roll.
if [[ -n "$KONSOLE_DBUS_SESSION" && -n "$KONSOLE_DBUS_SERVICE" && -z "$KONSOLE_TINT_APPLIED" ]]; then
    _tints=(tint-neutral tint-red tint-green tint-blue tint-purple tint-orange tint-yellow tint-cyan tint-magenta tint-teal tint-pink tint-olive)
    export KONSOLE_TINT_APPLIED="${_tints[$((RANDOM % ${#_tints[@]}+1))]}"
    qdbus6 "$KONSOLE_DBUS_SERVICE" "$KONSOLE_DBUS_SESSION" \
        org.kde.konsole.Session.setProfile "$KONSOLE_TINT_APPLIED" 2>/dev/null
    unset _tints
fi
```

Without the `KONSOLE_TINT_APPLIED` guard, the tint re-rolls every time `.zshrc`
is sourced again in the same window — `exec zsh` to reload, an interactive
shell launched from `vim :term`, a nested `zsh -i`, etc. Exporting the marker
makes the choice sticky for the lifetime of the Konsole session while still
letting each new window roll its own.

### Profiles — `~/.local/share/konsole/tint-<name>.profile`

Each profile (tint-neutral, tint-red, tint-green, tint-blue, tint-purple,
tint-orange, tint-yellow, tint-cyan, tint-magenta, tint-teal, tint-pink,
tint-olive) looks like this (only `Name` and `ColorScheme` differ):

```ini
[Appearance]
ColorScheme=tint-red
Font=Monospace,11,-1,5,50,0,0,0,0,0

[General]
Name=tint-red
Parent=FALLBACK/
LocalTabTitleFormat=%w
RemoteTabTitleFormat=%w
```

`tint-base.profile` uses `ColorScheme=Breeze` and serves as the template.

The `LocalTabTitleFormat=%w` / `RemoteTabTitleFormat=%w` lines duplicate the
setting from `Custom.profile` on purpose. Once the random-tint hook switches
the session away from Custom into a tint profile, the tab title format would
otherwise revert to FALLBACK and break the `title` helper described below.

### Color schemes — `~/.local/share/konsole/tint-<name>.colorscheme`

Full Breeze Dark palette, only `[Background] Color` differs per tint:

| Name    | Background RGB |
|---------|---------------|
| neutral | 35, 38, 39    |
| red     | 55, 38, 39    |
| green   | 35, 55, 39    |
| blue    | 35, 38, 58    |
| purple  | 50, 38, 55    |
| orange  | 52, 45, 35    |
| yellow  | 55, 55, 39    |
| cyan    | 35, 55, 58    |
| magenta | 58, 38, 52    |
| teal    | 38, 55, 55    |
| pink    | 58, 45, 50    |
| olive   | 52, 55, 38    |

---

## Konsole: set tab title from the shell

Run `title foo` in zsh and the Konsole tab/window title becomes `foo`.

### Why this needs setup

Shells set the title via the OSC escape sequence `\033]0;...\007`. Konsole
ignores it unless its tab title format is `%w` (the shell-supplied title).
The defaults are `%d : %n` (directory : program) for local shells and
`%h : %u` for SSH sessions — neither honors `%w`.

The built-in profile can't be edited to change those formats. You have to
create a profile file and set it as the default in `konsolerc`.

### `~/.local/share/konsole/Custom.profile`

```ini
[General]
Name=Custom
Parent=FALLBACK/
LocalTabTitleFormat=%w
RemoteTabTitleFormat=%w
```

### `~/.config/konsolerc`

Add this section (anywhere — typically at the top):

```ini
[Desktop Entry]
DefaultProfile=Custom.profile
```

### `~/.zshrc` snippet

```zsh
# Set the Konsole tab/window title: `title my project`
title() { printf '\033]0;%s\007' "$*"; }
```

Open a new Konsole window after the profile/konsolerc changes — already-open
windows keep the old default and won't pick up the new format.

---

## Shell aliases and functions (`~/.zshrc`)

### Navigation
```zsh
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
```

### File listing (eza)
```zsh
alias ls='eza'
alias ll='eza -la --group-directories-first'
alias la='eza -a'
alias lt='eza --tree --level=2'
```

### Git
```zsh
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gp='git pull --rebase'
alias gP='git push'
```

### Misc
```zsh
alias bex='cd ~/dev/bex'
alias grep='grep --color=auto'
alias clip='xclip -selection clipboard'
```

### `mkcd` — make and enter a directory
```zsh
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}
```

### Integrations (if installed)
- **fzf** — fuzzy finder key bindings and completions loaded automatically
- **zoxide** — smarter `cd` with frecency (`z` command)

---

## Claude Code: Auto-raise Konsole window on Wayland

When Claude finishes a response or asks a question, the Konsole window it's running
in automatically raises to the front — even with multiple Konsole windows open.

### How it works

Claude Code fires hooks on `Stop` (response done) and `PreToolUse` for `AskUserQuestion`.
The hook script walks the process tree to find the correct Konsole instance, identifies
the specific window containing the Claude session, then uses a KWin script to activate
it. KWin scripting is used instead of D-Bus `raise()` or `Activate` because only KWin
has compositor authority to bypass Wayland's focus-stealing prevention.

Key challenges solved:
- `QWidget.raise()` via D-Bus does nothing on Wayland
- `org.freedesktop.Application.Activate` raises the app but picks the wrong window
  when a single Konsole process has multiple windows
- KWin 6's `loadScript` D-Bus slot exists and works — an earlier test failure was
  due to an empty path argument, not a missing API
- KWin reports window geometry with DPI/decoration offsets vs Qt's D-Bus values,
  so geometry matching uses a ±10% tolerance

### `~/.claude/settings.json`

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "~/.claude/raise-konsole.sh", "async": true }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          { "type": "command", "command": "~/.claude/raise-konsole.sh", "async": true }
        ]
      }
    ]
  }
}
```

### `~/.claude/raise-konsole.sh`

```bash
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
# Parse "(<(x, y, w, h)>,)" → extract w and h
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
    # Fallback: raises the app (may pick wrong window if multiple exist)
    gdbus call --session --dest "$service" --object-path /org/kde/konsole \
        --method org.freedesktop.Application.Activate '{}' >/dev/null 2>&1 || true
fi
```

## Claude Code: freeze/restore all sessions across a reboot

Reboot without resuming a dozen Claude windows one by one. `claude-freeze`
snapshots every running session to `~/.claude/session-snapshot.tsv`; after the
reboot `claude-restore` reopens each one in its own Konsole window running
`claude --resume <session-id>`, in its original working directory.

Usage: run `claude-freeze`, eyeball the printed table, reboot, run
`claude-restore` from any terminal.

### How sessions are identified

Which claudes are *running* is exact: `pgrep` + `/proc/<pid>/cwd`, so an exited
claude cannot appear. Which *session id* each process owns is not exposed by
Claude Code — it is absent from the process environment, its open file
descriptors (only the pty, epoll/eventfd handles and the binary) and its
children. So freeze infers it: for each working directory it takes the N most
recently modified transcripts in `~/.claude/projects/<munged-path>/`, N being
the number of claude processes running there. Each row prints the transcript's
last-modified time and first user message — check those against your open
windows before rebooting.

Rejected alternative: scanning each process's memory (`/proc/<pid>/mem`) for
`<uuid>.jsonl` strings and taking the most frequent. It needs root, and it is
wrong — a session id that merely appears in a conversation's *text* outranks
the session's own id. Tested on 11 live sessions: 9 agreed with the timestamp
method, and where ground truth was known the memory scan was the wrong one.

An exact method exists if you want it later: a SessionStart/SessionEnd hook
pair writing pid→session-id into `~/.claude/live-sessions/`. It only helps
sessions started after the hooks are installed, which is why it isn't used
here.

### Two annoyances handled by claude-restore

- **Workspace trust dialog.** Trust lives in `~/.claude.json` under
  `.projects["<dir>"].hasTrustDialogAccepted`. Restore pre-sets it to `true`
  for every directory in the snapshot (backup at `~/.claude.json.bak`), so 11
  windows don't each stop on "do you trust this folder?". It only does this
  when no claude is running — right after a reboot nothing else is writing
  that file, so there's no clobber risk.
- **Konsole Qt noise.** `Unsupported return type 4097 QPixmap in method
  "grab"` is a harmless warning Konsole prints on startup; the launches
  redirect it so it doesn't land in the terminal you ran restore from.

### `~/.local/bin/claude-freeze`

```zsh
#!/usr/bin/env zsh
# claude-freeze — snapshot all running Claude Code sessions before a reboot.
# Writes ~/.claude/session-snapshot.tsv (workdir <TAB> session-id <TAB> exact|guessed <TAB> preview).
# Restore after reboot with: claude-restore
#
# Session identity comes from two sources:
#   exact   — ~/.claude/live-sessions/ registry maintained by the SessionStart/
#             SessionEnd hooks (session-registry.sh): pid <-> session id binding.
#   guessed — for claudes with no registry entry (started before the hooks were
#             installed): the N most recently modified transcripts in the
#             directory's ~/.claude/projects/ folder. Verify via the preview.

SNAP="$HOME/.claude/session-snapshot.tsv"
REG="$HOME/.claude/live-sessions"

# Running claude processes and their working directories (live kernel state —
# an exited claude cannot appear here). Skips the chrome-native-host helper.
typeset -A pid_cwd
for pid in $(pgrep -f '^claude( |$)'); do
  cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null) || continue
  pid_cwd[$pid]=$cwd
done
if (( ${#pid_cwd} == 0 )); then
  echo "No running claude processes found — nothing to snapshot."
  exit 1
fi

# Registry: oldest file first, so if one pid appears twice (e.g. after /clear
# changed the session id) the newest registration wins. Entries whose pid is
# gone are stale (crash/kill skipped SessionEnd) and get cleaned up.
typeset -A pid_sid claimed_sid
if [[ -d $REG ]]; then
  for f in $(ls -tr "$REG" 2>/dev/null); do
    IFS=$'\t' read -r rpid _rcwd < "$REG/$f"
    if [[ -z ${pid_cwd[$rpid]:-} ]]; then
      rm -f "$REG/$f"
    else
      pid_sid[$rpid]=$f
    fi
  done
  for s in ${(v)pid_sid}; do claimed_sid[$s]=1; done
fi

preview() {  # $1 = transcript path -> "mtime | first user message"
  local first mt
  first=$(grep -a -m1 -o '"type":"user","message":{"role":"user","content":"[^"]\{1,60\}' "$1" 2>/dev/null | sed 's/.*content":"//')
  mt=$(date -r "$1" '+%m-%d %H:%M' 2>/dev/null)
  print -r -- "$mt | ${first:-(no text preview)}"
}

projdir() {  # $1 = cwd -> transcript dir (claude munges / and . to -)
  print -r -- "$HOME/.claude/projects/${${1//\//-}//./-}"
}

: > "$SNAP"
typeset -A fallback_count
for pid in ${(k)pid_cwd}; do
  cwd=${pid_cwd[$pid]}
  if [[ -n ${pid_sid[$pid]:-} ]]; then
    sid=${pid_sid[$pid]}
    printf '%s\t%s\texact\t%s\n' "$cwd" "$sid" "$(preview "$(projdir $cwd)/$sid.jsonl")" >> "$SNAP"
  else
    fallback_count[$cwd]=$(( ${fallback_count[$cwd]:-0} + 1 ))
  fi
done

for cwd in ${(k)fallback_count}; do
  proj=$(projdir "$cwd")
  if [[ ! -d $proj ]]; then
    echo "WARNING: no transcript dir for $cwd (expected $proj) — skipped"
    continue
  fi
  n=${fallback_count[$cwd]}
  find "$proj" -maxdepth 1 -name '*.jsonl' -printf '%T@\t%f\n' \
    | sort -rn \
    | while IFS=$'\t' read -r _t f; do
        (( n > 0 )) || break
        sid=${f%.jsonl}
        [[ -n ${claimed_sid[$sid]:-} ]] && continue
        printf '%s\t%s\tguessed\t%s\n' "$cwd" "$sid" "$(preview "$proj/$f")" >> "$SNAP"
        (( n-- )) || true
      done
  (( n > 0 )) && echo "WARNING: $cwd: $n running claude(s) with no matching transcript"
done

sort -o "$SNAP" "$SNAP"
echo "Snapshot written to $SNAP:"
column -t -s $'\t' "$SNAP"
echo ""
if grep -q $'\tguessed\t' "$SNAP"; then
  echo "Lines marked 'guessed' were matched by transcript freshness, not the hook"
  echo "registry — check their previews against your open windows before rebooting."
fi
echo "You can reboot now. Afterwards run: claude-restore"
```

### `~/.local/bin/claude-restore`

```zsh
#!/usr/bin/env zsh
# claude-restore — reopen every Claude Code session saved by claude-freeze.
# Opens one Konsole window per session, running `claude --resume <session-id>`
# in the session's original working directory.

SNAP="$HOME/.claude/session-snapshot.tsv"
CJ="$HOME/.claude.json"

if [[ ! -s $SNAP ]]; then
  echo "No snapshot found at $SNAP — run claude-freeze before rebooting."
  exit 1
fi

# Pre-accept the workspace trust dialog for every directory we're about to
# reopen, so 11 windows don't each stop on "do you trust this folder?".
# Safe to rewrite ~/.claude.json here: right after a reboot no claude process
# is running yet, so nothing else is writing the file.
if command -v jq >/dev/null 2>&1 && [[ -f $CJ ]]; then
  if pgrep -f '^claude( |$)' >/dev/null; then
    echo "NOTE: claude is already running — skipping trust pre-accept to avoid"
    echo "      clobbering ~/.claude.json (a running session may rewrite it)."
  else
    typeset -a dirs
    dirs=(${(f)"$(cut -f1 "$SNAP" | sort -u)"})
    filter=""
    for d in $dirs; do
      filter+=".projects[\"$d\"].hasTrustDialogAccepted = true | "
    done
    filter+="."
    cp -f "$CJ" "$CJ.bak"
    if jq "$filter" "$CJ" > "$CJ.tmp" && [[ -s $CJ.tmp ]]; then
      mv -f "$CJ.tmp" "$CJ"
      echo "Trust pre-accepted for: $dirs (backup: $CJ.bak)"
    else
      rm -f "$CJ.tmp"
      echo "WARNING: could not update trust flags in $CJ — dialogs may appear."
    fi
  fi
fi

n=0
while IFS=$'\t' read -r cwd id _rest; do
  # Konsole prints harmless Qt DBus warnings ("Unsupported return type ...
  # QPixmap in method grab") on startup — keep them out of this terminal.
  konsole --workdir "$cwd" -e zsh -ic "claude --resume $id" >/dev/null 2>&1 &!
  (( n++ ))
  sleep 0.4   # space out window creation so KDE doesn't choke
done < "$SNAP"

echo "Opened $n Konsole windows."
```

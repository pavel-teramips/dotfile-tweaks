#!/bin/bash
# Maintains ~/.claude/live-sessions/ — one file per running Claude Code session,
# named by session id, containing "pid<TAB>cwd" of the owning claude process.
# Wired to the SessionStart and SessionEnd hooks in ~/.claude/settings.json.
# Consumed by claude-freeze for exact enumeration of running sessions.

input=$(cat)
sid=$(jq -r '.session_id // empty' <<< "$input")
event=$(jq -r '.hook_event_name // empty' <<< "$input")
[ -z "$sid" ] && exit 0

dir="$HOME/.claude/live-sessions"
mkdir -p "$dir"

if [ "$event" = "SessionEnd" ]; then
    rm -f "$dir/$sid"
    exit 0
fi

# SessionStart: the hook runs as a descendant of the claude process — walk up
# the parent chain to find it.
p=$PPID
while [ -n "$p" ] && [ "$p" != 1 ] && [ "$p" != 0 ]; do
    if [ "$(cat /proc/$p/comm 2>/dev/null)" = "claude" ]; then
        cwd=$(jq -r '.cwd // empty' <<< "$input")
        printf '%s\t%s\n' "$p" "$cwd" > "$dir/$sid"
        exit 0
    fi
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
done
exit 0

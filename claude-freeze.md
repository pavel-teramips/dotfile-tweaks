# claude-freeze / claude-restore

Reboot without resuming a dozen Claude Code windows one by one.

## Quick usage

```zsh
claude-freeze     # before the reboot — snapshots every running session
# ...reboot...
claude-restore    # after the reboot — reopens them all
```

Both live in `~/.local/bin` (already in `PATH`). Nothing else to install.

## What each one does

**`claude-freeze`** finds every running `claude` process, works out which
session each one is, and writes `~/.claude/session-snapshot.tsv` — one line per
session:

```
<working dir>	<session id>	exact|guessed	<last modified> | <first user message>
```

It prints that table so you can check it. It does **not** close anything — the
reboot does that, and that's safe: Claude appends every turn to its transcript
on disk as it happens, so nothing is lost when the windows die.

**`claude-restore`** reads the snapshot and opens one Konsole **window** per
session, in that session's original directory, running
`claude --resume <session-id>`. Windows are spaced 0.4s apart so KDE doesn't
choke. It also, before opening anything:

- pre-accepts the workspace trust dialog for every directory in the snapshot
  (sets `.projects["<dir>"].hasTrustDialogAccepted = true` in
  `~/.claude.json`, backup at `~/.claude.json.bak`), so the windows don't each
  stop on "do you trust this folder?";
- redirects Konsole's harmless Qt startup warnings
  (`Unsupported return type 4097 QPixmap in method "grab"`) so they don't land
  in the terminal you ran it from.

## Rules of thumb

- **Re-run `claude-freeze` right before each reboot.** The snapshot is a
  point-in-time list; after a restore the old file holds the *previous* run's
  session ids and is useless.
- **Read the table before rebooting.** Rows marked `guessed` were matched by
  transcript freshness, not by an exact record — the preview column (time +
  first message) is there so you can spot a wrong pick.
- **Restore only on a machine with no claude running.** That's the normal
  post-reboot state. If claude *is* running, restore skips the trust
  pre-accept (to avoid clobbering `~/.claude.json`) and says so.

## Why some rows say "guessed"

Which claudes are *running* is exact — `pgrep` plus `/proc/<pid>/cwd`, so an
exited claude cannot show up. Which *session id* a given process owns is not
exposed by Claude Code anywhere: not in the process environment, not in its
open file descriptors (just the pty, some epoll/eventfd handles and the
binary), not in its children. So freeze infers it: per working directory it
takes the N most recently modified transcripts in
`~/.claude/projects/<munged-path>/`, N being the number of claude processes
running in that directory.

This is right whenever the open sessions are the recently active ones — the
normal case. It can slip if a session you closed minutes ago displaces one that
has sat idle for days. Worst case is benign: restore reopens a recently closed
session instead, and you resume the missed one by hand with `claude --resume`.

Two exact-identification approaches were tried and set aside:

- **Memory scanning** (`~/.local/bin/claude-sessions`, needs `sudo`): reads
  each process's `/proc/<pid>/mem` and counts `<uuid>.jsonl` strings. Rejected
  — a session id merely *quoted in a conversation's text* outranks the
  session's own id. Tested against 11 live sessions: 9 matched the timestamp
  method, and in the one case with known ground truth the memory scan was the
  one that was wrong.
- **A hook registry** (`~/.claude/session-registry.sh`): SessionStart /
  SessionEnd hooks writing pid → session id into `~/.claude/live-sessions/`.
  Exact, but only for sessions started *after* the hooks are installed, so it
  couldn't identify the sessions already open. Kept, not wired up; to enable
  it, add both hooks to `~/.claude/settings.json` pointing at that script —
  freeze already prefers the registry and marks those rows `exact`.

## Open item

On resume, Claude sometimes offers to restart from a summary instead of the
full session. Auto-answering that is not implemented — the exact prompt
wording is needed first.

## Files

| Path | Role |
|---|---|
| `~/.local/bin/claude-freeze` | writes the snapshot |
| `~/.local/bin/claude-restore` | reopens the windows |
| `~/.claude/session-snapshot.tsv` | the snapshot itself |
| `~/.claude.json.bak` | backup made before the trust pre-accept |
| `~/.local/bin/claude-sessions` | unused memory-scan experiment (sudo) |
| `~/.claude/session-registry.sh` | unused hook-registry script |

Full script sources are in `usefultweaks.md`; both are committed to
`pavel-teramips/dotfile-tweaks`.

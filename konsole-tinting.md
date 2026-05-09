# Random-Tinted Konsole Windows on KDE Plasma 6

Each new Konsole window gets a random subtle background tint — makes it easy to
tell windows apart when task-switching.

---

## What it looks like

Twelve possible tints, all based on the Breeze Dark palette (`35,38,39` background):

| Profile | Background tweak |
|---------|-----------------|
| `tint-neutral` | unchanged (`35,38,39`) |
| `tint-red`     | `55,38,39` |
| `tint-green`   | `35,55,39` |
| `tint-blue`    | `35,38,58` |
| `tint-purple`  | `50,38,55` |
| `tint-orange`  | `52,45,35` |
| `tint-yellow`  | `55,55,39` |
| `tint-cyan`    | `35,55,58` |
| `tint-magenta` | `58,38,52` |
| `tint-teal`    | `38,55,55` |
| `tint-pink`    | `58,45,50` |
| `tint-olive`   | `52,55,38` |

Shifts are ~15–20 RGB counts — just enough to notice, not enough to look weird.
The pool is intentionally large so several open windows are unlikely to collide
on the same tint.

---

## How it works

### 1. Color schemes — `~/.local/share/konsole/tint-*.colorscheme`

Each file is a full Breeze Dark color table with the `[Background]` section's
`Color` line shifted. Konsole picks these up automatically from the user's
local share directory.

### 2. Profiles — `~/.local/share/konsole/tint-*.profile`

One profile per tint. Each just points at the matching color scheme:

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

The `LocalTabTitleFormat=%w` / `RemoteTabTitleFormat=%w` lines aren't strictly
needed for tinting itself — they're there so the `title` helper (see
`usefultweaks.md`) keeps working after the random-tint hook switches the
session to one of these profiles. Without them, the tab title format would
revert to the FALLBACK default the moment the tint hook fires, and `title foo`
would silently become a no-op.

### 3. The hook — `~/.zshrc`

The key insight: **Konsole exports `$KONSOLE_DBUS_SERVICE` and
`$KONSOLE_DBUS_SESSION` into every shell it spawns.** The `Session.setProfile`
D-Bus method changes the color scheme of the running session. So we just add
this to `.zshrc`:

```zsh
if [[ -n "$KONSOLE_DBUS_SESSION" && -n "$KONSOLE_DBUS_SERVICE" && -z "$KONSOLE_TINT_APPLIED" ]]; then
    _tints=(tint-neutral tint-red tint-green tint-blue tint-purple tint-orange tint-yellow tint-cyan tint-magenta tint-teal tint-pink tint-olive)
    export KONSOLE_TINT_APPLIED="${_tints[$((RANDOM % ${#_tints[@]}+1))]}"
    qdbus6 "$KONSOLE_DBUS_SERVICE" "$KONSOLE_DBUS_SESSION" \
        org.kde.konsole.Session.setProfile "$KONSOLE_TINT_APPLIED" 2>/dev/null
    unset _tints
fi
```

This runs every time a new shell opens inside Konsole — regardless of how
Konsole was launched (shortcut, app launcher, terminal, whatever). No wrappers,
no desktop file hacks needed.

### Why the `KONSOLE_TINT_APPLIED` guard

Without it, the tint re-rolls every time `.zshrc` is sourced again in the same
window: `exec zsh` to reload config, an interactive shell launched from
`vim :term`, a nested `zsh -i`, etc. The user-visible bug was "I open a
window, it's blue, then later the same window is suddenly green." Exporting
`KONSOLE_TINT_APPLIED` makes the marker survive `exec zsh` and propagate to
subshells, so the choice is sticky for the lifetime of the Konsole session.
A brand-new window starts with the marker unset → rolls a fresh tint as
intended.

---

## What didn't work (and why)

We first tried a wrapper script at `~/.local/bin/konsole` that passes
`--profile tint-X` to the real Konsole binary. This works fine when called
from the command line. But **Ctrl+Alt+T goes through KDE's global shortcut
system**, which is handled inside `kwin_wayland`. That process was started at
login with a restricted `PATH` (no `~/.local/bin`) and it caches the Konsole
launch path at startup. Rebuilding the KDE service cache (`kbuildsycoca6`),
restarting `plasmashell`, and tweaking desktop file overrides all had no
effect on the already-running `kwin_wayland`. Restarting the Wayland
compositor would have killed the whole session.

The D-Bus hook in `.zshrc` sidesteps all of that entirely.

---

## Files created

```
~/.local/share/konsole/tint-neutral.colorscheme
~/.local/share/konsole/tint-red.colorscheme
~/.local/share/konsole/tint-green.colorscheme
~/.local/share/konsole/tint-blue.colorscheme
~/.local/share/konsole/tint-purple.colorscheme
~/.local/share/konsole/tint-orange.colorscheme
~/.local/share/konsole/tint-yellow.colorscheme
~/.local/share/konsole/tint-cyan.colorscheme
~/.local/share/konsole/tint-magenta.colorscheme
~/.local/share/konsole/tint-teal.colorscheme
~/.local/share/konsole/tint-pink.colorscheme
~/.local/share/konsole/tint-olive.colorscheme

~/.local/share/konsole/tint-neutral.profile
~/.local/share/konsole/tint-red.profile
~/.local/share/konsole/tint-green.profile
~/.local/share/konsole/tint-blue.profile
~/.local/share/konsole/tint-purple.profile
~/.local/share/konsole/tint-orange.profile
~/.local/share/konsole/tint-yellow.profile
~/.local/share/konsole/tint-cyan.profile
~/.local/share/konsole/tint-magenta.profile
~/.local/share/konsole/tint-teal.profile
~/.local/share/konsole/tint-pink.profile
~/.local/share/konsole/tint-olive.profile

~/.local/share/applications/org.kde.konsole.desktop   (local desktop override)
~/.local/bin/konsole                                   (wrapper, used from CLI)
```

Hook added to `~/.zshrc`.

# dotfile-tweaks

Personal Linux/KDE Plasma 6 tweaks and dotfiles.

The full write-up of every tweak in here lives in **[`usefultweaks.md`](./usefultweaks.md)**.
For a deeper dive on just the random Konsole tinting feature, see
**[`konsole-tinting.md`](./konsole-tinting.md)**.

## What's inside

| Path in repo | Path on disk | What it is |
|---|---|---|
| `.zshrc` | `~/.zshrc` | Shell config — history, completion, plugins, aliases, prompt, and the Konsole auto-tint hook |
| `.local/share/konsole/tint-*.profile` | `~/.local/share/konsole/tint-*.profile` | Konsole profiles, one per tint |
| `.local/share/konsole/tint-*.colorscheme` | `~/.local/share/konsole/tint-*.colorscheme` | Color schemes — Breeze Dark with one channel shifted per tint |
| `.local/share/konsole/tint-base.profile` | `~/.local/share/konsole/tint-base.profile` | Template profile (unmodified Breeze) |
| `.claude/raise-konsole.sh` | `~/.claude/raise-konsole.sh` | Wayland-friendly script that raises the Konsole window running Claude Code |
| `.claude/settings.json.example` | `~/.claude/settings.json` | Hooks wiring the raise-konsole script + a desktop notification on `Stop` |

`settings.json.example` is a sanitized template — drop it in as
`~/.claude/settings.json` and merge with anything else you have there. Real-life
`settings.json` may also contain machine-specific hooks (e.g. third-party CLI
integrations) that aren't included here.

## Install (manual copy)

```sh
cd ~/dev/dotfiles

# Shell
cp .zshrc ~/.zshrc

# Konsole tints
mkdir -p ~/.local/share/konsole
cp .local/share/konsole/tint-* ~/.local/share/konsole/

# Claude Code raise hook
mkdir -p ~/.claude
cp .claude/raise-konsole.sh ~/.claude/raise-konsole.sh
chmod +x ~/.claude/raise-konsole.sh

# Settings template — review and merge with existing settings.json
cp .claude/settings.json.example ~/.claude/settings.json
```

## Keeping in sync

The docs (`usefultweaks.md`, `konsole-tinting.md`) and the dotfiles in this repo
are **manual copies** of the live versions in `~/`. After tweaking the live
files, copy them back into the repo and commit. There's no symlink/install
script (yet) — keeping it simple deliberately.

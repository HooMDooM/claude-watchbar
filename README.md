# Claude Usage Bar

<p align="center">
  <img src="screenshots/statusbar.png" alt="Status Bar" height="28">
</p>

**Native macOS menu bar app for tracking Claude Code token usage, costs, and rate limits.**

No Electron. No web server. One Swift file, zero dependencies. Just build and run.

---

## What You Get

**Status Bar** — always visible at a glance:
- Two progress bars (5-hour session limit & weekly limit)
- Your plan badge (Free / Pro / Max 5x / Max 20x)
- Today's cost in real-time

**Click to open dashboard:**

<p align="center">
  <img src="screenshots/collapsed.png" alt="Collapsed View" width="420">
</p>

- Cost breakdown by period (Today / Yesterday / 7d / 30d / All time)
- 8 metric cards (sessions, turns, tokens in/out, cache, total cost)
- Daily token usage chart (stacked by type)
- Model distribution donut chart
- Top projects with cost per project
- Cost breakdown table by model (Input / Output / Cache Read / Cache Write)

**Expand for the full picture:**

<p align="center">
  <img src="screenshots/expanded.png" alt="Expanded View" width="420">
</p>

Smooth expand/collapse animation. All data, no scrollbar.

---

## Features

- **7 languages** — RU, EN, DE, FR, ES, TR, AR (auto-detects system language)
- **Rate limits** — reads from local token data with configurable thresholds
- **Auto-refresh** — scans new Claude Code logs every 30 seconds
- **Dark theme** — native macOS dark mode
- **Model versions** — shows Opus 4.6, Sonnet 4.5, Haiku 4.5, etc.
- **Expand / Collapse** — compact or full dashboard with smooth animation
- **Login item** — optional auto-start on macOS login

---

## Requirements

- macOS 14.0+ (Sonoma or later)
- Xcode Command Line Tools (`xcode-select --install`)
- Python 3 (comes with macOS / Xcode CLT)
- [claude-usage](https://github.com/phuryn/claude-usage) scanner (for the SQLite database)

---

## Install

### 1. Set up the scanner

Claude Code writes JSONL logs to `~/.claude/projects/`. The [claude-usage](https://github.com/phuryn/claude-usage) scanner parses them into a SQLite database:

```bash
git clone https://github.com/phuryn/claude-usage ~/.claude-usage-scanner
cd ~/.claude-usage-scanner
python3 cli.py scan
```

### 2. Install the menu bar app

```bash
git clone https://github.com/HooMDooM/claude-usage-bar
cd claude-usage-bar
./install.sh --login
```

That's it. The app appears in your menu bar.

### One-liner

```bash
git clone https://github.com/HooMDooM/claude-usage-bar && cd claude-usage-bar && ./install.sh --login
```

---

## Usage

| Action | How |
|--------|-----|
| Open dashboard | Click the status bar icon |
| Expand / Collapse | Click the `expand` button in footer |
| Change language | Click the `globe` button in footer |
| Manual refresh | Click the `refresh` button in footer |
| Quit | Click the `power` button in footer |

---

## Configuration

Rate limits and plan type are stored in `~/.claude/usage-bar.json`:

```json
{
  "plan": "Max 20x",
  "session_limit": 80,
  "weekly_limit": 2000
}
```

| Field | Description |
|-------|-------------|
| `plan` | Displayed in status bar. Any string: `Free`, `Pro`, `Max 5x`, `Max 20x` |
| `session_limit` | Estimated cost limit ($) per 5-hour session window |
| `weekly_limit` | Estimated cost limit ($) per 7-day window |

Adjust these based on your subscription. The progress bars show `(spent / limit) %`.

---

## Cost Calculation

Costs are estimated using Anthropic API pricing (April 2026):

| Model | Input | Output | Cache Write | Cache Read |
|-------|-------|--------|-------------|------------|
| Opus 4.6 | $5.00/MTok | $25.00/MTok | $6.25/MTok | $0.50/MTok |
| Sonnet 4.6 | $3.00/MTok | $15.00/MTok | $3.75/MTok | $0.30/MTok |
| Haiku 4.5 | $1.00/MTok | $5.00/MTok | $1.25/MTok | $0.10/MTok |

> These are API prices. Subscription plans (Pro/Max) have different cost structures.

---

## Scripts

| Script | Description |
|--------|-------------|
| `./install.sh` | Build + install to `~/Applications` + launch |
| `./install.sh --login` | Same + add to Login Items (auto-start) |
| `./build.sh` | Build only (creates `.app` bundle in current dir) |
| `./uninstall.sh` | Stop + remove app + remove from Login Items |

---

## How It Works

```
~/.claude/projects/**/*.jsonl     Claude Code session logs (JSONL)
        |
        v
  claude-usage scanner            Parses JSONL -> SQLite
        |
        v
  ~/.claude/usage.db              Token usage database
        |
        v
  Claude Usage Bar                Reads DB, shows in menu bar
```

The app is a single Swift file (`main.swift`) compiled into a native macOS `.app` bundle. It uses:
- **SwiftUI** for the UI
- **Swift Charts** for graphs
- **SQLite3** (system library) for reading the database
- **AppKit** (NSPanel) for the menu bar popover

No third-party dependencies. No CocoaPods. No SPM packages.

---

## Tech Stack

- Swift 5 / SwiftUI / Charts
- SQLite3 (C API via system library)
- AppKit (NSStatusItem, NSPanel)
- ~1100 lines, single file

---

## Uninstall

```bash
./uninstall.sh
```

Or manually:
1. Quit the app (power button in footer)
2. Delete `~/Applications/Claude Usage.app`
3. Remove from System Settings > General > Login Items

---

## Credits

- Token scanner: [claude-usage](https://github.com/phuryn/claude-usage) by [phuryn](https://github.com/phuryn)
- Inspired by [OpenUsage](https://openusage.dev)

---

## License

MIT

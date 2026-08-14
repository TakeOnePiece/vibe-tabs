# Coding Sessions

Coding Sessions restores named AI coding workspaces with one click on macOS. A YAML file defines the project folder, tmux layout, and any coding commands you want in its panes: Claude, Codex, Gemini, Pi, Aider, OpenCode, a DeepSeek-backed command, or something else entirely.

Each workspace name is shared by tmux and its Terminal tab. Claude and Codex additionally get name-aware conversation resume behavior.

Running the launcher again selects the existing named Terminal tab. It does not create duplicate Terminal tabs, tmux sessions, or agent processes.

![Coding Sessions icon](assets/coding-sessions-icon.png)

## Install with Homebrew

```sh
brew install takeonepiece/tap/coding-sessions
```

Your chosen coding CLIs must already be installed and authenticated. Homebrew installs `tmux`, `jq`, `yq`, and `ripgrep`.

Create `~/.coding-sessions.yml`:

```yaml
version: 1

defaults:
  session_suffix: laptop
  layout: auto
  panes:
    - claude
    - codex
  codex_args: ""

sessions:
  - name: web
    path: ~/Code/example-web

  - name: mobile
    path: ~/Code/example-mobile
    panes:
      - gemini
      - codex

  - name: research
    path: ~/Code/research
    layout: tiled
    panes:
      - claude
      - pi
      - aider --model deepseek/deepseek-chat
```

Launch everything:

```sh
coding-sessions
```

Or open the bundled launcher app:

```sh
coding-sessions --app
```

After opening **Coding Sessions**, you can keep it in the Dock.

## YAML specification

The default config path is `~/.coding-sessions.yml`; `.yaml` is also accepted. A different YAML file can be passed to `coding-sessions`.

Top level:

- `version`: config schema version; currently `1`.
- `defaults`: optional values inherited by every session.
- `sessions`: required list of session objects.

Defaults and per-session options:

- `session_suffix`: appended to names unless already present; useful for names such as `web-m1-mbp`.
- `layout`: `auto`, `even-horizontal`, `even-vertical`, `main-horizontal`, `main-vertical`, or `tiled`. `auto` uses side-by-side panes for two commands and tiled panes for three or more.
- `panes`: non-empty list of shell commands. `claude` and `codex` activate built-in resume handling. Other entries run through the login shell exactly as configured.
- `codex_args`: optional shell-style arguments for Codex. The safe default is empty.

Each session requires:

- `name`: stable session name before any suffix.
- `path`: absolute or `~/` project folder.

Per-session options override `defaults`. Existing tmux sessions remain untouched, so pane or layout changes take effect after that tmux session is removed.

## Commands

```sh
# Open every configured workspace
coding-sessions

# Use another YAML config
coding-sessions ./team-sessions.yml

# Open one workspace directly with explicit panes
coding-session --layout tiled web-m1-mbp ~/Code/example-web claude codex gemini

# Default to Claude + Codex and derive the name from the folder
coding-session ~/Code/example-web
```

## Reuse behavior

1. If the exact tmux session exists, its panes and processes are preserved.
2. If tmux is missing, Claude and Codex histories are searched for the exact name and their saved IDs are resumed when available.
3. If no matching Claude or Codex history exists, a new named conversation is started.
4. Other configured commands launch normally in their own pane.
5. If Terminal already has a tab with the session name, that tab is selected instead of duplicated.

## Security

Coding Sessions does not collect telemetry or send credentials anywhere. Authentication remains inside each coding CLI. Do not put API keys or tokens directly in the YAML; configure them through the CLI's normal credential mechanism or your local environment.

The repository ignores local configs, environment files, agent histories, SQLite state, private keys, and certificates. Pane entries are trusted local shell commands and should be reviewed like any shell script.

## Source install

```sh
git clone https://github.com/takeonepiece/coding-sessions.git
cd coding-sessions
./install.sh
```

This installs commands in `~/bin` and builds `~/Applications/Coding Sessions.app`.

## License

MIT

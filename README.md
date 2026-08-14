# Vibe Tabs

Vibe Tabs restores named AI coding workspaces with one click on macOS. A YAML file defines the project folder, tmux layout, Terminal color profile, and any coding commands you want in its panes: Claude, Codex, Gemini, Pi, Aider, OpenCode, a DeepSeek-backed command, or something else entirely.

Each workspace name is shared by tmux and its native Terminal tab. One launch creates one dedicated Terminal window and puts every project in that window as a tab. Claude and Codex additionally get name-aware conversation resume behavior.

Running the launcher again selects the existing named Terminal tab. It does not create duplicate Terminal tabs, tmux sessions, or agent processes.

![Vibe Tabs icon](assets/vibe-tabs-icon.png)

## Install with Homebrew

```sh
brew install takeonepiece/tap/vibe-tabs
```

Your chosen coding CLIs must already be installed and authenticated. Homebrew installs `tmux`, `jq`, `yq`, and `ripgrep`.

Create `~/.vibe-tabs.yml`:

```yaml
version: 1

defaults:
  session_suffix: laptop
  layout: auto
  terminal_profile: Pro
  agents:
    claude:
      dangerous: false
    codex:
      dangerous: false
  panes:
    - agent: claude
    - agent: codex

sessions:
  - name: web
    path: ~/Code/example-web

  - name: mobile
    path: ~/Code/example-mobile
    terminal_profile: Ocean
    panes:
      - agent: gemini
        dangerous: true
      - agent: codex

  - name: research
    path: ~/Code/research
    layout: tiled
    panes:
      - agent: claude
      - agent: pi
        dangerous: true
        dangerous_args: --dangerously-skip-permissions
      - command: aider --model deepseek/deepseek-chat
        title: deepseek
```

Launch everything:

```sh
vibe-tabs
```

Or open the bundled launcher app:

```sh
vibe-tabs --app
```

After opening **Vibe Tabs**, you can keep it in the Dock.

The launcher uses macOS UI scripting only to create native Terminal tabs. The first launch may ask you to allow **Vibe Tabs** under **System Settings → Privacy & Security → Accessibility**.

## YAML specification

The default config path is `~/.vibe-tabs.yml`; `.yaml` is also accepted. A different YAML file can be passed to `vibe-tabs`.

Top level:

- `version`: config schema version; currently `1`.
- `defaults`: optional values inherited by every session.
- `sessions`: required list of session objects.

Defaults and per-session options:

- `session_suffix`: appended to names unless already present; useful for names such as `web-m1-mbp`.
- `layout`: `auto`, `even-horizontal`, `even-vertical`, `main-horizontal`, `main-vertical`, or `tiled`. `auto` uses side-by-side panes for two commands and tiled panes for three or more.
- `terminal_profile`: optional Terminal settings profile such as `Pro`, `Ocean`, or `Homebrew`. A session can override the default.
- `agents`: optional defaults keyed by agent name. Each agent can set `dangerous`, `args`, and `dangerous_args`.
- `panes`: non-empty list of agent or command entries. Plain strings remain supported as shorthand. `claude` and `codex` activate built-in resume handling.

Pane objects support:

- `agent`: executable name, such as `claude`, `codex`, `gemini`, `pi`, or `opencode`.
- `command`: a complete shell command instead of an agent name. Use exactly one of `agent` or `command`.
- `dangerous`: boolean; defaults to `false`. When enabled, Vibe Tabs adds the agent's dangerous-mode arguments.
- `dangerous_args`: override for the flag added by `dangerous: true`. Built-in defaults are `--dangerously-skip-permissions` for Claude and `--yolo` for Codex and Gemini. Unknown agents and custom commands require this field when dangerous mode is enabled.
- `args`: additional shell-style arguments passed whether dangerous mode is on or off.
- `title`: optional short tmux pane title.

Dangerous mode bypasses approval or sandbox safeguards in the selected coding CLI. Enable it only for agents and projects where that is intentional. Never put credentials in `args`, `dangerous_args`, or commands.

Each session requires:

- `name`: stable session name before any suffix.
- `path`: absolute or `~/` project folder.

Per-session options override `defaults`. Existing tmux sessions remain untouched, so pane or layout changes take effect after that tmux session is removed.

## Commands

```sh
# Open every configured workspace
vibe-tabs

# Use another YAML config
vibe-tabs ./team-sessions.yml

# Open one workspace directly with explicit panes
vibe-tab --layout tiled --profile Ocean web-m1-mbp ~/Code/example-web claude codex gemini

# Default to Claude + Codex and derive the name from the folder
vibe-tab ~/Code/example-web
```

## Reuse behavior

1. If the exact tmux session exists, its panes and processes are preserved.
2. If tmux is missing, Claude and Codex histories are searched for the exact name and their saved IDs are resumed when available.
3. If no matching Claude or Codex history exists, a new named conversation is started.
4. Other configured commands launch normally in their own pane.
5. If Terminal already has a tab with the session name, that tab is selected instead of duplicated.
6. If no project tab exists, the first project starts a dedicated Terminal window and later projects become native tabs in it.

## Security

Vibe Tabs does not collect telemetry or send credentials anywhere. Authentication remains inside each coding CLI. Do not put API keys or tokens directly in the YAML; configure them through the CLI's normal credential mechanism or your local environment.

The repository ignores local configs, environment files, agent histories, SQLite state, private keys, and certificates. Pane entries are trusted local shell commands and should be reviewed like any shell script.

## Source install

```sh
git clone https://github.com/takeonepiece/vibe-tabs.git
cd vibe-tabs
./install.sh
```

This installs commands in `~/bin` and builds `~/Applications/Vibe Tabs.app`.

## License

MIT

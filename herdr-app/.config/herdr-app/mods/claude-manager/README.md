<div align="center">

<img src="hero.png" width="100%" alt="All of Claude Code. One switch each. The Claude Manager dialog: tabs for skills, commands, agents, MCP, hooks and plugins, a switch on every row, and per-kind counts in the footer.">

<br>

**Every skill, command, agent, MCP server, hook and plugin Claude Code loads, each with a switch.**<br>
Turn off what you don't need and new sessions start lighter. Turn it back on and your settings file is exactly as it was.

```sh
./install.sh claude-manager
```

<sub><a href="../README.md">All modules</a> · <a href="RECIPE.md">Recipe, to rebuild it with your agent</a></sub>

</div>

## What it does

- **Six tabs:** Skills, Commands, Agents, MCP, Hooks, Plugins. Each has its own icon, and a gauge
  in the footer shows how many items are on (`269/271`). The count turns amber when something is off.
- **Click a row, or press Enter, to flip it.** Off rows dim and carry an amber `off`.
- **Search** across names and descriptions, and hook events. **Off only** shows what you turned off.
- **Hooks** are grouped by event (`PreToolUse`, `Stop`…). The first row, **All hooks**, is the master switch.
- **Move to the Trash** (Skills and Agents tabs): **⌘⌫** names what will go, **⌘⌫** again moves it.
  - A skill goes whole, every file in its folder, along with the real folder if the skill is a link.
  - Finder's Put Back restores it.

## How "off" works

Claude Manager uses Claude Code's own switches in `~/.claude/settings.json`, so nothing is moved or
deleted when you turn something off:

| Tab | Off writes | Effect in a new session |
|---|---|---|
| Skills | `"skillOverrides": {"name": "off"}` | hidden from Claude and from the `/` menu |
| Commands | `"skillOverrides": {"name": "off"}` | gone from the `/` menu |
| Agents | `"permissions.deny": ["Agent(name)"]` | gone from the Agent tool's list |
| MCP | `"deniedMcpServers": [{"serverName": "name"}]` | the server doesn't load, in any project |
| Plugins | `"enabledPlugins": {"name@marketplace": false}` | the plugin and everything in it doesn't load |
| All hooks | `"disableAllHooks": true` | no hook runs, and no status line either |
| One hook | moved to `~/.claude/claude-manager/hooks-off.json` | that hook doesn't run |

Claude Code has no switch for a single hook. So a hook you turn off is set aside in a side file,
along with where it was, and put back in the same place when you turn it on.

Every write is atomic: a temporary file, then a rename. The previous file is kept as
`settings.json.bak-claude-manager`.

## Good to know

- **Changes apply to new sessions.** A running session keeps what it loaded, except agent denials,
  which reach it right away.
- **Plugin skills** don't follow `skillOverrides`. Turn the plugin off instead.
- **Partial modes are lost.** A skill set to `name-only` or `user-invocable-only` comes back plain on
  after an off and on.
- **Shared skills folders.** Trashing a linked skill also trashes the folder it points to. Other tools
  that read that folder (for example `~/.agents/skills`) lose it too.
- **Secrets stay out.** MCP rows show only the transport and the command's name or the URL's host,
  never `env`, headers or arguments.

## Install

```sh
./install.sh claude-manager
```

It opens with **⌘⇧K** in any layout.

| Key | What it does |
|---|---|
| <kbd>↑</kbd> <kbd>↓</kbd> · <kbd>PgUp</kbd> <kbd>PgDn</kbd> | Move |
| <kbd>↵</kbd> or click | On / off |
| <kbd>Tab</kbd> · <kbd>⇧</kbd><kbd>Tab</kbd> | Next / previous tab |
| <kbd>⌘</kbd><kbd>⌫</kbd> twice | Move to the Trash (Skills, Agents) |
| <kbd>Esc</kbd> | Close |

## Requirements

The Herdr desktop app, `python3` and Claude Code. Move to the Trash uses macOS `/usr/bin/trash`.

## Tests

```sh
python3 -I mods/claude-manager/tests/test_manage.py
```

It switches every kind off and on in a throwaway `HOME` and checks the settings file comes back byte
for byte, including hooks put back in a different order and a trashed linked skill.

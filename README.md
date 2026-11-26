# YASB Skills

An [Agent Skill](https://agentskills.io) for writing [YASB](https://github.com/amnweb/yasb) 3 widgets, themes and
layouts with an AI coding agent, and packaging them as addons. It works with Claude Code, Codex, Gemini CLI, GitHub
Copilot and other tools that support Agent Skills.

The skill includes YASB's docs, a starter widget, theme and layouts, and a script that checks an addon and compiles
its QML against YASB.

## Install

In Claude Code:

```
/plugin marketplace add amnweb/yasb-skills
```

```
/plugin install yasb@yasb-skills
```

In Codex:

```powershell
codex plugin marketplace add amnweb/yasb-skills
```

```powershell
codex plugin add yasb@yasb-skills
```

In Gemini CLI:

```powershell
gemini skills install https://github.com/amnweb/yasb-skills.git --path plugins/yasb/skills/yasb
```

For GitHub Copilot, with the GitHub CLI:

```powershell
gh skill install amnweb/yasb-skills plugins/yasb/skills/yasb/SKILL.md
```

For other agents, such as Cursor, OpenCode or Cline, with
[Vercel's skills installer](https://github.com/vercel-labs/skills):

```powershell
npx skills add amnweb/yasb-skills
```

Or copy the `plugins/yasb/skills/yasb` folder into your tool's skills folder:

| Tool | For all projects | For one project |
| --- | --- | --- |
| Claude Code | `%USERPROFILE%\.claude\skills\yasb` | `.claude\skills\yasb` |
| Codex | `%USERPROFILE%\.agents\skills\yasb` | `.agents\skills\yasb` |
| Gemini CLI | `%USERPROFILE%\.gemini\skills\yasb` | `.gemini\skills\yasb` |
| GitHub Copilot CLI | `%USERPROFILE%\.copilot\skills\yasb` | `.github\skills\yasb` |
| GitHub Copilot in VS Code | `%USERPROFILE%\.copilot\skills\yasb` | `.github\skills\yasb` |

Codex, Gemini CLI and GitHub Copilot CLI also read `%USERPROFILE%\.agents\skills\yasb`, so one copy there works for all
three.

If your tool doesn't support skills, copy [templates/AGENTS.md](templates/AGENTS.md) into your YASB config folder
(`%USERPROFILE%\.config\yasb`) and open the tool there.

## Usage

Ask for a widget, theme or layout, for example "a YASB widget that shows my public IP". The skill loads automatically,
or run `/yasb:yasb` in Claude Code.

The agent saves the files to your config folder and checks `yasb.log` for errors while YASB is running. If you have
the YASB repository on your PC with its Python packages installed, tell the agent where it is, and it compiles the
QML before YASB loads it.

## License

[MIT](LICENSE)
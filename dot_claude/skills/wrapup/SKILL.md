name: wrapup
description: Execute wrap-up protocol — collect facts, commit, check for SOP. Trigger: /wrapup
disable-model-invocation: true
---

# Wrap-Up Protocol

Execute end-of-session knowledge capture and commit.

## Trigger

User runs `/wrapup` command.

## Steps

### 1. Collect Facts

Scan session for **non-obvious, non-ephemeral** facts — things not already in BrainOS files or git history:

| Fact type | Destination | Examples |
|-----------|-------------|----------|
| Technical reference | `Knowledge/` subtree | Board specs, protocol details, pinouts, version numbers |
| Project-level info | `Projects/{project}/` subtree | Rollout scope, QA results, client decisions |
| Operator preference | `Rules/` or memory/ | Workflow corrections, tool preferences |

**Skip**: anything already recorded, session-only chatter, draft message text.

### 2. Commit

Stage and commit all changed files. Message follows conventional commit format. No separate confirmation needed — `/wrapup` is the confirmation.

### 3. Flag Repeatable Procedures (follow-up)

After commit, scan session for any repeatable procedure. If found, ask the user where to store it:

| Option | Location | When to use |
|--------|----------|-------------|
| Project-scoped skill | `.claude/skills/{slug}/SKILL.md` | Procedure specific to this project, invoked via `/skill-name` |
| User-scoped skill | `~/.claude/skills/{slug}/SKILL.md` | Procedure applies across all projects |
| Rules file | `Rules/{slug}.md` | Behavioral constraint or coding preference (not executable steps) |
| Knowledge reference | `Knowledge/` subtree | Passive reference material (not triggered by command) |

Present options and ask user to choose. Default recommendation: project-scoped skill (keeps skills close to the context they need).

On confirmation, create the skill/Rule/Knowledge file and commit.

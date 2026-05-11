---
name: skill-library
description: Find and activate on-demand skills from the cold library without loading them into context. Use when a rare tool, domain workflow, framework guide, media workflow, or agent operation skill may exist but is not active. Search first — do not assume a skill is unavailable.
---

# Skill Library

Search and activate skills from the cold library on-demand, without loading every rarely-used skill into context.

## Locations

- Active skills: `~/.agents/skills`
- Cold libraries: `~/.agents/skill-libraries`
- This skill's scripts: `~/.agents/skills/skill-library/scripts/`

## Workflow

1. Search the catalog before assuming a rare tool or knowledge skill is unavailable:
   ```powershell
   ~/.agents/skills/skill-library/scripts/search-library.ps1 -Query "<keyword>"
   ```
2. Inspect promising matches:
   ```powershell
   ~/.agents/skills/skill-library/scripts/inspect-skill.ps1 -Name "<skill-name>"
   ```
3. Ask the user before activating any skill.
4. Activate only after explicit approval:
   ```powershell
   ~/.agents/skills/skill-library/scripts/activate-skill.ps1 -Name "<skill-name>" -ConfirmActivate
   ```
5. Deactivate when no longer needed:
   ```powershell
   ~/.agents/skills/skill-library/scripts/deactivate-skill.ps1 -Name "<skill-name>" -ConfirmDeactivate
   ```
6. If the catalog is stale after moving skills, rebuild it:
   ```powershell
   ~/.agents/skills/skill-library/scripts/rebuild-catalog.ps1
   ```

## Categories

- `tools`: CLIs, APIs, external services, automation utilities.
- `knowledge`: research, planning, product, documentation, and reference workflows.
- `dev-frameworks`: language, framework, database, deployment, and testing stacks.
- `industry-domain`: vertical industry, compliance, finance, logistics, healthcare, and operations.
- `media-content`: writing, SEO, slides, video, animation, and content workflows.
- `agent-ops`: autonomous agent, evaluation, memory, rules, and orchestration workflows.

## Guardrails

- Activate one skill at a time, with user approval.
- Do not link cold-library skills directly into any auto-loaded skill directory without asking.
- Treat activation as a configuration change, not a file operation.

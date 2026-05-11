---
name: skill-library
description: Find and activate on-demand skills from the cold library at C:\Users\w\.agents\skill-libraries without loading all 170 skills into context. Use when a rare tool, domain workflow, framework guide, media workflow, or agent operation skill may exist but is not active. Search first — do not assume a skill is unavailable.
---

# Skill Library

Use this skill to discover cold-library skills without loading all 170 on-demand skills into Claude's context at once.

## Locations

- Active shared skills: `C:\Users\w\.agents\skills`
- Claude skill junctions: `C:\Users\w\.claude\skills`
- Cold libraries: `C:\Users\w\.agents\skill-libraries`

## Workflow

0. If the catalog looks stale after archive changes, rebuild it:
   ```powershell
   C:\Users\w\.agents\skills\skill-library\scripts\rebuild-catalog.ps1
   ```
1. Search the catalog before saying a rare tool or knowledge skill is unavailable:
   ```powershell
   C:\Users\w\.agents\skills\skill-library\scripts\search-library.ps1 -Query "<keyword>"
   ```
2. Inspect promising matches:
   ```powershell
   C:\Users\w\.agents\skills\skill-library\scripts\inspect-skill.ps1 -Name "<skill-name>"
   ```
3. Ask the user before activating any archived skill.
4. Activate only after explicit approval:
   ```powershell
   C:\Users\w\.agents\skills\skill-library\scripts\activate-skill.ps1 -Name "<skill-name>" -ConfirmActivate
   ```
5. If a restored skill is no longer needed, deactivate it after explicit approval:
   ```powershell
   C:\Users\w\.agents\skills\skill-library\scripts\deactivate-skill.ps1 -Name "<skill-name>" -ConfirmDeactivate
   ```

## Categories

- `tools`: CLIs, APIs, external services, automation utilities.
- `knowledge`: research, planning, product, documentation, and reference workflows.
- `dev-frameworks`: language, framework, database, deployment, and testing stacks.
- `industry-domain`: vertical industry, compliance, finance, logistics, healthcare, and operations.
- `media-content`: writing, SEO, slides, video, animation, and content workflows.
- `agent-ops`: ECC, autonomous agent, evaluation, memory, rules, and orchestration workflows.

## Guardrails

- Do not link archived library skills directly into `.claude\skills`.
- Do not place archived skill bodies under `.agents\skills\skill-library`.
- Do not touch `.codex\skills` unless the user explicitly asks.
- Treat activation as a configuration change: ask first, then restore one skill at a time.

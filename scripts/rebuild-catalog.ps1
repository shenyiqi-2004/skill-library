param(
    [string]$ArchiveRoot = "C:\Users\w\.agents\skills-archive",
    [string]$LibraryRoot = "C:\Users\w\.agents\skill-libraries"
)

$ErrorActionPreference = "Stop"

$categories = @(
    "tools",
    "knowledge",
    "dev-frameworks",
    "industry-domain",
    "media-content",
    "agent-ops"
)

foreach ($category in $categories) {
    $categoryPath = Join-Path $LibraryRoot $category
    New-Item -ItemType Directory -Force -Path $categoryPath | Out-Null
    Get-ChildItem -LiteralPath $categoryPath -Directory -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force
}

function Get-FrontmatterDescription {
    param([string]$SkillFile)

    $lines = Get-Content -LiteralPath $SkillFile -TotalCount 160
    if ($lines.Count -eq 0 -or $lines[0] -ne "---") {
        return ""
    }

    $frontmatter = @()
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq "---") { break }
        $frontmatter += $lines[$i]
    }

    $descriptionLines = @()
    $collecting = $false
    foreach ($line in $frontmatter) {
        if ($line -match "^description:\s*(.*)$") {
            $collecting = $true
            $first = $Matches[1]
            if ($first -notmatch "^>[-+]?$|^\|[-+]?$" -and $first.Trim()) {
                $descriptionLines += $first
            }
            continue
        }

        if ($collecting) {
            if ($line -match "^[A-Za-z0-9_-]+:\s*") { break }
            if ($line -match "^\s+(.*)$") {
                $descriptionLines += $Matches[1]
            } else {
                break
            }
        }
    }

    $value = ($descriptionLines -join " ").Trim()
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    return (($value -replace "\s+", " ").Trim())
}

function Get-Category {
    param(
        [string]$Name,
        [string]$Description
    )

    $nameText = $Name.ToLowerInvariant()
    $allText = ($Name + " " + $Description).ToLowerInvariant()

    if ($nameText -match "^(jira-integration|google-workspace-ops|email-ops|messages-ops|unified-notifications-ops|x-api|exa-search|fal-ai-media|videodb|csv-data-summarizer|data-scraper-agent|api-connector-builder|nanoclaw-repl|automation-audit-ops)$" -or
        $nameText -match "^(mcp-server-patterns|content-hash-cache-pattern|hermes-imports)$") {
        return "tools"
    }

    if ($nameText -match "^(healthcare|hipaa|defi|evm|visa|energy|customs|inventory|logistics|quality|returns|production|carrier|customer|finance|investor|lead|agent-payment|llm-trading)" -or
        $allText -match "healthcare|hipaa|emr|cdss|phi|energy procurement|customs|trade compliance|inventory|demand planning|production scheduling|quality nonconformance|reverse logistics|billing|financial model|investor outreach|visa document|defi|trading agent|token decimals") {
        return "industry-domain"
    }

    if ($nameText -match "(video|media|remotion|manim|seo|article|brand|content-engine|crosspost|frontend-slides|social-graph|ui-demo|liquid-glass)" -or
        $allText -match "video|animation|seo|article writing|brand voice|content workflow|slides|screen recording") {
        return "media-content"
    }

    if ($nameText -match "(django|laravel|springboot|kotlin|rust|golang|cpp|csharp|dotnet|java|perl|flutter|dart|android|nestjs|nuxt|nextjs|bun|postgres|clickhouse|database|docker|deployment|jpa|ktor|exposed|coroutines|swift|testing|patterns|security|tdd|verification|clean-architecture|hexagonal)" -or
        $allText -match "framework|runtime|package manager|database migration|orm|api design with drf") {
        return "dev-frameworks"
    }

    if ($nameText -match "(agent-eval|agent-harness|agentic|autonomous|continuous-agent|continuous-learning|eval-harness|council|openclaw|claude-devfleet|team-builder|configure-ecc|dmux|skill-comply|rules-distill|agent-sort|agent-introspection|ai-first|strategic-compact|cost-aware-llm|token-budget|gateguard|santa-method|^ck$)" -or
        $allText -match "agent harness|autonomous agent|claude code|ecc ecosystem|evaluation framework") {
        return "agent-ops"
    }

    if ($nameText -match "(knowledge|research|market|company|documentation|document|retrieval|rfc|architecture-decision|product|code-tour|regex|structured-text)" -or
        $allText -match "research|documentation|product direction|decision record|retrieval") {
        return "knowledge"
    }

    return "knowledge"
}

function Escape-MarkdownCell {
    param(
        [AllowNull()][string]$Value,
        [int]$Max = 180
    )

    if ($null -eq $Value) { return "" }
    $escaped = ($Value -replace "\|", "/" -replace "`r?`n", " ").Trim()
    if ($escaped.Length -gt $Max) {
        $escaped = $escaped.Substring(0, $Max - 3) + "..."
    }
    return $escaped
}

$items = @()
foreach ($archive in Get-ChildItem -LiteralPath $ArchiveRoot -Directory | Sort-Object Name) {
    $sourceRoot = Join-Path $archive.FullName "agents-skills"
    if (-not (Test-Path -LiteralPath $sourceRoot)) { continue }

    foreach ($skillDir in Get-ChildItem -LiteralPath $sourceRoot -Directory | Sort-Object Name) {
        $skillFile = Join-Path $skillDir.FullName "SKILL.md"
        if (-not (Test-Path -LiteralPath $skillFile)) { continue }

        $description = Get-FrontmatterDescription -SkillFile $skillFile
        $category = Get-Category -Name $skillDir.Name -Description $description
        $destination = Join-Path (Join-Path $LibraryRoot $category) $skillDir.Name
        if (Test-Path -LiteralPath $destination) {
            $destination = Join-Path (Join-Path $LibraryRoot $category) ($skillDir.Name + "--" + $archive.Name)
        }

        Copy-Item -LiteralPath $skillDir.FullName -Destination $destination -Recurse -Force

        $suggestedAction = if ($skillDir.Name -match "prompt-optimizer|blueprint|search-first|tdd-workflow|verification-loop|accessibility|documentation-lookup|everything-claude-code") {
            "review-before-restore"
        } else {
            "restore-on-demand"
        }

        $riskNotes = if ($skillDir.Name -match "security|bounty|payment|trading|hipaa|healthcare|phi|defi|token|credential|auth|ops|automation|deploy|vercel|jira|google|email|messages|x-api") {
            "Review tool access, secrets, and external side effects before activation."
        } else {
            "Low to medium. Inspect SKILL.md before activation."
        }

        $items += [pscustomobject]@{
            name = $skillDir.Name
            category = $category
            library_path = $destination
            source_archive = $archive.Name
            source_path = $skillDir.FullName
            origin = if ($archive.Name -match "ecc") { "ECC archived" } elseif ($archive.Name -match "manual") { "manual prune archive" } else { "local archived" }
            description = $description
            suggested_action = $suggestedAction
            risk_notes = $riskNotes
        }
    }
}

$items = @($items | Sort-Object category, name, source_archive)

[pscustomobject]@{
    generated_at = (Get-Date).ToString("o")
    library_root = $LibraryRoot
    archive_root = $ArchiveRoot
    items = $items
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $LibraryRoot "catalog.json") -Encoding UTF8

$catalog = New-Object System.Text.StringBuilder
[void]$catalog.AppendLine("# Agent Skill Libraries Catalog")
[void]$catalog.AppendLine("")
[void]$catalog.AppendLine("Cold library for archived skills. These skills are not active until restored to C:\Users\w\.agents\skills and linked from C:\Users\w\.claude\skills.")
[void]$catalog.AppendLine("")

foreach ($category in $categories) {
    $group = @($items | Where-Object { $_.category -eq $category } | Sort-Object name)
    [void]$catalog.AppendLine("## $category")
    [void]$catalog.AppendLine("")
    [void]$catalog.AppendLine("| Skill | Description | Source | Action | Risk |")
    [void]$catalog.AppendLine("|---|---|---|---|---|")
    foreach ($item in $group) {
        [void]$catalog.AppendLine("| ``$($item.name)`` | $(Escape-MarkdownCell $item.description) | $($item.source_archive) | $($item.suggested_action) | $(Escape-MarkdownCell $item.risk_notes 140) |")
    }
    [void]$catalog.AppendLine("")
}

[System.IO.File]::WriteAllText((Join-Path $LibraryRoot "catalog.md"), $catalog.ToString(), [System.Text.UTF8Encoding]::new($false))

foreach ($category in $categories) {
    $categoryFile = Join-Path $LibraryRoot ($category + ".md")
    $group = @($items | Where-Object { $_.category -eq $category } | Sort-Object name)
    $markdown = New-Object System.Text.StringBuilder
    [void]$markdown.AppendLine("# $category")
    [void]$markdown.AppendLine("")
    [void]$markdown.AppendLine("| Skill | Description | Path |")
    [void]$markdown.AppendLine("|---|---|---|")
    foreach ($item in $group) {
        [void]$markdown.AppendLine("| ``$($item.name)`` | $(Escape-MarkdownCell $item.description 220) | ``$($item.library_path)`` |")
    }
    [System.IO.File]::WriteAllText($categoryFile, $markdown.ToString(), [System.Text.UTF8Encoding]::new($false))
}

$items | Group-Object category | Sort-Object Name | Select-Object Name, Count

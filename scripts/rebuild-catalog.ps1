param(
    [string]$LibraryRoot = "$env:USERPROFILE\.agents\skill-libraries",
    [string]$ActiveSkills = "$env:USERPROFILE\.agents\skills"
)

$ErrorActionPreference = "Stop"

$categories = @("tools","knowledge","dev-frameworks","industry-domain","media-content","agent-ops")

function Get-FrontmatterDescription {
    param([string]$SkillFile)
    $lines = Get-Content -LiteralPath $SkillFile -TotalCount 160
    if ($lines.Count -eq 0 -or $lines[0] -ne "---") { return "" }
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
            if ($first -notmatch "^>[-+]?$|^\|[-+]?$" -and $first.Trim()) { $descriptionLines += $first }
            continue
        }
        if ($collecting) {
            if ($line -match "^[A-Za-z0-9_-]+:\s*") { break }
            if ($line -match "^\s+(.*)$") { $descriptionLines += $Matches[1] }
            else { break }
        }
    }
    $value = ($descriptionLines -join " ").Trim()
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    return ($value -replace "\s+", " ").Trim()
}

function Get-Category {
    param([string]$Name, [string]$Description)
    $nameText = $Name.ToLowerInvariant()
    $allText = ($Name + " " + $Description).ToLowerInvariant()
    # Match against known patterns — adjust to your own skill set
    if ($nameText -match "^(jira|google-workspace|email-|messages-|unified-notifications|x-api|exa-|fal-ai|videodb|api-connector|nanoclaw|automation-audit|mcp-server-patterns|content-hash)") { return "tools" }
    if ($nameText -match "^(healthcare|hipaa|defi|evm|visa|energy|customs|inventory|logistics|quality|returns|production|carrier|customer-billing|finance|investor|lead|agent-payment|llm-trading)") { return "industry-domain" }
    if ($nameText -match "(video|media|remotion|manim|seo|article|brand|content-engine|crosspost|frontend-slides|social-graph|ui-demo|liquid-glass)") { return "media-content" }
    if ($nameText -match "(django|laravel|springboot|kotlin|rust|golang|cpp|csharp|dotnet|java|perl|flutter|dart|android|nestjs|nuxt|nextjs|bun|postgres|clickhouse|database|docker|deployment|jpa|ktor|exposed|coroutines|swift|testing$|patterns$|security$|tdd|verification|clean-architecture|hexagonal)") { return "dev-frameworks" }
    if ($nameText -match "(agent-eval|agent-harness|agentic|autonomous|continuous-agent|continuous-learning|eval-harness|council|openclaw|claude-devfleet|team-builder|configure-ecc|dmux|skill-comply|rules-distill|agent-sort|agent-introspection|ai-first|strategic-compact|cost-aware-llm|token-budget|gateguard|santa-method|^ck$)") { return "agent-ops" }
    if ($nameText -match "(knowledge|research|market|company|documentation|document|retrieval|rfc|architecture-decision|product|code-tour|regex|structured-text)") { return "knowledge" }
    return "knowledge"
}

$items = @()
foreach ($category in $categories) {
    $categoryPath = Join-Path $LibraryRoot $category
    if (-not (Test-Path $categoryPath)) { continue }
    foreach ($skillDir in Get-ChildItem -LiteralPath $categoryPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name) {
        $skillFile = Join-Path $skillDir.FullName "SKILL.md"
        if (-not (Test-Path -LiteralPath $skillFile)) { continue }
        $description = Get-FrontmatterDescription -SkillFile $skillFile
        $items += [pscustomobject]@{
            name = $skillDir.Name
            category = $category
            path = $skillDir.FullName
            description = $description
        }
    }
}

$items = @($items | Sort-Object category, name)

[pscustomobject]@{
    generated_at = (Get-Date).ToString("o")
    library_root = $LibraryRoot
    items = $items
} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $LibraryRoot "catalog.json") -Encoding UTF8

Write-Output "Catalog rebuilt: $($items.Count) skills across $($categories.Count) categories"

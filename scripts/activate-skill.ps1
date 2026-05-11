param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [switch]$ConfirmActivate
)

$ErrorActionPreference = "Stop"

if (-not $ConfirmActivate) {
    throw "Activation changes active skills. Re-run with -ConfirmActivate after user approval."
}

$skillRoot = Split-Path -Parent $PSScriptRoot
$agentsRoot = Split-Path -Parent (Split-Path -Parent $skillRoot)
$libraryRoot = Join-Path $agentsRoot "skill-libraries"
$activeRoot = Join-Path $agentsRoot "skills"
$claudeRoot = Join-Path (Split-Path -Parent $agentsRoot) ".claude\skills"
$catalogPath = Join-Path $libraryRoot "catalog.json"

if (-not (Test-Path -LiteralPath $catalogPath)) {
    throw "Catalog not found: $catalogPath"
}

$catalogDoc = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$catalog = if ($catalogDoc.PSObject.Properties.Name -contains "items") { @($catalogDoc.items) } else { @($catalogDoc) }
$matches = @($catalog | Where-Object { $_.name -eq $Name })

if ($matches.Count -eq 0) {
    throw "No archived skill found for exact name: $Name"
}

if ($matches.Count -gt 1) {
    "Multiple archived entries have this name. Inspect and activate manually:"
    $matches | Select-Object name, category, source_archive, library_path | Format-Table -AutoSize -Wrap
    exit 2
}

$item = $matches[0]
$sourcePath = $item.library_path
$activePath = Join-Path $activeRoot $item.name
$claudePath = Join-Path $claudeRoot $item.name

if (-not (Test-Path -LiteralPath (Join-Path $sourcePath "SKILL.md"))) {
    throw "Source skill is invalid or missing SKILL.md: $sourcePath"
}

if (Test-Path -LiteralPath $activePath) {
    throw "Active skill already exists: $activePath"
}

Copy-Item -LiteralPath $sourcePath -Destination $activePath -Recurse

$existingClaude = Get-Item -LiteralPath $claudePath -Force -ErrorAction SilentlyContinue
if ($existingClaude) {
    $target = @($existingClaude.Target)[0]
    if ($existingClaude.LinkType -eq "Junction" -and $target -eq $activePath) {
        [pscustomobject]@{ activated = $activePath; claude_junction = $claudePath; status = "already-linked" }
        exit 0
    }
    throw "Claude path already exists and is not the expected junction: $claudePath"
}

New-Item -ItemType Junction -Path $claudePath -Target $activePath | Out-Null

[pscustomobject]@{
    activated = $activePath
    claude_junction = $claudePath
    source = $sourcePath
    status = "activated"
} | Format-List

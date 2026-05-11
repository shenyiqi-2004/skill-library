param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [switch]$Full
)

$ErrorActionPreference = "Stop"

$skillRoot = Split-Path -Parent $PSScriptRoot
$agentsRoot = Split-Path -Parent (Split-Path -Parent $skillRoot)
$libraryRoot = Join-Path $agentsRoot "skill-libraries"
$catalogPath = Join-Path $libraryRoot "catalog.json"

if (-not (Test-Path -LiteralPath $catalogPath)) {
    throw "Catalog not found: $catalogPath"
}

$catalogDoc = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
$catalog = if ($catalogDoc.PSObject.Properties.Name -contains "items") { @($catalogDoc.items) } else { @($catalogDoc) }
$matches = @($catalog | Where-Object { $_.name -eq $Name })

if ($matches.Count -eq 0) {
    $matches = @($catalog | Where-Object { $_.name -like "*$Name*" })
}

if ($matches.Count -eq 0) {
    throw "No archived skill found for: $Name"
}

if ($matches.Count -gt 1) {
    "Multiple matches found. Re-run with the exact name:"
    $matches | Select-Object name, category, source_archive, library_path | Format-Table -AutoSize -Wrap
    exit 2
}

$item = $matches[0]
$skillFile = Join-Path $item.library_path "SKILL.md"

if (-not (Test-Path -LiteralPath $skillFile)) {
    throw "SKILL.md not found: $skillFile"
}

[pscustomobject]@{
    name = $item.name
    category = $item.category
    description = $item.description
    library_path = $item.library_path
    source_archive = $item.source_archive
    suggested_action = $item.suggested_action
    risk_notes = $item.risk_notes
} | Format-List

""
"--- SKILL.md preview ---"
if ($Full) {
    Get-Content -LiteralPath $skillFile
} else {
    Get-Content -LiteralPath $skillFile -TotalCount 140
}

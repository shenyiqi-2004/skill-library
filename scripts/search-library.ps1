param(
    [string]$Query = "",
    [ValidateSet("tools", "knowledge", "dev-frameworks", "industry-domain", "media-content", "agent-ops")]
    [string]$Category,
    [int]$Limit = 30,
    [switch]$Json
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

if ($Category) {
    $catalog = @($catalog | Where-Object { $_.category -eq $Category })
}

if ($Query.Trim()) {
    $terms = $Query.ToLowerInvariant().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($term in $terms) {
        $catalog = @($catalog | Where-Object {
            (($_.name + " " + $_.category + " " + $_.description + " " + $_.source_archive) -as [string]).ToLowerInvariant().Contains($term)
        })
    }
}

$matches = @($catalog | Sort-Object category, name | Select-Object -First $Limit)

if ($Json) {
    $matches | ConvertTo-Json -Depth 6
    exit 0
}

$matches |
    Select-Object name, category, description, source_archive, suggested_action |
    Format-Table -AutoSize -Wrap

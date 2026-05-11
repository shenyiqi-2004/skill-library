param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [switch]$ConfirmDeactivate
)

$ErrorActionPreference = "Stop"

if (-not $ConfirmDeactivate) {
    throw "Deactivation changes active skills. Re-run with -ConfirmDeactivate after user approval."
}

$skillRoot = Split-Path -Parent $PSScriptRoot
$agentsRoot = Split-Path -Parent (Split-Path -Parent $skillRoot)
$libraryRoot = Join-Path $agentsRoot "skill-libraries"
$activeRoot = Join-Path $agentsRoot "skills"
$claudeRoot = Join-Path (Split-Path -Parent $agentsRoot) ".claude\skills"
$catalogPath = Join-Path $libraryRoot "catalog.json"

$activePath = Join-Path $activeRoot $Name
$claudePath = Join-Path $claudeRoot $Name

if (-not (Test-Path -LiteralPath $activePath)) {
    throw "Active skill not found: $activePath"
}

$category = "knowledge"
if (Test-Path -LiteralPath $catalogPath) {
    $catalogDoc = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
    $catalog = if ($catalogDoc.PSObject.Properties.Name -contains "items") { @($catalogDoc.items) } else { @($catalogDoc) }
    $match = @($catalog | Where-Object { $_.name -eq $Name } | Select-Object -First 1)
    if ($match.Count -gt 0 -and $match[0].category) {
        $category = $match[0].category
    }
}

$destinationRoot = Join-Path $libraryRoot $category
New-Item -ItemType Directory -Force -Path $destinationRoot | Out-Null

$destination = Join-Path $destinationRoot $Name
if (Test-Path -LiteralPath $destination) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $destination = Join-Path $destinationRoot ($Name + "--deactivated-" + $stamp)
}

$existingClaude = Get-Item -LiteralPath $claudePath -Force -ErrorAction SilentlyContinue
if ($existingClaude) {
    $target = @($existingClaude.Target)[0]
    if ($existingClaude.LinkType -ne "Junction" -or $target -ne $activePath) {
        throw "Claude path exists but is not the expected junction: $claudePath"
    }
    try {
        Remove-Item -LiteralPath $claudePath -Force -ErrorAction Stop
    } catch {
        [System.IO.Directory]::Delete($claudePath)
    }
}

Move-Item -LiteralPath $activePath -Destination $destination

[pscustomobject]@{
    deactivated = $Name
    moved_to = $destination
    removed_claude_junction = [bool]$existingClaude
    status = "deactivated"
} | Format-List

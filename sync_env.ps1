# Reads network.env and writes it into PULSE/.env and PULSE-CC/.env
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root "network.env"

if (-not (Test-Path $src)) {
    Write-Error "network.env not found in project root."
    exit 1
}

$vars = @{}
Get-Content $src | ForEach-Object {
    if ($_ -match '^\s*([A-Z_]+)\s*=\s*(.+)$') {
        $vars[$Matches[1]] = $Matches[2].Trim()
    }
}

$lines = @()
if ($vars['API_BASE_URL']) {
    $lines += "API_BASE_URL=$($vars['API_BASE_URL'])"
    Write-Host "  Mode: Cloud (API_BASE_URL=$($vars['API_BASE_URL']))"
} else {
    $lines += "API_HOST=$($vars['API_HOST'])"
    $lines += "API_PORT=$($vars['API_PORT'])"
    Write-Host "  Mode: LAN (API_HOST=$($vars['API_HOST']):$($vars['API_PORT']))"
}
$content = ($lines -join "`n") + "`n"

Set-Content -Path (Join-Path $root "PULSE\.env") -Value $content -NoNewline
Set-Content -Path (Join-Path $root "PULSE-CC\.env") -Value $content -NoNewline

Write-Host "Synced network.env -> PULSE/.env and PULSE-CC/.env"

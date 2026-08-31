param(
    [string]$RepoRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
Write-Host "Scanning working tree for secrets..." -ForegroundColor Cyan

$patterns = @(
    'value:\s+[a-f0-9]{20,}',
    'password:\s+[^\s\{]',
    'token:\s+(?!(?:true|false|null|~)\b)[^\s\{]',
    'PRIVATE KEY',
    'api\s+key\s*=\s*[0-9a-fA-F-]{20,}'
)

$scanExtensions = @("*.yaml", "*.yml", "*.env", "*.conf")
$hits = @()
foreach ($pattern in $patterns) {
    foreach ($extension in $scanExtensions) {
        $found = Get-ChildItem -Path $RepoRoot -Filter $extension -Recurse -File |
            Select-String -Pattern $pattern -ErrorAction SilentlyContinue
        if ($found) { $hits += $found }
    }
}

$hits = $hits | Where-Object { $_.Line -notmatch '\{\{' }
if ($hits.Count -gt 0) {
    Write-Host "Secret scan FAILED. Review the following matches:" -ForegroundColor Red
    $hits | ForEach-Object {
        Write-Host "  $($_.Path):$($_.LineNumber)" -ForegroundColor Yellow
    }
    exit 1
}

Write-Host "Scan passed - no secrets detected." -ForegroundColor Green

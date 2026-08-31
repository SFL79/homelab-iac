<#
.SYNOPSIS
Validate that every .sfl Ingress or IngressRoute is explicitly cataloged or excluded.
#>

param(
    [string]$RepoRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
$requiredAnnotations = @(
    "name",
    "description",
    "group",
    "icon",
    "href",
    "weight"
)
$allowedGroups = @("Media", "AI", "Operations", "Platform")
$errors = @()
$enabledRoutes = @()

$yamlFiles = Get-ChildItem -LiteralPath (Join-Path $RepoRoot "k8s") -Recurse -File |
    Where-Object { $_.Extension -in @(".yaml", ".yml") }

foreach ($file in $yamlFiles) {
    $relativePath = $file.FullName.Substring($RepoRoot.Length).TrimStart("\", "/")
    $documents = (Get-Content -Raw -LiteralPath $file.FullName) -split '(?m)^---\s*$'

    for ($documentIndex = 0; $documentIndex -lt $documents.Count; $documentIndex++) {
        $document = $documents[$documentIndex]
        if ($document -notmatch '(?m)^kind:\s+(Ingress|IngressRoute)\s*$') {
            continue
        }
        $resourceKind = $Matches[1]
        if ($document -notmatch '\.sfl') {
            continue
        }

        $resourceName = if ($document -match '(?ms)^metadata:\s*\r?\n(?:\s{2}.*\r?\n)*?\s{2}name:\s*([^\r\n]+)') {
            $Matches[1].Trim()
        } else {
            "document-$($documentIndex + 1)"
        }
        $resourceId = "$relativePath::$resourceKind/$resourceName"

        if ($document -notmatch '(?m)^\s+gethomepage\.dev/enabled:\s*["'']?(true|false)["'']?\s*$') {
            $errors += "$resourceId is missing gethomepage.dev/enabled"
            continue
        }

        $enabled = $Matches[1] -eq "true"
        if (-not $enabled) {
            continue
        }

        foreach ($annotation in $requiredAnnotations) {
            if ($document -notmatch "(?m)^\s+gethomepage\.dev/$([regex]::Escape($annotation)):\s*\S.*$") {
                $errors += "$resourceId is missing gethomepage.dev/$annotation"
            }
        }

        if ($document -match '(?m)^\s+gethomepage\.dev/group:\s*["'']?([^"''\r\n]+)["'']?\s*$') {
            $group = $Matches[1].Trim()
            if ($group -notin $allowedGroups) {
                $errors += "$resourceId uses unsupported catalog group '$group' (allowed: $($allowedGroups -join ', '))"
            }
        }

        $isExternal = $document -match '(?m)^\s+gethomepage\.dev/external:\s*["'']?true["'']?\s*$'
        if (-not $isExternal) {
            $errors += "$resourceId must set gethomepage.dev/external: true to keep one application-level status request per card"
        }

        $hasSiteMonitor = $document -match '(?m)^\s+gethomepage\.dev/siteMonitor:\s*\S.*$'
        $hasPing = $document -match '(?m)^\s+gethomepage\.dev/ping:\s*\S.*$'
        if (-not $hasSiteMonitor -and -not $hasPing) {
            $errors += "$resourceId must set gethomepage.dev/siteMonitor or gethomepage.dev/ping"
        }

        if ($document -match '(?m)^\s+gethomepage\.dev/href:\s*["'']?([^"''\s]+)') {
            $href = $Matches[1]
            if ($enabledRoutes -contains $href) {
                $errors += "$resourceId duplicates enabled catalog href $href"
            } else {
                $enabledRoutes += $href
            }
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Homepage catalog validation FAILED:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}

Write-Host "Homepage catalog validation passed: $($enabledRoutes.Count) unique routes enabled." -ForegroundColor Green

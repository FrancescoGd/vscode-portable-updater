<#
.SYNOPSIS
    Update VSCode Portable installations while preserving user data.

.DESCRIPTION
    1. Renames VSCode -> VSCode-bak
    2. Locates most recent ZIP VSCode-win32-x64-*.zip (using semantic versioning)
    3. Extracts ZIP -> VSCode
    4. Copies VSCode-bak\data -> VSCode\data
    5. Deletes source ZIP after a simple check

.NOTES
    Author   : Francesco Giordano
    Email    : inuyaksa@geocities.com
    Version  : 1.0.2
    License  : MIT

.LINK
    https://github.com/FrancescoGd/vscode-portable-updater
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$basePath = $PSScriptRoot
$vscodePath = Join-Path -Path $basePath -ChildPath 'VSCode'
$backupPath = Join-Path -Path $basePath -ChildPath 'VSCode-bak'

# ---------------------------------------------------------------------------
# Helper Function - extract semantic version from file name
# ---------------------------------------------------------------------------
function Get-ZipSemanticVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FileName
    )
    # Expected pattern: VSCode-win32-x64-<major>.<minor>.<patch>.zip
    if ($FileName -match 'VSCode-win32-x64-(\d+\.\d+\.\d+)\.zip$') {
        try {
            return [System.Version]$Matches[1]
        }
        catch {
            return $null
        }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Step 0 - Initiial Checks
# ---------------------------------------------------------------------------
Write-Host '=== VSCode Portable Update ===' -ForegroundColor Cyan

if (-not (Test-Path -Path $vscodePath -PathType Container)) {
    Write-Error "'$vscodePath' directory not found, nothing to update."
    exit 1
}

if (Test-Path -Path $backupPath) {
    Write-Error "The backup directory '$backupPath' already exists, remove or rename it."
    exit 1
}

# --- Find and select the correct ZIP based on version number ---
$allZips = Get-ChildItem -Path $basePath -Filter 'VSCode-win32-x64-*.zip' -File

if (-not $allZips -or $allZips.Count -eq 0) {
    Write-Error "No 'VSCode-win32-x64-*.zip' file found in '$basePath'."
    exit 1
}

# Create a list of every ZIP and version number rejecting non parseable files
$zipVersions = $allZips | ForEach-Object {
    $ver = Get-ZipSemanticVersion -FileName $_.Name
    if ($ver) {
        [PSCustomObject]@{
            File    = $_
            Version = $ver
        }
    }
    else {
        Write-Warning "'$($_.Name)' ignored: cannot extract version from name."
    }
}

if (-not $zipVersions) {
    Write-Error "Cannot find a ZIP with a valid semantic version."
    exit 1
}

# Sort by version-descending and pick the most recent
$selected = $zipVersions | Sort-Object -Property Version -Descending | Select-Object -First 1
$zipFile = $selected.File

if ($allZips.Count -gt 1) {
    Write-Host "Found $($allZips.Count) corresponding ZIP:" -ForegroundColor Yellow
    $zipVersions | Sort-Object -Property Version -Descending | ForEach-Object {
        $marker = if ($_.File.Name -eq $zipFile.Name) { ' >> ' } else { '    ' }
        Write-Host "$marker$($_.File.Name)  (v$($_.Version))" -ForegroundColor Gray
    }
    Write-Host "Selected: $($zipFile.Name)" -ForegroundColor Green
}
else {
    Write-Host "Found ZIP: $($zipFile.Name)  (v$($selected.Version))" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Step 1 - Rename VSCode -> VSCode-bak
# ---------------------------------------------------------------------------
Write-Host "`n[1/4] Renaming 'VSCode' -> 'VSCode-bak' ..." -ForegroundColor Yellow

try {
    Rename-Item -Path $vscodePath -NewName 'VSCode-bak'
    Write-Host '      OK.' -ForegroundColor Green
}
catch {
    Write-Error "Error while renaming: $_"
    exit 1
}

# ---------------------------------------------------------------------------
# Step 2 - Extract ZIP -> VSCode
# ---------------------------------------------------------------------------
Write-Host "[2/4] Extracting '$($zipFile.Name)' -> 'VSCode' ..." -ForegroundColor Yellow

try {
    if (-not (Test-Path -Path $vscodePath -PathType Container)) {
        New-Item -Path $vscodePath -ItemType Directory -Force | Out-Null
    }
    Expand-Archive -Path $zipFile.FullName -DestinationPath $vscodePath -Force
    Write-Host '      OK.' -ForegroundColor Green
}
catch {
    Write-Error "Error while extracting: $_"
    exit 1
}

# ---------------------------------------------------------------------------
# Step 3 - Copy data folder from VSCode-bak -> VSCode
# ---------------------------------------------------------------------------
Write-Host "[3/4] Copying 'VSCode-bak\data' -> 'VSCode\data' ..." -ForegroundColor Yellow

$sourceData = Join-Path -Path $backupPath -ChildPath 'data'
$destData = Join-Path -Path $vscodePath -ChildPath 'data'

if (-not (Test-Path -Path $sourceData -PathType Container)) {
    Write-Warning "'$sourceData' directory doesn't exist inside the backup, nothing to copy."
}
else {
    try {
        Copy-Item -Path $sourceData -Destination $destData -Recurse -Force
        Write-Host '      OK.' -ForegroundColor Green
    }
    catch {
        Write-Error "Error while copying data folder: $_"
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Step 4 - Cleanup
# ---------------------------------------------------------------------------
Write-Host "[4/4] Checking extracted file and removing source ZIP ..." -ForegroundColor Yellow

# Check for Code.exe existence
$codeExe = Get-ChildItem -Path $vscodePath -Filter 'Code.exe' -Recurse -File | Select-Object -First 1

if ($codeExe) {
    try {
        Remove-Item -Path $zipFile.FullName -Force
        Write-Host "      '$($zipFile.Name)' removed." -ForegroundColor Green
    }
    catch {
        Write-Warning "Error while removing: '$($zipFile.Name)': $_"
    }
}
else {
    Write-Warning "Cannot find Code.exe in the new directory, the ZIP won't be deleted."
}

# ---------------------------------------------------------------------------
# Riepilogo
# ---------------------------------------------------------------------------
Write-Host "`n=== Update complete ===" -ForegroundColor Cyan
Write-Host "New version         : v$($selected.Version)"
Write-Host "Previous backup     : VSCode-bak"
Write-Host "To remove the backup: Remove-Item -Path '$backupPath' -Recurse -Force"

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/mdkeenan/fancy-shells.git'
$Marker = 'fancy-shells'
$HomeMarker = Join-Path $HOME '.fancy-shells-home'
$VersionMarker = Join-Path $HOME '.fancy-shells-version'
$LegacyVersion = '1.0.0'

if (-not $PSVersionTable) {
    Write-Error 'This installer must be run from PowerShell.'
    exit 1
}

function Test-FancyShellsRepo {
    param([string]$Path)
    if (-not $Path) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Path 'tools')) -and (
        (Test-Path -LiteralPath (Join-Path $Path 'profile.ps1')) -or
        (Test-Path -LiteralPath (Join-Path $Path 'bashrc'))
    ) -and (Test-Path -LiteralPath (Join-Path $Path 'VERSION'))
}

function Read-VersionFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $raw = [System.IO.File]::ReadAllText($Path).Trim()
    if ($raw -match '^\d+\.\d+\.\d+') { return $Matches[0] }
    return $null
}

function Get-InstalledFancyShellsVersion {
    $fromMarker = Read-VersionFile $VersionMarker
    if ($fromMarker) { return $fromMarker }

    if (Test-Path -LiteralPath $PROFILE) {
        $line = Select-String -LiteralPath $PROFILE -Pattern 'fancy-shells version:\s*(\d+\.\d+\.\d+)' | Select-Object -First 1
        if ($line) { return $line.Matches[0].Groups[1].Value }
        if (Select-String -LiteralPath $PROFILE -Pattern $Marker -Quiet) {
            return $LegacyVersion
        }
    }

    return $null
}

function Compare-SemVer {
    param([string]$Left, [string]$Right)
    $l = ($Left -split '\.') | ForEach-Object { [int]$_ }
    $r = ($Right -split '\.') | ForEach-Object { [int]$_ }
    for ($i = 0; $i -lt 3; $i++) {
        if ($l[$i] -lt $r[$i]) { return -1 }
        if ($l[$i] -gt $r[$i]) { return 1 }
    }
    return 0
}

function Update-FancyShellsCheckout {
    param([string]$Path)
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return }
    if (-not (Test-Path -LiteralPath (Join-Path $Path '.git'))) { return }
    Push-Location $Path
    try {
        git pull --ff-only 2>$null | Out-Null
    } catch {
        # Keep existing checkout if pull fails (offline, dirty tree, etc.).
    } finally {
        Pop-Location
    }
}

function Resolve-FancyShellsHome {
    if ($PSScriptRoot -and (Test-FancyShellsRepo $PSScriptRoot)) {
        return (Resolve-Path -LiteralPath $PSScriptRoot).Path
    }

    if (Test-Path -LiteralPath $HomeMarker) {
        $existing = [System.IO.File]::ReadAllText($HomeMarker).Trim().Trim([char]0xFEFF)
        if ((Test-FancyShellsRepo $existing)) {
            Update-FancyShellsCheckout $existing
            return (Resolve-Path -LiteralPath $existing).Path
        }
    }

    $default = Join-Path $HOME 'fancy-shells'
    if (Test-FancyShellsRepo $default) {
        Update-FancyShellsCheckout $default
        return (Resolve-Path -LiteralPath $default).Path
    }

    # Pre-tools checkout at the default path: pull and re-check, or replace if empty-ish.
    if ((Test-Path -LiteralPath $default) -and (Test-Path -LiteralPath (Join-Path $default '.git'))) {
        Update-FancyShellsCheckout $default
        if (Test-FancyShellsRepo $default) {
            return (Resolve-Path -LiteralPath $default).Path
        }
    }

    if (Test-Path -LiteralPath $default) {
        throw "Path $default exists but is not a fancy-shells checkout with tools/ and VERSION."
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git is required on PATH to clone fancy-shells.'
    }

    git clone $RepoUrl $default
    if (-not (Test-FancyShellsRepo $default)) {
        throw "Cloned $default but it is missing tools/ or VERSION. Push/tag a complete release first."
    }
    return (Resolve-Path -LiteralPath $default).Path
}

function Install-ToolsVenv {
    param([string]$Root)

    $venvDir = Join-Path $Root 'tools\venv'
    $venvPython = Join-Path $venvDir 'Scripts\python.exe'
    $requirements = Join-Path $Root 'tools\requirements.txt'

    if (-not (Test-Path -LiteralPath $requirements)) {
        throw "Missing tools requirements at $requirements"
    }

    if (-not (Test-Path -LiteralPath $venvPython)) {
        Write-Host 'Creating tools virtual environment...' -ForegroundColor Yellow
        if (Get-Command python -ErrorAction SilentlyContinue) {
            & python -m venv $venvDir
        } elseif (Get-Command py -ErrorAction SilentlyContinue) {
            & py -3 -m venv $venvDir
        } else {
            throw 'Python 3 is required on PATH to install fancy-shells tools.'
        }
    }

    if (-not (Test-Path -LiteralPath $venvPython)) {
        throw "Failed to create tools venv at $venvDir"
    }

    Write-Host 'Installing tool dependencies...' -ForegroundColor Yellow
    & $venvPython -m pip install -q -r $requirements
}

function Install-ProfileFromClone {
    param([string]$Root)

    $src = Join-Path $Root 'profile.ps1'
    if (-not (Test-Path -LiteralPath $src)) {
        throw "Missing profile.ps1 in $Root"
    }

    $content = Get-Content -Raw -LiteralPath $src
    if ([string]::IsNullOrWhiteSpace($content) -or ($content -notlike "*$Marker*")) {
        throw 'profile.ps1 failed validation (empty or missing fancy-shells marker); aborting.'
    }

    $backup = "$PROFILE.original"
    $profileIsFancy = $false
    if (Test-Path -LiteralPath $PROFILE) {
        $profileIsFancy = [bool](Select-String -LiteralPath $PROFILE -Pattern $Marker -Quiet)
    }

    # Never treat an existing fancy-shells profile as the pre-install backup.
    if ((Test-Path -LiteralPath $PROFILE) -and -not (Test-Path -LiteralPath $backup) -and -not $profileIsFancy) {
        Copy-Item -LiteralPath $PROFILE -Destination $backup
        Write-Host "Backed up existing profile to $backup"
    } elseif ((Test-Path -LiteralPath $PROFILE) -and -not (Test-Path -LiteralPath $backup) -and $profileIsFancy) {
        Write-Host "Skipping backup: current profile is already fancy-shells and no $backup exists." -ForegroundColor Yellow
    }

    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path -LiteralPath $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    $temp = Join-Path ([System.IO.Path]::GetTempPath()) ("fancy-shells-profile-{0}.ps1" -f [guid]::NewGuid())
    try {
        Copy-Item -LiteralPath $src -Destination $temp -Force
        $tempContent = Get-Content -Raw -LiteralPath $temp
        if ([string]::IsNullOrWhiteSpace($tempContent) -or ($tempContent -notlike "*$Marker*")) {
            throw 'Temp profile validation failed; aborting install.'
        }
        Copy-Item -LiteralPath $temp -Destination $PROFILE -Force
    } finally {
        if (Test-Path -LiteralPath $temp) {
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
    }
}

$previousVersion = Get-InstalledFancyShellsVersion
$root = Resolve-FancyShellsHome
$targetVersion = Read-VersionFile (Join-Path $root 'VERSION')
if (-not $targetVersion) {
    throw "Missing or invalid VERSION in $root"
}

if ($previousVersion) {
    $cmp = Compare-SemVer $previousVersion $targetVersion
    if ($cmp -eq 0) {
        Write-Host "Reinstalling fancy-shells $targetVersion (same version)..." -ForegroundColor Cyan
    } elseif ($cmp -lt 0) {
        Write-Host "Upgrading fancy-shells $previousVersion -> $targetVersion..." -ForegroundColor Cyan
    } else {
        Write-Host "Installing fancy-shells $targetVersion over newer installed $previousVersion (downgrade)..." -ForegroundColor Yellow
    }
} else {
    Write-Host "Installing fancy-shells $targetVersion..." -ForegroundColor Cyan
}

[System.IO.File]::WriteAllText($HomeMarker, $root)
[System.IO.File]::WriteAllText($VersionMarker, $targetVersion)

Install-ToolsVenv -Root $root
Install-ProfileFromClone -Root $root

Write-Host "Fancy shells $targetVersion installed from $root"
Write-Host "Wrote $HomeMarker"
Write-Host "Wrote $VersionMarker"
Write-Host "Profile installed at $PROFILE."
. $PROFILE
Write-Host 'fs* tools are on PATH for this session (and future sessions via the profile).'

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$Marker = 'fancy-shells'
$HomeMarker = Join-Path $HOME '.fancy-shells-home'
$VersionMarker = Join-Path $HOME '.fancy-shells-version'

if (-not $PSVersionTable) {
    Write-Error 'This uninstaller must be run from PowerShell.'
    exit 1
}

$backup = "$PROFILE.original"
$didSomething = $false

if (Test-Path -LiteralPath $backup) {
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path -LiteralPath $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    Copy-Item -LiteralPath $backup -Destination $PROFILE -Force
    Remove-Item -LiteralPath $backup -Force
    Write-Host "Restored $PROFILE from backup and removed $backup."
    $didSomething = $true
    . $PROFILE
    Write-Host 'PowerShell profile restored and reloaded.'
} elseif ((Test-Path -LiteralPath $PROFILE) -and (Select-String -LiteralPath $PROFILE -Pattern $Marker -Quiet)) {
    Remove-Item -LiteralPath $PROFILE -Force
    Write-Host "Removed fancy-shells profile at $PROFILE (no prior backup)."
    Write-Host 'PowerShell profile removed. Restart your shell to apply.'
    $didSomething = $true
}

if (Test-Path -LiteralPath $HomeMarker) {
    Remove-Item -LiteralPath $HomeMarker -Force
    Write-Host "Removed $HomeMarker"
    $didSomething = $true
}

if (Test-Path -LiteralPath $VersionMarker) {
    Remove-Item -LiteralPath $VersionMarker -Force
    Write-Host "Removed $VersionMarker"
    $didSomething = $true
}

if (-not $didSomething) {
    Write-Host 'Nothing to uninstall for PowerShell.'
}

exit 0

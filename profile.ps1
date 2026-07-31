# fancy-shells version: 2.0.1 — https://github.com/mdkeenan/fancy-shells
# PowerShell profile: custom prompt and shell defaults.

# fancy-shells tools on PATH (install writes ~/.fancy-shells-home)
$fancyShellsHomeFile = Join-Path $HOME '.fancy-shells-home'
if (Test-Path -LiteralPath $fancyShellsHomeFile) {
    $fancyShellsHome = (Get-Content -LiteralPath $fancyShellsHomeFile -Raw).Trim()
    if ($fancyShellsHome) {
        $fancyShellsBin = Join-Path $fancyShellsHome 'tools\bin'
        if ((Test-Path -LiteralPath $fancyShellsBin) -and ($env:PATH -notlike "*$fancyShellsBin*")) {
            $env:PATH = "$fancyShellsBin;$env:PATH"
        }
    }
}

# History settings (PowerShell caps MaximumHistoryCount at 32767)
$MaximumHistoryCount = 32767
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    Set-PSReadLineOption -HistoryNoDuplicates -ErrorAction SilentlyContinue
}

function global:Shorten-PathSegments {
    param(
        [string]$Path,
        [int]$MaxLen = 3
    )

    if ($Path -eq '~') { return '~' }

    $prefix = ''
    $rest = $Path
    if ($Path.StartsWith('~/')) {
        $prefix = '~/'
        $rest = $Path.Substring(2)
    } elseif ($Path.StartsWith('/')) {
        $prefix = '/'
        $rest = $Path.TrimStart('/')
    }

    if (-not $rest) { return $prefix.TrimEnd('/') }

    $segments = $rest -split '[/\\]' | Where-Object { $_ }
    $short = @($segments | ForEach-Object {
        if ($_.Length -gt $MaxLen) { $_.Substring(0, $MaxLen) } else { $_ }
    })
    $joined = $short -join '/'

    if ($prefix -eq '~/') { return $prefix + $joined }
    if ($prefix -eq '/') { return '/' + $joined }
    if ($short.Count -eq 1) { return $short[0] }
    return $joined
}

function global:Test-FancyShellsPrivileged {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IsWindows) {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = [Security.Principal.WindowsPrincipal]$identity
            $adminSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
            return $principal.IsInRole($adminSid)
        }
        if ($IsLinux -or $IsMacOS) {
            if ((id -u) -eq 0) { return $true }
            $groups = (id -nG) -split '\s+'
            return 'sudo' -in $groups -or 'wheel' -in $groups -or 'admin' -in $groups
        }
        return $false
    }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    $adminSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
    return $principal.IsInRole($adminSid)
}

function global:Get-PromptDirectory {
    param([string]$Path)

    if (-not $HOME) {
        return Shorten-PathSegments $Path
    }

    try {
        $currentPath = [System.IO.Path]::GetFullPath($Path)
        $homePath = [System.IO.Path]::GetFullPath($HOME)
    } catch {
        return Shorten-PathSegments $Path
    }

    if ($currentPath.Equals($homePath, [StringComparison]::OrdinalIgnoreCase)) {
        return '~'
    }

    $homePrefix = $homePath.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if ($currentPath.StartsWith($homePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $relative = $currentPath.Substring($homePrefix.Length).Replace('\', '/')
        return Shorten-PathSegments "~/$relative"
    }

    $display = $currentPath.Replace('\', '/')
    if ($display -match '^[A-Za-z]:/') {
        $drive = $display.Substring(0, 1).ToLowerInvariant()
        $rest = $display.Substring(3)
        if ($rest) {
            return Shorten-PathSegments "/$drive/$rest"
        }
        return "/$drive"
    }

    return Shorten-PathSegments $display
}

function global:prompt {
    $time = Get-Date -Format 'HH:mm:ss'
    $user = if ($env:USERNAME) { $env:USERNAME } else { $env:USER }
    $hostname = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { (hostname) }
    $location = Get-Location
    $leaf = Get-PromptDirectory $location.Path
    $isPrivileged = Test-FancyShellsPrivileged

    $Host.UI.RawUI.WindowTitle = "${user}@${hostname}: $($location.Path)"

    $privLabel = if ($isPrivileged) { 'admuser' } else { 'stduser' }
    $privColor = if ($isPrivileged) { 'Red' } else { 'DarkGray' }

    Write-Host '[' -NoNewline -ForegroundColor Yellow
    Write-Host $time -NoNewline
    Write-Host ':' -NoNewline -ForegroundColor Yellow
    Write-Host $user -NoNewline -ForegroundColor Green
    Write-Host ':' -NoNewline -ForegroundColor Yellow
    Write-Host $privLabel -NoNewline -ForegroundColor $privColor
    Write-Host ':' -NoNewline -ForegroundColor Yellow
    Write-Host $hostname -NoNewline -ForegroundColor Cyan
    Write-Host ':' -NoNewline -ForegroundColor Yellow
    Write-Host $leaf -NoNewline -ForegroundColor Blue
    Write-Host ']$' -NoNewline -ForegroundColor Yellow
    return ' '
}

function global:ll { Get-ChildItem -Force }
function global:la { Get-ChildItem -Force | Where-Object { $_.Name -notin '.', '..' } }
function global:l  { Get-ChildItem -Name }

$aliasesPath = Join-Path $HOME '.powershell_aliases.ps1'
if (Test-Path $aliasesPath) {
    . $aliasesPath
}

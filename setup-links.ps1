# setup-links.ps1
# Creates junctions so both Vim and Neovim point to the same config repo.
#
# Usage:
#   .\setup-links.ps1 -RepoPath "path/to/dotfiles"

param(
    [Parameter(Mandatory, HelpMessage = 'Absolute path to the config repo')]
    [string]$RepoPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- helpers -----------------------------------------------------------------

function Write-Ok  ([string]$msg) { Write-Host "  [ok] $msg" -ForegroundColor Green }
function Write-Skip([string]$msg) { Write-Host " [skip] $msg" -ForegroundColor Yellow }
function Write-Fail([string]$msg) { Write-Host " [fail] $msg" -ForegroundColor Red }

function New-Junction {
    param([string]$Link, [string]$Target)

    if (Test-Path $Link) {
        $item = Get-Item -LiteralPath $Link -Force
        if ($item.LinkType -eq 'Junction') {
            Write-Skip "$Link  (already a junction -> $($item.Target[0]))"
        } else {
            Write-Fail "$Link already exists and is not a junction."
            Write-Host "        Remove it manually, then re-run." -ForegroundColor DarkGray
            exit 1
        }
    } else {
        New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
        Write-Ok "Junction: $Link  ->  $Target"
    }
}

# --- validate repo path ------------------------------------------------------

$RepoPath = $RepoPath.TrimEnd('\', '/')

if (-not (Test-Path $RepoPath -PathType Container)) {
    Write-Fail "Repo path not found: $RepoPath"
    exit 1
}

foreach ($expected in @('init.lua', 'vimrc', 'autoload\plug.vim')) {
    if (-not (Test-Path "$RepoPath\$expected")) {
        Write-Host " [warn] Expected file not found in repo: $expected" -ForegroundColor DarkYellow
    }
}

# --- create links ------------------------------------------------------------

Write-Host "`nSetting up editor links...`n"

New-Junction -Link "$env:LOCALAPPDATA\nvim"   -Target $RepoPath
New-Junction -Link "$env:USERPROFILE\vimfiles" -Target $RepoPath

Write-Host "`nDone.`n" -ForegroundColor Cyan

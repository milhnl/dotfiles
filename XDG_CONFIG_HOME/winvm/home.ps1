#!/usr/bin/env pwsh

#Set environment
function Set-Env {
    param($Name, $Value)
    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Set-Content (Join-Path env: $Name) $Value
}

Set-Env "WORKSPACE_REPO_HOME" `
    (Join-Path ([Environment]::GetFolderPath("UserProfile")) Workspaces)
Set-Env "DOTFILES" "$env:WORKSPACE_REPO_HOME/dotfiles"
Set-Env "XDG_CONFIG_HOME" `
    (Join-Path ([Environment]::GetFolderPath("ApplicationData")) xdg/config)
Set-Env "XDG_DATA_HOME" `
    (Join-Path ([Environment]::GetFolderPath("ApplicationData")) xdg/share)
Set-Env "XDG_CACHE_HOME" `
    (Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) `
        xdg/cache)

#Install packages
function Sync-Path {
  $env:PATH = "$((Get-ItemProperty -Path `
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\' `
    -Name 'PATH').Path);$((Get-ItemProperty -Path 'HKCU:\Environment' `
    -Name 'PATH').Path)"
}

choco install -y --no-progress git dotnetcore-sdk nodejs
Sync-Path

if (!(Test-Path "$env:WORKSPACE_REPO_HOME/workspace")) {
    git clone https://milhnl@github.com/Eforah-oss/workspace `
        "$env:WORKSPACE_REPO_HOME/workspace"
}
Start-Process -WorkingDirectory "$env:WORKSPACE_REPO_HOME/workspace" `
    -FilePath powershell `
    -ArgumentList "$env:WORKSPACE_REPO_HOME/workspace/Install.ps1"

irm 'https://raw.githubusercontent.com/Eforah-oss/pmmux/master/pmmux.ps1' `
    | % {$_ -replace "pmmux @args$", "pmmux -1 pmmux+pmmux"} | iex

Sync-Path

#Clone dotfiles and install
if (!(Test-Path $env:DOTFILES)) {
    git clone https://milhnl@github.com/milhnl/dotfiles $env:DOTFILES
}

function Set-Link {
    param($Target, $Link)
    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $Link)) >$null
    if ((Get-Item $Link -Force -ErrorAction SilentlyContinue).LinkType `
            -ne "SymbolicLink") {
        Remove-Item -ErrorAction SilentlyContinue $Link
        New-Item -ItemType SymbolicLink -Path $Link -Value $Target >$null
    }
}

Set-Link "$env:DOTFILES/XDG_CONFIG_HOME/powershell/profile.ps1" `
    $PROFILE.CurrentUserAllHosts
Set-Link "$env:DOTFILES/XDG_CONFIG_HOME/git" "$env:XDG_CONFIG_HOME/git"
Set-Link "$env:DOTFILES/XDG_CONFIG_HOME/workspace" `
    "$env:XDG_CONFIG_HOME/workspace"

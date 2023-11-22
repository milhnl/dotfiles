#!/usr/bin/env pwsh

#Set environment
function Set-Env {
    param($Name, $Value)
    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Set-Content (Join-Path env: $Name) $Value
}

Set-Env "WORKSPACE_REPO_HOME" `
    (Join-Path ([Environment]::GetFolderPath("UserProfile")) Workspaces)

#Install packages
function Sync-Path {
  $env:PATH = "$((Get-ItemProperty -Path `
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\' `
    -Name 'PATH').Path);$((Get-ItemProperty -Path 'HKCU:\Environment' `
    -Name 'PATH').Path)"
}

choco install -y --no-progress git dotnetcore-sdk nodejs
Sync-Path

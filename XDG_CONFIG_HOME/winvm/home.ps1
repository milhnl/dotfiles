#!/usr/bin/env pwsh

function Sync-Path {
  $env:PATH = "$((Get-ItemProperty -Path `
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\' `
    -Name 'PATH').Path);$((Get-ItemProperty -Path 'HKCU:\Environment' `
    -Name 'PATH').Path)"
}

#Install packages
choco install -y --no-progress git dotnetcore-sdk nodejs
Sync-Path

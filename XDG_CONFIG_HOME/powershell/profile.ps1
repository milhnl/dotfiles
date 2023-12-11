Set-PSReadlineOption -EditMode Vi

function dot {
  git -C "$env:DOTFILES" @Args
}

if (([System.Environment]::OSVersion.Platform -eq "Win32NT") `
    -or ($PSVersionTable.Platform -eq "Windows")) {
  $env:EDITOR="wsl -- sh -lic 'editor `"\`$(wslpath -u `"\$@`")`"' --"
}

Set-Alias w Enter-Workspace

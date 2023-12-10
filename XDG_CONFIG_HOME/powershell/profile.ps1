Set-PSReadlineOption -EditMode Vi

function dot {
  git -C "$env:DOTFILES" @Args
}

Set-Alias w Enter-Workspace

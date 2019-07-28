#!/usr/bin/env sh
if [ "$OS" = Darwin ]; then
    defaults write NSGlobalDomain AppleHighlightColor \
        "0.847059 0.847059 0.862745";
    defaults write NSGlobalDomain AppleInterfaceStyle Dark
    defaults write NSGlobalDomain AppleAquaColorVariant 6
    defaults write NSGlobalDomain _HIHideMenuBar -bool true
    defaults write com.apple.dock autohide -bool true && \
    defaults write com.apple.dock autohide-delay -float 1000 && \
    defaults write com.apple.dock no-bouncing -bool TRUE && \
    defaults write com.apple.dock mru-spaces -bool false && \
        killall Dock
    defaults write com.apple.finder QuitMenuItem -bool true && \
        killall Finder
    killall Dock SystemUIServer
    defaults write com.apple.Terminal FocusFollowsMouse -string YES
elif grep -iq microsoft /proc/version 2>/dev/null; then (
    cd "$(wslpath -u "$(cmd.exe /c 'echo %APPDATA%' | tr -d '\r')")"
    wget -q "$(printf '%s%s' 'https://github.com/Microsoft/console/' \
        'releases/download/1708.14008/colortool.zip' )"
    python3 -c "$(printf '%s\n%s\n%s\n' \
        'import zipfile' \
        'with zipfile.ZipFile("colortool.zip", "r") as z:' \
        '    z.extractall("./colortool/")')"
    tee ./colortool/schemes/base16-default-dark.ini >/dev/null <<EOF
[table]
DARK_BLACK =           24,24,24 
DARK_BLUE =           124,175,194     
DARK_GREEN =           161,181,108        
DARK_CYAN =           134,193,185         
DARK_RED =           171,70,66     
DARK_MAGENTA =           186,139,175            
DARK_YELLOW =           220,150,86          
DARK_WHITE =           216,216,216            
BRIGHT_BLACK =           88,88,88              
BRIGHT_BLUE =           40,40,40           
BRIGHT_GREEN =           56,56,56          
BRIGHT_CYAN =           88,88,88           
BRIGHT_RED =           184,184,184        
BRIGHT_MAGENTA =           216,216,216            
BRIGHT_YELLOW =           232,232,232               
BRIGHT_WHITE =           248,248,248    

[info]
name = Base16 Default Dark
author = Chris Kempson
EOF
    ./colortool/colortool.exe -b base16-default-dark
    rm -rf 'colortool.zip'
) fi


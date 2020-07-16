if os.getenv('XDG_DATA_HOME') ~= nil then
    package.path = package.path..';'..os.getenv('XDG_DATA_HOME')..'/vis/?.lua'
end
require('vis')

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
    vis:command('set colorcolumn 80')
    vis:command('set theme default')
    
    vis:command('set autoindent on')
    vis:command('set numbers on')
    vis:command('set expandtab on')
    vis:command('set show-tabs on')
    vis.win.tabwidth = 4

    -- The stdlib uses file(1), which does not support this shebang
    if win.file.lines[1]:match("^#!/usr/bin/env sh") then
        vis:command("set syntax bash")
    elseif (win.file.name or ''):match(".cshtml$") then
        vis:command("set syntax html")
        vis:command('set colorcolumn 120')
    elseif (win.file.name or ''):match(".csproj$") then
        vis:command("set syntax xml")
    elseif (win.file.name or ''):match("git/config$") then
        vis:command("set syntax ini")
        vis:command('set show-tabs off')
        vis:command('set expandtab off')
    elseif (win.file.name or ''):match(".tsx?$") then
        vis:command("set syntax javascript")
    end

    if win.syntax == 'makefile' then
        vis:command('set expandtab off')
        vis:command('set show-tabs off')
    elseif win.syntax == 'csharp' then
        vis:command('set colorcolumn 120')
    elseif win.syntax == 'javascript' then
        vis.win.tabwidth = 2
    elseif win.syntax == 'html' then
        vis.win.tabwidth = 2
    elseif win.syntax == 'yaml' or win.syntax == 'json' then
        vis.win.tabwidth = 2
    end
    
    vis:command('set tabwidth '..vis.win.tabwidth)

    vis:map(vis.modes.INSERT, '<M-Escape>', '<vis-mode-normal>')
    vis:map(vis.modes.VISUAL, '<M-Escape>', '<vis-mode-normal>')
    vis:map(vis.modes.INSERT, '<Backspace>', function()
        if vis.win.tabwidth == nil then
            vis:feedkeys('<vis-delete-char-prev>')
        else
            vis:command('?\n|'..string.rep(' ', vis.win.tabwidth)..'|.?d')    
        end
        vis:feedkeys('<vis-mode-insert>')
    end, 'Remove character to the left or unindent')
    vis:map(vis.modes.INSERT, '<Delete>', function()
        vis:command('/\n[\t ]*|./d')
        vis:feedkeys('<vis-mode-insert>')
    end, 'Remove character to the right or join lines if at the end')
    vis:map(vis.modes.NORMAL, 'U', '<vis-redo>')

    -- g<dir> mappings
    vis:map(vis.modes.NORMAL, 'gj', '<vis-motion-line-last>')
    vis:map(vis.modes.NORMAL, 'gk', '<vis-motion-line-first>')
    vis:map(vis.modes.NORMAL, 'gh', '<vis-motion-line-start>')
    vis:map(vis.modes.NORMAL, 'gl', '<vis-motion-line-end>')
    vis:map(vis.modes.OPERATOR_PENDING, 'gj', '<vis-motion-line-last>')
    vis:map(vis.modes.OPERATOR_PENDING, 'gk', '<vis-motion-line-first>')
    vis:map(vis.modes.OPERATOR_PENDING, 'gh', '<vis-motion-line-start>')
    vis:map(vis.modes.OPERATOR_PENDING, 'gl', '<vis-motion-line-end>')
    vis:map(vis.modes.VISUAL, 'gj', '<vis-motion-line-last>')
    vis:map(vis.modes.VISUAL, 'gk', '<vis-motion-line-first>')
    vis:map(vis.modes.VISUAL, 'gh', '<vis-motion-line-start>')
    vis:map(vis.modes.VISUAL, 'gl', '<vis-motion-line-end>')

    -- Y and P for system clipboard
    vis:map(vis.modes.NORMAL, 'Y', '"*y')
    vis:map(vis.modes.NORMAL, 'P', '"*p')
    vis:map(vis.modes.VISUAL, 'Y', '"*y')
    vis:map(vis.modes.VISUAL, 'P', '"*p')

    -- make integration
    make = function ()
        local status, out, err = vis:pipe(win.file, { start = 0, finish = 0 },
            'makedir="$(dirname "$(upwardfind . Makefile)")";'..
            'cd "$makedir";'..
            'printf "\\e[1A">"$TTY";'..
            'tgt="$(<Makefile sed -n "s/^.PHONY://p" | tr " " "\\n"'..
            '    | vis-menu -p make)";'..
            'printf "\r\\e[1A\\e[2K\\e[7m make %s  " "$tgt">"$TTY";'..
            '(x="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"; while :; do '..
            '    printf "\b%.1s" "$x"; x=${x#?}${x%?????????}; sleep .1;'..
            'done)>"$TTY"&'..
            'make "$tgt";'..
            'printf "\\e[?7h"; kill $!'
        )
        if status ~= 0 or not out then
            if err then vis:info(err) end
            return
        end
    end
    vis:map(vis.modes.NORMAL, 'm', function ()
        vis:command('w')
        make()
        vis:command('e')
    end, 'Run make command')

    -- open other file
    vis:map(vis.modes.NORMAL, '<C-p>', function ()
        local status, out, err = vis:pipe(win.file, { start = 0, finish = 0 },
            'printf "\\e[1A">"$TTY";'..
            'git ls-files --cached --other --exclude-standard'..
            '    | vis-menu -i'
        )
        if status == 0 then
            vis:command(string.format("e %s", out))
        end
    end)

    vis:command(string.format(":!echo -ne '\\033]0;edit %s\\007'",
        win.file.name))
end)

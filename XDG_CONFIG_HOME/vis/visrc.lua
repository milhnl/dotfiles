-- load standard vis module, providing parts of the Lua API
package.path = package.path..';'..os.getenv('XDG_DATA_HOME')..'/vis/?.lua'
require('vis')

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
    vis:command('set colorcolumn 80')
    vis:command('set theme default')
    
    vis:command('set autoindent on')
    vis:command('set numbers on')
    vis:command('set expandtab on')
    vis:command('set show-tabs on')
    vis.win.tabwidth = 4

    if win.syntax == 'makefile' then
        vis:command('set expandtab off')
        vis:command('set show-tabs off')
    elseif win.syntax == 'yaml' then
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
    vis:map(vis.modes.NORMAL, 'gh', '<vis-motion-line-begin>')
    vis:map(vis.modes.NORMAL, 'gl', '<vis-motion-line-end>')
    vis:map(vis.modes.OPERATOR_PENDING, 'gj', '<vis-motion-line-last>')
    vis:map(vis.modes.OPERATOR_PENDING, 'gk', '<vis-motion-line-first>')
    vis:map(vis.modes.OPERATOR_PENDING, 'gh', '<vis-motion-line-begin>')
    vis:map(vis.modes.OPERATOR_PENDING, 'gl', '<vis-motion-line-end>')
    vis:map(vis.modes.VISUAL, 'gj', '<vis-motion-line-last>')
    vis:map(vis.modes.VISUAL, 'gk', '<vis-motion-line-first>')
    vis:map(vis.modes.VISUAL, 'gh', '<vis-motion-line-begin>')
    vis:map(vis.modes.VISUAL, 'gl', '<vis-motion-line-end>')

    -- Y and P for system clipboard
    vis:map(vis.modes.NORMAL, 'Y', '"*y')
    vis:map(vis.modes.NORMAL, 'P', '"*p')
    vis:map(vis.modes.VISUAL, 'Y', '"*y')
    vis:map(vis.modes.VISUAL, 'P', '"*p')
end)
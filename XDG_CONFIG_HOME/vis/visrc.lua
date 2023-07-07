local xdg_dir = function(name, fallback)
  return os.getenv(name) or os.getenv('HOME') .. fallback
end
package.path = package.path
  .. ';'
  .. (xdg_dir('XDG_DATA_HOME', '/.local/share') .. '/vis/?.lua;')
  .. (xdg_dir('XDG_CONFIG_HOME', '/.config') .. '/vis/?/init.lua;')
require('vis')
require('vis-cursors')
require('vis-backspace')
local lspc = vis.communicate and require('vis-lspc') or nil
if lspc then
  lspc.message_level = 1
  lspc.highlight_diagnostics = true
  lspc.ls_map.csharp = { name = 'csharp', cmd = 'csharp-ls' }
  lspc.ls_map.rust = {
    name = 'rust',
    cmd = 'rustup component list --installed | grep -q rust-analyzer'
        .. '    || rustup component add rust-analyzer 2>/dev/null'
        .. '    && rustup run stable rust-analyzer',
  }
  vis:map(vis.modes.NORMAL, '<M-Left>', function()
    vis:command('lspc-back')
  end)
end

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
  vis:command('set colorcolumn 80')
  vis:command('set theme default')

  vis:command('set autoindent on')
  vis:command('set numbers on')
  vis:command('set expandtab on')
  vis:command('set show-tabs on')
  win.tabwidth = 4

  local set_syntax = function(syntax)
    win:set_syntax(syntax)
    if
      lspc
      and lspc.ls_map[syntax]
      and not lspc.running[lspc.ls_map[syntax].name]
    then
      vis:command('lspc-start-server ' .. syntax)
    end
  end
  -- The stdlib uses file(1), which does not support the env shebang style
  if win.file.lines[1]:match('^#!/usr/bin/env sh') then
    set_syntax('bash')
  elseif win.file.lines[1]:match('^#!/usr/bin/env python') then
    set_syntax('python')
  elseif (win.file.name or ''):match('.cshtml$') then
    set_syntax('html')
    vis:command('set colorcolumn 120')
  elseif (win.file.name or ''):match('.csproj$') then
    set_syntax('xml')
  elseif (win.file.name or ''):match('.editorconfig$') then
    set_syntax('ini')
  elseif (win.file.name or ''):match('git/config$') then
    set_syntax('ini')
    vis:command('set show-tabs off')
    vis:command('set expandtab off')
  elseif (win.file.name or ''):match('PKGBUILD$') then
    set_syntax('bash')
    win.tabwidth = 2
  elseif (win.file.name or ''):match('.psm1$') then
    set_syntax('powershell')
  elseif (win.file.name or ''):match('.tsx?$') then
    set_syntax('javascript')
  elseif (win.file.name or ''):match('.tf$') then
    win.tabwidth = 2
  elseif (win.file.name or ''):match('.git/COMMIT_EDITMSG$') then
    set_syntax('git-commit')
    vis:command('set colorcolumn 73')
    win.selection.pos = 0
    vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function(win)
      local line1_len = #win.file.lines[1]
      if line1_len > 50 then
        win:style(win.STYLE_COLOR_COLUMN, 50, line1_len)
      end
      local line2_len = #win.file.lines[2]
      if line2_len > 0 and not win.file.lines[2]:match('^#') then
        win:style(win.STYLE_COLOR_COLUMN, line1_len + 1, line1_len + line2_len)
      end
    end)
  elseif (win.file.name or ''):match('/workspace/config$') then
    set_syntax('bash')
  end

  if win.syntax == 'makefile' then
    vis:command('set expandtab off')
    vis:command('set show-tabs off')
  elseif win.syntax == 'csharp' then
    vis:command('set colorcolumn 120')
  elseif win.syntax == 'go' then
    vis:command('set expandtab off')
    vis:command('set show-tabs off')
  elseif win.syntax == 'javascript' or win.syntax == 'typescript' then
    win.tabwidth = 2
  elseif win.syntax == 'html' then
    win.tabwidth = 2
  elseif win.syntax == 'powershell' then
    win.tabwidth = 2
  elseif win.syntax == 'yaml' or win.syntax == 'json' then
    win.tabwidth = 2
  end

  vis:command('set tabwidth ' .. win.tabwidth)

  vis:map(vis.modes.INSERT, '<M-Escape>', '<vis-mode-normal>')
  vis:map(vis.modes.VISUAL, '<M-Escape>', '<vis-mode-normal>')
  vis:map(vis.modes.INSERT, '<Delete>', function()
    vis:command('/\n[\t ]*|./d')
    vis:feedkeys('<vis-mode-insert>')
  end, 'Remove character to the right or join lines if at the end')
  vis:map(vis.modes.NORMAL, 'U', '<vis-redo>')

  -- Y and P for system clipboard
  vis:map(vis.modes.NORMAL, 'Y', '"*y')
  vis:map(vis.modes.NORMAL, 'P', '"*p')
  vis:map(vis.modes.VISUAL, 'Y', '"*y')
  vis:map(vis.modes.VISUAL, 'D', '"*d')
  vis:map(vis.modes.VISUAL, 'P', '"*p')

  -- make integration
  local make = function()
    local status, out, err = vis:pipe(
      win.file,
      { start = 0, finish = 0 },
      'makedir="$(dirname "$(upwardfind . Makefile)")";'
        .. 'cd "$makedir";'
        .. 'printf "\\e[1A">"$TTY";'
        .. 'tgt="$(<Makefile sed -n "s/^.PHONY://p" | tr " " "\\n"'
        .. '    | vis-menu -p make)";'
        .. 'printf "\r\\e[1A\\e[2K\\e[7m make %s  " "$tgt">"$TTY";'
        .. '(x="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"; while :; do '
        .. '    printf "\b%.1s" "$x"; x=${x#?}${x%?????????}; sleep .1;'
        .. 'done)>"$TTY"&'
        .. 'make "$tgt";'
        .. 'printf "\\e[?7h"; kill $!'
    )
    if status ~= 0 or not out then
      if err then
        vis:info(err)
      end
      return
    end
  end
  vis:map(vis.modes.NORMAL, 'm', function()
    vis:command('w')
    local pos = win.selection.pos
    make()
    vis:command('e')
    vis:redraw()
    win.selection.pos = pos
  end, 'Run make command')

  vis:map(vis.modes.NORMAL, '<M-p>', function()
    local fz = io.popen(
      'tput cup $(( $(tput lines) - 10)) >/dev/tty;'
        .. 'tty="$(stty -g)"; stty sane; ' --printf "\\e[1A">"$TTY";'
        .. 'git ls-files --cached --other --exclude-standard'
        .. '    | fzf --border=top --border-label-pos=1 --height=10 '
        .. '--layout=default --border-label=" '
        .. win.file.path
        .. ' "; r=$?; stty "$tty">/dev/tty; exit $r'
    )
    if fz then
      local out = fz:read('*a')
      local _, _, status = fz:close()
      if status == 0 then
        vis:command(string.format('e %s', out))
        return
      end
    end
    vis:redraw()
  end)

  vis:command(
    string.format(
      ":!echo -ne '\\033]0;edit %s\\007'",
      string.gsub(win.file.name or '', "'", "'\\''")
    )
  )
end)

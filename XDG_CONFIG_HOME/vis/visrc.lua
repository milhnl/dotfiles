local xdg_dir = function(name, fallback)
  return os.getenv(name) or os.getenv('HOME') .. fallback
end
package.path = package.path
  .. ';'
  .. (xdg_dir('XDG_DATA_HOME', '/.local/share') .. '/vis/?.lua;')
  .. (xdg_dir('XDG_CONFIG_HOME', '/.config') .. '/vis/?/init.lua;')
require('vis')
require('vis-options-backport')
require('vis-cursors')
require('vis-backspace')
local format = require('vis-format')
local lspc = vis.communicate and require('vis-lspc') or nil
if lspc then
  lspc.message_level = 1
  lspc.highlight_diagnostics = true
  lspc.ls_map.csharp = { name = 'csharp', cmd = 'csharp-ls' }
  lspc.ls_map.javascript.formatting_options =
    { tabSize = 2, insertSpaces = true }
  lspc.ls_map.lua.formatting_options = { tabSize = 2, insertSpaces = true }
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
table.insert(vis.ftdetect.filetypes.ini.ext, '^.editorconfig$')
table.insert(vis.ftdetect.filetypes.yaml.ext, '^.clang%-format$')
table.insert(vis.ftdetect.filetypes.powershell.ext, '.psm1$')
table.insert(vis.ftdetect.filetypes.typescript.ext, '.tsx?$')
table.insert(vis.ftdetect.filetypes.xml.ext, '.csproj$')

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
  vis:command('set theme default')
  vis.options.autoindent = true
  win.options.colorcolumn = 80
  win.options.numbers = true
  win.options.expandtab = true
  win.options.showtabs = true
  win.options.tabwidth = 4

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

  if (win.file.name or ''):match('.cshtml$') then
    set_syntax('html')
    win.options.colorcolumn = 120
  elseif (win.file.name or ''):match('git/config$') then
    set_syntax('ini')
    win.options.expandtab = false
    win.options.showtabs = false
  elseif (win.file.name or ''):match('.tf$') then
    win.options.tabwidth = 2
  elseif (win.file.name or ''):match('/workspace/config$') then
    set_syntax('bash')
  end

  if win.syntax == 'makefile' then
    win.options.expandtab = false
    win.options.showtabs = false
  elseif win.syntax == 'csharp' then
    win.options.colorcolumn = 120
  elseif win.syntax == 'git-commit' then
    win.options.colorcolumn = 73
    win.selection.pos = 0
    vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function(win)
      local line1_len = #win.file.lines[1]
      if line1_len > 50 then
        win:style(win.STYLE_COLOR_COLUMN, 50, line1_len)
      end
      local line2_len = #win.file.lines > 1 and #win.file.lines[2] or 0
      if line2_len > 0 and not win.file.lines[2]:match('^#') then
        win:style(win.STYLE_COLOR_COLUMN, line1_len + 1, line1_len + line2_len)
      end
    end)
  elseif win.syntax == 'go' then
    win.options.expandtab = false
    win.options.showtabs = false
  elseif win.syntax == 'javascript' or win.syntax == 'typescript' then
    win.options.tabwidth = 2
  elseif win.syntax == 'html' then
    win.options.tabwidth = 2
  elseif win.syntax == 'lua' then
    win.options.tabwidth = 2
  elseif win.syntax == 'pkgbuild' then
    win.options.tabwidth = 2
  elseif win.syntax == 'powershell' then
    win.options.tabwidth = 2
  elseif win.syntax == 'yaml' or win.syntax == 'json' then
    win.options.tabwidth = 2
  end

  local format_multiplex = function(file, range, pos)
    if format.formatters[vis.win.syntax] then
      vis.win.selection.pos = format.apply(file, range, pos)
    elseif lspc then
      local lspc_conf = lspc.ls_map[win.syntax]
      if lspc_conf then
        local ls = lspc.running[lspc_conf.name]
        if ls and ls.capabilities['documentFormattingProvider'] then
          vis:command('lspc-format')
        end
      end
    else
      vis:info('No formatter for ' .. vis.win.syntax)
    end
  end
  vis:operator_new('=', format_multiplex)
  vis:map(vis.modes.NORMAL, '=', function()
    format_multiplex(vis.win.file, nil, vis.win.selection.pos)
  end)

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
        .. '    | vis-menu -p make)" || exit 1;'
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
        .. 'tty="$(stty -g)"; stty sane; '
        .. 'git ls-files -z --cached --other --exclude-standard'
        .. '    | fzf --read0 --print0 --height=10'
        .. '        --border=top --border-label-pos=1'
        .. '        --color=border:7:reverse,label:7:reverse:bold'
        .. '        --color=scrollbar:regular'
        .. '        --layout=default --border-label=" '
        .. (win.file.name .. string.rep(' ', win.width - #win.file.name - 2))
        .. ' "; r=$?; stty "$tty">/dev/tty; exit $r'
    )
    if fz then
      local out = fz:read('*a')
      local _, _, status = fz:close()
      if status == 0 then
        lspc.open_file(win, out, nil, nil, 'e')
        return
      end
    end
    vis:redraw()
  end)

  vis:map(vis.modes.NORMAL, '<M-f>', function()
    local fz = io.popen('rfv; r=$?; tput smcup >/dev/tty; exit $r')
    if fz then
      local out = fz:read('*a')
      local _, _, status = fz:close()
      if status == 0 then
        local C, P, R = vis.lpeg.C, vis.lpeg.P, vis.lpeg.R
        local any, colon, num = P(1), P(':'), R('09')
        local file, line, col = vis.lpeg.match(
          C((any - P(colon * num ^ 1 * colon * num ^ 1 * colon)) ^ 1)
            * P(colon * C(num ^ 1) * colon * C(num ^ 1) * colon),
          out
        )
        vis:redraw()
        lspc.open_file(win, file, line, col, 'e')
        return
      end
    end
    vis:redraw()
  end)

  vis:command(
    string.format(
      ":!echo -ne '\\033]0;edit %s\\007'",
      (win.file.name or ''):gsub("'", "'\\''"):gsub('\n', '␊')
    )
  )
end)

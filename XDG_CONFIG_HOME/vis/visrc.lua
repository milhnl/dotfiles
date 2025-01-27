local xdg_dir = function(name, fallback)
  return os.getenv(name) or os.getenv('HOME') .. fallback
end
package.path = package.path
  .. ';'
  .. (xdg_dir('XDG_DATA_HOME', '/.local/share') .. '/vis/?.lua;')
  .. (xdg_dir('XDG_CONFIG_HOME', '/.config') .. '/vis/?/init.lua;')

require('vis')
local require_plugin = require('vis-require-plugin')
require_plugin('https://milhnl@github.com/milhnl/vis-options-backport')
require_plugin('https://github.com/erf/vis-cursors.git')
require_plugin('https://milhnl@github.com/milhnl/vis-sudoedit')
require_plugin('https://milhnl@github.com/milhnl/vis-editorconfig-options')
local ft_options =
  require_plugin('https://milhnl@github.com/milhnl/vis-filetype-options')
require_plugin('https://milhnl@github.com/milhnl/vis-backspace')
require_plugin('https://milhnl@github.com/milhnl/vis-term-title')
local format = require_plugin('https://milhnl@github.com/milhnl/vis-format')
local lspc = require_plugin('https://gitlab.com/muhq/vis-lspc')

ft_options.makefile = {
  expandtab = false,
  showtabs = false,
}
ft_options.csharp = {
  colorcolumn = 120,
}
ft_options.go = {
  expandtab = false,
  showtabs = false,
}
ft_options.javascript = {
  tabwidth = 2,
}
ft_options.typescript = {
  tabwidth = 2,
}
ft_options.pkgbuild = {
  tabwidth = 2,
}
ft_options.powershell = {
  tabwidth = 2,
}
ft_options.rust = {
  tabwidth = 4,
  expandtab = true,
}
ft_options.yaml = {
  tabwidth = 2,
}
ft_options.json = {
  tabwidth = 2,
}

local prettier = format.stdio_formatter(function(win)
  return 'prettier ' .. format.with_filename(win, '--stdin-filepath ')
end, { ranged = false })
local prettier_md = format.formatters.markdown
format.formatters.css = prettier
format.formatters.hcl = format.stdio_formatter('terraform fmt -')
format.formatters.html = {
  pick = function(win)
    if not (win.file.name or ''):match('.cshtml$') then
      return format.stdio_formatter(function(win, range, pos)
        return 'prettier --parser html --stdin-filepath ' .. win.file.path
      end, { ranged = false })
    end
  end,
}
format.formatters.javascript = prettier
format.formatters.json = prettier
format.formatters.markdown = {
  pick = function(win)
    if (win.file.name or ''):match('.eml$') then
      return {
        apply = function(win, range, pos)
          local nl = lpeg.P('\n')
          local _, finish = win.file:match_at(((1 - nl) ^ 1 * nl) ^ 1 * nl, 1)
          local status, out, err = vis:pipe(
            win.file,
            { start = finish, finish = win.file.size },
            'prettier --parser markdown --prose-wrap always --print-width 69'
          )
          if status == 0 then
            win.file:delete({ start = finish, finish = win.file.size })
            win.file:insert(finish, out)
          else
            vis:message(err)
          end
          return nil, nil, pos
        end,
        options = { ranged = false },
      }
    else
      return prettier_md
    end
  end,
}
format.formatters.powershell = format.stdio_formatter([[
  pwsh -c '
    Invoke-Formatter -Settings @{
      Rules = @{
        PSUseConsistentWhitespace = @{ Enable = $true };
        PSUseConsistentIndentation = @{ Enable = $true; IndentationSize = 2};
      };
    } -ScriptDefinition `
      ([IO.StreamReader]::new([Console]::OpenStandardInput()).ReadToEnd())
  ' | sed -e :a -e '/^\(\r\{0,1\}\n\)*$/{$d;N;};/\n$/ba'
]])
format.formatters.python = format.stdio_formatter('yapf')
format.formatters.typescript = prettier
format.formatters.xml = format.formatters.html
format.formatters.yaml = prettier

lspc.message_level = 1
lspc.highlight_diagnostics = 'range'
lspc.ls_map.beancount = {
  name = 'beancount',
  cmd = 'beancount-language-server --stdio',
}
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

vis:command_register('format', function(argv, force, win, selection, range)
  if format.formatters[vis.win.syntax] then
    win.selection.pos = format.apply(win.file, range, selection.pos)
  elseif lspc then
    local lspc_conf = lspc.ls_map[win.syntax]
    if lspc_conf then
      local ls = lspc.running[lspc_conf.name]
      if ls and ls.capabilities['documentFormattingProvider'] then
        vis:command('lspc-format')
      end
    end
  else
    vis:info('No formatter for ' .. win.syntax)
  end
end, 'Format file using configured formatter')
vis:operator_new('=', function()
  vis:command('format')
end)
vis:map(vis.modes.NORMAL, '=', function()
  vis:command('format')
end)

vis.ftdetect.filetypes.mail = nil
vis.ftdetect.filetypes.bash.detect = function(file)
  return file.name:match('workspace/config$')
end
vis.ftdetect.filetypes.beancount = {
  ext = { '%.bean$', '%.beancount$' },
}
vis.ftdetect.filetypes.hcl = {
  ext = { '%.hcl$', '%.tf$', '%.tfvars$' },
}
table.insert(vis.ftdetect.filetypes.html.ext, '.cshtml$')
table.insert(vis.ftdetect.filetypes.ini.ext, '^.editorconfig$')
vis.ftdetect.filetypes.ini.detect = function(file)
  return file.name:match('.git/config$')
end
table.insert(vis.ftdetect.filetypes.markdown.ext, '.eml$')
table.insert(vis.ftdetect.filetypes.yaml.ext, '^.clang%-format$')
table.insert(
  (vis.ftdetect.filetypes.typescript or vis.ftdetect.filetypes.javascript).ext,
  '.tsx?$'
)
table.insert(vis.ftdetect.filetypes.xml.ext, '.csproj$')

vis:command_register('debug', function(argv, force, win, sel, range)
  if win.syntax == 'markdown' then
    vis:pipe(
      win.file,
      { start = 0, finish = win.file.size },
      (
        (win.file.name or ''):match('.eml$') and 'mail_client format'
        or 'pandoc -s'
      )
        .. ' | tee "${tmp_md:=$(mktemp -d)/md.html}" >/dev/null;'
        .. '(browser "${tmp_md}" >/dev/null 2>&1);'
        .. 'sleep 0.5;'
        .. 'rm -r "$tmp_md"'
    )
  else
    vis:info('No debugger for ' .. win.syntax)
  end
end, 'Run file in debugger')
vis:map(vis.modes.NORMAL, '<M-r>r', function()
  vis:command('debug')
end)
vis:map(vis.modes.NORMAL, '<C-r>r', function()
  vis:command('debug')
end)

vis:command_register('fuzzy-open', function(argv, force, win, sel, range)
  local t = win.file.name .. string.rep(' ', win.width - #win.file.name - 2)
  local fz = io.popen([[
    exec </dev/tty
    tput cup $(($(tput lines) - 10)) >/dev/tty
    tty="$(stty -g)"
    stty sane >/dev/tty 2>/dev/null
    git ls-files -z --cached --other --exclude-standard \
      | fzf --read0 --print0 --height=10 \
        --border=top --border-label-pos=1 \
        --color=border:7:reverse,label:7:reverse:bold \
        --color=scrollbar:regular \
        --layout=default --border-label=" ]] .. t .. [["
    r=$?
    stty "$tty" >/dev/tty 2>/dev/null
    exit $r
  ]])
  if fz then
    local out = fz:read('*a')
    local _, _, status = fz:close()
    vis:redraw()
    if status == 0 then
      lspc.open_file(win, out, nil, nil, 'e')
      return
    end
  end
  vis:redraw()
end, 'Open file using fuzzy finder')
vis:map(vis.modes.NORMAL, '<M-p>', function()
  vis:command('fuzzy-open')
end)
vis:map(vis.modes.NORMAL, '<C-p>', function()
  vis:command('fuzzy-open')
end)

vis:command_register('fuzzy-find', function(argv, force, win, sel, range)
  local fz = io.popen(
    "RFV_QUERY='"
      .. vis.registers['/'][1]:sub(1, -2):gsub("'", "'\\''")
      .. "'"
      .. ' rfv; r=$?; tput smcup >/dev/tty; exit $r'
  )
  if fz then
    local out = fz:read('*a')
    local _, _, status = fz:close()
    if status == 0 then
      local C, P, R = vis.lpeg.C, vis.lpeg.P, vis.lpeg.R
      local any, colon, num, nl = P(1), P(':'), R('09'), P('\n')
      local query, file, line, col = vis.lpeg.match(
        P(C(P(1 - nl) ^ 0) * nl)
          * C((any - P(colon * num ^ 1 * colon * num ^ 1 * colon)) ^ 1)
          * P(colon * C(num ^ 1) * colon * C(num ^ 1) * colon),
        out
      )
      vis:redraw()
      lspc.open_file(win, file, line, col, 'e')
      vis.registers['/'] = { query }
      return
    end
  end
  vis:redraw()
end, 'Find in containing repository using fuzzy finder with preview')
vis:map(vis.modes.NORMAL, '<M-f>', function()
  vis:command('fuzzy-find')
end)
vis:map(vis.modes.NORMAL, '<C-f>', function()
  vis:command('fuzzy-find')
end)

vis:command_register(
  'show-syntax',
  function(argv, force, win, selection, range)
    vis:info(vis.win.syntax)
  end,
  'Show syntax of current file'
)

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

vis:command_register('make', function(argv, force, win, selection, range)
  vis:command('w')
  local pos = win.selection.pos
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
  vis:command('e')
  vis:redraw()
  win.selection.pos = pos
end, 'Run make target')
vis:map(vis.modes.NORMAL, 'm', function()
  vis:command('make')
end)

vis.options.autoindent = true
vis.options.escdelay = 1
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
  vis:command('set theme default')
  win.options.numbers = true
  win.options.showtabs = win.options.expandtab

  if (win.file.name or ''):match('git/config$') then
    win.options.expandtab = false
    win.options.showtabs = false
  elseif (win.file.name or ''):match('.tf$') then
    win.options.tabwidth = 2
  elseif
    (win.syntax == 'diff' or win.syntax == 'git-commit')
    and (win.file.name or ''):match('COMMIT_EDITMSG$')
  then
    win.options.colorcolumn = 73
    win.selection.pos = 0
    vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function(win)
      if not win.syntax or not vis.lexers.load then
        return
      end
      local line1_len = #win.file.lines[1]
      if line1_len > 50 then
        win:style(win.STYLE_COLOR_COLUMN, 50, line1_len)
      end
      local line2_len = #win.file.lines > 1 and #win.file.lines[2] or 0
      if line2_len > 0 and not win.file.lines[2]:match('^#') then
        win:style(win.STYLE_COLOR_COLUMN, line1_len + 1, line1_len + line2_len)
      end
      local lexer = vis.lexers.load(win.syntax, nil, true)
      local comment_style_id = nil
      if lexer._TAGS then
        for id, token_name in ipairs(lexer._TAGS) do
          if token_name:upper() == 'COMMENT' then
            comment_style_id = id
          end
        end
      else
        comment_style_id = lexer._TOKENSTYLES.comment
      end
      local bytes = win.viewport.bytes or win.viewport
      local len = bytes.start
      for line in win.file:content(bytes):gmatch('([^\n]*)\n') do
        if line:match('^#') then
          win:style(comment_style_id, len, len + #line)
        end
        len = len + #line + 1
      end
    end)
  end
end)

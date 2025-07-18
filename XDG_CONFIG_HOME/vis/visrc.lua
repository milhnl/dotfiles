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
local ft_options =
  require_plugin('https://milhnl@github.com/milhnl/vis-filetype-options')
require_plugin('https://milhnl@github.com/milhnl/vis-editorconfig-options')
require_plugin('https://milhnl@github.com/milhnl/vis-modeline-options')
require_plugin('https://milhnl@github.com/milhnl/vis-backspace')
require_plugin('https://milhnl@github.com/milhnl/vis-term-title')
require_plugin('https://milhnl@github.com/milhnl/vis-crlf')
local format = require_plugin('https://milhnl@github.com/milhnl/vis-format')
local lspc = require_plugin('https://gitlab.com/muhq/vis-lspc')

local vis_pipe = function(input, cmd, fullscreen)
  if cmd == nil then
    input, cmd = '', input
  end
  local fz = io.popen(cmd)
  if fz then
    local out = fz:read('*a')
    local _, _, status = fz:close()
    return status, status == 0 and out or nil
  end
end

ft_options.go = { expandtab = false, showtabs = false }
ft_options.javascript = { tabwidth = 2 }
ft_options.typescript = { tabwidth = 2 }
ft_options.pkgbuild = { tabwidth = 2 }
ft_options.powershell = { tabwidth = 2 }
ft_options.rust = { tabwidth = 4, expandtab = true }
ft_options.yaml = { tabwidth = 2 }
ft_options.json = { tabwidth = 2 }

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
format.formatters.sql = format.stdio_formatter(function(win)
  return [[
    plug="$(npm -g list -p | grep prettier-plugin-sql)/lib/index.js"
    [ -n "$plug" ] || npm i -g prettier-plugin-sql
    plug="$(npm -g list -p | grep prettier-plugin-sql)/lib/index.js"
    [ -n "$plug" ] || { printf "prettier-plugin-sql not found" >&2; exit 1; }
    prettier --plugin="$plug" \
      --keyword-case='lower' \
      --data-type-case='lower' \
      ]] .. format.with_filename(win, ' --stdin-filepath ') .. [[
  ]]
end, { ranged = false })
format.formatters.swift = format.stdio_formatter(function(win)
  return 'swift-format format'
    .. format.with_filename(win, ' --assume-filename ')
    .. ' -'
end)
format.formatters.typescript = prettier
format.formatters.xml = format.formatters.html
format.formatters.yaml = prettier

lspc.message_level = 1
lspc.logging = true
lspc.log_file = os.getenv('XDG_CACHE_HOME') .. '/vis-lspc.log'
lspc.highlight_diagnostics = 'range'
lspc.ls_map.beancount = {
  name = 'beancount',
  cmd = 'beancount-language-server --stdio',
}
lspc.ls_map.csharp = {
  name = 'csharp',
  cmd = 'csharp-language-server',
  roots = { 'global.json' },
}
lspc.ls_map.javascript = {
  name = 'typescript',
  cmd = [[sh -c '
    if [ -e deno.json ] || [ -e deno.lock ]; then
      exec deno lsp
    else
      exec typescript-language-server --stdio
    fi
  ']],
  roots = { 'package.json', 'tsconfig.json', 'jsconfig.json', 'deno.json' },
}
lspc.ls_map.python = {
  name = 'python-lsp-server',
  cmd = 'uv run --with python-lsp-server,pylsp-mypy pylsp',
  roots = { 'requirements.txt', 'setup.py', 'pyproject.toml' },
}
lspc.ls_map.rust = {
  name = 'rust',
  cmd = 'rustup component list --installed | grep -q rust-analyzer'
    .. '    || rustup component add rust-analyzer 2>/dev/null'
    .. '    && rustup run stable rust-analyzer',
  roots = { 'Cargo.toml' },
}
lspc.ls_map.typescript = lspc.ls_map.javascript

vis:map(vis.modes.NORMAL, 'gb', function()
  vis:command('lspc-back')
end)
vis:map(vis.modes.INSERT, '<S-Tab>', function()
  vis:command('lspc-completion')
  vis.mode = vis.modes.INSERT
end, 'lspc: completion')

format.options.on_save = function(win)
  return win.syntax ~= 'text'
end
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
vis.ftdetect.filetypes.beancount = {
  ext = { '%.bean$', '%.beancount$' },
}
vis.ftdetect.filetypes.hcl = {
  ext = { '%.hcl$', '%.tf$', '%.tfvars$' },
}
vis.ftdetect.filetypes.swift = {
  ext = { '%.swift$' },
}
table.insert(vis.ftdetect.filetypes['git-commit'].cmd, 'set cc 73')
table.insert(vis.ftdetect.filetypes.html.ext, '.cshtml$')
table.insert(vis.ftdetect.filetypes.ini.ext, '^.editorconfig$')
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
        (win.file.name or ''):match('.eml$')
          and '$PREFIX/libexec/eml-to-html'
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

vis:map(vis.modes.NORMAL, ' e', function()
  local anchored = vis.win.selection.anchored
  local range = vis.win.selection.range
  vis:feedkeys('<vis-search-forward>lspc-diagnostic-search<Enter>')
  vis.win.selection.anchored = anchored
  vis.win.selection.range = range
  vis:command('lspc-show-diagnostics')
  vis.mode = vis.modes.NORMAL
end, 'lspc: show diagnostic of current line')
vis:map(vis.modes.NORMAL, 'n', function()
  if vis.registers['/'][1]:sub(1, -2) == 'lspc-diagnostic-search' then
    vis:command('lspc-next-diagnostic')
  else
    vis:feedkeys('<vis-motion-search-repeat-forward>')
  end
end)
vis:map(vis.modes.NORMAL, 'N', function()
  if vis.registers['/'][1]:sub(1, -2) == 'lspc-diagnostic-search' then
    vis:command('lspc-prev-diagnostic')
  else
    vis:feedkeys('<vis-motion-search-repeat-backward>')
  end
end)

vis:command_register('fuzzy-open', function(_, _, win)
  local t = win.file.name .. string.rep(' ', win.width - #win.file.name - 2)
  local _, out = vis_pipe([[
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
  if out ~= nil then
    vis:redraw()
    lspc.open_file(win, out, nil, nil, 'e')
    return
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
  local _, out = vis_pipe(
    "RFV_QUERY='"
      .. vis.registers['/'][1]
        :gsub(string.char(0) .. '$', '')
        :gsub("'", "'\\''")
      .. "'"
      .. ' rfv; r=$?; tput smcup >/dev/tty; exit $r'
  )
  if out ~= nil then
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

vis:map(vis.modes.NORMAL, '<Escape>', function()
  if (not vis.win.file.modified) and (vis.win.file.path == nil) then
    vis:command(':q')
    return
  else
    -- vis does not expose whether the message window is open
    local height = 0
    local term_height = 0
    for win in vis:windows() do
      height = height + win.viewport.height + 1
    end
    local _, out = vis_pipe('tput lines')
    if out ~= nil then
      term_height = tonumber(out) or 0
    end
    if height <= (term_height - vis.win.height) then
      vis:message('')
      vis:command('q')
    end
  end
  vis:feedkeys('<vis-mode-normal-escape>')
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

vis.options.autoindent = true
vis.options.escdelay = 1

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
  win.options.numbers = true
  win.options.showtabs = win.options.expandtab

  if
    (win.syntax == 'diff' or win.syntax == 'git-commit')
    and (win.file.name or ''):match('COMMIT_EDITMSG$')
  then
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

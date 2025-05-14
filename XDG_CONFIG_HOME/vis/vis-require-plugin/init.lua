return function(spec)
  spec = type(spec) == 'string' and { url = spec } or spec
  spec.alias = spec.alias or spec.url:gsub('^.*/', ''):gsub('.git$', '')
  local status, res = pcall(require, spec.alias)
  if status then
    return res
  elseif
    res:find(
      "module '"
        .. spec.alias:gsub('([(%:)%:.%:%%:+%:-%:*%:?%:[%:^%:$])', '%%%1')
        .. "' not found:"
    )
  then
    local base = (
      os.getenv('XDG_CONFIG_HOME') or os.getenv('HOME') .. '/.config'
    ) .. '/vis'
    local fz = io.popen([[
      set -eu
      printf '\rCloning ]] .. spec.alias:gsub("'", "'\\''") .. [[\n' >/dev/tty
      dir=']] .. (base .. '/' .. spec.alias):gsub("'", "'\\''") .. [['
      mkdir -p "$dir"
      git clone  --recurse-submodules \
        ']] .. spec.url:gsub("'", "'\\''") .. [[' "$dir" 2>&1
    ]])
    if fz then
      local out = fz:read('*a')
      local _, _, status = fz:close()
      if status ~= 0 then
        vis:message(out)
        error()
      end
    end
  end
  return require(spec.alias .. (spec.file and ('/' .. spec.file) or ''))
end

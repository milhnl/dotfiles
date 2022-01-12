local l = require('lexer')
local token = l.token
local S = lpeg.S
local diff = l.load('diff')

local M = {_NAME = 'git-commit'}

local comment = token(l.COMMENT, '#' * l.any^0)

local _rules = diff._rules
table.insert(_rules, #_rules - 1, {'comment', comment})
M._rules = _rules
M._tokenstyles = diff._tokenstyles
M._foldsymbols = diff._foldsymbols
M._LEXBYLINE = diff._LEXBYLINE

return M

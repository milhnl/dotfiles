local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, S = lpeg.P, lpeg.S

local lex = lexer.new('git-commit', {lex_by_line = true})
local diff = lexer.load('diff')

lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.any^0))
lex:add_rule('any_line', token(lexer.DEFAULT, lexer.any^1))

return lex

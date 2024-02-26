-- Beancount LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

local string = lex:tag(lexer.STRING, lexer.range('"', '"'))
lex:add_rule(lexer.STRING, string)

local comment = lex:tag(
  lexer.COMMENT,
  lexer.to_eol('#') + lexer.to_eol('//') + lexer.range('/*', '*/')
)
lex:add_rule(lexer.COMMENT, comment)

return lex

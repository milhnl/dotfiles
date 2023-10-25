-- Beancount LPeg lexer.

local lexer = lexer
local P, S = lpeg.P, lpeg.S

local lex = lexer.new(...)

local ws = lex:get_rule('whitespace')

local date = lex:tag(
  lexer.NUMBER,
  lexer.digit
    * lexer.digit
    * lexer.digit
    * lexer.digit
    * '-'
    * lexer.digit
    * lexer.digit
    * '-'
    * lexer.digit
    * lexer.digit
)

local string = lex:tag(lexer.STRING, lexer.range('"', '"'))

local invalid = lex:tag(lexer.ERROR, '!')

local directive = lex:tag(
  lexer.KEYWORD,
  lexer.word_match({
    'open',
    'close',
    'commodity',
    'txn',
    'balance',
    'pad',
    'note',
    'document',
    'price',
    'event',
    'query',
  })
)

lex:add_rule(
  'transaction',
  date * ws * (directive * ws) ^ -1 * ('*' + invalid) * (ws * string) ^ -2
)
lex:add_rule('date', date)
lex:add_rule(lexer.KEYWORD, directive)

local comment = lex:tag(lexer.COMMENT, lexer.to_eol(';'))
lex:add_rule(lexer.COMMENT, comment)

local top_account = lex:tag(
  lexer.VARIABLE,
  lexer.word_match({
    'Assets',
    'Liabilities',
    'Equity',
    'Income',
    'Expenses',
  })
)

local account = lex:tag(
  lexer.VARIABLE,
  top_account
    * (':' * (lexer.upper + lexer.digit) * (lexer.alnum + '-') ^ 0) ^ 0
)
lex:add_rule('account', account)

return lex

-- base16-vis (https://github.com/pshevtsov/base16-vis)
-- by Petr Shevtsov
-- Default Dark scheme by Chris Kempson (http://chriskempson.com)

local lexers = vis.lexers

local colors = {
    ['black'] = '0',
    ['red'] = '1',
    ['green'] = '2',
    ['yellow'] = '3',
    ['blue'] = '4',
    ['magenta'] = '5',
    ['cyan'] = '6',
    ['white'] = '7',
    ['bright_black'] = '8',
    ['bright_white'] = '15',
    ['base09'] = '16',
    ['base0f'] = '17',
    ['base01'] = '18',
    ['base02'] = '19',
    ['base04'] = '20',
    ['base06'] = '21',
}

lexers.colors = colors

--local fg = ',fore:'..fg..','
--local bg = ',back:'..colors.base00..','
lexers.STYLE_DEFAULT ='back:default,fore:default'
lexers.STYLE_NOTHING = 'back:default'
lexers.STYLE_CLASS = 'fore:yellow,bold'
lexers.STYLE_COMMENT = 'fore:'..colors.bright_black
lexers.STYLE_CONSTANT = 'fore:cyan,bold'
lexers.STYLE_DEFINITION = 'fore:blue,bold'
lexers.STYLE_ERROR = 'fore:red,italics'
lexers.STYLE_FUNCTION = 'fore:blue'
lexers.STYLE_KEYWORD = 'fore:magenta'
lexers.STYLE_LABEL = 'fore:green,bold'
lexers.STYLE_NUMBER = 'fore:yellow'
lexers.STYLE_OPERATOR = 'fore:white'
lexers.STYLE_REGEX = 'fore:green,bold'
lexers.STYLE_STRING = 'fore:green'
lexers.STYLE_PREPROCESSOR = 'fore:magenta'
lexers.STYLE_TAG = 'fore:red,bold'
lexers.STYLE_TYPE = 'fore:magenta'
lexers.STYLE_VARIABLE = 'fore:blue,bold'
lexers.STYLE_WHITESPACE = ''
lexers.STYLE_EMBEDDED = 'back:blue,bold'
lexers.STYLE_IDENTIFIER = 'fore:white'

lexers.STYLE_LINENUMBER = 'fore:'..colors.bright_black
lexers.STYLE_CURSOR = 'reverse'
lexers.STYLE_CURSOR_PRIMARY = lexers.STYLE_CURSOR..',fore:yellow'
lexers.STYLE_CURSOR_LINE = 'underlined'
lexers.STYLE_COLOR_COLUMN = 'fore:red,back:'..colors.bright_black
lexers.STYLE_SELECTION = 'back:white'
lexers.STYLE_STATUS = 'reverse'
lexers.STYLE_STATUS_FOCUSED = 'reverse,bold'
lexers.STYLE_SEPARATOR = lexers.STYLE_DEFAULT
lexers.STYLE_INFO = 'fore:default,back:default,bold'
lexers.STYLE_EOF = 'fore:'..colors.bright_black

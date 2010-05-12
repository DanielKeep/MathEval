module Tokens;

import tango.text.convert.Format;
import Location;

private
{
    import TokensCtfe : generateTokens_ctfe;
}

const char[][2][] SymbolTokens =
[
    ["=", "eq"],
    ["/=", "slasheq"],
    ["!=", "noteq"],
    ["<>", "ltgt"],
    ["(", "lparen"],
    [")", "rparen"],
    ["[", "lbracket"],
    ["]", "rbracket"],
    [",", "comma"],
    ["**", "starstar"],
    ["*", "star"],
    ["//", "slashslash"],
    ["/", "slash"],
    ["+", "plus"],
    ["-", "hyphen"],
    ["<=", "lteq"],
    [">=", "gteq"],
    ["<", "lt"],
    [">", "gt"],
];

const char[][] LiteralTokens =
[
    "let",
    "uniform",
];

const char[][] OtherTokens =
[
    "number",
    "ident",
    "eol",
    "eos",
];

/*
    Generates the following:

    TOK type
    TOKxxx constants (including TOKnone)
    tokToNameMap : char[][TOK]
    tokToName(TOK) : char[]
    nameToTokMap : TOK[char[]]
    nameToTok(char[]) : TOK
*/

mixin(generateTokens_ctfe(__FILE__, __LINE__,
            SymbolTokens, LiteralTokens, OtherTokens));

struct Token
{
    Location loc;
    TOK type = TOKnone;
    char[] text;

    static Token opCall(Location loc, TOK type, char[] text)
    {
        Token r;
        r.loc = loc;
        r.type = type;
        r.text = text;
        return r;
    }

    char[] toString()
    {
        return Format("<{}:{}@{}>", tokToName(type), text, loc);
    }
}


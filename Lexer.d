module Lexer;

import tango.text.convert.Format;
import tango.text.Unicode : isWhitespace, isSpace, isDigit, isLetter,
       isLetterOrDigit;

import Location : LocErr;
import Source : Source;
import Tokens; // Token, TOKx, ...

alias LocErr LexErr;

void skipWhitespace(Source src, LexErr err)
{
    while( true )
    {
        auto cp = src[0];

        // newlines don't count as whitespace; they lex as TOKeol
        if( cp == '\r' || cp == '\n' )
            return;

        else if( isWhitespace(cp) )
            src.advance;
        
        else if( isSpace(cp) )
            err(src.loc, "unusual whitespace detected; only regular spaces, "
                    "tabs and newlines allowed");

        else
            return;
    }
}

bool lexSymbol(Source src, LexErr err, out Token token)
{
    auto cp0 = src.get(0);
    auto cp1 = src.get(1);

    size_t l = 0; // length of symbol
    TOK tok; // symbol token type

    switch( cp0 )
    {
        // unique prefix single-cp symbols
        case '=': l = 1; tok = TOKeq; break;
        case '(': l = 1; tok = TOKlparen; break;
        case ')': l = 1; tok = TOKrparen; break;
        case '[': l = 1; tok = TOKlbracket; break;
        case ']': l = 1; tok = TOKrbracket; break;
        case ',': l = 1; tok = TOKcomma; break;
        case '+': l = 1; tok = TOKplus; break;
        case '-': l = 1; tok = TOKhyphen; break;

        // multi-cp symbols
        case '!':
            switch( cp1 )
            {
                case '=': l = 2; tok = TOKnoteq; break;
                default:  err(src.loc, "unexpected '{}' after '!'", cp1);
            }
            break;

        case '/':
            switch( cp1 )
            {
                case '=': l = 2; tok = TOKslasheq; break;
                case '/': l = 2; tok = TOKslashslash; break;
                default:  l = 1; tok = TOKslash; break;
            }
            break;

        case '*':
            switch( cp1 )
            {
                case '*': l = 2; tok = TOKstarstar; break;
                default:  l = 1; tok = TOKstar; break;
            }
            break;

        case '<':
            switch( cp1 )
            {
                case '>': l = 2; tok = TOKltgt; break;
                case '=': l = 2; tok = TOKlteq; break;
                default:  l = 1; tok = TOKlt; break;
            }
            break;

        case '>':
            switch( cp1 )
            {
                case '=': l = 2; tok = TOKgteq; break;
                default:  l = 1; tok = TOKgt; break;
            }
            break;

        default:
            // no op
    }

    if( l == 0 )
        return false;

    token = Token(src.loc, tok, src.slice(l));
    src.advance(l);
    return true;
}

version( Unittest )
{
    import tango.text.convert.Format;
    
    unittest
    {
        Token tok;

        void lexErr(Location loc, char[] fmt, ...)
        {
            assert( false,
                    Format("unit test failure: {}: {}",
                        loc.toString,
                        Format.convert(_arguments, _argptr, fmt)) );
        }

        foreach( sym_name ; SymbolTokens )
        {
            auto sym = sym_name[0];
            auto name = sym_name[1];
            scope src = new Source(__FILE__~":unittest", sym, __LINE__, 1);

            bool f = lexSymbol(src, &lexErr, tok);
            assert( f, "failed on "~name );
            assert( tok.type == nameToTok(name), name~"; got: "~tokToName(tok.type) );
            assert( tok.text == sym, name~"; got: \""~tok.text~"\"" );
        }
    }
}

bool lexEol(Source src, LexErr err, out Token token)
{
    auto cp0 = src[0];
    size_t l = 0;

    if( cp0 == '\r' )
    {
        if( src[1] == '\n' )
            l = 2;
        else
            l = 1;
    }
    else if( cp0 == '\n' )
    {
        l = 1;
    }

    if( l == 0 )
        return false;

    token = Token(src.loc, TOKeol, src.slice(l));
    src.advance(l);
    return true;
}

bool lexEos(Source src, LexErr err, out Token token)
{
    if( src.length == 0 )
    {
        token = Token(src.loc, TOKeos, "");
        return true;
    }
    else
        return false;
}

bool isIdentStart(dchar c)
{
    switch( c )
    {
        case '$':
        case '_':   return true;

        default:    return isLetter(c);
    }
}

bool isIdent(dchar c)
{
    switch( c )
    {
        case '\'':  return true;

        default:    return isIdentStart(c) || isDigit(c);
    }
}

version( Unittest )
{
    unittest
    {
        assert( !isIdent(' ') );
    }
}

bool lexLiteral(Source src, LexErr err, out Token token)
{
    Source.Mark mark;
    auto cp0 = src[0];

    char[] tail; // used to look for next matching substring

    // switch on first character and then match progressively longer
    // substrings.
    switch( cp0 )
    {
        case 'l':
            mark = src.save;
            src.advance;
            tail = src.advance("et".length);
            if( isIdent(src[0]) || tail != "et" )
            {
                src.restore(mark);
                return false;
            }

            token = Token(src.locFrom(mark),
                    TOKlet, src.sliceFrom(mark));
            return true;

        case 'u':
            mark = src.save;
            src.advance;
            tail = src.advance("niform".length);
            if( isIdent(src[0]) || tail != "niform" )
            {
                src.restore(mark);
                return false;
            }

            token = Token(src.locFrom(mark),
                    TOKuniform, src.sliceFrom(mark));
            return true;

        default:
    }

    return false;
}

bool lexIdentifier(Source src, LexErr err, out Token token)
{
    if( !isIdentStart(src[0]) )
        return false;

    auto loc = src.loc;
    auto mark = src.save;
    size_t l = 1;

    bool isDollar = (src[0] == '$');

    src.advance;

    if( isDollar )
    {
        if( src[0] == '(' )
        {
            src.advance;
            size_t depth = 1;

            while( src.length > 0 && depth > 0 )
            {
                auto src0 = src[0];

                if( src0 == '(' )
                    ++ depth;

                else if( src0 == ')' )
                    -- depth;

                else if( !( src0 == '-' || isIdent(src0) ) )
                    break;

                src.advance;
                ++ l;
            }

            if( depth > 0 )
                err(loc, "unterminated identifier; expected {} more"
                        " closing parentheses", depth);
        }
        else
            while( src.length > 0 )
            {
                auto src0 = src[0];
                if( !( src0 == '-' || isIdent(src0) ) )
                    break;

                src.advance;
                ++ l;
            }
    }
    else
        while( src.length > 0 )
        {
            if( !isIdent(src[0]) )
                break;

            src.advance;
            ++ l;
        }

    token = Token(src.locFrom(mark),
            TOKident, src.sliceFrom(mark));
    return true;
}

/**
    An inner digit can be either a decimal digit OR an underscore.
*/
bool isInnerDigit(dchar cp)
{
    return (cp == '_') || isDigit(cp);
}

bool lexNumber(Source src, LexErr err, out Token token)
{
    /*

    Number Literal

    >>─┬─╢ digit seq ╟─┬─'.'─┬─╢ digit seq ╟─┐
       │               │     └───────────────│
       │               └─────────────────────│
       └─'.'─╢ digit seq ╟─────────────────────┬─╢ exponent ╟─┐
                                               └────────────────┐
                                                                ╧

    Digit Sequence

    ╟─digit─┬───digit or '_'─┬───╢
            │ └──────────────┘ │
            └──────────────────┘

    Exponent

                      ┌───────┐
    ╟─┬─'e'───┬─────────digit─┴─╢
      └─'E'─┘ ├─'+'─┘
              └─'-'─┘

    */

    auto cp0 = src[0];

    if( !( isDigit(cp0) || cp0 == '.' ) )
        return false;

    auto loc = src.loc;
    auto mark = src.save;

    void eatDigitSeq()
    {
        auto cp = src[0];
        if( ! isDigit(cp) )
            err(loc, "expected decimal digit, not '{}'", cp);

        src.advance;

        while( isInnerDigit(src[0]) )
            src.advance;
    }

    void eatExponent()
    {
        auto cp = src[0];
        if( !( cp == 'e' || cp == 'E' ) )
            err(loc, "expected 'e' or 'E', not '{}'", cp);

        src.advance;

        cp = src[0];
        if( cp == '+' || cp == '-' )
        {
            src.advance;
            cp = src[0];
        }

        if( !isDigit(cp) )
            err(loc, "expected decimal digit, not '{}'", cp);

        src.advance;

        while( isDigit(src[0]) )
            src.advance;
    }

    if( cp0 == '.' )
    {
        src.advance;
        eatDigitSeq;
    }
    else
    {
        eatDigitSeq;

        cp0 = src[0];
        if( cp0 == '.' )
        {
            src.advance;
            cp0 = src[0];
            if( isDigit(cp0) )
                eatDigitSeq;
        }
    }

    cp0 = src[0];
    if( cp0 == 'e' || cp0 == 'E' )
        eatExponent;

    token = Token(loc, TOKnumber, src.sliceFrom(mark));
    return true;
}

bool lexNext(Source src, LexErr err, out Token token)
{
    skipWhitespace(src, err);

    if( lexEos(src, err, token) )           return true;
    if( lexEol(src, err, token) )           return true;
    if( lexSymbol(src, err, token) )        return true;
    if( lexLiteral(src, err, token) )       return true;
    if( lexIdentifier(src, err, token) )    return true;
    if( lexNumber(src, err, token) )        return true;
    
    return false;
}

struct LexIter
{
    Source src;
    LexErr err;

    int opApply(int delegate(ref Token) dg)
    {
        int r = 0;
        Token token;
        auto err = this.err;

        if( err is null )
            err = &defaultErr;

        while( true )
        {
            auto f = lexNext(src, err, token);
            if( !f )
                err(src.loc, "unexpected '{}'", src[0]);

            if( token.type == TOKeos )
                break;
            r = dg(token);
            if( r )
                break;
        }

        return r;
    }

    void defaultErr(Location loc, char[] fmt, ...)
    {
        throw new LexError(loc, Format.convert(_arguments, _argptr, fmt));
    }
}

class LexError : Exception
{
    Location loc;
    char[] reason;

    this(Location loc, char[] reason)
    {
        this.loc = loc;
        this.reason = reason;

        super(Format("{}: {}", loc.toString, reason));
    }
}

LexIter lexIter(char[] name, char[] src, LexErr err = null)
{
    return lexIter(new Source(name, src), err);
}

LexIter lexIter(Source src, LexErr err = null)
{
    LexIter r;
    r.src = src;
    r.err = err;
    return r;
}


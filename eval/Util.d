/**
    Various things.

    Author: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.Util;

import Float    = tango.text.convert.Float;
import Integer  = tango.text.convert.Integer;
import Utf      = tango.text.convert.Utf;

bool parseBool(char[] text)
{
    switch( text )
    {
        case "true":    return true;
        case "false":   return false;
        default:        assert(false);
    }
}

real parseReal(char[] text)
{
    return Float.parse(text);
}

char[] parseString(char[] text)
{
    char[] r;
    char[] s = text;
    assert( s.length >= 2 );
    assert( s[0] == '"' );
    assert( s[$-1] == '"' );
    s = s[1..$-1];

    while( s.length > 0 )
    {
        if( s[0] == '\\' )
        {
            auto c = s[1];
            dchar ec;
            s = s[2..$];
            switch( c )
            {
                case 'a':   ec = '\a'; break;
                case 'b':   ec = '\b'; break;
                case 'f':   ec = '\f'; break;
                case 'n':   ec = '\n'; break;
                case 'r':   ec = '\r'; break;
                case 't':   ec = '\t'; break;
                case 'v':   ec = '\v'; break;
                case '\'':  ec = '\''; break;
                case '"':   ec = '"'; break;
                case '?':   ec = '\x1b'; break;
                case '\\':  ec = '\\'; break;

                case 'x':
                    ec = cast(dchar) Integer.convert(s[0..2], 16);
                    s = s[2..$];
                    break;

                case 'u':
                    ec = cast(dchar) Integer.convert(s[0..4], 16);
                    s = s[4..$];
                    break;

                case 'U':
                    ec = cast(dchar) Integer.convert(s[0..8], 16);
                    s = s[8..$];
                    break;

                default:
                    assert(false);
            }
            char[8] buffer;
            r ~= Utf.encode(buffer, ec);
        }
        else
        {
            size_t i=1;
            while( i < s.length && s[i] != '\\' )
                ++i;

            r ~= s[0..i];
            s = s[i..$];
        }
    }

    return r;
}

char[] toStringLiteral(char[] utf8)
{
    const char[] hexChars = "0123456789abcdef";

    char[] str;
    str ~= `"`;

    foreach( dchar c ; utf8 )
    {
        if( c < 0x80 )
        {
            switch( c )
            {
            case '\\', '"':
                str ~= "\\";
                str ~= c;
                break;

            case '\a':  str ~= `\a`;    break;
            case '\b':  str ~= `\b`;    break;
            case '\f':  str ~= `\f`;    break;
            case '\n':  str ~= `\n`;    break;
            case '\r':  str ~= `\r`;    break;
            case '\t':  str ~= `\t`;    break;
            case '\v':  str ~= `\v`;    break;
            case '\x1b':str ~= `\?`;    break;
            case '\0':  str ~= `\x00`;  break;

            default:
                str ~= c;
                break;
            }
        }
        else
        {
            if( c <= 0xff )
            {
                str ~= `\x`;
                str ~= hexChars[c & 0xF];
                str ~= hexChars[c >>> 4];
            }
            else if( c <= 0xffff )
            {
                str ~= `\u`;
                str ~= hexChars[(c      ) & 0xF];
                str ~= hexChars[(c >>  4) & 0xF];
                str ~= hexChars[(c >>  8) & 0xF];
                str ~= hexChars[(c >> 12)      ];
            }
            else
            {
                str ~= `\U`;
                str ~= hexChars[(c      ) & 0xF];
                str ~= hexChars[(c >>  4) & 0xF];
                str ~= hexChars[(c >>  8) & 0xF];
                str ~= hexChars[(c >> 12) & 0xF];
                str ~= hexChars[(c >> 16) & 0xF];
                str ~= hexChars[(c >> 20) & 0xF];
                str ~= hexChars[(c >> 24) & 0xF];
                str ~= hexChars[(c >> 28)      ];
            }
        }
    }

    str ~= `"`;

    return str;
}


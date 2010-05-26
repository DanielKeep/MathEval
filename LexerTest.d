/**
    Math Eval Lexer Tester

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module LexerTest;

import tango.core.tools.TraceExceptions;
import tango.io.Stdout;
import eval.Lexer;

int main(char[][] argv)
{
    auto args = argv[1..$];

    if( args.length == 0 )
    {
        Stderr.formatln("Usage: {} TOKENS", argv[0]);
        return 1;
    }

    char[] src;

    foreach( arg ; args )
        if( arg == ";;" )
            src ~= "\n";
        else
            src ~= (src.length > 0 && src[$-1] != '\n' ? " " : "") ~ arg;

    try
    {
        foreach( token ; lexIter("cmdline", src) )
        {
            Stdout(token).newline;
        }
    }
    catch( LexError le )
    {
        Stderr(le).newline;
        return 1;
    }

    return 0;
}


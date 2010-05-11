module LexerTest;

import tango.core.tools.TraceExceptions;
import tango.io.Stdout;
import Lexer;

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
        src ~= (src.length > 0 ? " " : "") ~ arg;

    try
    {
        foreach( token ; lexIter("stdin", src) )
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


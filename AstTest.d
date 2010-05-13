module AstTest;

import tango.core.tools.TraceExceptions;
import tango.io.Console;
import tango.io.Stdout;
import tango.text.convert.Format;

import Ast;
import AstDumpVisitor;
import Parser;
import Lexer;
import Location;
import Source;
import StructuredOutput;
import TokenStream;

class Stop : Exception
{
    this() { super("STOP!"); }
}

int main(char[][] argv)
{
    auto args = argv[1..$];

    if( args.length == 0 )
    {
        Stderr.formatln("Usage: {} CODE", argv[0]);
        return 1;
    }

    char[] src;

    foreach( arg ; args )
    {
        if( arg == ";;" )
            src ~= "\n";
        else
            src ~= (src.length > 0 && src[$-1] != '\n' ? " ": "") ~ arg;
    }

    void parseError(Location loc, char[] fmt, ...)
    {
        Stderr(Format.convert(_arguments, _argptr, fmt)).newline;
        throw new Stop;
    }
    
    AstScript script;

    try
    {
        scope ts = new TokenStream(new Source("stdin", src),
                &lexNext, &parseError);
        script = parseScript(ts);
    }
    catch( Stop )
    {
        return 1;
    }

    {
        scope so = new StructuredOutput(Cout.output);
        scope dump = new AstDumpVisitor(so);
        dump.visitBase(script);
    }

    return 0;
}


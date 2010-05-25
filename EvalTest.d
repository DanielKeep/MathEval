module EvalTest;

import tango.core.tools.TraceExceptions;
import tango.io.Console;
import tango.io.Stdout;
import tango.io.device.File;
import tango.text.convert.Format;

import eval.Ast;
import eval.AstDumpVisitor;
import eval.AstEvalVisitor;
import eval.BuiltinFunctions;
import eval.BuiltinVariables;
import eval.Parser;
import eval.Lexer;
import eval.Location;
import eval.Source;
import eval.StructuredOutput;
import eval.TokenStream;
import eval.Value;

class Stop : Exception
{
    this() { super("STOP!"); }
}

int main(char[][] argv)
{
    auto args = argv[1..$];

    if( args.length == 0 )
    {
        Stderr.formatln("Usage: {} FILE", argv[0]);
        Stderr.formatln("       {} -- CODE", argv[0]);
        return 1;
    }

    char[] name;
    char[] src;

    if( args[0] == "--" )
    {
        name = "cmdline";
        foreach( arg ; args[1..$] )
        {
            if( arg == ";;" )
                src ~= "\n";
            else
                src ~= (src.length > 0 && src[$-1] != '\n' ? " ": "") ~ arg;
        }
    }
    else
    {
        name = args[0];
        src = cast(char[]) File.get(args[0]);
    }

    void error(Location loc, char[] fmt, ...)
    {
        Stderr(loc.toString)(": ")
            (Format.convert(_arguments, _argptr, fmt)).newline;
        throw new Stop;
    }
    
    Value result;

    try
    {
        scope ts = new TokenStream(new Source(name, src), &lexNext, &error);
        auto script = parseScript(ts);

        Value[char[]] variables;

        bool resolve(char[] ident, out Value value)
        {
            auto ptr = ident in variables;
            if( ptr !is null )
                value = *ptr;
            return (ptr !is null);
        }

        bool define(char[] ident, ref Value value)
        {
            if( !!( ident in variables ) )
                return false;

            variables[ident] = value;
            return true;
        }
        
        scope vars = new BuiltinVariables(&resolve, &define);
        scope funcs = new BuiltinFunctions;
        scope eval = new AstEvalVisitor(&error,
                &vars.resolve, &vars.define, &funcs.eval);
        result = eval.visitBase(script);
    }
    catch( Stop )
    {
        return 1;
    }

    Stdout(result.toString).newline;

    return 0;
}



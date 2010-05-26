/**
    Read-Eval-Print Loop.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.Repl;

import tango.io.Console;
import tango.io.Stdout;
import tango.text.convert.Format;

import eval.Ast;
import eval.AstEvalVisitor;
import eval.BuiltinFunctions;
import eval.BuiltinVariables;
import eval.Parser;
import eval.Lexer;
import eval.Location;
import eval.Source;
import eval.TokenStream;
import eval.Value;
import eval.VariableStore;

private class Stop : Exception
{
    this() { super("STOP!"); }
}

void startRepl()
{
    void prompt()
    {
        Stdout(">>> ").flush;
    }

    void help()
    {
        Stdout
            ("Commands:").newline()
            .newline()
            (" .c, .clear   Clears all variables.").newline()
            (" .h, .help    Shows this text.").newline()
            (" .q, .quit    Exits the repl.").newline()
            (" .v, .vars    Lists all user-defined variables.").newline()
        ;
    }

    void error(Location loc, char[] fmt, ...)
    {
        Stderr(loc.toString)(": ")
            (Format.convert(_arguments, _argptr, fmt)).newline;
        throw new Stop;
    }

    char[] name = "stdin";

    scope bivars = new BuiltinVariables;
    scope bifunc = new BuiltinFunctions;
    scope vars = new VariableStore(&bivars.resolve);
    scope eval = new AstEvalVisitor(&error,
            &vars.resolve, &vars.define, &bifunc.eval);

    Stdout
        ("Hi, I'm the math eval REPL.").newline()
        ("Type '.help' for more commands.").newline()
        .newline()
        .flush();

replLoop:
    while( true )
    {
        prompt;
        char[] line;
        if( ! Cin.readln(line) )
            break replLoop;

        bool contLoop = false;

        switch( line )
        {
            case ".c": case ".clear":
                // HACK!
                vars.vars = null;
                continue replLoop;

            case ".h": case ".help":
                help;
                continue replLoop;

            case ".q": case ".quit":
                break replLoop;

            case ".v": case ".vars":
                Stdout("User-defined variables:").newline;
                foreach( k,v ; vars.vars )
                    Stdout.formatln("let {} = {}", k, v.toString);
                continue replLoop;

            default:
        }

        // Parse
        AstScript script;
        contLoop = false;
        try
        {
            scope src = new Source(name, line);
            scope ts = new TokenStream(src, &lexNext, &error);
            script = parseScript(ts);
        }
        catch( Stop _ )
        {
            contLoop = true;
        }

        if( contLoop ) continue;

        // Evaluate
        Value result;
        contLoop = false;
        try
        {
            result = eval.visitBase(script);
        }
        catch( Stop _ )
        {
            contLoop = true;
        }
        if( contLoop ) continue;

        if( ! result.isInvalid )
            Stdout(result.toString).newline;
    }
}


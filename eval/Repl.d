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
            (" .f, .funcs   Lists all functions.").newline()
            (" .h, .help    Shows this text.").newline()
            (" .q, .quit    Exits the repl.").newline()
            (" .v, .vars    Lists all variables.").newline()
            .newline()
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
    scope bifunc = new BuiltinFunctions(bivars);
    scope vars = new VariableStore(bifunc);
    scope eval = new AstEvalVisitor(&error, vars);

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

            case ".f": case ".funcs":
                foreach( n,v ; &vars.iterate )
                {
                    if( !v.isFunction ) continue;
                    auto fv = v.asFunction;
                    Stdout(" - ")(n)("(");
                    if( fv.args.length > 0 )
                    {
                        Stdout(fv.args[0].name);
                        foreach( arg ; fv.args[1..$] )
                            Stdout(",")(arg.name);
                    }
                    Stdout(")").newline;
                }
                Stdout.newline();
                continue replLoop;

            case ".h": case ".help":
                help;
                continue replLoop;

            case ".q": case ".quit":
                break replLoop;

            case ".v": case ".vars":
                foreach( n,v ; &vars.iterate )
                {
                    if( v.isFunction ) continue;
                    Stdout.formatln("let {} = {}", n, v.toString);
                }
                Stdout.newline();
                continue replLoop;

            default:
            {
                char[] tail;
                auto cmd = line.headTail(tail);
                switch( cmd )
                {
                    case ".ast":
                    {
                        AstStmt stmt;
                        try
                        {
                            scope ts = new TokenStream(
                                    new Source(name, tail),
                                    &lexNext, &error);
                            stmt = parseStmt(ts);
                        }
                        catch( Stop _ )
                        {
                            continue replLoop;
                        }

                        scope so = new StructuredOutput(Cout.output);
                        scope dump = new AstDumpVisitor(so);
                        dump.visitBase(stmt);
                        Stdout.newline;
                        continue replLoop;
                    }
                    case ".lex":
                    {
                        foreach( token ; lexIter(name, tail) )
                            Stdout("  ")(token).newline;
                        Stdout.newline;
                        continue replLoop;
                    }
                    default:
                }
            }
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

        if( ! result.isNil )
            Stdout(result.toString).newline;
    }
}

bool startsWith(char[] s, char[] test)
{
    return s.length >= test.length && s[0..test.length] == test;
}

char[] headTail(char[] s, out char[] tail)
{
    char[] r;
    foreach( i,c ; s )
    {
        if( (c == ' ' || c == '\t') && r is null )
            r = s[0..i];

        if( !(c == ' ' || c == '\t') && r !is null )
        {
            tail = s[i..$];
            return r;
        }
    }
    if( r is null )
        r = s;
    return r;
}


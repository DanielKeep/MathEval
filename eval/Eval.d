/**
    Simple Eval API.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.Eval;

import eval.Ast;
import eval.AstEvalVisitor;
import eval.BuiltinFunctions;
import eval.BuiltinVariables;
import eval.Parser;
import eval.Lexer;
import eval.Location;
import eval.Source;
import eval.TokenStream;
import eval.Variables;
import eval.VariableStore;

import tango.io.Stdout;
import tango.io.device.File;
import tango.text.convert.Format;

class Stop : Exception
{
    this()
    {
        super("Stop");
    }
}

bool evalFile(char[] path, Variables existing=null)
{
    Variables _a;
    return evalFile(path, existing, _a);
}

bool evalFile(char[] path, Variables existing, out Variables vars)
{
    void error(Location loc, char[] fmt, ...)
    {
        Stderr(loc.toString)(": ")
            (Format.convert(_arguments, _argptr, fmt)).newline;
        throw new Stop;
    }

    if( existing !is null )
        vars = existing;
    else
    {
        auto bivars = new BuiltinVariables(existing);
        auto bifunc = new BuiltinFunctions(bivars);
        vars = new VariableStore(bifunc);
    }

    scope eval = new AstEvalVisitor(&error, vars);

    bool flag = false;

    try
    {
        auto srcText = cast(char[]) File.get(path);

        AstScript script;
        {
            scope src = new Source(path, srcText);
            scope ts = new TokenStream(src, &lexNext, &error);
            script = parseScript(ts);
        }

        auto result = eval.visitBase(script);

        if( ! result.isNil )
            Stdout(result.toString).newline;

        flag = true;
    }
    catch( Stop _ ) {}

    return flag;
}


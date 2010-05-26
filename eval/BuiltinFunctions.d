module eval.BuiltinFunctions;

import eval.Value;

import Math = tango.math.Math;

class BuiltinFunctions
{
    alias bool delegate(char[], ErrDg, Value[] delegate(), out Value) EvalDg;

    EvalDg _nextEval;

    this(EvalDg nextEval = null)
    {
        this._nextEval = nextEval;
    }

    bool eval(char[] ident, ErrDg err,
            Value[] delegate() getArgs, out Value result)
    {
        Value[] ga() { return getArgs(); }

        switch( ident )
        {
            case "abs":     result = fnAbs(err, ga); break;

            default:
                return nextEval(ident, err, getArgs, result);
        }
        return true;
    }

    bool nextEval(char[] ident, ErrDg err,
            Value[] delegate() getArgs, out Value result)
    {
        if( _nextEval !is null )
            return _nextEval(ident, err, getArgs, result);
        return false;
    }
}

private:

alias void delegate(char[], ...) ErrDg;

void expNumArgs(ErrDg err, char[] name, size_t n, Value[] args)
{
    if( args.length != n )
        err("{}: expected {} arg{}, got {}", name, n,
                (n==1?"":"s"), args.length);
}

void expReal(ErrDg err, char[] name, Value[] args)
{
    foreach( i, arg ; args )
        if( !arg.isReal )
            err("{}: expected real for argument {}, got {}",
                    name, (i+1), arg.tagName);
}

Value fnAbs(ErrDg err, Value[] args)
{
    expNumArgs(err, "abs", 1, args);
    expReal(err, "abs", args);

    return Value(Math.abs(args[0].asReal));
}


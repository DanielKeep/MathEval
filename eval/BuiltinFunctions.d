module eval.BuiltinFunctions;

import eval.Value;

class BuiltinFunctions
{
    alias bool delegate(char[], Value[] delegate(), out Value) EvalDg;

    EvalDg _nextEval;

    this(EvalDg nextEval = null)
    {
        this._nextEval = nextEval;
    }

    bool eval(char[] ident, Value[] delegate() getArgs, out Value result)
    {
        switch( ident )
        {
            default:
                return nextEval(ident, getArgs, result);
        }
    }

    bool nextEval(char[] ident, Value[] delegate() getArgs, out Value result)
    {
        if( _nextEval !is null )
            return _nextEval(ident, getArgs, result);
        return false;
    }
}


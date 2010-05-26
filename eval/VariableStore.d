module eval.VariableStore;

import eval.Value;

class VariableStore
{
    alias bool delegate(char[], out Value) ResolveDg;

    ResolveDg   _nextResolve;
    Value[char[]] vars;

    this(ResolveDg nextResolve = null)
    {
        this._nextResolve = nextResolve;
    }

    bool resolve(char[] ident, out Value value)
    {
        auto ptr = ident in vars;
        if( ptr !is null )
        {
            value = *ptr;
            return true;
        }
        else
            return nextResolve(ident, value);
    }

    bool define(char[] ident, ref Value value)
    {
        Value tmp;
        if( resolve(ident, tmp) )
            return false;

        variables[ident] = value;
        return true;
    }

    bool nextResolve(char[] ident, out Value value)
    {
        if( _nextResolve )
            return _nextResolve(ident, value);
        return false;
    }
}


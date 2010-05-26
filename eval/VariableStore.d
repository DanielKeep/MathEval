module eval.VariableStore;

import eval.Value;

class VariableStore
{
    alias bool delegate(char[], out Value) ResolveDg;

    ResolveDg   _nextResolve;
    Value[char[]] vars;

    bool allowRedefine = false;

    this(ResolveDg nextResolve = null, bool allowRedefine = false)
    {
        this._nextResolve = nextResolve;
        this.allowRedefine = allowRedefine;
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
        if( nextResolve(ident, tmp) )
            return false;

        if( ! allowRedefine )
            if( !!( ident in vars ) )
                return false;

        vars[ident.dup] = value;
        return true;
    }

    bool nextResolve(char[] ident, out Value value)
    {
        if( _nextResolve )
            return _nextResolve(ident, value);
        return false;
    }
}


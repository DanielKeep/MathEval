module eval.BuiltinVariables;

import eval.Value;

class BuiltinVariables
{
    alias bool delegate(char[], out Value) ResolveDg;
    alias bool delegate(char[], ref Value) DefineDg;

    ResolveDg   _nextResolve;
    DefineDg    _nextDefine;

    this(ResolveDg nextResolve = null, DefineDg nextDefine = null)
    {
        this._nextResolve = nextResolve;
        this._nextDefine  = nextDefine;
    }

    bool resolve(char[] ident, out Value value)
    {
        switch( ident )
        {
            case "e":
                value = Value(2.718_281_828_459_045_235L);
                return true;

            case "pi": case "π":
                value = Value(3.141_592_653_589_793_238L);
                return true;

            case "phi": case "φ":
                value = Value(1.618_033_988_749_894_848L);
                return true;

            default:
                return nextResolve(ident, value);
        }
    }

    bool define(char[] ident, ref Value value)
    {
        switch( ident )
        {
            case "e":
            case "pi": case "π":
            case "phi": case "φ":
                return false;

            default:
                return nextDefine(ident, value);
        }
    }

    bool nextResolve(char[] ident, out Value value)
    {
        if( _nextResolve )
            return _nextResolve(ident, value);
        return false;
    }

    bool nextDefine(char[] ident, ref Value value)
    {
        if( _nextDefine )
            return _nextDefine(ident, value);
        return false;
    }
}


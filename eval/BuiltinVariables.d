/**
    Built-in Variables.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.BuiltinVariables;

import eval.Value;
import eval.Variables;

class BuiltinVariables : Variables
{
    Variables next;

    this(Variables next = null)
    {
        this.next = next;
    }

    bool resolve(char[] ident, out Value value)
    {
        if( auto vptr = ident in varMap )
        {
            value = *vptr;
            return true;
        }
        else
            return nextResolve(ident, value);
    }

    bool define(char[] ident, ref Value value)
    {
        if( !!( ident in varMap ) )
            return false;
        else
            return nextDefine(ident, value);
    }

    int iterate(int delegate(ref char[], ref Value) dg)
    {
        auto names = varNames;

        int r = 0;
        foreach( nextName, nextValue ; &nextIterate )
        {
            char[] name;
            Value value;

            while( names.length > 0 && names[0] < nextName )
            {
                name = names[0];
                value = varMap[name];
                names = names[1..$];
                r = dg(name, value);
                if( r != 0 )
                    return r;
            }

            name = nextName;
            value = nextValue;

            r = dg(name, value);
            if( r != 0 )
                return r;
        }

        foreach( name ; names )
        {
            auto tmpN = name;
            auto tmpV = varMap[tmpN];
            r = dg(tmpN, tmpV);
            if( r != 0 )
                return r;
        }

        return r;
    }

    bool nextResolve(char[] ident, out Value value)
    {
        if( next !is null )
            return next.resolve(ident, value);
        return false;
    }

    bool nextDefine(char[] ident, ref Value value)
    {
        if( next !is null )
            return next.define(ident, value);
        return false;
    }

    int nextIterate(int delegate(ref char[], ref Value) dg)
    {
        if( next !is null )
            return next.iterate(dg);

        return 0;
    }
}

private:

Value[char[]] varMap;
char[][] varNames;

static this()
{
    alias varMap vm;

    vm["e"]     = Value(2.718_281_828_459_045_235L);
    vm["pi"]    = Value(3.141_592_653_589_793_238L);
    vm["π"]     = Value(3.141_592_653_589_793_238L);
    vm["phi"]   = Value(1.618_033_988_749_894_848L);
    vm["φ"]     = Value(1.618_033_988_749_894_848L);
    vm["inf"]   = Value(real.infinity);
    vm["nan"]   = Value(real.nan);
    vm["nil"]   = Value();
    vm["true"]  = Value(true);
    vm["false"] = Value(false);

    varNames = vm.keys;
    varNames.sort;
}


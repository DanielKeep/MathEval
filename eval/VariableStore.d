/**
    Variable Store.

    Simple implementation of the variable protocol that lets users define
    their own variables.  For best results, wrap this around a
    BuiltinVariables instance.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.VariableStore;

import eval.Value;
import eval.Variables;

class VariableStore : Variables
{
    Variables next;
    Value[char[]] vars;

    bool allowRedefine = false;

    this(Variables next = null, bool allowRedefine = false)
    {
        this.next = next;
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

    int iterate(int delegate(ref char[], ref Value) dg)
    {
        char[][] names = vars.keys;
        names.sort;

        int r = 0;
        foreach( nextName, nextValue ; &nextIterate )
        {
            char[] name;
            Value value;

            while( names.length > 0 && names[0] < nextName )
            {
                name = names[0];
                value = vars[name];
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
            auto tmpV = vars[tmpN];
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

    int nextIterate(int delegate(ref char[], ref Value) dg)
    {
        if( next !is null )
            return next.iterate(dg);

        return 0;
    }
}


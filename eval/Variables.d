/**
    Variables interface.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.Variables;

import eval.Value;

interface Variables
{
    /**
        Resolves the given identifier to a value.

        Returns true if the lookup worked; false if the variable could not be
        found.
    */
    bool resolve(char[] ident, out Value value);

    /**
        Attempts to define a new variable.

        Return true if it succeeded, false if the variable has already been
        defined and cannot be re-defined.
    */
    bool define(char[] ident, ref Value value);

    /**
        Iterates over all defined variables.
    */
    int iterate(int delegate(ref char[]) dg);
}

class VariablesDelegate : Variables
{
    alias bool delegate(char[], out Value) ResolveDg;
    alias bool delegate(char[], ref Value) DefineDg;
    alias int delegate(int delegate(ref char[])) IterateDg;

    this(ResolveDg resolveDg, DefineDg defineDg, IterateDg iterateDg)
    {
        this.resolveDg = resolveDg;
        this.defineDg = defineDg;
        this.iterateDg = iterateDg;
    }

    bool resolve(char[] ident, out Value value)
    {
        return resolveDg(ident, value);
    }

    bool define(char[] ident, ref Value value)
    {
        return defineDg(ident, value);
    }

    int iterate(int delegate(ref char[]) dg)
    {
        return iterateDg(dg);
    }

    protected ResolveDg resolveDg;
    protected DefineDg defineDg;
    protected IterateDg iterateDg;
}


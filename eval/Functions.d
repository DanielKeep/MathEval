/**
    Functions interface.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.Functions;

import eval.Value;

interface Functions
{
    /**
        Delegate type called to raise an error in the calling code.
    */
    alias void delegate(char[], ...) ErrDg;

    /**
        Delegate type used to resolve a positional argument into a value.
    */
    alias Value delegate(size_t) ArgDg;

    /**
        Attempts to invoke the specified function.

        Returns true if invocation succeeded; false if the function is not
        defined.
    */
    bool invoke(char[] ident, ErrDg err, size_t args, ArgDg getArg,
            out Value result);

    /**
        Iterates over all defined functions.
    */
    int iterate(int delegate(ref char[]) dg);
}

class FunctionsDelegate : Functions
{
    alias bool delegate(char[], ErrDg, size_t, ArgDg, out Value) InvokeDg;
    alias int delegate(int delegate(ref char[])) IterateDg;

    this(InvokeDg invokeDg, IterateDg iterateDg)
    {
        this.invokeDg = invokeDg;
        this.iterateDg = iterateDg;
    }

    bool invoke(char[] ident, ErrDg err, size_t args, ArgDg getArg,
            out Value result)
    {
        return this.invokeDg(ident, err, args, getArg, result);
    }

    int iterate(int delegate(ref char[]) dg)
    {
        return this.iterateDg(dg);
    }

    protected InvokeDg invokeDg;
    protected IterateDg iterateDg;
}


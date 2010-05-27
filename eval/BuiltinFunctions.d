/**
    Built-in Functions.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.BuiltinFunctions;

import eval.Functions;
import eval.Statistical : rand, uniformReal;
import eval.Value;

import tango.math.ErrorFunction;
import tango.math.Math;
import tango.math.Probability;

class BuiltinFunctions : Functions
{
    Functions next;

    this(Functions next = null)
    {
        this.next = next;
    }

    bool invoke(char[] ident, ErrDg err,
            size_t args, ArgDg getArg, out Value result)
    {
        Value function(ErrDg, Value[]) fn;
        Value function(ErrDg, size_t, Value delegate(size_t)) lazyFn;

        if( auto fptr = ident in fnMap )
            fn = *fptr;

        else if( auto fptr = ident in lazyFnMap )
            lazyFn = *fptr;

        else
            return nextInvoke(ident, err, args, getArg, result);

        if( fn !is null )
        {
            auto vs = new Value[args];
            foreach( i, ref v ; vs )
                v = getArg(i);

            result = fn(err, vs);
        }
        else if( lazyFn !is null )
            result = lazyFn(err, args, getArg);
        
        else
            assert(false);

        return true;
    }

    int iterate(int delegate(ref char[]) dg)
    {
        auto names = fnNames;

        int r = 0;
        foreach( nextName ; &nextIterate )
        {
            char[] name;

            while( names.length > 0 && names[0] < nextName )
            {
                name = names[0];
                names = names[1..$];
                r = dg(name);
                if( r != 0 )
                    return r;
            }

            name = nextName;

            r = dg(name);
            if( r != 0 )
                return r;
        }

        foreach( name ; names )
        {
            char[] tmp = name;
            r = dg(tmp);
            if( r != 0 )
                return r;
        }

        return r;
    }

    bool nextInvoke(char[] ident, ErrDg err,
            size_t args, ArgDg getArg, out Value result)
    {
        if( next !is null )
            return next.invoke(ident, err, args, getArg, result);
        return false;
    }

    int nextIterate(int delegate(ref char[]) dg)
    {
        if( next !is null )
            return next.iterate(dg);
        return 0;
    }
}

private:

alias void delegate(char[], ...) ErrDg;
alias Value function(ErrDg, Value[]) Fn;
alias Value function(ErrDg, size_t, Value delegate(size_t)) LazyFn;

Fn[char[]] fnMap;
LazyFn[char[]] lazyFnMap;
char[][] fnNames;

static this()
{
    alias fnMap fm;
    alias lazyFnMap lm;

    lm["if"]      = &fnIf;

    fm["abs"]     = &fnAbs;
    fm["min"]     = &fnMin;
    fm["max"]     = &fnMax;
            
    fm["cos"]     = &fnCos;
    fm["sin"]     = &fnSin;
    fm["tan"]     = &fnTan;

    fm["acos"]    = &fnAcos;
    fm["asin"]    = &fnAsin;
    fm["atan"]    = &fnAtan;
    fm["atan2"]   = &fnAtan2;

    fm["cosh"]    = &fnCosh;
    fm["sinh"]    = &fnSinh;
    fm["tanh"]    = &fnTanh;

    fm["acosh"]   = &fnAcosh;
    fm["asinh"]   = &fnAsinh;
    fm["atanh"]   = &fnAtanh;

    fm["sqrt"]    = &fnSqrt;
    fm["log"]     = &fnLog;
    fm["log2"]    = &fnLog2;
    fm["log10"]   = &fnLog10;

    fm["floor"]   = &fnFloor;
    fm["ceil"]    = &fnCeil;
    fm["round"]   = &fnRound;
    fm["trunc"]   = &fnTrunc;
    fm["clamp"]   = &fnClamp;

    fm["erf"]     = &fnErf;
    fm["erfc"]    = &fnErfc;

    fm["normal"]  = &fnNormal;
    fm["poisson"] = &fnPoisson;

    fnNames = fm.keys ~ lm.keys;
    fnNames.sort;
}

void expNumArgs(ErrDg err, char[] name, size_t n, Value[] args)
{
    if( args.length != n )
        err("{}: expected {} argument{}, got {}", name, n,
                (n==1?"":"s"), args.length);
}

void expMinArgs(ErrDg err, char[] name, size_t n, Value[] args)
{
    if( args.length < n )
        err("{}: expected {} or more arguments, got {}", name, n, args.length);
}

void expReal(ErrDg err, char[] name, Value[] args, size_t offset=0)
{
    foreach( i, arg ; args )
        if( !arg.isReal )
            err("{}: expected real for argument {}, got {}",
                    name, (offset+i+1), arg.tagName);
}

Value fnUnaryReal(char[] name, alias fn)(ErrDg err, Value[] args)
{
    expNumArgs(err, name, 1, args);
    expReal(err, name, args);

    return Value(fn(args[0].asReal));
}

Value fnBinaryReal(char[] name, alias fn)(ErrDg err, Value[] args)
{
    expNumArgs(err, name, 2, args);
    expReal(err, name, args);

    return Value(fn(args[0].asReal, args[1].asReal));
}

//
// Custom implementations
//

real round_nonCrazy(real x)
{
    return real.nan;
}

private real randfu()
{
    uint i = rand.natural();
    return (cast(real)i)/i.max;
}

real normal(real Σ, real μ)
{
    // http://www.taygeta.com/random/gaussian.html
    real x1, x2, w, y1; // y2 not used
    
    do
    {
        x1 = 2.0 * randfu - 1.0;
        x2 = 2.0 * randfu - 1.0;
        w = x1*x1 + x2*x2;
    }
    while( w >= 1.0 );
    
    w = sqrt( (-2.0 * log(w)) / w );
    y1 = x1 * w;
    //y2 = x2 * w;
    
    // Adjust for sigma and mu
    return y1*Σ + μ;
}

real poisson(real λ)
{
    return poisson(λ, real.nan, real.nan);
}

real poisson(real λ, real min, real max)
{
    // Why am I using reals?  *shrug*  Why not?  I don't like the idea
    // that lambda can be any value, but min and max can't.
    
    real L = exp(-λ);
    
    while( true )
    {
        real k = 0;
        real p = 1;
        
        do
        {
            k = k+1;
            p = p * uniformReal(true, true, 0, 1);
        }
        while( p >= L );
        
        if( !( (min == min && (k-1) < min)
                || (max == max && (k-1) > max) ) )
            return cast(real) cast(long) k-1;
    }
}

// Branching

Value fnIf(ErrDg err, size_t args, Value delegate(size_t) getArg)
{
    if( args != 3 )
        err("if: expected 3 arguments, got {}", args);

    auto arg0 = getArg(0);

    if( !arg0.isLogical )
        err("if: expected logical for argument 1, got {}", arg0.tagName);

    if( arg0.asLogical )
        return getArg(1);
    else
        return getArg(2);
}

// Math

alias fnUnaryReal!("abs", abs) fnAbs;

Value fnMin(ErrDg err, Value[] args)
{
    expMinArgs(err, "min", 2, args);
    expReal(err, "min", args);

    real r = args[0].asReal;
    foreach( arg ; args[1..$] )
        r = min(r, arg.asReal);

    return Value(r);
}

Value fnMax(ErrDg err, Value[] args)
{
    expMinArgs(err, "max", 2, args);
    expReal(err, "max", args);

    real r = args[0].asReal;
    foreach( arg ; args[1..$] )
        r = max(r, arg.asReal);

    return Value(r);
}

alias fnUnaryReal!("cos", cos) fnCos;
alias fnUnaryReal!("sin", sin) fnSin;
alias fnUnaryReal!("tan", tan) fnTan;

alias fnUnaryReal!("acos", acos) fnAcos;
alias fnUnaryReal!("asin", asin) fnAsin;
alias fnUnaryReal!("atan", atan) fnAtan;
alias fnBinaryReal!("atan2", atan2) fnAtan2;

alias fnUnaryReal!("cosh", cosh) fnCosh;
alias fnUnaryReal!("sinh", sinh) fnSinh;
alias fnUnaryReal!("tanh", tanh) fnTanh;

alias fnUnaryReal!("acosh", acosh) fnAcosh;
alias fnUnaryReal!("asinh", asinh) fnAsinh;
alias fnUnaryReal!("atanh", atanh) fnAtanh;

alias fnUnaryReal!("sqrt", sqrt) fnSqrt;
alias fnUnaryReal!("log", log) fnLog;
alias fnUnaryReal!("log2", log2) fnLog2;
alias fnUnaryReal!("log10", log10) fnLog10;

alias fnUnaryReal!("floor", floor) fnFloor;
alias fnUnaryReal!("ceil", ceil) fnCeil;
alias fnUnaryReal!("round", round_nonCrazy) fnRound;
alias fnUnaryReal!("trunc", trunc) fnTrunc;

Value fnClamp(ErrDg err, Value[] args)
{
    expNumArgs(err, "clamp", 3, args);
    expReal(err, "clamp", args);

    return Value(max(args[1].asReal, min(args[0].asReal, args[2].asReal)));
}

// ErrorFunction

alias fnUnaryReal!("erf", erf) fnErf;
alias fnUnaryReal!("erfc", erfc) fnErfc;

// Probability

alias fnBinaryReal!("normal", normal) fnNormal;

Value fnPoisson(ErrDg err, Value[] args)
{
    if( args.length != 1 && args.length != 3 )
        err("poisson: expected 1 or 3 args, got {}", args.length);

    expReal(err, "max", args);

    real λ, min, max;
    λ = args[0].asReal;
    if( args.length > 1 )
    {
        min = args[1].asReal;
        max = args[2].asReal;
    }

    return Value(poisson(λ, min, max));
}


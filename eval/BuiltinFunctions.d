/**
    Built-in Functions.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.BuiltinFunctions;

import eval.Statistical : rand, uniformReal;
import eval.Value;
import eval.Variables;

import tango.io.Stdout;
import tango.math.ErrorFunction;
import tango.math.Math;
import tango.math.Probability;

class BuiltinFunctions : Variables
{
    Variables next;

    this(Variables next = null)
    {
        this.next = next;
    }

    override bool resolve(char[] ident, out Value value)
    {
        if( auto fvptr = ident in fnMap )
        {
            value = Value(*fvptr);
            return true;
        }
        else
            return nextResolve(ident, value);
    }

    override bool define(char[] ident, ref Value value)
    {
        if( !!( ident in fnMap ) )
            return false;
        else
            return nextDefine(ident, value);
    }

    int iterate(int delegate(ref char[], ref Value) dg)
    {
        auto names = fnNames;

        int r = 0;
        foreach( nextName, nextValue ; &nextIterate )
        {
            char[] name;
            Value value;

            while( names.length > 0 && names[0] < nextName )
            {
                name = names[0];
                value = Value(fnMap[name]);
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
            auto tmpV = Value(fnMap[tmpN]);
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

alias Function.ErrDg ErrDg;
alias Function.ArgDg ArgDg;

alias Function.NativeFn Fn;
Function[char[]] fnMap;
char[][] fnNames;

Function mk(Fn fn, char[][] args...)
{
    auto f = new Function;
    f.nativeFn = fn;
    f.args.length = args.length;
    foreach( i, arg ; args )
        f.args[i].name = arg;
    return f;
}

static this()
{
    alias fnMap fm;

    fm["if"]      = mk(&fnIf, "l", "a", "b");

    fm["abs"]     = mk(&fnAbs, "x");
    fm["min"]     = mk(&fnMin, "x", "y", "...");
    fm["max"]     = mk(&fnMax, "x", "y", "...");
            
    fm["cos"]     = mk(&fnCos, "x");
    fm["sin"]     = mk(&fnSin, "x");
    fm["tan"]     = mk(&fnTan, "x");

    fm["acos"]    = mk(&fnAcos, "x");
    fm["asin"]    = mk(&fnAsin, "x");
    fm["atan"]    = mk(&fnAtan, "x");
    fm["atan2"]   = mk(&fnAtan2, "x");

    fm["cosh"]    = mk(&fnCosh, "x");
    fm["sinh"]    = mk(&fnSinh, "x");
    fm["tanh"]    = mk(&fnTanh, "x");

    fm["acosh"]   = mk(&fnAcosh, "x");
    fm["asinh"]   = mk(&fnAsinh, "x");
    fm["atanh"]   = mk(&fnAtanh, "x");

    fm["sqrt"]    = mk(&fnSqrt, "x");
    fm["log"]     = mk(&fnLog, "x");
    fm["log2"]    = mk(&fnLog2, "x");
    fm["log10"]   = mk(&fnLog10, "x");

    fm["floor"]   = mk(&fnFloor, "x");
    fm["ceil"]    = mk(&fnCeil, "x");
    fm["round"]   = mk(&fnRound, "x");
    fm["trunc"]   = mk(&fnTrunc, "x");
    fm["clamp"]   = mk(&fnClamp, "y", "x", "z");

    fm["erf"]     = mk(&fnErf, "x");
    fm["erfc"]    = mk(&fnErfc, "x");

    fm["normal"]  = mk(&fnNormal, "μ", "σ");
    fm["poisson"] = mk(&fnPoisson, "λ", "x", "y");

    fm["print"]   = mk(&fnPrint, "a", "...");
    fm["printLn"] = mk(&fnPrintLn, "a", "...");

    fm["concat"]  = mk(&fnConcat, "s1", "s2", "...");
    fm["join"]    = mk(&fnJoin, "s", "s1", "s2", "...");

    version( MathEval_Lists )
    {
        fm["cons"]  = mk(&fnCons, "a", "li");
        fm["head"]  = mk(&fnHead, "li");
        fm["tail"]  = mk(&fnTail, "li");
    }

    fm["type"]    = mk(&fnType, "a");
    fm["logical"] = mk(&fnLogical, "a");
    fm["real"]    = mk(&fnReal, "a");
    fm["string"]  = mk(&fnString, "a");

    fnNames = fm.keys;
    fnNames.sort;
}

void expReal(ErrDg err, char[] name, Value[] args, size_t offset=0)
{
    foreach( i, arg ; args )
        expReal(err, name, arg, offset+i);
}

void expReal(ErrDg err, char[] name, Value arg, size_t index)
{
    if( !arg.isReal )
        err("{}: expected real for argument {}, got {}",
                name, index+1, arg.tagName);
}

void expString(ErrDg err, char[] name, Value[] args, size_t offset=0)
{
    foreach( i, arg ; args )
        expString(err, name, arg, offset+i);
}

void expString(ErrDg err, char[] name, Value arg, size_t index)
{
    if( !arg.isString )
        err("{}: expected string for argument {}, got {}",
                name, index+1, arg.tagName);
}

void expList(ErrDg err, char[] name, Value[] args, size_t offset=0)
{
    foreach( i, arg ; args )
        expList(err, name, arg, offset+i);
}

void expList(ErrDg err, char[] name, Value arg, size_t index)
{
    if( !arg.isList )
        err("{}: expected list for argument {}, got {}",
                name, index+1, arg.tagName);
}

void numArgs(ErrDg err, char[] name, size_t exp, size_t args, bool exact=true)
{
    if( args < exp )
        err("{}: expected {}{}, got {}",
                name, exp, (exact ? "" : " or more"), args);
}

void unpackArgs(ErrDg err, char[] name, Value[] vs,
        size_t args, ArgDg getArg, bool exact=true)
{
    if( args < vs.length )
        err("{}: expected {}{} arguments, got {}",
                name, vs.length, (exact ? "" : " or more"), args);

    foreach( i, ref v ; vs )
        v = getArg(i);
}

Value fnUnaryReal(char[] name, alias fn)(ErrDg err, size_t args, ArgDg getArg)
{
    Value[1] vs;
    unpackArgs(err, name, vs, args, getArg);
    expReal(err, name, vs);

    return Value(fn(vs[0].asReal));
}

Value fnBinaryReal(char[] name, alias fn)(ErrDg err, size_t args, ArgDg getArg)
{
    Value[2] vs;
    unpackArgs(err, name, vs, args, getArg);
    expReal(err, name, vs);

    return Value(fn(vs[0].asReal, vs[1].asReal));
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

Value fnIf(ErrDg err, size_t args, ArgDg getArg)
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

Value fnMin(ErrDg err, size_t args, ArgDg getArg)
{
    numArgs(err, "min", 2, args, false);
    auto arg0 = getArg(0);
    expReal(err, "min", arg0, 0);

    real r = arg0.asReal;
    for( size_t i=1; i<args; ++i )
    {
        auto arg = getArg(i);
        expReal(err, "min", arg, i);
        r = min(r, arg.asReal);
    }
    return Value(r);
}

Value fnMax(ErrDg err, size_t args, ArgDg getArg)
{
    numArgs(err, "max", 2, args, false);
    auto arg0 = getArg(0);
    expReal(err, "max", arg0, 0);

    real r = arg0.asReal;
    for( size_t i=1; i<args; ++i )
    {
        auto arg = getArg(i);
        expReal(err, "max", arg, i);
        r = max(r, arg.asReal);
    }
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

Value fnClamp(ErrDg err, size_t args, ArgDg getArg)
{
    Value[3] vs;
    unpackArgs(err, "clamp", vs, args, getArg);
    expReal(err, "clamp", vs);

    return Value(max(vs[1].asReal, min(vs[0].asReal, vs[2].asReal)));
}

// ErrorFunction

alias fnUnaryReal!("erf", erf) fnErf;
alias fnUnaryReal!("erfc", erfc) fnErfc;

// Probability

alias fnBinaryReal!("normal", normal) fnNormal;

Value fnPoisson(ErrDg err, size_t args, ArgDg getArg)
{
    if( args != 1 && args != 3 )
        err("poisson: expected 1 or 3 args, got {}", args);

    real λ, min, max;

    if( args == 1 )
    {
        Value[1] vs;
        unpackArgs(err, "poisson", vs, args, getArg);
        expReal(err, "poisson", vs);
        λ = vs[0].asReal;
    }
    else if( args == 3 )
    {
        Value[3] vs;
        unpackArgs(err, "poisson", vs, args, getArg);
        expReal(err, "poisson", vs);
        λ = vs[0].asReal;
        min = vs[1].asReal;
        max = vs[2].asReal;
    }
    else
        err("poisson: expected 1 or 3 args, got {}", args);

    return Value(poisson(λ, min, max));
}

// String

Value fnConcat(ErrDg err, size_t args, ArgDg getArg)
{
    numArgs(err, "concat", 2, args, false);

    char[] s;

    for( size_t i=0; i<args; ++i )
    {
        auto arg = getArg(i);
        expString(err, "concat", arg, i);
        s ~= arg.asString;
    }

    return Value(s);
}

Value fnJoin(ErrDg err, size_t args, ArgDg getArg)
{
    numArgs(err, "join", 3, args, false);

    auto sepV = getArg(0); expString(err, "join", sepV, 0);
    auto sep = sepV.asString;
    auto part0V = getArg(1); expString(err, "join", sepV, 1);
    auto part0 = part0V.asString;

    auto s = part0;
    for( size_t i=2; i<args; ++i )
    {
        auto part = getArg(i);
        expString(err, "join", part, i);
        s ~= sep;
        s ~= part.asString;
    }

    return Value(s);
}

// Lists

version( MathEval_Lists )
{
    Value fnCons(ErrDg err, size_t args, ArgDg getArg)
    {
        numArgs(err, "cons", 2, args);
        Value[2] vs;
        unpackArgs(err, "cons", vs, args, getArg);
        expList(err, "cons", vs[1], 1);

        auto li = new Value.ListNode;
        li.v = new Value;
        *li.v = vs[0];
        li.n = vs[1].asList;

        return Value(li);
    }
    
    Value fnHead(ErrDg err, size_t args, ArgDg getArg)
    {
        numArgs(err, "head", 1, args);
        Value[1] vs;
        unpackArgs(err, "head", vs, args, getArg);
        expList(err, "head", vs[0], 0);

        return *vs[0].asList.v;
    }
    
    Value fnTail(ErrDg err, size_t args, ArgDg getArg)
    {
        numArgs(err, "head", 1, args);
        Value[1] vs;
        unpackArgs(err, "head", vs, args, getArg);
        expList(err, "head", vs[0], 0);

        return Value(vs[0].asList.n);
    }
}

// Output & Formatting

Value fnPrint(ErrDg err, size_t args, ArgDg getArg)
{
    numArgs(err, "print", 1, args, false);

    for( size_t i=0; i<args; ++i )
    {
        auto arg = getArg(i);
        if( arg.isString )
            Stdout(arg.asString);
        else if( arg.isNil )
            {} // do nothing
        else
            Stdout(arg.toString);
    }
    Stdout.flush;

    return Value();
}

Value fnPrintLn(ErrDg err, size_t args, ArgDg getArg)
{
    fnPrint(err, args, getArg);
    Stdout.newline;
    return Value();
}

// Meta

Value fnType(ErrDg err, size_t args, ArgDg getArg)
{
    Value[1] vs;
    unpackArgs(err, "type", vs, args, getArg);

    return Value(vs[0].tagName);
}

Value fnLogical(ErrDg err, size_t args, ArgDg getArg)
{
    Value[1] vs;
    unpackArgs(err, "logical", vs, args, getArg);

    auto arg = vs[0];
    switch( arg.tag )
    {
        case Value.Tag.Logical:
            return arg;

        case Value.Tag.Real:
            return Value( arg.asReal != 0.0 );

        case Value.Tag.String:
            switch( arg.asString )
            {
                case "true":    return Value(true);
                case "false":   return Value(false);
                default:        err("logical: invalid value {}", arg.toString);
            }

        default:
            err("logical: invalid value {}", arg.toString);
    }
}

Value fnReal(ErrDg err, size_t args, ArgDg getArg)
{
    Value[1] vs;
    unpackArgs(err, "real", vs, args, getArg);

    auto arg = vs[0];
    switch( arg.tag )
    {
        case Value.Tag.Logical:
            return Value(arg.asLogical ? 1.0 : 0.0);

        case Value.Tag.Real:
            return arg;

        case Value.Tag.String:
        {
            uint ate;
            auto v = Float.parse(arg.asString, &ate);
            if( ate == 0 )
                err("real: invalid {}", arg.toString);
            return Value(v);
        }
        default:
            err("logical: invalid value {}", arg.toString);
    }
}

Value fnString(ErrDg err, size_t args, ArgDg getArg)
{
    Value[1] vs;
    unpackArgs(err, "string", vs, args, getArg);

    auto arg = vs[0];
    switch( arg.tag )
    {
        case Value.Tag.Logical:
        case Value.Tag.Real:
    version( MathEval_Lists )
    {
        case Value.Tag.List:
    }
            return Value(arg.toString);

        case Value.Tag.String:
            return arg;

        default:
            err("logical: invalid value {}", arg.toString);
    }
}


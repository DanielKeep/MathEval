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

alias Function.Context Context;
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

    fm["if"]        = mk(&fnIf, "l", "a", "b");
    fm["do"]        = mk(&fnDo, "a", "...");

    fm["abs"]       = mk(&fnAbs, "x");
    fm["min"]       = mk(&fnMin, "x", "y", "...");
    fm["max"]       = mk(&fnMax, "x", "y", "...");
            
    fm["cos"]       = mk(&fnCos, "x");
    fm["sin"]       = mk(&fnSin, "x");
    fm["tan"]       = mk(&fnTan, "x");

    fm["acos"]      = mk(&fnAcos, "x");
    fm["asin"]      = mk(&fnAsin, "x");
    fm["atan"]      = mk(&fnAtan, "x");
    fm["atan2"]     = mk(&fnAtan2, "x");

    fm["cosh"]      = mk(&fnCosh, "x");
    fm["sinh"]      = mk(&fnSinh, "x");
    fm["tanh"]      = mk(&fnTanh, "x");

    fm["acosh"]     = mk(&fnAcosh, "x");
    fm["asinh"]     = mk(&fnAsinh, "x");
    fm["atanh"]     = mk(&fnAtanh, "x");

    fm["sqrt"]      = mk(&fnSqrt, "x");
    fm["log"]       = mk(&fnLog, "x");
    fm["log2"]      = mk(&fnLog2, "x");
    fm["log10"]     = mk(&fnLog10, "x");

    fm["floor"]     = mk(&fnFloor, "x");
    fm["ceil"]      = mk(&fnCeil, "x");
    fm["round"]     = mk(&fnRound, "x");
    fm["trunc"]     = mk(&fnTrunc, "x");
    fm["clamp"]     = mk(&fnClamp, "y", "x", "z");

    fm["erf"]       = mk(&fnErf, "x");
    fm["erfc"]      = mk(&fnErfc, "x");

    fm["normal"]    = mk(&fnNormal, "μ", "σ");
    fm["poisson"]   = mk(&fnPoisson, "λ", "x", "y");

    fm["print"]     = mk(&fnPrint, "a", "...");
    fm["printLn"]   = mk(&fnPrintLn, "a", "...");

    fm["concat"]    = mk(&fnConcat, "s1", "s2", "...");
    fm["join"]      = mk(&fnJoin, "s", "s1", "s2", "...");

    version( MathEval_Lists )
    {
        fm["cons"]  = mk(&fnCons, "a", "li");
        fm["head"]  = mk(&fnHead, "li");
        fm["tail"]  = mk(&fnTail, "li");
        fm["map"]   = mk(&fnMap_, "f", "li");
        fm["filter"]= mk(&fnFilter, "f", "li");
        fm["apply"] = mk(&fnApply, "f", "li");
        fm["seq"]   = mk(&fnSeq, "a", "b", "c");
    }

    fm["type"]      = mk(&fnType, "a");
    fm["logical"]   = mk(&fnLogical, "a");
    fm["real"]      = mk(&fnReal, "a");
    fm["string"]    = mk(&fnString, "a");

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

void expFunction(ErrDg err, char[] name, Value[] args, size_t offset=0)
{
    foreach( i, arg ; args )
        expFunction(err, name, arg, offset+i);
}

void expFunction(ErrDg err, char[] name, Value arg, size_t index)
{
    if( !arg.isFunction )
        err("{}: expected function for argument {}, got {}",
                name, index+1, arg.tagName);
}

version( MathEval_Lists )
{
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

Value fnUnaryReal(char[] name, alias fn)(ref Context ctx)
{
    Value[1] vs;
    unpackArgs(ctx.err, name, vs, ctx.args, ctx.getArg);
    expReal(ctx.err, name, vs);

    return Value(fn(vs[0].asReal));
}

Value fnBinaryReal(char[] name, alias fn)(ref Context ctx)
{
    Value[2] vs;
    unpackArgs(ctx.err, name, vs, ctx.args, ctx.getArg);
    expReal(ctx.err, name, vs);

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

Value fnIf(ref Context ctx)
{
    if( ctx.args != 3 )
        ctx.err("if: expected 3 arguments, got {}", ctx.args);

    auto arg0 = ctx.getArg(0);

    if( !arg0.isLogical )
        ctx.err("if: expected logical for argument 1, got {}", arg0.tagName);

    if( arg0.asLogical )
        return ctx.getArg(1);
    else
        return ctx.getArg(2);
}

Value fnDo(ref Context ctx)
{
    numArgs(ctx.err, "do", 1, ctx.args, false);
    Value lastVal;

    for( size_t i=0; i<ctx.args; ++i )
        lastVal = ctx.getArg(i);
    
    return lastVal;
}

// Math

alias fnUnaryReal!("abs", abs) fnAbs;

Value fnMin(ref Context ctx)
{
    numArgs(ctx.err, "min", 2, ctx.args, false);
    auto arg0 = ctx.getArg(0);
    expReal(ctx.err, "min", arg0, 0);

    real r = arg0.asReal;
    for( size_t i=1; i<ctx.args; ++i )
    {
        auto arg = ctx.getArg(i);
        expReal(ctx.err, "min", arg, i);
        r = min(r, arg.asReal);
    }
    return Value(r);
}

Value fnMax(ref Context ctx)
{
    numArgs(ctx.err, "max", 2, ctx.args, false);
    auto arg0 = ctx.getArg(0);
    expReal(ctx.err, "max", arg0, 0);

    real r = arg0.asReal;
    for( size_t i=1; i<ctx.args; ++i )
    {
        auto arg = ctx.getArg(i);
        expReal(ctx.err, "max", arg, i);
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

Value fnClamp(ref Context ctx)
{
    Value[3] vs;
    unpackArgs(ctx.err, "clamp", vs, ctx.args, ctx.getArg);
    expReal(ctx.err, "clamp", vs);

    return Value(max(vs[1].asReal, min(vs[0].asReal, vs[2].asReal)));
}

// ErrorFunction

alias fnUnaryReal!("erf", erf) fnErf;
alias fnUnaryReal!("erfc", erfc) fnErfc;

// Probability

alias fnBinaryReal!("normal", normal) fnNormal;

Value fnPoisson(ref Context ctx)
{
    if( ctx.args != 1 && ctx.args != 3 )
        ctx.err("poisson: expected 1 or 3 args, got {}", ctx.args);

    real λ, min, max;

    if( ctx.args == 1 )
    {
        Value[1] vs;
        unpackArgs(ctx.err, "poisson", vs, ctx.args, ctx.getArg);
        expReal(ctx.err, "poisson", vs);
        λ = vs[0].asReal;
    }
    else if( ctx.args == 3 )
    {
        Value[3] vs;
        unpackArgs(ctx.err, "poisson", vs, ctx.args, ctx.getArg);
        expReal(ctx.err, "poisson", vs);
        λ = vs[0].asReal;
        min = vs[1].asReal;
        max = vs[2].asReal;
    }
    else
        ctx.err("poisson: expected 1 or 3 args, got {}", ctx.args);

    return Value(poisson(λ, min, max));
}

// String

Value fnConcat(ref Context ctx)
{
    numArgs(ctx.err, "concat", 2, ctx.args, false);

    char[] s;

    for( size_t i=0; i<ctx.args; ++i )
    {
        auto arg = ctx.getArg(i);
        expString(ctx.err, "concat", arg, i);
        s ~= arg.asString;
    }

    return Value(s);
}

Value fnJoin(ref Context ctx)
{
    numArgs(ctx.err, "join", 3, ctx.args, false);

    auto sepV = ctx.getArg(0); expString(ctx.err, "join", sepV, 0);
    auto sep = sepV.asString;
    auto part0V = ctx.getArg(1); expString(ctx.err, "join", sepV, 1);
    auto part0 = part0V.asString;

    auto s = part0;
    for( size_t i=2; i<ctx.args; ++i )
    {
        auto part = ctx.getArg(i);
        expString(ctx.err, "join", part, i);
        s ~= sep;
        s ~= part.asString;
    }

    return Value(s);
}

// Lists

version( MathEval_Lists )
{
    Value fnCons(ref Context ctx)
    {
        numArgs(ctx.err, "cons", 2, ctx.args);
        Value[2] vs;
        unpackArgs(ctx.err, "cons", vs, ctx.args, ctx.getArg);
        expList(ctx.err, "cons", vs[1], 1);

        auto li = new Value.ListNode;
        li.v = new Value;
        *li.v = vs[0];
        li.n = vs[1].asList;

        return Value(li);
    }
    
    Value fnHead(ref Context ctx)
    {
        numArgs(ctx.err, "head", 1, ctx.args);
        Value[1] vs;
        unpackArgs(ctx.err, "head", vs, ctx.args, ctx.getArg);
        expList(ctx.err, "head", vs[0], 0);

        return *vs[0].asList.v;
    }
    
    Value fnTail(ref Context ctx)
    {
        numArgs(ctx.err, "head", 1, ctx.args);
        Value[1] vs;
        unpackArgs(ctx.err, "head", vs, ctx.args, ctx.getArg);
        expList(ctx.err, "head", vs[0], 0);

        return Value(vs[0].asList.n);
    }

    Value fnMap_(ref Context ctx)
    {
        numArgs(ctx.err, "map", 1, ctx.args);
        Value[2] vs;
        unpackArgs(ctx.err, "map", vs, ctx.args, ctx.getArg);
        expFunction(ctx.err, "map", vs[0], 0);
        expList(ctx.err, "map", vs[1], 1);

        auto fv = vs[0].asFunction;
        auto li = vs[1].asList;

        Value.ListNode* head, tail;

        while( li !is null )
        {
            if( head is null )
            {
                head = tail = new Value.ListNode;
            }
            else
            {
                tail.n = new Value.ListNode;
                tail = tail.n;
            }
            tail.v = new Value;
            Value[1] argVals;
            argVals[0] = *li.v;
            *tail.v = ctx.invoke(fv, argVals);
            li = li.n;
        }

        return Value(head);
    }

    Value fnFilter(ref Context ctx)
    {
        numArgs(ctx.err, "filter", 1, ctx.args);
        Value[2] vs;
        unpackArgs(ctx.err, "filter", vs, ctx.args, ctx.getArg);
        expFunction(ctx.err, "filter", vs[0], 0);
        expList(ctx.err, "filter", vs[1], 1);

        auto fv = vs[0].asFunction;
        auto li = vs[1].asList;

        Value.ListNode* head, tail;

        while( li !is null )
        {
            Value[1] argVals;
            argVals[0] = *li.v;
            auto fr = ctx.invoke(fv, argVals);
            if( !fr.isLogical )
                ctx.err("filter: expected logical result from filter, "
                        "got {}", fr.tagName);

            if( fr.asLogical )
            {
                if( head is null )
                {
                    head = tail = new Value.ListNode;
                }
                else
                {
                    tail.n = new Value.ListNode;
                    tail = tail.n;
                }
                tail.v = new Value;
                *tail.v = *li.v;
            }

            li = li.n;
        }

        return Value(head);
    }

    Value fnApply(ref Context ctx)
    {
        numArgs(ctx.err, "apply", 1, ctx.args);
        Value[2] vs;
        unpackArgs(ctx.err, "apply", vs, ctx.args, ctx.getArg);
        expFunction(ctx.err, "apply", vs[0], 0);
        expList(ctx.err, "apply", vs[1], 1);

        auto fv = vs[0].asFunction;
        auto li = vs[1].asList;

        Value[] argVals;

        while( li !is null )
        {
            argVals ~= *li.v;
            li = li.n;
        }

        return ctx.invoke(fv, argVals);
    }

    Value fnSeq(ref Context ctx)
    {
        if( !( 1 <= ctx.args && ctx.args <= 3 ) )
            ctx.err("seq: expected 1, 2 or 3 args; got {}", ctx.args);

        Value[3] vs;

        real a, b, step;

        if( ctx.args == 1 )
        {
            unpackArgs(ctx.err, "seq", vs[0..1], ctx.args, ctx.getArg);
            expReal(ctx.err, "seq", vs[0..1]);
            a = 1;
            b = vs[0].asReal;
            step = (b >= 0.0) ? 1 : -1;
        }
        else if( ctx.args == 2 )
        {
            unpackArgs(ctx.err, "seq", vs[0..2], ctx.args, ctx.getArg);
            expReal(ctx.err, "seq", vs[0..2]);
            a = vs[0].asReal;
            b = vs[1].asReal;
            step = (a <= b) ? 1 : -1;
        }
        else
        {
            assert( ctx.args == 3 );
            unpackArgs(ctx.err, "seq", vs[0..3], ctx.args, ctx.getArg);
            expReal(ctx.err, "seq", vs[0..3]);
            a = vs[0].asReal;
            b = vs[1].asReal;
            step = vs[2].asReal;
        }

        Value.ListNode* head, tail;

        void addValue(real x)
        {
            if( head is null )
            {
                head = tail = new Value.ListNode;
                head.v = new Value;
                *head.v = Value(x);
            }
            else
            {
                tail.n = new Value.ListNode;
                tail = tail.n;
                tail.v = new Value;
                *tail.v = Value(x);
            }
        }

        if( step == 0.0 )
            ctx.err("seq: cannot have step of zero");

        if( step > 0.0 )
            for( real v=a; v<=b; v+=step )
                addValue(v);
        else
            for( real v=a; v>=b; v+=step )
                addValue(v);

        return Value(head);
    }
}

// Output & Formatting

Value fnPrint(ref Context ctx)
{
    numArgs(ctx.err, "print", 1, ctx.args, false);

    for( size_t i=0; i<ctx.args; ++i )
    {
        auto arg = ctx.getArg(i);
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

Value fnPrintLn(ref Context ctx)
{
    fnPrint(ctx);
    Stdout.newline;
    return Value();
}

// Meta

Value fnType(ref Context ctx)
{
    Value[1] vs;
    unpackArgs(ctx.err, "type", vs, ctx.args, ctx.getArg);

    return Value(vs[0].tagName);
}

Value fnLogical(ref Context ctx)
{
    Value[1] vs;
    unpackArgs(ctx.err, "logical", vs, ctx.args, ctx.getArg);

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
                default:        ctx.err("logical: invalid value {}", arg.toString);
            }

        default:
            ctx.err("logical: invalid value {}", arg.toString);
    }
}

Value fnReal(ref Context ctx)
{
    Value[1] vs;
    unpackArgs(ctx.err, "real", vs, ctx.args, ctx.getArg);

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
                ctx.err("real: invalid {}", arg.toString);
            return Value(v);
        }
        default:
            ctx.err("logical: invalid value {}", arg.toString);
    }
}

Value fnString(ref Context ctx)
{
    Value[1] vs;
    unpackArgs(ctx.err, "string", vs, ctx.args, ctx.getArg);

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
            ctx.err("logical: invalid value {}", arg.toString);
    }
}


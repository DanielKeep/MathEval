/**
    Built-in Functions.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.BuiltinFunctions;

import eval.Ast : AstVariableExpr;
import eval.Statistical : rand, uniformReal;
import eval.Value;
import eval.Variables;

version( MathEval_Lists )
    import eval.Ast : AstListExpr;

import tango.io.Console : Cin, Cout;
import tango.io.Stdout;
import tango.math.ErrorFunction;
import tango.math.Math;
import tango.math.Probability;
import tango.util.Convert : to;

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
    version( MathEval_Lists )
    {
        fm["tramp"]     = mk(&fnTramp, "f", "li");
        fm["bind"]      = mk(&fnBind, "binding", "...", "a");
        fm["cond"]      = mk(&fnCond, "cond", "...");
        fm["case"]      = mk(&fnCase, "case", "a", "case", "...");
    }

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
    fm["printByte"] = mk(&fnPrintByte, "n");
    fm["readLn"]    = mk(&fnReadLn);
    fm["readByte"]  = mk(&fnReadByte);

    fm["concat"]    = mk(&fnConcat, "s1", "s2", "...");
    fm["join"]      = mk(&fnJoin, "a", "...");
    version( MathEval_Lists )
        fm["split"]     = mk(&fnSplit, "a", "s");

    fm["slice"]     = mk(&fnSlice, "s", "i", "j");
    fm["length"]    = mk(&fnLength, "s");

    version( MathEval_Lists )
    {
        fm["cons"]  = mk(&fnCons, "a", "li");
        fm["head"]  = mk(&fnHead, "li");
        fm["tail"]  = mk(&fnTail, "li");
        fm["nth"]   = mk(&fnNth, "n", "li");
        fm["map"]   = mk(&fnMap_, "f", "li");
        fm["filter"]= mk(&fnFilter, "f", "li");
        fm["reduce"]= mk(&fnReduce, "f", "li");
        fm["apply"] = mk(&fnApply, "f", "li");
        fm["seq"]   = mk(&fnSeq, "a", "b", "c");
    }

    version( MathEval_Units )
    {
        fm["stripUnits"]    = mk(&fnStripUnits, "q");
        fm["unitsOf"]       = mk(&fnUnitsOf, "q");
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

version( MathEval_Units )
{
    void expQuantity(ErrDg err, char[] name, Value[] args, size_t offset=0)
    {
        foreach( i, arg ; args )
            expQuantity(err, name, arg, offset+i);
    }

    void expQuantity(ErrDg err, char[] name, Value arg, size_t index)
    {
        if( !arg.isQuantity )
            err("{}: expected quantity for argument {}, got {}",
                    name, index+1, arg.tagName);
    }
}

void numArgs(ErrDg err, char[] name, size_t exp, size_t args, bool exact=true)
{
    if( args < exp )
        err("{}: expected {}{} arguments, got {}",
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

version( MathEval_Lists )
{
    Value fnTramp(ref Context ctx)
    {
        numArgs(ctx.err, "tramp", 2, ctx.args);
        Value[2] vs;
        unpackArgs(ctx.err, "tramp", vs, ctx.args, ctx.getArg);

        auto fv = vs[0];
        auto liv = vs[1];

        while( ! fv.isNil )
        {
            expFunction(ctx.err, "tramp", fv, 0);
            expList(ctx.err, "tramp", liv, 1);

            auto rliv = ctx.invoke(fv.asFunction, liv.asList.toValues);
            if( !rliv.isList )
                ctx.err("tramp: expected list result, got {}", rliv.tagName);

            auto rli = rliv.asList;

            if( rli.length != 2 )
                ctx.err("tramp: expected list of two elements, got {}",
                        rli.length);

            fv = rli.head.v;
            liv = rli.head.n.v;
        }

        return liv;
    }

    Value fnBind(ref Context ctx)
    {
        numArgs(ctx.err, "bind", 2, ctx.args, false);

        Value[char[]] locals;

        for( size_t i=0; i<ctx.args-1; ++i )
        {
            auto ast = cast(AstListExpr) ctx.getAst(i);
            if( ast is null || ast.elements.length != 2 )
                ctx.err("bind: expected list literal with two elements "
                        "for argument {}", i+1);
            auto var = cast(AstVariableExpr) ast.elements[0];
            if( var is null )
                ctx.err("bind: expected variable name in argument {}", i+1);

            locals[var.ident] = ctx.evalAst(ast.elements[1], null);
        }

        return ctx.evalAst(ctx.getAst(ctx.args-1), locals);
    }

    Value fnCond(ref Context ctx)
    {
        numArgs(ctx.err, "cond", 1, ctx.args, false);

        for( size_t i=0; i<ctx.args; ++i )
        {
            auto ast = cast(AstListExpr) ctx.getAst(i);
            if( ast is null || ast.elements.length != 2 )
                ctx.err("cond: expected list literal with two elements "
                        "for argument {}", i+1);

            auto test = ast.elements[0];
            auto value = ast.elements[1];
            auto valueKw = cast(AstVariableExpr) test;

            if( i==ctx.args-1 && valueKw !is null && valueKw.ident == "else" )
                return ctx.evalAst(value, null);

            auto testR = ctx.evalAst(test, null);
            if( ! testR.isLogical )
                ctx.err("cond: expected logical result for condition of "
                        "argument {}, got {}", i+1, testR.tagName);

            if( testR.asLogical )
                return ctx.evalAst(value, null);
        }

        return Value();
    }

    Value fnCase(ref Context ctx)
    {
        numArgs(ctx.err, "case", 3, ctx.args, false);

        auto match = ctx.getArg(0);

        for( size_t i=1; i<ctx.args; ++i )
        {
            auto ast = cast(AstListExpr) ctx.getAst(i);
            if( ast is null || ast.elements.length != 2 )
                ctx.err("case: expected list literal with two elements "
                        "for argument {}", i+1);

            auto test = ast.elements[0];
            auto value = ast.elements[1];
            auto elseKw = cast(AstVariableExpr) test;

            if( i==ctx.args-1 && elseKw !is null && elseKw.ident == "else" )
                return ctx.evalAst(value, null);

            auto testV = ctx.evalAst(test, null);

            if( match == testV )
                return ctx.evalAst(value, null);
        }

        return Value();
    }
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

// Sequence

Value fnConcat(ref Context ctx)
{
    numArgs(ctx.err, "concat", 2, ctx.args, false);
    auto vs = new Value[](ctx.args);
    unpackArgs(ctx.err, "concat", vs, ctx.args, ctx.getArg);

    if( vs[0].isString )
    {
        expString(ctx.err, "concat", vs[1..$], 1);

        size_t len = 0;

        foreach( arg ; vs )
            len += arg.asString.length;

        auto r = new char[](len);
        size_t offset = 0;

        foreach( arg ; vs )
        {
            auto s = arg.asString;
            r[offset..offset+s.length] = s;
            offset += s.length;
        }

        return Value(r);
    }
    
version( MathEval_Lists )
    if( vs[0].isList )
    {
        expList(ctx.err, "concat", vs[1..$], 1);

        List.Node* head, tail;

        foreach( arg ; vs )
        {
            auto li = arg.asList.head;

            while( li !is null )
            {
                if( head is null )
                {
                    head = tail = new List.Node;
                }
                else
                {
                    tail.n = new List.Node;
                    tail = tail.n;
                }
                tail.v = li.v;

                li = li.n;
            }
        }

        return Value(head);
    }

    ctx.err("concat: cannot concatenate {}", vs[0].tagName);
}

Value fnJoin(ref Context ctx)
{
    numArgs(ctx.err, "join", 1, ctx.args, false);
    auto vs = new Value[](ctx.args);
    unpackArgs(ctx.err, "join", vs, ctx.args, ctx.getArg);

    if( vs[0].isString )
    {
        expString(ctx.err, "join", vs[1..$], 1);

        auto sep = vs[0].asString;

        size_t len = sep.length * vs[1..$].length-1;
        foreach( arg ; vs[1..$] )
            len += arg.asString.length;

        if( len == 0 )
            return Value("");

        auto r = new char[](len);
        size_t offset = 0;

        foreach( i, arg ; vs[1..$] )
        {
            auto s = arg.asString;
            if( i > 0 && sep.length > 0 )
            {
                r[offset..offset+sep.length] = sep;
                offset += sep.length;
            }
            r[offset..offset+s.length] = s;
            offset += s.length;
        }

        return Value(r);
    }

version( MathEval_Lists )
    if( vs[0].isList )
    {
        expList(ctx.err, "join", vs[1..$], 1);

        auto sep = vs[0].asList;

        List.Node* head, tail;

        foreach( i, arg ; vs[1..$] )
        {
            if( i > 0 )
            {
                auto li = sep.head;
                while( li !is null )
                {
                    if( head is null )
                        head = tail = new List.Node;
                    else
                    {
                        tail.n = new List.Node;
                        tail = tail.n;
                    }
                    tail.v = li.v;
                    li = li.n;
                }
            }

            auto li = arg.asList.head;

            while( li !is null )
            {
                if( head is null )
                    head = tail = new List.Node;
                else
                {
                    tail.n = new List.Node;
                    tail = tail.n;
                }
                tail.v = li.v;
                li = li.n;
            }
        }

        return Value(head);
    }

    ctx.err("join: cannot join {}", vs[0].tagName);
}

version( MathEval_Lists )
    Value fnSplit(ref Context ctx)
    {
        numArgs(ctx.err, "split", 2, ctx.args, false);
        auto vs = new Value[](ctx.args);
        unpackArgs(ctx.err, "split", vs, ctx.args, ctx.getArg);

        if( vs[1].isString )
        {
            if( vs[0].isString )
            {
                auto s = vs[1].asString;
                auto sep = vs[0].asString;
                size_t off = 0;

                while( s.length > sep.length )
                {
                    if( s[0..sep.length] == sep )
                        return Value(List(
                            Value(vs[1].asString[0..off]),
                            Value(s[sep.length..$])));
                    ++ off;
                    s = s[1..$];
                }
                return Value(List(vs[1], Value()));
            }
            else if( vs[0].isFunction )
            {
                auto s = vs[1].asString;
                auto sep = vs[0].asFunction;
                size_t off = 0;

                while( s.length > 0 )
                {
                    Value[1] argVs;
                    argVs[0] = Value(s);
                    auto lV = ctx.invoke(sep, argVs);
                    if( !lV.isLogical )
                        ctx.err("split: expected logical result from "
                                "split function, got {}", lV.tagName);
                    auto l = lV.asLogical;
                    if( l )
                        return Value(List(
                            Value(vs[1].asString[0..off]),
                            Value(s)));
                    ++ off;
                    s = s[1..$];
                }
                return Value(List(vs[1], Value()));
            }
            else
                ctx.err("split: expected string or function for argument 0, "
                        "got {}", vs[0].tagName);
        }

        if( vs[1].isList )
        {
            if( vs[0].isList )
            {
                auto li = vs[1].asList.head;
                auto sep = vs[0].asList;

                while( li !is null )
                {
                    if( List(li).startsWith(sep) )
                    {
                        auto head = vs[1].asList.split(li, sep.length);
                        return Value(List(Value(head), Value(li)));
                    }
                    li = li.n;
                }

                return Value(List(vs[1], Value()));
            }
            else if( vs[0].isFunction )
            {
                auto li = vs[1].asList;
                auto sep = vs[0].asFunction;

                foreach( n ; li )
                {
                    Value[1] argVs;
                    argVs[0] = Value(n);
                    auto lV = ctx.invoke(sep, argVs);
                    if( !lV.isLogical )
                        ctx.err("split: expected logical result from "
                                "split function, got {}", lV.tagName);
                    auto l = lV.asLogical;
                    if( l )
                        return Value(List(
                            Value(li.split(n,0)),
                            Value(n)));
                }

                return Value(List(vs[1], Value()));
            }
            else
                ctx.err("split: expected list or function for argument 0, "
                        "got {}", vs[0].tagName);
        }

        ctx.err("split: cannot split {}", vs[1].tagName);
    }

// Strings

Value fnLength(ref Context ctx)
{
    numArgs(ctx.err, "length", 1, ctx.args);
    Value[1] vs;
    unpackArgs(ctx.err, "length", vs, ctx.args, ctx.getArg);
    expString(ctx.err, "length", vs[0], 0);

    return Value(to!(real)(vs[0].asString.length));
}

Value fnSlice(ref Context ctx)
{
    numArgs(ctx.err, "slice", 3, ctx.args);
    Value[3] vs;
    unpackArgs(ctx.err, "slice", vs, ctx.args, ctx.getArg);
    expString(ctx.err, "slice", vs[0], 0);
    expReal(ctx.err, "slice", vs[1..$], 1);

    auto s = vs[0].asString;
    size_t i = vs[1].asIndex,
           j = vs[2].asIndex;

    return Value(s[i..j]);
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

        auto li = new List.Node;
        li.v = vs[0];
        li.n = vs[1].asList.head;

        return Value(li);
    }
    
    Value fnHead(ref Context ctx)
    {
        numArgs(ctx.err, "head", 1, ctx.args);
        Value[1] vs;
        unpackArgs(ctx.err, "head", vs, ctx.args, ctx.getArg);
        expList(ctx.err, "head", vs[0], 0);

        return vs[0].asList.head.v;
    }
    
    Value fnTail(ref Context ctx)
    {
        numArgs(ctx.err, "head", 1, ctx.args);
        Value[1] vs;
        unpackArgs(ctx.err, "head", vs, ctx.args, ctx.getArg);
        expList(ctx.err, "head", vs[0], 0);

        return Value(vs[0].asList.head.n);
    }

    Value fnNth(ref Context ctx)
    {
        numArgs(ctx.err, "nth", 2, ctx.args);
        Value[2] vs;
        unpackArgs(ctx.err, "nth", vs, ctx.args, ctx.getArg);
        expReal(ctx.err, "nth", vs[0], 0);
        expList(ctx.err, "nth", vs[1], 1);

        auto n = vs[0].asReal;
        auto li = vs[1].asList.head;

        while( li !is null )
        {
            if( n <= 0.0 )
                return li.v;

            n -= 1.0;
            li = li.n;
        }

        ctx.err("nth: index out of bounds");
        assert(false);
    }

    Value fnMap_(ref Context ctx)
    {
        numArgs(ctx.err, "map", 1, ctx.args);
        Value[2] vs;
        unpackArgs(ctx.err, "map", vs, ctx.args, ctx.getArg);
        expFunction(ctx.err, "map", vs[0], 0);
        expList(ctx.err, "map", vs[1], 1);

        auto fv = vs[0].asFunction;
        auto li = vs[1].asList.head;

        List.Node* head, tail;

        while( li !is null )
        {
            if( head is null )
            {
                head = tail = new List.Node;
            }
            else
            {
                tail.n = new List.Node;
                tail = tail.n;
            }
            Value[1] argVals;
            argVals[0] = li.v;
            tail.v = ctx.invoke(fv, argVals);
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
        auto li = vs[1].asList.head;

        List.Node* head, tail;

        while( li !is null )
        {
            Value[1] argVals;
            argVals[0] = li.v;
            auto fr = ctx.invoke(fv, argVals);
            if( !fr.isLogical )
                ctx.err("filter: expected logical result from filter, "
                        "got {}", fr.tagName);

            if( fr.asLogical )
            {
                if( head is null )
                {
                    head = tail = new List.Node;
                }
                else
                {
                    tail.n = new List.Node;
                    tail = tail.n;
                }
                tail.v = li.v;
            }

            li = li.n;
        }

        return Value(head);
    }

    Value fnReduce(ref Context ctx)
    {
        numArgs(ctx.err, "filter", 2, ctx.args);
        Value[2] vs;
        unpackArgs(ctx.err, "filter", vs, ctx.args, ctx.getArg);
        expFunction(ctx.err, "filter", vs[0], 0);
        expList(ctx.err, "filter", vs[1], 1);

        auto fv = vs[0].asFunction;
        auto li = vs[1].asList;
        
        if( li.head is null )
            return Value();
        
        Value[2] argVs;
        argVs[0] = li.head.v;
        foreach( n ; List(li.head.n) )
        {
            argVs[1] = n.v;
            argVs[0] = ctx.invoke(fv, argVs);
        }
        return argVs[0];
    }

    Value fnApply(ref Context ctx)
    {
        numArgs(ctx.err, "apply", 1, ctx.args);
        Value[2] vs;
        unpackArgs(ctx.err, "apply", vs, ctx.args, ctx.getArg);
        expFunction(ctx.err, "apply", vs[0], 0);
        expList(ctx.err, "apply", vs[1], 1);

        auto fv = vs[0].asFunction;
        auto li = vs[1].asList.head;

        Value[] argVals;

        while( li !is null )
        {
            argVals ~= li.v;
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

        List.Node* head, tail;

        void addValue(real x)
        {
            if( head is null )
            {
                head = tail = new List.Node;
                head.v = Value(x);
            }
            else
            {
                tail.n = new List.Node;
                tail = tail.n;
                tail.v = Value(x);
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

version( MathEval_Units )
{
    Value fnStripUnits(ref Context ctx)
    {
        Value[1] vs;
        unpackArgs(ctx.err, "stripUnits", vs, ctx.args, ctx.getArg);
        expQuantity(ctx.err, "stripUnits", vs);

        return Value(vs[0].asQuantity.mag);
    }

    Value fnUnitsOf(ref Context ctx)
    {
        Value[1] vs;
        unpackArgs(ctx.err, "unitsOf", vs, ctx.args, ctx.getArg);
        expQuantity(ctx.err, "unitsOf", vs);

        auto q = vs[0].asQuantity;
        q.mag = 1.0;
        return Value(q);
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

Value fnPrintByte(ref Context ctx)
{
    numArgs(ctx.err, "printByte", 1, ctx.args);
    Value[1] vs;
    unpackArgs(ctx.err, "printByte", vs, ctx.args, ctx.getArg);
    expReal(ctx.err, "printByte", vs);

    Stdout(cast(char)(to!(ubyte)(vs[0].asReal)));
    return Value();
}

Value fnReadLn(ref Context ctx)
{
    numArgs(ctx.err, "readLn", 0, ctx.args);
    char[] line;
    if( ! Cin.readln(line) )
        return Value();

    return Value(line.dup);
}

Value fnReadByte(ref Context ctx)
{
    numArgs(ctx.err, "readByte", 0, ctx.args);
    ubyte[1] inp;
    //Cin.stream.flush;
    auto read = Cin.stream.read(inp[]);
    if( read == ~0 )
        return Value();
    else
        return Value(inp[0]);
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
            if( ate == 0 || ate < arg.asString.length )
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


/**
    Runtime Value.

    This is for storing actual values at evaluation time.  The reason I'm not
    using Variant is because Variant switches to reference semantics for
    values larger than an array and I might want to support complex numbers in
    the future.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.Value;

import eval.Ast;
import eval.Util : toStringLiteral;

import tango.util.Convert : to;
import Float = tango.text.convert.Float;

// Just a guess
private enum : uint { FloatDP = 30 }

struct Value
{
    enum Tag
    {
        Nil,
        Logical,
        Real,
        String,
        Function,
    }

    union Data
    {
        bool l;
        real r;
        char[] s;
        FunctionValue f;
    }

    Tag tag;
    Data data;

    static Value opCall()
    {
        return Value.init;
    }

    static Value opCall(bool v)
    {
        Value r;
        r.tag = Tag.Logical;
        r.data.l = v;
        return r;
    }

    static Value opCall(real v)
    {
        Value r;
        r.tag = Tag.Real;
        r.data.r = v;
        return r;
    }

    static Value opCall(char[] v)
    {
        Value r;
        r.tag = Tag.String;
        r.data.s = v;
        return r;
    }

    static Value opCall(FunctionValue v)
    {
        Value r;
        r.tag = Tag.Function;
        r.data.f = v;
        return r;
    }

    bool isNil()
    {
        return tag == Tag.Nil;
    }

    bool isLogical()
    {
        return tag == Tag.Logical;
    }

    bool isReal()
    {
        return tag == Tag.Real;
    }

    bool isString()
    {
        return tag == Tag.String;
    }

    bool isFunction()
    {
        return tag == Tag.Function;
    }

    bool asLogical()
    {
        assert( tag == Tag.Logical );
        return data.l;
    }

    real asReal()
    {
        assert( tag == Tag.Real );
        return data.r;
    }

    char[] asString()
    {
        assert( tag == Tag.String );
        return data.s;
    }

    FunctionValue asFunction()
    {
        assert( tag == Tag.Function );
        return data.f;
    }

    char[] tagName()
    {
        switch( tag )
        {
            case Tag.Nil:       return "nil";
            case Tag.Logical:   return "logical";
            case Tag.Real:      return "real";
            case Tag.String:    return "string";
            case Tag.Function:  return "function";
            default:            return "unknown("~to!(char[])(tag)~")";
        }
    }

    char[] toString()
    {
        switch( tag )
        {
            case Tag.Nil:       return "nil";
            case Tag.Logical:   return data.l ? "true" : "false";
            case Tag.Real:      return Float.truncate(
                                        Float.toString(data.r, FloatDP));
            case Tag.String:    return toStringLiteral(data.s);
            case Tag.Function:  return asFunction.toString;
            default:            return "<<unknown("~to!(char[])(tag)~")>>";
        }
    }
}

class FunctionValue
{
    struct Arg
    {
        char[] name;
    }

    alias void delegate(char[], ...) ErrDg;
    alias Value delegate(size_t) ArgDg;
    alias Value function(ErrDg, size_t, ArgDg) NativeFn;

    Arg[] args;
    AstExpr expr;
    NativeFn nativeFn;
    Value[char[]] upvalues;

    char[] toString()
    {
        // TODO
        return "function";
    }
}


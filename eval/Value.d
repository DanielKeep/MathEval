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
    }

    union Data
    {
        bool l;
        real r;
        char[] s;
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

    char[] tagName()
    {
        switch( tag )
        {
            case Tag.Nil:       return "nil";
            case Tag.Logical:   return "logical";
            case Tag.Real:      return "real";
            case Tag.String:    return "string";
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
            default:            return "<<unknown("~to!(char[])(tag)~")>>";
        }
    }
}


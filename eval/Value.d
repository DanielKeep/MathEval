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

import tango.util.Convert : to;
import Float = tango.text.convert.Float;

// Just a guess
private enum : uint { FloatDP = 30 }

struct Value
{
    enum Tag
    {
        Invalid,
        Logical,
        Real,
    }

    union Data
    {
        bool l;
        real r;
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

    bool isInvalid()
    {
        return tag == Tag.Invalid;
    }

    bool isLogical()
    {
        return tag == Tag.Logical;
    }

    bool isReal()
    {
        return tag == Tag.Real;
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

    char[] tagName()
    {
        switch( tag )
        {
            case Tag.Invalid:   return "invalid";
            case Tag.Logical:   return "logical";
            case Tag.Real:      return "real";
            default:            return "unknown("~to!(char[])(tag)~")";
        }
    }

    char[] toString()
    {
        switch( tag )
        {
            case Tag.Invalid:   return "<<invalid>>";
            case Tag.Logical:   return data.l ? "true" : "false";
            case Tag.Real:      return Float.truncate(
                                        Float.toString(data.r, FloatDP));
            default:            return "<<unknown("~to!(char[])(tag)~")>>";
        }
    }
}


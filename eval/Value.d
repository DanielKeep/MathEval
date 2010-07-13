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

version( MathEval_Units )
    import eval.Units : Quantity;

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
        List,
        Quantity,
    }

    union Data
    {
        bool l;
        real r;
        char[] s;
        Function f;

        version( MathEval_Lists )
            List li;

        version( MathEval_Units )
            Quantity q;
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

    static Value opCall(Function v)
    {
        Value r;
        r.tag = Tag.Function;
        r.data.f = v;
        return r;
    }

    version( MathEval_Lists )
    {
        static Value opCall(List v)
        {
            Value r;
            r.tag = Tag.List;
            r.data.li = v;
            return r;
        }

        static Value opCall(List.Node* v)
        {
            Value r;
            r.tag = Tag.List;
            r.data.li.head = v;
            return r;
        }
    }

    version( MathEval_Units )
    {
        static Value opCall(Quantity v)
        {
            Value r;
            r.tag = Tag.Quantity;
            r.data.q = v;
            return r;
        }
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

    version( MathEval_Lists )
        bool isList()
        {
            return tag == Tag.List;
        }

    version( MathEval_Units )
        bool isQuantity()
        {
            return tag == Tag.Quantity;
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

    size_t asIndex()
    {
        assert( tag == Tag.Real );
        return to!(size_t)(data.r);
    }

    char[] asString()
    {
        assert( tag == Tag.String );
        return data.s;
    }

    Function asFunction()
    {
        assert( tag == Tag.Function );
        return data.f;
    }

    version( MathEval_Lists )
        List asList()
        {
            assert( tag == Tag.List );
            return data.li;
        }

    version( MathEval_Units )
        Quantity asQuantity()
        {
            assert( tag == Tag.Quantity );
            return data.q;
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
            case Tag.List:      return "list";
            case Tag.Quantity:  return "quantity";
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

        version( MathEval_Lists )
        {
            case Tag.List:
            {
                char[] s;
                auto n = asList.head;
                while( n !is null )
                {
                    if( s != "" )
                        s ~= ", ";
                    s ~= n.v.toString;
                    n = n.n;
                }
                return "["~s~"]";
            }
        }

        version( MathEval_Units )
        {
            case Tag.Quantity:
            {
                return asQuantity.toString;
            }
        }

            default:            return "<<unknown("~to!(char[])(tag)~")>>";
        }
    }

    bool opEquals(ref Value rhs)
    {
        auto lhs = this;

        if( lhs.tag != rhs.tag ) return false;

        switch( tag )
        {
            case Tag.Nil:       return true;
            case Tag.Logical:   return lhs.data.l == rhs.data.l;
            case Tag.Real:      return lhs.data.r == rhs.data.r;
            case Tag.String:    return lhs.data.s == rhs.data.s;
            case Tag.Function:  return lhs.data.f is rhs.data.f;
        version( MathEval_Lists )
        {
            case Tag.List:      return lhs.data.li == rhs.data.li;
        }
        version( MathEval_Units )
        {
            case Tag.Quantity:  return lhs.data.q == rhs.data.q;
        }
            default:            assert(false);
        }
    }
}

class Function
{
    alias void delegate(char[], ...) ErrDg;
    alias Value delegate(size_t) ArgDg;
    alias AstExpr delegate(size_t) AstDg;
    alias Value delegate(AstExpr, Value[char[]]) EvalAstDg;
    alias Value delegate(Function, Value[]) InvokeDg;
    alias Value function(ref Context) NativeFn;

    struct Context
    {
        ErrDg err;
        size_t args;
        ArgDg getArg;
        InvokeDg invoke;
        AstDg getAst;
        EvalAstDg evalAst;
    }

    struct Arg
    {
        char[] name;
    }

    Arg[] args;
    AstExpr expr;
    NativeFn nativeFn;
    Value[char[]] upvalues;
    Function nextFn;

    bool opEquals(Function rhs)
    {
        auto lhs = this;
        return (lhs == rhs) ? 1 : 0;
    }

    Function dup()
    {
        auto r = new Function;
        r.args = args;
        r.expr = expr;
        r.nativeFn = nativeFn;
        r.nextFn = nextFn;
        return r;
    }

    char[] toString()
    {
        // TODO
        return "function";
    }
}

version( MathEval_Lists )
{
    struct List
    {
        struct Node
        {
            Value v;
            Node* n;
        }

        Node* head;

        static List opCall(Node* head)
        {
            List r;
            r.head = head;
            return r;
        }

        static List opCall(Value[] vs...)
        {
            Node* head, tail;

            foreach( v ; vs )
            {
                if( head is null )
                    head = tail = new Node;
                else
                {
                    tail.n = new Node;
                    tail = tail.n;
                }
                tail.v = v;
            }

            List r;
            r.head = head;
            return r;
        }

        Value[] toValues()
        {
            Value[] vs;

            foreach( n ; *this )
                vs ~= n.v;
            
            return vs;
        }

        bool opEquals(List rhs)
        {
            auto lhs = this;

            auto lhsN = lhs.head;
            auto rhsN = rhs.head;

            while( lhsN !is null && rhsN !is null )
            {
                if( lhsN.v != rhsN.v )
                    return false;

                lhsN = lhsN.n;
                rhsN = rhsN.n;
            }

            return (lhsN is null && rhsN is null);
        }

        bool startsWith(List test)
        {
            auto lhsN = this.head;
            auto rhsN = test.head;

            while( lhsN !is null && rhsN !is null )
            {
                if( lhsN.v != rhsN.v )
                    return false;

                lhsN = lhsN.n;
                rhsN = rhsN.n;
            }

            return (rhsN is null);
        }

        size_t length()
        {
            auto n = this.head;
            size_t len = 0;
            while( n !is null )
            {
                ++ len;
                n = n.n;
            }
            return len;
        }

        List split(ref Node* splitN, size_t drop)
        {
            Appender newHead;
            foreach( n ; *this )
            {
                if( n is splitN )
                {
                    // Let's DO dis
                    while( drop > 0 )
                    {
                        splitN = splitN.n;
                        -- drop;
                    }
                    return newHead.toList;
                }
                newHead ~= n.v;
            }
            assert(false);
        }

        int opApply(int delegate(ref Node*) dg)
        {
            int r = 0;
            auto n = head;
            while( n !is null )
            {
                r = dg(n);
                if( r ) break;
                n = n.n;
            }
            return r;
        }

        struct Appender
        {
            Node* head, tail;

            List toList()
            {
                return List(head);
            }

            void opCatAssign(Node* n)
            {
                if( head is null )
                    head = tail = n;
                else
                {
                    tail.n = n;
                    tail = n;
                }
            }

            void opCatAssign(Value v)
            {
                auto n = new Node;
                n.v = v;
                (*this) ~= n;
            }
        }
    }
}


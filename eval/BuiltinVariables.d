/**
    Built-in Variables.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.BuiltinVariables;

import eval.Value;
import eval.Variables;

class BuiltinVariables : Variables
{
    Variables next;

    this(Variables next = null)
    {
        this.next = next;
    }

    bool resolve(char[] ident, out Value value)
    {
        if( auto vptr = ident in varMap )
        {
            value = *vptr;
            return true;
        }
        else
            return nextResolve(ident, value);
    }

    bool define(char[] ident, ref Value value)
    {
        if( !!( ident in varMap ) )
            return false;
        else
            return nextDefine(ident, value);
    }

    int iterate(int delegate(ref char[], ref Value) dg)
    {
        auto names = varNames;

        int r = 0;
        foreach( nextName, nextValue ; &nextIterate )
        {
            char[] name;
            Value value;

            while( names.length > 0 && names[0] < nextName )
            {
                name = names[0];
                value = varMap[name];
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
            auto tmpV = varMap[tmpN];
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

Value[char[]] varMap;
char[][] varNames;

version( MathEval_Units )
{
    import eval.Units;

    alias Dimension D;
    alias DerivedDimension DD;
    alias DerivedFrequency DF;

    Value q(D d, byte e = 1)
    {
        byte[D.Max+1] dims;
        dims[d] = e;
        return Value(Quantity(1.0, Dimensions(dims)));
    }

    Value qc(byte[] dims...)
    {
        byte[D.Max+1] dims2;
        dims2[0..dims.length] = dims;
        return Value(Quantity(1.0, Dimensions(dims2)));
    }

    Value qd(D d, DD dd, byte e = 1, byte de = 1)
    {
        byte[D.Max+1] dims;
        byte[DD.Max+1] ders;
        dims[d] = e;
        ders[dd] = de;
        return Value(Quantity(1.0, Dimensions(dims, ders)));
    }

    Value qdf(DF df, byte fe = 1)
    {
        byte[D.Max+1] dims;
        byte[DD.Max+1] ders;
        dims[D.Time] = -fe;
        ders[DD.Frequency] = fe;
        return Value(Quantity(1.0, Dimensions(dims, ders, df)));
    }
}

static this()
{
    alias varMap vm;

    vm["e"]     = Value(2.718_281_828_459_045_235L);
    vm["pi"]    = Value(3.141_592_653_589_793_238L);
    vm["π"]     = Value(3.141_592_653_589_793_238L);
    vm["phi"]   = Value(1.618_033_988_749_894_848L);
    vm["φ"]     = Value(1.618_033_988_749_894_848L);
    vm["inf"]   = Value(real.infinity);
    vm["nan"]   = Value(real.nan);
    vm["nil"]   = Value();
    vm["true"]  = Value(true);
    vm["false"] = Value(false);

    version( MathEval_Units )
    {
        vm["m"]     = q(D.Length);
        vm["g"]     = q(D.Mass);
        vm["s"]     = q(D.Time);
        vm["A"]     = q(D.Current);
        vm["K"]     = q(D.Temperature);
        vm["cd"]    = q(D.Luminance);
        vm["mol"]   = q(D.Substance);
        vm["rad"]   = q(D.Angle);
        vm["sr"]    = q(D.SolidAngle);
        vm["b"]     = q(D.Storage);

        //vm["C"]     = qd(D.Temperature, DD.Temperature);
        vm["Hz"]    = qdf(DF.Hertz);
        vm["Bq"]    = qdf(DF.Becquerel);

        vm["N"]     = qc(1, 1, -2);
        vm["Pa"]    = qc(-1, 1, -2);
        vm["J"]     = qc(2, 1, -2);
        vm["W"]     = qc(2, 1, -3);
        vm["C"]     = qc(0, 0, 1, 1);
        vm["V"]     = qc(2, 1, -3, -1);
        vm["F"]     = qc(-2, -1, 4, 2);
        vm["ohm"]   = qc(2, 1, -3, -2);
        vm["S"]     = qc(-2, -1, 3, 2);
        vm["Wb"]    = qc(2, 1, -2, -1);
        vm["T"]     = qc(0, 1, -2, -1);
        vm["H"]     = qc(2, 1, -2, -2);
        vm["lm"]    = qc(0, 0, 0, 0, 0, 1, 0, 0, 1);
        vm["lx"]    = qc(-2, 0, 0, 0, 0, 1, 0, 0, 1);
        vm["Gy"]    = qc(2, 0, -2);
        vm["Sv"]    = qc(2, 0, -2);
        vm["kat"]   = qc(0, 0, -1, 0, 0, 0, 1);
    }

    varNames = vm.keys;
    varNames.sort;
}


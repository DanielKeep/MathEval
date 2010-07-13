/**

Physical quantity implementation.

This module contains definitions and code for implementing a units system.

The SI system is used throughout; imperial units are not supported in any
fashion.  Users wishing to, for example, display a length in imperial should
convert the value themselves and render as a string.

In addition to the base units, the module also supports the derived SI units
in various forms.  For dimensionless units, they are treated as base units in
order to preserve them (for example, radians are treated as a base unit of
measure since they would otherwise instantly disappear and be
unrepresentable).

Derived and compound units are used for *display* where possible.
For example, if one had a quantity of 1 kg.m^2.s^-2, it would be rendered by
default as 1 N.m.

In some cases, there is more than one derived unit for he same combination of
base units.  For instance, both hertz and becquerel are inverse seconds.  In
these cases, these units are treated specially and are explicitly stored along
with the base unit in question.  Note that only one of the alternatives can be
used in a single quantity.

This means that, for example, 5Hz × 1s^1 = 5Hz.s^-1 whilst still being
internally equivalent to 10s^-2.
Operations which would introduce inconsistencies result in all units derived
from that base unit being dropped (1Hz × 1Bq = 1s^-2).

Some common non-SI units may be used for display purposes.  These are:

=============== =============== =============== ================
Name            Symbol(s)       Dimension       Equivalence
=============== =============== =============== ================
minute          min             time            1 min = 60 s
hour            h               time            1 h = 60 min
day             d               time            1 d = 24 h
degree of arc   °, arcdeg       angle           1° = (π/180) rad
minute of arc   ', arcmin       angle           1' = (1/60)°
second of arc   ", arcsec       angle           1" = (1/60)'
=============== =============== =============== ================

Authors: Daniel Keep <daniel.keep@gmail.com>
Copyright: See LICENSE.

*/
module eval.Units;

/*

TODO:

- Remove Celsius special casing.  It was a bad idea to begin with.

*/

private
{
    import eval.ComplexCmp;

    import tango.util.Convert : to;
}

enum Dimension : size_t
{
    // SI Base Units
    Length,
    Mass,
    Time,
    Current,
    Temperature,
    Luminance,
    Substance,

    // SI Derived Units
    Angle,
    SolidAngle,

    // Other Units
    Storage,

    Max = Storage
}

enum DerivedDimension : size_t
{
    Frequency,          // Hertz | Becquerel
    Temperature,        // Celsius

    Max = Temperature
}

enum DerivedFrequency : ubyte
{
    None,
    Hertz,
    Becquerel,

    Max = Becquerel
}

private
{
    alias Dimension D;
    alias DerivedDimension DD;
    alias DerivedFrequency DF;

    enum
    {
        DM = Dimension.Max + 1,
        DDM = DerivedDimension.Max + 1,
        DFM = DerivedFrequency.Max + 1,
    }

    const char[][DM] unitSymbols = [
        "m", "g", "s", "A", "K", "cd", "mol",
        "rad", "sr", "b"
    ];

    const char[][DFM] derFreqSymbols = [
        null, "Hz", "Bq"
    ];

    const char[][] SuperscriptDigits = [
        "⁰","¹","²","³","⁴","⁵","⁶","⁷","⁸","⁹"
    ];
    const SuperscriptMinus = "⁻";

    char[] formatSuperscript(byte v, char[12] buffer)
    {
        auto t = v;
        char* ptr = buffer.ptr + buffer.length;

        if( t == -128 )
        {
            static assert( t.min == -128 );
            return "⁻¹²⁸";
        }

        if( t < 0 ) t = -t;

        do
        {
            char[] digit = SuperscriptDigits[t%10];
            ptr -= digit.length;
            ptr[0..digit.length] = digit;
            t /= 10;
        }
        while( t > 0 );

        if( v < 0 )
        {
            ptr -= SuperscriptMinus.length;
            ptr[0..SuperscriptMinus.length] = SuperscriptMinus;
        }

        return buffer[ptr - buffer.ptr..$];
    }

    unittest
    {
        char[12] buffer;
        char[] fss(byte v) { return formatSuperscript(v, buffer); }

        assert( fss(0) == "⁰" );
        assert( fss(1) == "¹" );
        assert( fss(42) == "⁴²" );
        assert( fss(107) == "¹⁰⁷" );
        assert( fss(-5) == "⁻⁵" );
        assert( fss(-64) == "⁻⁶⁴" );
        assert( fss(-123) == "⁻¹²³" );
    }
}

struct Dimensions
{
    byte[DM] dims;
    byte[DDM] ders;
    DF derFreq;

    static Dimensions opCall(byte[DM] dims)
    {
        Dimensions r;
        r.dims[] = dims[];
        return r;
    }

    static Dimensions opCall(byte[DM] dims, byte[DDM] ders)
    {
        Dimensions r;
        r.dims[] = dims[];
        r.ders[] = ders[];
        return r;
    }

    static Dimensions opCall(byte[DM] dims, byte[DDM] ders, DF derFreq)
    {
        Dimensions r;
        r.dims[] = dims[];
        r.ders[] = ders[];
        r.derFreq = derFreq;
        return r;
    }

    bool isDimensionless()
    {
        foreach( d ; dims )
            if( d != 0 )
                return false;
        return true;
    }

    bool opEquals(ref Dimensions rhs)
    {
        auto lhs = this;

        return this.dims[] == rhs.dims[];
    }

    void opAddAssign(ref Dimensions rhs)
    {
        foreach( i, ref dst ; dims )
            dst += rhs.dims[i];
        foreach( i, ref dst ; ders )
            dst += rhs.ders[i];

        combineDerived(rhs);
        sanityCheckDerived();
    }

    void opSubAssign(ref Dimensions rhs)
    {
        foreach( i, ref dst ; dims )
            dst -= rhs.dims[i];
        foreach( i, ref dst ; ders )
            dst -= rhs.ders[i];

        combineDerived(rhs);
        sanityCheckDerived();
    }

    private void combineDerived(ref Dimensions rhs)
    {
        if( this.derFreq == DF.None )
        {
            this.derFreq = rhs.derFreq;
        }
        else if( this.derFreq != rhs.derFreq )
        {
            this.derFreq = DF.None;
            this.ders[DD.Frequency] = 0;
        }
    }

    private void sanityCheckDerived()
    {
        if( this.derFreq != DF.None 
                && (-this.dims[D.Time] < this.ders[DD.Frequency]) )
        {
            this.ders[DD.Frequency] = -this.dims[D.Time];
        }
    }

    void format(void delegate(char[]) sink)
    {
        bool sinkSep = false;
        char[12] ssBuff;

        char[] fss(byte v) { return formatSuperscript(v, ssBuff); }

        void sep() { if( sinkSep ) sink("·"); sinkSep = true; }

        foreach( i, d ; dims )
        {
            switch( i )
            {
                case D.Time:
                    auto t = d;

                    if( ders[DD.Frequency] != 0 )
                    {
                        assert( derFreq != DF.None );
                        sep;
                        sink(derFreqSymbols[derFreq]);
                        if( ders[DD.Frequency] != 1 )
                            sink(fss(ders[DD.Frequency]));

                        t = d + ders[DD.Frequency];
                    }

                    if( t != 0 )
                    {
                        sep;
                        sink(unitSymbols[i]);
                        if( t != 1 )
                            sink(fss(t));
                    }
                    break;

                case D.Temperature:
                    auto T = d;

                    if( ders[DD.Temperature] != 0 )
                    {
                        sep;
                        sink("C");
                        if( ders[DD.Temperature] != 1 )
                            sink(fss(ders[DD.Temperature]));

                        T = d - ders[DD.Temperature];
                    }

                    if( T != 0 )
                    {
                        sep;
                        sink(unitSymbols[i]);
                        if( T != 1 )
                            sink(fss(T));
                    }
                    break;

                default:
                    if( d != 0 )
                    {
                        sep;
                        sink(unitSymbols[i]);
                        if( d != 1 )
                            sink(fss(d));
                    }
                    break;
            }

            //sinkSep = true;
        }
    }
}

struct Quantity
{
    Dimensions dims;
    real mag;

    static Quantity opCall(real mag)
    {
        Quantity r;
        r.mag = mag;
        return r;
    }

    static Quantity opCall(real mag, Dimensions dims)
    {
        Quantity r;
        r.mag = mag;
        r.dims = dims;
        return r;
    }

    bool isDimensionless()
    {
        return dims.isDimensionless;
    }

    bool canAdd(ref Quantity rhs)
    {
        return this.dims == rhs.dims;
    }

    Quantity opAdd(ref Quantity rhs)
    {
        auto lhs = this;
        return Quantity(lhs.mag+rhs.mag, lhs.dims);
    }

    Quantity opSub(ref Quantity rhs)
    {
        auto lhs = this;
        return Quantity(lhs.mag-rhs.mag, lhs.dims);
    }

    Quantity opMul(ref Quantity rhs)
    {
        auto lhs = this;
        auto r = Quantity(lhs.mag * rhs.mag, lhs.dims);
        r.dims += rhs.dims;
        return r;
    }

    Quantity opDiv(ref Quantity rhs)
    {
        auto lhs = this;
        auto r = Quantity(lhs.mag / rhs.mag, lhs.dims);
        r.dims -= rhs.dims;
        return r;
    }

    ComplexCmp opComplexCmp(ref Quantity rhs)
    {
        auto lhs = this;

        if( lhs.dims != rhs.dims )
            return ComplexCmp.Un;
        else
        {
            if( lhs.mag < rhs.mag )
                return ComplexCmp.Lt;
            else if( lhs.mag == rhs.mag )
                return ComplexCmp.Eq;
            else if( lhs.mag > rhs.mag )
                return ComplexCmp.Gt;
            else
                return ComplexCmp.Un;
        }
    }

    char[] toString()
    {
        char[] b;
        void sink(char[] s) { b ~= s; }

        b ~= to!(char[])(mag);
        dims.format(&sink);

        return b;
    }
}


/**
    Structured Output.

    This is used to print out nicely indented and formatted text.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.StructuredOutput;

import tango.io.model.IConduit : OutputStream;
import tango.io.stream.Format : FormatOutput;

/**
  
    r is for raw, it does naught but out',
    f is for format, it throws strings about.
    v is for vararg, because D is so shit,
    l is for line, it makes a new it.
    p is for print; f sans show-off,
    that's all there is to this,
    now go bugger off.

*/
final class StructuredOutput
{
    alias StructuredOutput This;

    this(OutputStream os)
    {
        this.os = os;
        this.of = new FormatOutput!(char)(os);
    }

    This seq(void delegate() dg)
    {
        dg();
        return this;
    }

    This r(char[] s)
    {
        os.write(s);
        return this;
    }

    This rf(char[] s, ...)
    {
        return rfv(s, _arguments, _argptr);
    }

    This rfv(char[] fmt, TypeInfo[] arguments, void* argptr)
    {
        of.layout()(&emit, arguments, argptr, fmt);
        return this;
    }

    This rfl(char[] s, ...)
    {
        rfv(s, _arguments, _argptr);
        r(Nl);
        os.flush;
        return this;
    }

    This rl(char[] s)
    {
        r(s);
        r(Nl);
        os.flush;
        return this;
    }

    This p(char[] s)
    {
        if( !indented )
            indent;
        r(s);
        return this;
    }

    This indent()
    {
        for( size_t i=0; i<depth; ++i )
            r(Ind);
        indented = true;
        return this;
    }

    This l()
    {
        r(Nl);
        os.flush;
        indented = false;
        return this;
    }

    This pl(char[] s)
    {
        p(s);
        l();
        return this;
    }

    This f(char[] s, ...)
    {
        if( !indented )
            indent;
        rfv(s, _arguments, _argptr);
        return this;
    }

    This fl(char[] s, ...)
    {
        if( !indented )
            indent;
        rfv(s, _arguments, _argptr);
        l();
        return this;
    }

    This push(char[] s = null)
    {
        assert( depth < depth.max );
        if( s !is null )
            pl(s);
        ++ depth;
        return this;
    }

    This pop(char[] s = null)
    {
        assert( depth > 0 );
        -- depth;
        if( s !is null )
            pl(s);
        return this;
    }

private:
    OutputStream os;
    FormatOutput!(char) of;
    size_t depth = 0;
    bool indented = false;

    version( Win32 )
        const Nl = "\r\n";
    else
        const Nl = "\n";

    const Ind = "  ";

    uint emit(char[] s)
    {
        auto count = os.write(s);
        if( count is OutputStream.Eof )
            os.conduit.error("FormatOutput :: unexpected Eof");
        return count;
    }
}


/**
    Source code class.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.Source;

import Utf = tango.text.convert.Utf;
import eval.Location;

final class Source
{
    char[] name, src;
    
    this(char[] name, char[] src)
    {
        reset(name, src);
    }

    /**
    Params:
        line    = natural line number; 1 is the first line.
        col     = natural column number; 1 is the first column;
    */
    this(char[] name, char[] src, uint line, uint col)
    {
        reset(name, src, line, col);
    }

    void reset()
    {
        reset(name, src);
    }

    void reset(char[] name, char[] src)
    {
        this.name = name;
        this.src = src;
        this.mark = Mark.init;
    }

    void reset(char[] name, char[] src, uint line, uint col)
    {
        // TODO: enforce
        assert( line >= 1 );
        assert( col >= 1 );

        reset(name, src);
        this.mark.line = line;
        this.mark.column = col;
    }

    Source dup()
    {
        auto r = new Source(name, src);
        r.mark = this.mark;
        return r;
    }

    Location loc()
    {
        Location r;
        r.file = name;
        r.line = mark.line;
        r.column = mark.column;
        return r;
    }

    dchar get(size_t i)
    {
        dchar r;
        auto src = this.src[mark.offset..$];

        if( src.length > 0 )
            do
            {
                uint ate;
                r = Utf.decode(src, ate);
                src = src[ate..$];
            }
            while( i --> 0 && src.length > 0 );

        // +1 to undo the last i--; consider the case of i=0
        if( (i+1) > 0 )
            return dchar.init;

        return r;
    }

    alias get opIndex;

    char[] slice(size_t n)
    {
        size_t len = 0;
        auto src = this.src[mark.offset..$];
        while( n --> 0 && src.length > 0 )
        {
            uint ate;
            Utf.decode(src, ate);
            src = src[ate..$];
            len += ate;
        }
        return this.src[mark.offset..mark.offset + len];
    }

    char[] sliceFrom(Mark mark)
    {
        return this.src[mark.offset..this.mark.offset];
    }

    size_t length()
    {
        return src[mark.offset..$].length;
    }

    char[] advance()
    {
        return advance(1);
    }
    
    char[] advance(size_t n)
    {
        size_t lineInc = 0;
        auto col = mark.column;
        auto cr = mark.hangingCR;

        auto src = this.src[mark.offset..$];
        size_t bytes = 0; // actual bytes consumed

        while( n --> 0 && src.length > 0 )
        {
            uint ate;
            auto cp = Utf.decode(src, ate);
            src = src[ate..$];
            bytes += ate;

            switch( cp )
            {
                case '\r':
                    cr = true;
                    ++ lineInc;
                    col = 1;
                    break;

                case '\n':
                    if( cr )
                        cr = false;
                    else
                    {
                        ++ lineInc;
                        col = 1;
                    }
                    break;

                default:
                    cr = false;
                    ++ col;
            }
        }

        auto slice = this.src[mark.offset..mark.offset + bytes];

        mark.offset += bytes;
        mark.line += lineInc;
        mark.column = col;
        mark.hangingCR = cr;

        return slice;
    }
    
    struct Mark
    {
    private:
        size_t offset;
        uint line = 1,
             column = 1;
        bool hangingCR = false;
    }

    Mark save()
    {
        return mark;
    }

    void restore(Mark mark)
    {
        this.mark = mark;
    }

    Location locFrom(Mark mark)
    {
        Location r;
        r.file = name;
        r.line = mark.line;
        r.column = mark.column;
        return r;
    }

private:
    Mark mark;
}

version( Unittest )
{
    import tango.text.convert.Format;

    unittest
    {
        // Test newline handling of advance
        {
            scope src = new Source(__FILE__,"\r\n\n\r \n\r\r\n");
            auto start = src.save;

            void next() { src.advance(1); }

            bool locis(uint l, uint c)
            {
                auto loc = src.loc;
                return (loc.line == l) && (loc.column == c);
            }

            char[] les() /* location error string */
            {
                return "got: "~src.loc.toString;
            }

            bool hcr() { return src.mark.hangingCR; }

            src.restore(start);
                    assert( locis(1,1), les );
            next;   assert( locis(2,1), les ); assert( hcr );
            next;   assert( locis(2,1), les ); assert( !hcr );
            next;   assert( locis(3,1), les ); assert( !hcr );
            next;   assert( locis(4,1), les ); assert( hcr );
            next;   assert( locis(4,2), les ); assert( !hcr );
            next;   assert( locis(5,1), les ); assert( !hcr );
            next;   assert( locis(6,1), les ); assert( hcr );
            next;   assert( locis(7,1), les ); assert( hcr );
            next;   assert( locis(7,1), les ); assert( !hcr );
            next;   assert( src.length == 0, Format("got: {}",src.length) );

            src.restore(start);
            src.advance(10);
                    assert( locis(7,1) ); assert( !hcr );
        }
    }
}


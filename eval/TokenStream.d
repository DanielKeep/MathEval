module eval.TokenStream;

import eval.Location;
import eval.Source;
import eval.Tokens;

final class TokenStream
{
    alias bool function(Source, LocErr, out Token) NextToken;

    Source src;
    NextToken next;
    LocErr err;

    this(Source src, NextToken next, LocErr err)
    {
        this.src = src;
        this.next = next;
        this.err = err;

        this.cache = new Token[](BaseCacheSize);
        this.cached = 0;
    }

    Token peek()
    {
        return peek(0);
    }

    Token peek(size_t n)
    {
        if( cached > n )
            return cache[n];

        assert( cached <= n );

        if( next is null )
            return Token.init;

        assert( next !is null );

        if( cache.length <= n )
        {
            size_t newSize = cache.length*2;
            while( newSize <= n )
                newSize *= 2;

            auto newCache = new Token[](newSize);
            newCache[0..cache.length] = cache;
            delete cache;
            cache = newCache;
        }

        assert( cache.length > n );

        foreach( ref cacheEl ; cache[cached..n+1] )
        {
            auto f = next(src, err, cacheEl);
            if( !f )
                err(src.loc, "unexpected '{}'", src[0]);

            ++ cached;

            if( cacheEl.type == TOKeos )
            {
                next = null;
                break;
            }
        }

        if( cached > n )
            return cache[n];

        else
            return Token.init;
    }

    Token pop()
    {
        if( cached > 0 )
        {
            auto r = cache[0];
            foreach( i, ref dst ; cache[0..$-1] )
                dst = cache[i+1];
            -- cached;
            return r;
        }
        else if( next !is null )
        {
            Token token;
            auto f = next(src, err, token);
            if( !f )
                err(src.loc, "unexpected '{}'", src[0]);

            if( token.type == TOKeos )
                next = null;

            return token;
        }
        else
            err(src.loc, "expected something, got end of source");
    }

    Token popExpect(TOK type, char[] msg = null)
    {
        auto actual = pop();
        if( actual.type == type )
            return actual;

        err(actual.loc, (msg !is null ? msg : "expected {0}, got {1}"),
                tokToName(type), tokToName(actual.type));
    }

    Token popExpectAny(TOK[] types...)
    {
        auto actual = pop();
        foreach( type ; types )
            if( actual.type == type )
                return actual;

        char[] exp;
        foreach( type ; types )
            exp ~= (exp.length == 0 ? "" : ", ") ~ tokToName(type);

        err(actual.loc, "expected one of {0}; got {1}", exp,
                tokToName(actual.type));
    }

private:
    enum { BaseCacheSize = 2 }

    Token[] cache;
    size_t cached;
}


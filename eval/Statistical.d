module eval.Statistical;

import tango.math.random.Kiss;

Kiss* rand;

static this()
{
    rand = new Kiss;
    rand.seed;
}

real uniformReal(bool li, bool ui, real l, real u)
{
    /*
    HACK: this is a huge and horrible hack.  OPTLINK dies if you pull in too
    many functions from Kiss.  Thus, the only function (apart from seed) that
    we can use is Kiss.natural.

    Fucking OPTLINK!
    */
    uint i = rand.natural;

    if( !li && !ui )
        while( i == i.min || i == i.max )
            i = rand.natural;

    else if( li && !ui )
        while( i == i.max )
            i = rand.natural;

    else if( !li && ui )
        while( i == i.min )
            i = rand.natural;

    return ((cast(real)i)/i.max) * (u - l) + l;
}


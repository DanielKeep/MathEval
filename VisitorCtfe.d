module VisitorCtfe;

char[] visitorDispatch_ctfe
(
    char[] baseType,
    char[][] subTypes,
    char[] resultType
)
{
    char[] r;
    const nl = ""; // empty to keep the mixin on one line

    r ~= resultType~" visitBase("~baseType~" node) {"~nl;

    foreach( subType ; subTypes )
        r ~= "if( auto stn = cast("~subType~") node ) {"
           ~ "return visit(stn);"
           ~ "}"~nl;

    r ~= "return defaultVisit(node);"~nl
       ~ "}"~nl;

    return r;
}


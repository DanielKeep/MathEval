module eval.TokensCtfe;

char[] generateTokens_ctfe
(
    char[] file, long line,
    char[][2][] symbolTokens,
    char[][] literalTokens,
    char[][] otherTokens,
)
{
    char[] r = "";

    // Insert line renumbering
    r ~= lineSpec_ctfe(file, line, "");

    // Token type
    r ~= lineSpec_ctfe(file, line, "TOK typedef");
    r ~= "typedef int TOK;\n";

    // Token enums
    r ~= lineSpec_ctfe(file, line, "TOK enums");
    r ~= "enum : TOK {\n";
    r ~= "  TOKnone,\n";
    foreach( pair ; symbolTokens )
        r ~= "  TOK" ~ pair[1] ~ ",\n";
    foreach( name ; literalTokens )
        r ~= "  TOK" ~ name ~ ",\n";
    foreach( name ; otherTokens )
        r ~= "  TOK" ~ name ~ ",\n";
    r ~= "}\n";

    // TOK -> string
    r ~= lineSpec_ctfe(file, line, "TOK to string map");
    r ~= "char[][TOK] tokToNameMap;\n";
    r ~= "static this() {\n";
    r ~= "  alias tokToNameMap m;\n";
    foreach( pair ; symbolTokens )
        r ~= "  m[TOK" ~ pair[1] ~ "] = \"" ~ pair[1] ~ "\";\n";
    foreach( name ; literalTokens )
        r ~= "  m[TOK" ~ name ~ "] = \"" ~ name ~ "\";\n";
    foreach( name ; otherTokens )
        r ~= "  m[TOK" ~ name ~ "] = \"" ~ name ~ "\";\n";
    r ~= "  m.rehash;\n";
    r ~= "}\n";

    r ~= lineSpec_ctfe(file, line, "TOK to string func");
    r ~= "char[] tokToName(TOK tok) {\n";
    r ~= "  switch(tok) {\n";
    foreach( pair ; symbolTokens )
        r ~= "  case TOK" ~ pair[1] ~ ": return \"" ~ pair[1] ~ "\";\n";
    foreach( name ; literalTokens )
        r ~= "  case TOK" ~ name ~ ": return \"" ~ name ~ "\";\n";
    foreach( name ; otherTokens )
        r ~= "  case TOK" ~ name ~ ": return \"" ~ name ~ "\";\n";
    r ~= "  default: return \"\";\n";
    r ~= "  }\n";
    r ~= "}\n";

    // string -> TOK
    r ~= lineSpec_ctfe(file, line, "string to TOK map");
    r ~= "TOK[char[]] nameToTokMap;\n";
    r ~= "static this() {\n";
    r ~= "  alias nameToTokMap m;\n";
    foreach( pair ; symbolTokens )
        r ~= "  m[\"" ~ pair[1] ~ "\"] = TOK" ~ pair[1] ~ ";\n";
    foreach( name ; literalTokens )
        r ~= "  m[\"" ~ name ~ "\"] = TOK" ~ name ~ ";\n";
    foreach( name ; otherTokens )
        r ~= "  m[\"" ~ name ~ "\"] = TOK" ~ name ~ ";\n";
    r ~= "  m.rehash;\n";
    r ~= "}\n";

    r ~= lineSpec_ctfe(file, line, "string to TOK func");
    r ~= "TOK nameToTok(char[] name) {\n";
    r ~= "  switch(name) {\n";
    foreach( pair ; symbolTokens )
        r ~= "  case \"" ~ pair[1] ~ "\": return TOK" ~ pair[1] ~ ";\n";
    foreach( name ; literalTokens )
        r ~= "  case \"" ~ name ~ "\": return TOK" ~ name ~ ";\n";
    foreach( name ; otherTokens )
        r ~= "  case \"" ~ name ~ "\": return TOK" ~ name ~ ";\n";
    r ~= "  default: return TOKnone;\n";
    r ~= "  }\n";
    r ~= "}\n";

    return r;
}

private:

char[] lineSpec_ctfe(char[] file, long line, char[] section)
{
    char[] r = "#line 1 \""~file~":"~format_ctfe(line)~":generateTokens_ctfe";

    if( section != "" )
        r ~= "(" ~ section ~ ")";

    r ~= "\"\n";
    return r;
}

/**
 * Formats an integer as a string.  You can optionally specify a different
 * base; any value between 2 and 16 inclusive is supported.
 * 
 * Params:
 *     v = value to format.
 *     base = base to use; defaults to 10.
 * Returns:
 *      integer formatted as a string.
 */

char[] format_ctfe(intT)(intT v, int base = 10)
{
    static if( !is( intT == ulong ) ) 
    {
        return (v < 0)
            ? "-" ~ format_ctfe(cast(ulong) -v, base)
            : format_ctfe(cast(ulong) v, base);
    }
    else
    {
        assert( 2 <= base && base <= 16,
                "base must be between 2 and 16; got " ~ format_ctfe(base, 10) );
        
        char[] r = "";
        do
        {
            r = INT_CHARS[v % base] ~ r;
            v /= base;
        }
        while( v > 0 );
        return r;
    }
}

const INT_CHARS = "0123456789abcdef";


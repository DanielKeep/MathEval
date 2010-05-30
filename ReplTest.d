/**
    Math Eval CLI.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module ReplTest;

import eval.Eval;
import eval.Repl;

import tango.io.Stdout;

void showHelp(char[] exec)
{
    Stdout.formatln("Usage: {} [--help] [FILE]", exec);
}

int main(char[][] rawArgs)
{
    auto exec = rawArgs[0];
    auto args = rawArgs[1..$];

    char[] file;

    while( args.length > 0 )
    {
        auto arg = args[0];
        switch( arg )
        {
            case "--help":
                showHelp(exec);
                return 0;

            default:
                if( arg.startsWith("-") )
                {
                    Stderr("unknown option: ")(arg).newline;
                    return 1;
                }
                if( file != "" )
                {
                    Stderr("too many arguments").newline;
                    return 1;
                }
                file = arg;
        }
        args = args[1..$];
    }

    if( file == "" )
    {
        startRepl;
        return 0;
    }
    else
        return evalFile(file) ? 0 : 1;
}

bool startsWith(char[] s, char[] test)
{
    return (s.length >= test.length && s[0..test.length] == test);
}


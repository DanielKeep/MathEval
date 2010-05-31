/**
    Math Eval CLI.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module Cli;

import eval.Eval;
import eval.Repl;
import eval.Variables;

import tango.io.Stdout;

void showHelp(char[] exec)
{
    Stdout.formatln("Usage: {} [--help] [-i|--interactive] [FILE]", exec);
}

int main(char[][] rawArgs)
{
    auto exec = rawArgs[0];
    auto args = rawArgs[1..$];

    char[] file;
    bool forceInter = false;

    while( args.length > 0 )
    {
        auto arg = args[0];
        switch( arg )
        {
            case "--help":
                showHelp(exec);
                return 0;

            case "-i": case "--interactive":
                forceInter = true;
                break;

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

    Variables existing;
    bool result = false;

    if( file != "" )
        result = evalFile(file, null, existing);

    if( file == "" || forceInter )
    {
        startRepl(existing);
        result = true;
    }

    return result ? 0 : 1;
}

bool startsWith(char[] s, char[] test)
{
    return (s.length >= test.length && s[0..test.length] == test);
}


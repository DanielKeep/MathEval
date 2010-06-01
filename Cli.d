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

            case "--version":
                showVersion();
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

void showHelp(char[] exec)
{
    Stdout.formatln("Usage: {} [-i|--interactive] [--help] [--version] [FILE]", exec);
}

import GitVer;
import tango.core.Version : Tango;

const COPYRIGHT = "Copyright (c) 2010, Daniel Keep.";
const TANGO_COPYRIGHT = "Portions copyright (c) 2004-2009, Tango contributors.";

const LICENSE = cast(char[]) import("LICENSE");
const TANGO_LICENSE = cast(char[]) import("TANGO_LICENSE");

void showVersion()
{
    {
        Stdout("MathEval REPL ");
        if( GIT_COMMIT_TAG != "" )
            Stdout(GIT_COMMIT_TAG);
        else
        {
            Stdout("commit ")(GIT_COMMIT_HASH_ABBR);
            if( GIT_COMMIT_BRANCH != "" )
                Stdout(" (on ")(GIT_COMMIT_BRANCH)(")");
        }
        Stdout(" - ")(__DATE__);
    
        debug Stdout(" (debug build)");
    
        Stdout.newline;
    }
    {
        Stdout("Compiled with ")(__VENDOR__)
            (" ")(__VERSION__/1000)
            (".").format("{,03:d}",__VERSION__%1000)
            (" with Tango ")(Tango.Major)(".")(Tango.Minor).newline;
    }
    {
        char[][] options;
        version( MathEval_Lists )       options ~= "lists";

        if( options.length > 0 )
        {
            Stdout("Options: ");
            bool first = true;
            if( options.length > 1 )
                foreach( option ; options[0..$-1] )
                {
                    Stdout(first?"":", ")(option);
                    first = false;
                }
            Stdout(first?"":" and ")(options[$-1])(".").newline;
        }
    }
    Stdout.newline;
    {
        Stdout(COPYRIGHT).newline;
        Stdout(TANGO_COPYRIGHT).newline;
    }
}


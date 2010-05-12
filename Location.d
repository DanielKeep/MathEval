module Location;

import tango.text.convert.Format;

struct Location
{
    char[] file;
    uint line = 0;      /// natural line number; 1 is the first line
    uint column = 0;    /// natural column number; 1 is the first column

    char[] toString()
    {
        return Format("{}({}:{})", file, line, column);
    }
}

alias void delegate(Location, char[], ...) LocErr;


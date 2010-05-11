module Location;

import tango.text.convert.Format;

struct Location
{
    char[] file;
    uint line;      /// natural line number; 1 is the first line
    uint column;    /// natural column number; 1 is the first column

    char[] toString()
    {
        return Format("{}({}:{})", file, line, column);
    }
}


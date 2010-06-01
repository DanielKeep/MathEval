/**
 * This program will dump the following information into a module called
 * GitVer:
 * 
 * * the full SHA1 hash of the current Git commit,
 * * the abbreviated hash,
 * * current branch and
 * * the associated tag, if any.
 * 
 * Authors: Daniel Keep <daniel.keep@gmail.com>
 * Copyright: See LICENSE.GPLv3.
 */
module GitVerGen;

alias char[] string;

import tango.core.Thread;
import tango.io.stream.Lines;
import tango.io.stream.TextFile;
import tango.io.FilePath;
import tango.io.Stdout;
import tango.sys.Environment;
import tango.sys.Process;
import tango.text.Util;
import tango.util.Convert;

struct Git
{
    version( Windows )
        static const GIT = "git.cmd";
    else
        static const GIT = "git";
    
    struct Hashes
    {
        string full, abbrev;
    }
    
    static string getBranch()
    {
        scope p = new Process(true, GIT~" branch");
        p.redirect = Redirect.Output;
        p.execute;
        
        assert(p.stdout !is null);
        char[] branch;
        {
            scope stdout_lines = new Lines!(char)(p.stdout);
            foreach( line ; stdout_lines )
            {
                if( line == "" ) continue;
                
                if( line[0] == '*' )
                {
                    branch = line[2..$];
                    break;
                }
            }
        }
        p.stdout.close;
        
        // Finish up
        auto p_res = p.wait;
        
        if( branch == "" )
            throw new Exception("couldn't work out git branch");
        
        if( p_res.reason != Process.Result.Exit )
            throw new Exception("call to git show failed");
        
        else if( p_res.status )
            throw new Exception("call to git show failed with exit code "
                ~ to!(string)(p_res.status));
        
        // Done
        return branch;
    }
    
    static string getTag(string hash)
    {
        scope tagsPath = new FilePath(".git/refs/tags/");
        foreach( tagInfo ; tagsPath )
        {
            scope tagFile = new File(tagInfo.path~tagInfo.name);
            scope tagLines = new Lines!(char)(tagFile);
            string line;
            tagLines.readln(line);
            if( line == hash )
                return tagInfo.name.dup;
        }
        return "";
    }
    
    static Hashes getHEADHashes()
    {
        scope p = new Process(true, GIT~" show --pretty=format:%h,%H HEAD");
        p.redirect = Redirect.Output;
        p.execute;
        
        // Read the first line only (don't care about the rest)
        assert(p.stdout !is null);
        char[] line;
        {
            scope stdout_lines = new Lines!(char)(p.stdout);
            stdout_lines.readln(line);
        }
        p.stdout.close;
        
        // Parse out hashes
        Hashes hashes;
        hashes.abbrev = head(line, ",", hashes.full);
        
        // Finish up
        auto p_res = p.wait;
        
        if( p_res.reason != Process.Result.Exit )
            throw new Exception("call to git show failed");
        
        else if( p_res.status )
            throw new Exception("call to git show failed with exit code "
                ~ to!(string)(p_res.status));
        
        return hashes;
    }
}

int main()
{
    Stdout("Generating gitver.d...");
    scope(failure) Stdout(" failed.").newline;
    
    auto hash = Git.getHEADHashes;
    auto tag = Git.getTag(hash.full);
    auto branch = Git.getBranch;
    
    {
        scope out_dir = new FilePath("src");
        if( !out_dir.exists )
            out_dir.create;
        
        else if( !out_dir.isFolder )
            throw new Exception("cannot create src directory: already exists");
    }
    
    {
        scope out_f = new TextFileOutput("GitVer.d");
        out_f
            ("/**\n")
            (" * Contains information on the commit this code was compiled\n")
            (" * from.\n")
            (" * \n")
            (" * NOTE: this file is auto-generated; any changes will\n")
            (" * be lost.\n")
            (" */\n")
            ("module GitVer;\n")
            ("\n")
            ("static const GIT_COMMIT_TAG=\"")(tag)("\";\n")
            ("static const GIT_COMMIT_BRANCH=\"")(branch)("\";\n")
            ("static const GIT_COMMIT_HASH_FULL=\"")(hash.full)("\";\n")
            ("static const GIT_COMMIT_HASH_ABBR=\"")(hash.abbrev)("\";\n")
            ("\n")
            ;
        out_f.flush.close;
    }
    
    Stdout(" done.").newline;
    return 0;
}


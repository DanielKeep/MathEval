module Ast;

import Location;

abstract class AstNode
{
    Location loc;

    this(Location loc)
    {
        this.loc = loc;
    }
}

class AstScript : AstNode
{
    AstStatement[] stmts;

    this(Location loc, AstStatement[] stmts)
    {
        super(loc);
        this.stmts = stmts;
    }
}

abstract class AstStatement : AstNode
{
    this(Location loc)
    {
        super(loc);
    }
}

class AstLetStatement : AstStatement
{
    char[] ident;
    AstExpr expr;

    this(Location loc, char[] ident, AstExpr expr)
    {
        assert( ident != "" );
        assert( expr !is null );

        super(loc);
        this.ident = ident;
        this.expr = expr;
    }
}

class AstExprStatement : AstStatement
{
    AstExpr expr;

    this(Location loc, AstExpr expr)
    {
        assert( expr !is null );

        super(loc);
        this.expr = expr;
    }
}

abstract class AstExpr : AstNode
{
    this(Location loc)
    {
        super(loc);
    }
}

class AstNumberExpr : AstExpr
{
    real value;

    this(Location loc, real value)
    {
        super(loc);
        this.value = value;
    }
}

class AstUniformExpr : AstExpr
{
    real l, u;
    bool li, ui;

    this(Location loc, real l, real u, bool li, bool ui)
    {
        super(loc);
        this.l = l;
        this.u = u;
        this.li = li;
        this.ui = ui;
    }
}

class AstBinaryExpr : AstExpr
{
    enum Op
    {
        Eq,
        NotEq,
        Lt,
        LtEq,
        Gt,
        GtEq,
        Add,
        Sub,
        Mul,
        Div,
        IntDiv,
        Exp,
    }

    Op op;
    AstExpr lhs, rhs;

    this(Location loc, Op op, AstExpr lhs, AstExpr rhs)
    {
        assert( lhs !is null );
        assert( rhs !is null );

        super(loc);
        this.op = op;
        this.lhs = lhs;
        this.rhs = rhs;
    }
}

class AstUnaryExpr : AstExpr
{
    enum Op
    {
        Pos,
        Neg,
    }

    Op op;
    AstExpr expr;

    this(Location loc, Op op, AstExpr expr)
    {
        assert( expr !is null );

        super(loc);
        this.op = op;
        this.expr = expr;
    }
}

class AstVariableExpr : AstExpr
{
    char[] ident;

    this(Location loc, char[] ident)
    {
        assert( ident != "" );

        super(loc);
        this.ident = ident;
    }
}

class AstFunctionExpr : AstExpr
{
    char[] ident;
    AstExpr[] args;

    this(Location loc, char[] ident, AstExpr[] args)
    {
        assert( ident != "" );
        foreach( arg ; args ) assert( arg !is null );

        super(loc);
        this.ident = ident;
        this.args = args;
    }
}


module eval.Ast;

import eval.Location;

const char[][] AstNodeNames =
[
    "AstScript",
    "AstLetStmt",
    "AstExprStmt",
    "AstNumberExpr",
    "AstBinaryExpr",
    "AstUnaryExpr",
    "AstVariableExpr",
    "AstFunctionExpr",
    "AstUniformExpr",
    "AstSharedExpr",
];

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
    AstStmt[] stmts;

    this(Location loc, AstStmt[] stmts)
    {
        super(loc);
        this.stmts = stmts;
    }
}

abstract class AstStmt : AstNode
{
    this(Location loc)
    {
        super(loc);
    }
}

class AstLetStmt : AstStmt
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

class AstExprStmt : AstStmt
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
        And,
        Or,
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

    static char[] opToString(Op op)
    {
        switch( op )
        {
            case Op.Eq:     return "Eq";
            case Op.NotEq:  return "NotEq";
            case Op.Lt:     return "Lt";
            case Op.LtEq:   return "LtEq";
            case Op.Gt:     return "Gt";
            case Op.GtEq:   return "GtEq";
            case Op.Add:    return "Add";
            case Op.Sub:    return "Sub";
            case Op.Mul:    return "Mul";
            case Op.Div:    return "Div";
            case Op.IntDiv: return "IntDiv";
            case Op.Exp:    return "Exp";
            case Op.And:    return "And";
            case Op.Or:     return "Or";

            default:        assert(false);
        }
    }
}

class AstUnaryExpr : AstExpr
{
    enum Op
    {
        Pos,
        Neg,
        Not,
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

    static char[] opToString(Op op)
    {
        switch( op )
        {
            case Op.Pos:    return "Pos";
            case Op.Neg:    return "Neg";
            case Op.Not:    return "Not";

            default:        assert(false);
        }
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

class AstUniformExpr : AstExpr
{
    bool li, ui;
    AstExpr le, ue;

    this(Location loc, bool li, bool ui, AstExpr le, AstExpr ue)
    {
        super(loc);

        this.li = li;
        this.ui = ui;
        this.le = le;
        this.ue = ue;
    }
}

class AstSharedExpr : AstExpr
{
    AstExpr expr;

    this(Location loc, AstExpr expr)
    {
        super(loc);
        this.expr = expr;
    }
}


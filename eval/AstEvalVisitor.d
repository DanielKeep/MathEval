module eval.AstEvalVisitor;

import eval.Ast;
import eval.Location;
import eval.Statistical : uniformReal;
import eval.Value;

import tango.math.Math : floor, pow;
import tango.text.convert.Format;

class AstEvalVisitor
{
    alias bool delegate(char[], out Value) ResolveDg;
    alias bool delegate(char[], ref Value) DefineDg;
    alias bool delegate(char[], void delegate(char[], ...), Value[] delegate(), out Value) EvalDg;

    LocErr err;
    ResolveDg resolve;
    DefineDg define;
    EvalDg eval;

    this(LocErr err, ResolveDg resolve, DefineDg define, EvalDg eval)
    {
        this.err = err;
        this.resolve = resolve;
        this.define = define;
        this.eval = eval;
    }

    Value visitBase(AstNode node)
    {
        if( auto stn = cast(AstScript) node )
            return visit(stn);
        if( auto stn = cast(AstLetStmt) node )
            return visit(stn);
        if( auto stn = cast(AstExprStmt) node )
            return visit(stn);
        if( auto stn = cast(AstNumberExpr) node )
            return visit(stn);
        if( auto stn = cast(AstBinaryExpr) node )
            return visit(stn);
        if( auto stn = cast(AstUnaryExpr) node )
            return visit(stn);
        if( auto stn = cast(AstVariableExpr) node )
            return visit(stn);
        if( auto stn = cast(AstFunctionExpr) node )
            return visit(stn);
        if( auto stn = cast(AstUniformExpr) node )
            return visit(stn);

        return defaultVisit(node);
    }

    Value defaultVisit(AstNode node)
    {
        assert(false, "missing visit for "~node.classinfo.name);
    }

    Value visit(AstScript node)
    {
        Value r;
        foreach( stmt ; node.stmts )
            r = visitBase(stmt);
        return r;
    }

    Value visit(AstLetStmt node)
    {
        if( ! define(node.ident, visitBase(node.expr)) )
            err(node.loc, "cannot redefine '{}'", node.ident);

        return Value();
    }

    Value visit(AstExprStmt node)
    {
        return visitBase(node.expr);
    }

    Value visit(AstNumberExpr node)
    {
        return Value(node.value);
    }

    Value visit(AstBinaryExpr node)
    {
        auto lhs = visitBase(node.lhs);
        auto rhs = visitBase(node.rhs);
        alias AstBinaryExpr.Op Op;

        void opErr(char[] fmt, ...)
        {
            err(node.loc, Format.convert(_arguments, _argptr, fmt));
        }

        switch( node.op )
        {
            case Op.Eq:     return binCmp(&opErr, lhs, rhs, Cmp.Eq);
            case Op.NotEq:  return binCmp(&opErr, lhs, rhs, Cmp.Ne);
            case Op.Lt:     return binCmp(&opErr, lhs, rhs, Cmp.Lt);
            case Op.LtEq:   return binCmp(&opErr, lhs, rhs, Cmp.LtEq);
            case Op.Gt:     return binCmp(&opErr, lhs, rhs, Cmp.Gt);
            case Op.GtEq:   return binCmp(&opErr, lhs, rhs, Cmp.GtEq);
            case Op.Add:    return binAdd(&opErr, lhs, rhs);
            case Op.Sub:    return binSub(&opErr, lhs, rhs);
            case Op.Mul:    return binMul(&opErr, lhs, rhs);
            case Op.Div:    return binDiv(&opErr, lhs, rhs);
            case Op.IntDiv: return binIntDiv(&opErr, lhs, rhs);
            case Op.Exp:    return binExp(&opErr, lhs, rhs);
            case Op.And:    return binAnd(&opErr, lhs, rhs);
            case Op.Or:     return binOr(&opErr, lhs, rhs);
            default:        assert(false);
        }
    }

    Value visit(AstUnaryExpr node)
    {
        auto expr = visitBase(node.expr);
        alias AstUnaryExpr.Op Op;

        void opErr(char[] fmt, ...)
        {
            err(node.loc, "{}", Format.convert(_arguments, _argptr, fmt));
        }

        switch( node.op )
        {
            case Op.Pos:    return unPos(&opErr, expr);
            case Op.Neg:    return unNeg(&opErr, expr);
            case Op.Not:    return unNot(&opErr, expr);
            default:        assert(false);
        }
    }

    Value visit(AstVariableExpr node)
    {
        Value r;
        if( ! resolve(node.ident, r) )
            err(node.loc, "unknown variable '{}'", node.ident);
        return r;
    }

    Value visit(AstFunctionExpr node)
    {
        void fnErr(char[] fmt, ...)
        {
            err(node.loc, "{}", Format.convert(_arguments, _argptr, fmt));
        }

        Value[] toArgs()
        {
            Value[] r;
            foreach( arg ; node.args )
                r ~= visitBase(arg);
            return r;
        }

        // For now, functions aren't variables.
        Value r;
        if( ! eval(node.ident, &fnErr, &toArgs, r) )
            err(node.loc, "unknown function '{}'", node.ident);
        return r;
    }

    Value visit(AstUniformExpr node)
    {
        auto lv = visitBase(node.le);
        auto uv = visitBase(node.ue);

        if( !lv.isReal || !uv.isReal )
            err(node.loc, "invalid types for range: {} and {}",
                    lv.tagName, uv.tagName);

        auto l = lv.asReal;
        auto u = uv.asReal;

        return Value(uniformReal(node.li, node.ui, l, u));
    }
}

private:

enum Cmp
{
    Nothing = 0,
    Ne      = 1,
    Lt      = 2,
    Eq      = 4,
    Gt      = 8,

    LtEq    = Lt | Eq,
    GtEq    = Gt | Eq,
}

alias void delegate(char[], ...) OpErr;

Value binCmp(OpErr err, Value lhs, Value rhs, Cmp cmp)
{
    if( lhs.isReal && rhs.isReal )
    {
        auto l = lhs.asReal;
        auto r = rhs.asReal;

        Cmp act;
        act |= (l != r) ? Cmp.Ne : Cmp.Nothing;
        act |= (l < r)  ? Cmp.Lt : Cmp.Nothing;
        act |= (l == r) ? Cmp.Eq : Cmp.Nothing;
        act |= (l > r)  ? Cmp.Gt : Cmp.Nothing;

        return Value((act & cmp) != Cmp.Nothing);
    }
    else
        err("invalid types for comparison: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value binAdd(OpErr err, Value lhs, Value rhs)
{
    if( lhs.isReal && rhs.isReal )
        return Value(lhs.asReal + rhs.asReal);
    
    else
        err("invalid types for addition: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value binSub(OpErr err, Value lhs, Value rhs)
{
    if( lhs.isReal && rhs.isReal )
        return Value(lhs.asReal - rhs.asReal);
    
    else
        err("invalid types for subtraction: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value binMul(OpErr err, Value lhs, Value rhs)
{
    if( lhs.isReal && rhs.isReal )
        return Value(lhs.asReal * rhs.asReal);
    
    else
        err("invalid types for multiplication: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value binDiv(OpErr err, Value lhs, Value rhs)
{
    if( lhs.isReal && rhs.isReal )
        return Value(lhs.asReal / rhs.asReal);
    
    else
        err("invalid types for division: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value binIntDiv(OpErr err, Value lhs, Value rhs)
{
    if( lhs.isReal && rhs.isReal )
        return Value(floor(lhs.asReal / rhs.asReal));
    
    else
        err("invalid types for division: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value binExp(OpErr err, Value lhs, Value rhs)
{
    if( lhs.isReal && rhs.isReal )
        return Value(pow(lhs.asReal, rhs.asReal));
    
    else
        err("invalid types for exponentiation: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value binAnd(OpErr err, Value lhs, Value rhs)
{
    if( lhs.isLogical && rhs.isLogical )
        return Value(lhs.asLogical && rhs.asLogical);
    
    else
        err("invalid types for logical and: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value binOr(OpErr err, Value lhs, Value rhs)
{
    if( lhs.isLogical && rhs.isLogical )
        return Value(lhs.asLogical || rhs.asLogical);
    
    else
        err("invalid types for logical or: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value unPos(OpErr err, Value val)
{
    if( val.isReal )
        return val;

    else
        err("invalid type for ensure positive: {}", val.tagName);
}

Value unNeg(OpErr err, Value val)
{
    if( val.isReal )
        return Value(-val.asReal);

    else
        err("invalid type for negation: {}", val.tagName);
}

Value unNot(OpErr err, Value val)
{
    if( val.isLogical )
        return Value(!val.asLogical);

    else
        err("invalid type for logical not: {}", val.tagName);
}


/**
    Parser

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.Parser;

import eval.Ast;
import eval.Tokens;
import eval.TokenStream;
import eval.Util : parseReal, parseString;

AstScript parseScript(TokenStream ts)
{
    AstStmt[] stmts;

    skipEmptyStmts(ts);

    auto loc = ts.peek.loc;

    while( ts.peek.type != TOKnone )
    {
        stmts ~= parseStmt(ts);
        skipEmptyStmts(ts);
    }

    return new AstScript(loc, stmts);
}

void skipEmptyStmts(TokenStream ts)
{
    bool isEnd(TOK type)
    {
        return type == TOKeol || type == TOKeos;
    }

    while( isEnd(ts.peek.type) )
        ts.pop;
}

AstStmt parseStmt(TokenStream ts)
{
    skipEmptyStmts(ts);

    AstStmt stmt;

    stmt = tryparseLetStmt(ts);     if( stmt !is null ) goto gotStmt;

    // fallback
    stmt = parseExprStmt(ts);

gotStmt:
    return stmt;
}

AstLetStmt tryparseLetStmt(TokenStream ts)
{
    if( ts.peek.type != TOKlet ) return null;

    auto loc = ts.pop.loc;
    auto ident = ts.popExpect(TOKident).text;
    if( ts.peek.type == TOKlparen )
    {
        char[][] args;
        ts.popExpect(TOKlparen);
        if( ts.peek.type != TOKrparen )
            ts.skipEolDo
            ({
                while( ts.peek.type != TOKrparen )
                {
                    args ~= ts.popExpect(TOKident).text;
                    if( ts.popExpectAny(TOKcomma, TOKrparen)
                            .type == TOKrparen )
                        break;
                }
            });
        else
            ts.popExpect(TOKrparen);

        ts.popExpect(TOKeq);
        auto expr = parseExpr(ts);
        ts.popExpectAny(TOKeol, TOKeos);

        return new AstLetFuncStmt(loc, ident, args, expr);
    }
    else
    {
        ts.popExpect(TOKeq);
        auto expr = parseExpr(ts);
        ts.popExpectAny(TOKeol, TOKeos);

        return new AstLetVarStmt(loc, ident, expr);
    }
}

AstExprStmt parseExprStmt(TokenStream ts)
{
    auto loc = ts.peek.loc;
    auto expr = parseExpr(ts);
    ts.popExpectAny(TOKeol, TOKeos);

    return new AstExprStmt(loc, expr);
}

enum Fixity
{
    Left,
    Right,
}

Fixity fixityOf(AstBinaryExpr.Op op)
{
    alias AstBinaryExpr.Op Op;
    enum : Fixity { L = Fixity.Left, R = Fixity.Right }

    switch( op )
    {
        case Op.Or:         return L;
        case Op.And:        return L;
        case Op.Eq:         return L;
        case Op.NotEq:      return L;
        case Op.Lt:         return L;
        case Op.LtEq:       return L;
        case Op.Gt:         return L;
        case Op.GtEq:       return L;
        case Op.Add:        return L;
        case Op.Sub:        return L;
        case Op.Mul:        return L;
        case Op.Div:        return L;
        case Op.IntDiv:     return L;
        case Op.Mod:        return L;
        case Op.Rem:        return L;
        case Op.Exp:        return R;
        case Op.Comp:       return R;

        default:            assert(false, "missing binary op fixity");
    }
}

float precOf(AstBinaryExpr.Op op)
{
    alias AstBinaryExpr.Op Op;

    switch( op )
    {
        case Op.Or:         return 3.8;
        case Op.And:        return 3.9;
        case Op.Eq:         return 4.0;
        case Op.NotEq:      return 4.0;
        case Op.Lt:         return 4.0;
        case Op.LtEq:       return 4.0;
        case Op.Gt:         return 4.0;
        case Op.GtEq:       return 4.0;
        case Op.Add:        return 6.2;
        case Op.Sub:        return 6.2;
        case Op.Mul:        return 6.5;
        case Op.Div:        return 6.5;
        case Op.IntDiv:     return 6.5;
        case Op.Mod:        return 6.5;
        case Op.Rem:        return 6.5;
        case Op.Exp:        return 6.7;
        case Op.Comp:       return 9.0;

        default:            assert(false, "missing binary op precedence");
    }
}

struct ExprState
{
    struct Op
    {
        AstBinaryExpr.Op op;
        float prec;
    }

    AstExpr[] exprs;
    Op[] ops;

    void pushExpr(AstExpr expr)
    {
        exprs ~= expr;
    }

    void pushOp(AstBinaryExpr.Op binOp)
    {
        Op top;
        top.op = binOp;
        top.prec = precOf(binOp);

        while( ops.length > 0 && ops[$-1].prec > top.prec )
            crushTop;

        ops ~= top;
    }

    AstExpr force()
    {
        assert( exprs.length >= 1 );
        assert( ops.length == exprs.length-1 );

        while( ops.length > 0 )
            crushTop;

        assert( exprs.length == 1 );
        return exprs[0];
    }

    void crushTop()
    {
        assert( ops.length >= 1 );
        assert( exprs.length >= 2 );
        assert( ops.length == exprs.length-1 );

        auto prec = ops[$-1].prec;
        auto fix = fixityOf(ops[$-1].op);

        size_t i = ops.length-1;
        while( i>0 && ops[i-1].prec == prec )
            -- i;

        auto crushOps = ops[i..$];
        auto crushExprs = exprs[$-(crushOps.length+1)..$];

        ops = ops[0..$-crushOps.length];
        exprs = exprs[0..$-crushExprs.length+1];

        if( fix == Fixity.Left )
            exprs[$-1] = crushLTR(crushOps, crushExprs);
        else
            exprs[$-1] = crushRTL(crushOps, crushExprs);
    }

    AstExpr crushLTR(Op[] ops, AstExpr[] exprs)
    {
        assert( ops.length > 0 );
        assert( exprs.length == ops.length + 1 );

        AstExpr lhs = exprs[0];
        exprs = exprs[1..$];

        while( ops.length > 0 )
        {
            lhs = foldBinaryOp(ops[0].op, lhs, exprs[0]);
            ops = ops[1..$];
            exprs = exprs[1..$];
        }

        return lhs;
    }

    AstExpr crushRTL(Op[] ops, AstExpr[] exprs)
    {
        assert( ops.length > 0 );
        assert( exprs.length == ops.length + 1 );

        AstExpr rhs = exprs[$-1];
        exprs = exprs[0..$-1];

        while( ops.length > 0 )
        {
            rhs = foldBinaryOp(ops[$-1].op, exprs[$-1], rhs);
            ops = ops[0..$-1];
            exprs = exprs[0..$-1];
        }

        return rhs;
    }
}

AstExpr parseExpr(TokenStream ts)
{
    /*
    Every expression must begin with one of the following:

    - number literal
    - prefix op
    - function call
    - variable
    - uniform expression
    - subexpression
    */

    auto lhs = parseExprAtom(ts);

    if( lhs is null )
        ts.err(ts.src.loc, "expected expression, got '{}'", ts.peek.text);

    /*
    Now we need to parse the chain of infix operators.
    */
    AstBinaryExpr.Op op;
    if( tryparseBinaryOp(ts, op) )
    {
        ExprState st;
        st.pushExpr(lhs);
        st.pushOp(op);

        while( true )
        {
            st.pushExpr(parseExprAtom(ts));

            if( tryparseBinaryOp(ts, op) )
                st.pushOp(op);
            else
                break;
        }

        return st.force;
    }
    else
        // No infix chain
        return lhs;
}

AstExpr tryparseExprAtom(TokenStream ts)
{
    if( auto e = tryparseFunctionExpr(ts) ) return e;
    if( auto e = tryparseNumberExpr(ts) )   return e;
    if( auto e = tryparseStringExpr(ts) )   return e;
    if( auto e = tryparseLambdaExpr(ts) )   return e;
    if( auto e = tryparseUnaryExpr(ts) )    return e;
    if( auto e = tryparseUniformExpr(ts) )  return e;
    return null;
}

AstExpr parseExprAtom(TokenStream ts)
{
    auto expr = tryparseExprAtom(ts);
    if( expr is null )
        ts.err(ts.src.loc, "expected expression, got '{}'", ts.peek.text);
    return expr;
}

AstExpr tryparseNumberExpr(TokenStream ts)
{
    if( ts.peek.type != TOKnumber ) return null;

    auto loc = ts.peek.loc;
    real value = parseReal(ts.popExpect(TOKnumber).text);
    auto expr = new AstNumberExpr(loc, value);

    if( auto func = tryparseFunctionExpr(ts) )
        return new AstBinaryExpr(loc, AstBinaryExpr.Op.Mul, expr, func);
    else if( auto var = tryparseVariableExpr(ts) )
        return new AstBinaryExpr(loc, AstBinaryExpr.Op.Mul, expr, var);
    else
        return expr;
}

AstExpr tryparseStringExpr(TokenStream ts)
{
    if( ts.peek.type != TOKstring ) return null;

    auto loc = ts.peek.loc;
    char[] value = parseString(ts.popExpect(TOKstring).text);
    return new AstStringExpr(loc, value);
}

AstLambdaExpr tryparseLambdaExpr(TokenStream ts)
{
    if( ts.peek.type != TOKbslash ) return null;

    auto loc = ts.popExpect(TOKbslash).loc;
    char[][] args;
    if( ts.peek.type == TOKident )
    {
        args ~= ts.popExpect(TOKident).text;
        while( ts.peek.type == TOKcomma )
        {
            ts.popExpect(TOKcomma);
            args ~= ts.popExpect(TOKident).text;
        }
    }
    ts.popExpect(TOKcolon);

    auto expr = parseExpr(ts);
    return new AstLambdaExpr(loc, args, expr);
}

AstVariableExpr tryparseVariableExpr(TokenStream ts)
{
    if( ts.peek.type != TOKident ) return null;

    auto loc = ts.peek.loc;
    char[] ident = ts.pop.text;
    return new AstVariableExpr(loc, ident);
}

AstExpr tryparseFunctionExpr(TokenStream ts)
{
    AstExpr baseExpr;

    if( auto varExpr = tryparseVariableExpr(ts) )
        baseExpr = varExpr;
    else if( auto subExpr = tryparseSubExpr(ts) )
        baseExpr = subExpr;
    else
        return null;

    while( ts.peek.type == TOKlparen )
    {
        auto loc = baseExpr.loc;
        ts.popExpect(TOKlparen);

        AstExpr[] args;

        if( ts.peek.type != TOKrparen )
            ts.skipEolDo
            ({
                while( true )
                {
                    args ~= parseExpr(ts);
                    if( ts.popExpectAny(TOKrparen, TOKcomma).type == TOKrparen )
                        break;
                }
            });
        else
            ts.popExpect(TOKrparen);

        baseExpr = new AstCallExpr(loc, baseExpr, args);
    }
    return baseExpr;
}

AstExpr tryparseUnaryExpr(TokenStream ts)
{
    alias AstUnaryExpr.Op Op;
    auto t = ts.peek;
    
    Op op;
    switch( t.type )
    {
        case TOKplus:       op = Op.Pos;    break;
        case TOKhyphen:     op = Op.Neg;    break;
        case TOKnot:        op = Op.Not;    break;

        default:            return null;
    }

    auto loc = ts.pop.loc;
    auto expr = parseExprAtom(ts);

    // Simplify
    switch( op )
    {
        case Op.Pos:
            if( auto ne = cast(AstNumberExpr) expr )
                return ne;
            break;

        case Op.Neg:
            if( auto ne = cast(AstNumberExpr) expr )
                return new AstNumberExpr(ne.loc, -ne.value);
            break;

        default:
    }

    return new AstUnaryExpr(loc, op, expr);
}

bool tryparseBinaryOp(TokenStream ts, out AstBinaryExpr.Op op)
{
    alias AstBinaryExpr.Op Op;
    auto t = ts.peek;

    switch( t.type )
    {
        case TOKeq:         op = Op.Eq;     break;
        case TOKslasheq:
        case TOKnoteq:
        case TOKltgt:       op = Op.NotEq;  break;
        case TOKlt:         op = Op.Lt;     break;
        case TOKlteq:       op = Op.LtEq;   break;
        case TOKgt:         op = Op.Gt;     break;
        case TOKgteq:       op = Op.GtEq;   break;
        case TOKplus:       op = Op.Add;    break;
        case TOKhyphen:     op = Op.Sub;    break;
        case TOKstar:       op = Op.Mul;    break;
        case TOKslash:      op = Op.Div;    break;
        case TOKslashslash: op = Op.IntDiv; break;
        case TOKmod:        op = Op.Mod;    break;
        case TOKrem:        op = Op.Rem;    break;
        case TOKstarstar:   op = Op.Exp;    break;
        case TOKand:        op = Op.And;    break;
        case TOKor:         op = Op.Or;     break;
        case TOKperiod:     op = Op.Comp;   break;

        default:            return false;
    }

    ts.pop;
    return true;
}

AstUniformExpr tryparseUniformExpr(TokenStream ts)
{
    if( ts.peek.type != TOKuniform ) return null;

    auto loc = ts.pop.loc;
    AstExpr le, ue;
    bool li, ui;

    li = (ts.popExpectAny(TOKlparen,TOKlbracket).type == TOKlbracket);
    le = parseExpr(ts);
    ts.popExpect(TOKcomma);
    ue = parseExpr(ts);
    ui = (ts.popExpectAny(TOKrparen,TOKrbracket).type == TOKrbracket);

    return new AstUniformExpr(loc, li, ui, le, ue);
}

AstExpr tryparseSubExpr(TokenStream ts)
{
    if( ts.peek.type != TOKlparen ) return null;

    AstExpr expr;
    ts.skipEolDo
    ({
        ts.pop();
        expr = parseExpr(ts);
        ts.popExpect(TOKrparen);
    });
    return expr;
}

AstExpr foldBinaryOp(AstBinaryExpr.Op op, AstExpr lhs, AstExpr rhs)
{
    alias AstBinaryExpr.Op Op;

    if( auto lhsBin = cast(AstBinaryExpr) lhs )
    {
        if( ( (lhsBin.op == Op.Lt || lhsBin.op == Op.LtEq)
                  && (op == Op.Lt || op == Op.LtEq) )
            ||
            ( (lhsBin.op == Op.Gt || lhsBin.op == Op.GtEq)
                  && (op == Op.Gt || op == Op.GtEq) )
          )
        {
            auto mid = sharedExpr(lhsBin.rhs);
            return new AstBinaryExpr(lhs.loc, Op.And,
                    new AstBinaryExpr(lhs.loc, lhsBin.op, lhsBin.lhs, mid),
                    new AstBinaryExpr(lhs.loc, op, mid, rhs));;
        }
    }
    else if( auto rhsBin = cast(AstBinaryExpr) rhs )
    {
        if( ( (rhsBin.op == Op.Lt || rhsBin.op == Op.LtEq)
                  && (op == Op.Lt || op == Op.LtEq) )
            ||
            ( (rhsBin.op == Op.Gt || rhsBin.op == Op.GtEq)
                  && (op == Op.Gt || op == Op.GtEq) )
          )
        {
            auto mid = sharedExpr(rhsBin.lhs);
            return new AstBinaryExpr(lhs.loc, Op.And,
                    new AstBinaryExpr(lhs.loc, op, lhs, mid),
                    new AstBinaryExpr(lhs.loc, rhsBin.op, mid, rhsBin.rhs));
        }
    }
    
    return new AstBinaryExpr(lhs.loc, op, lhs, rhs);
}

/*
    Turns expr into a shared expression if it's worth doing so.
*/
AstExpr sharedExpr(AstExpr expr)
{
    if( cast(AstNumberExpr) expr )
        return expr;

    if( cast(AstVariableExpr) expr )
        return expr;

    return new AstSharedExpr(expr.loc, expr);
}


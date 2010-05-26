module eval.Parser;

import Float = tango.text.convert.Float;
import eval.Ast;
import eval.Tokens;
import eval.TokenStream;

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
    ts.popExpect(TOKeq);
    auto expr = parseExpr(ts);
    ts.popExpectAny(TOKeol, TOKeos);

    return new AstLetStmt(loc, ident, expr);
}

AstExprStmt parseExprStmt(TokenStream ts)
{
    auto loc = ts.peek.loc;
    auto expr = parseExpr(ts);
    ts.popExpectAny(TOKeol, TOKeos);

    return new AstExprStmt(loc, expr);
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
        case Op.Exp:        return 6.7;

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
            crushRTL;

        ops ~= top;
    }

    AstExpr force()
    {
        assert( exprs.length >= 1 );
        assert( ops.length == exprs.length-1 );

        while( ops.length > 0 )
            crushRTL;

        assert( exprs.length == 1 );
        return exprs[0];
    }

    void crushLTR()
    {
        assert( ops.length >= 1 );
        assert( exprs.length >= 2 );
        assert( ops.length == exprs.length-1 );

        auto op = ops[0];
        ops = ops[1..$];

        auto lhs = exprs[0];
        auto rhs = exprs[1];
        exprs = exprs[1..$]; // drop 2, prepend 1

        exprs[0] = foldBinaryOp(op.op, lhs, rhs);
    }

    void crushRTL()
    {
        assert( ops.length >= 1 );
        assert( exprs.length >= 2 );
        assert( ops.length == exprs.length-1 );

        auto op = ops[$-1];
        ops = ops[0..$-1];

        auto lhs = exprs[$-2];
        auto rhs = exprs[$-1];
        exprs = exprs[0..$-1]; // pop 2, push 1

        exprs[$-1] = foldBinaryOp(op.op, lhs, rhs);
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

    AstExpr tryparseAtom()
    {
        if( auto e = tryparseNumberExpr(ts) )   return e;
        if( auto e = tryparseUnaryExpr(ts) )    return e;
        if( auto e = tryparseFunctionExpr(ts) ) return e;
        if( auto e = tryparseVariableExpr(ts) ) return e;
        if( auto e = tryparseUniformExpr(ts) )  return e;
        if( auto e = tryparseSubExpr(ts) )      return e;
        return null;
    }

    AstExpr parseAtom()
    {
        auto expr = tryparseAtom();
        if( expr is null )
            ts.err(ts.src.loc, "expected expression, got '{}'", ts.peek.text);
        return expr;
    }

    auto lhs = parseAtom();

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
            st.pushExpr(parseAtom());

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

AstExpr tryparseNumberExpr(TokenStream ts)
{
    if( ts.peek.type != TOKnumber ) return null;

    auto loc = ts.peek.loc;
    real value = parseReal(ts);
    auto expr = new AstNumberExpr(loc, value);

    if( auto var = tryparseVariableExpr(ts) )
        return new AstBinaryExpr(loc, AstBinaryExpr.Op.Mul, expr, var);
    else
        return expr;
}

AstVariableExpr tryparseVariableExpr(TokenStream ts)
{
    if( ts.peek.type != TOKident ) return null;

    auto loc = ts.peek.loc;
    char[] ident = ts.pop.text;
    return new AstVariableExpr(loc, ident);
}

AstFunctionExpr tryparseFunctionExpr(TokenStream ts)
{
    if( ts.peek(0).type != TOKident ) return null;
    if( ts.peek(1).type != TOKlparen ) return null;

    auto loc = ts.peek.loc;
    auto ident = ts.pop.text;
    ts.pop;

    AstExpr[] args;

    if( ts.peek.type != TOKrparen )
    while( true )
    {
        args ~= parseExpr(ts);
        if( ts.popExpectAny(TOKrparen, TOKcomma).type == TOKrparen )
            break;
        ts.pop;
    }

    ts.pop;

    return new AstFunctionExpr(loc, ident, args);
}

AstUnaryExpr tryparseUnaryExpr(TokenStream ts)
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
    auto expr = parseExpr(ts);

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
        case TOKstarstar:   op = Op.Exp;    break;
        case TOKand:        op = Op.And;    break;
        case TOKor:         op = Op.Or;     break;

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

real parseReal(TokenStream ts)
{
    auto t = ts.popExpect(TOKnumber);
    return Float.parse(t.text);
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
            return new AstBinaryExpr(lhs.loc, Op.And,
                    lhs,
                    new AstBinaryExpr(lhs.loc, op, lhsBin.rhs, rhs));;
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
            return new AstBinaryExpr(lhs.loc, Op.And,
                    new AstBinaryExpr(lhs.loc, op, lhs, rhsBin.lhs),
                    rhs);
        }
    }
    
    return new AstBinaryExpr(lhs.loc, op, lhs, rhs);
}


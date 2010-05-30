/**
    AST Evaluation Visitor.

    This will recursively evaluate the provided AST.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.AstEvalVisitor;

import eval.Ast;
import eval.Location;
import eval.Statistical : uniformReal;
import eval.Value;
import eval.Variables;

import tango.math.Math : floor, pow, trunc;
import tango.text.convert.Format;

class AstEvalVisitor
{
    LocErr err;
    Variables vars;

    this(LocErr err, Variables vars)
    {
        this.err = err;
        this.vars = vars;
    }

    Value visitBase(AstNode node)
    {
        if( auto stn = cast(AstScript) node )
            return visit(stn);
        if( auto stn = cast(AstLetVarStmt) node )
            return visit(stn);
        if( auto stn = cast(AstLetFuncStmt) node )
            return visit(stn);
        if( auto stn = cast(AstExprStmt) node )
            return visit(stn);
        if( auto stn = cast(AstNumberExpr) node )
            return visit(stn);
        if( auto stn = cast(AstStringExpr) node )
            return visit(stn);
        if( auto stn = cast(AstLambdaExpr) node )
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
        if( auto stn = cast(AstSharedExpr) node )
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

    Value visit(AstLetVarStmt node)
    {
        if( ! vars.define(node.ident, visitBase(node.expr)) )
            err(node.loc, "cannot redefine '{}'", node.ident);

        return Value();
    }

    Value visit(AstLetFuncStmt node)
    {
        auto fv = new FunctionValue;
        fv.args.length = node.args.length;
        foreach( i, name ; node.args )
            fv.args[i].name = name;
        fv.expr = node.expr;

        if( ! vars.define(node.ident, Value(fv)) )
            err(node.loc, "cannot redefine '{}'", node.ident);

        return Value();
    }

    Value visit(AstExprStmt node)
    {
        sharedCache = null;
        return visitBase(node.expr);
    }

    Value visit(AstNumberExpr node)
    {
        return Value(node.value);
    }

    Value visit(AstStringExpr node)
    {
        return Value(node.value);
    }

    Value visit(AstLambdaExpr node)
    {
        auto fv = new FunctionValue;
        fv.args.length = node.args.length;
        foreach( i, name ; node.args )
            fv.args[i].name = name;
        fv.expr = node.expr;
        return Value(fv);
    }

    Value visit(AstBinaryExpr node)
    {
        Value lhs() { return visitBase(node.lhs); }
        Value rhs() { return visitBase(node.rhs); }
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
            case Op.Mod:    return binMod(&opErr, lhs, rhs);
            case Op.Rem:    return binRem(&opErr, lhs, rhs);
            case Op.Exp:    return binExp(&opErr, lhs, rhs);
            case Op.And:    return binAnd(&opErr, lhs, &rhs);
            case Op.Or:     return binOr(&opErr, lhs, &rhs);
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
        if( ! vars.resolve(node.ident, r) )
            err(node.loc, "unknown variable '{}'", node.ident);
        return r;
    }

    Value visit(AstFunctionExpr node)
    {
        void fnErr(char[] fmt, ...)
        {
            err(node.loc, "{}", Format.convert(_arguments, _argptr, fmt));
        }

        Value getArg(size_t i)
        {
            return visitBase(node.args[i]);
        }

        Value fnVar;
        if( ! vars.resolve(node.ident, fnVar) )
            err(node.loc, "unknown function '{}'", node.ident);

        if( ! fnVar.isFunction )
            err(node.loc, "expected function, got {}", fnVar.tagName);

        auto fv = fnVar.asFunction;
        Value r;

        if( fv.nativeFn !is null )
            r = fv.nativeFn(&fnErr, node.args.length, &getArg);
        else
        {
            assert( fv.expr !is null );

            if( node.args.length != fv.args.length )
                err(node.loc, "{}: expected {} argument{}, got {}",
                        node.ident, fv.args.length,
                        (fv.args.length == 1) ? "" : "s",
                        node.args.length);

            scope locals = new LocalVariables(this, vars);

            foreach( i, arg ; fv.args )
                locals.vars[arg.name] = node.args[i];

            auto oldVars = vars;
            vars = locals;
            scope(exit) vars = oldVars;

            r = visitBase(fv.expr);
        }

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

    Value[AstSharedExpr] sharedCache;

    Value visit(AstSharedExpr node)
    {
        if( auto v = node in sharedCache )
            return *v;
        else
        {
            auto v = visitBase(node.expr);
            sharedCache[node] = v;
            return v;
        }
    }
}

private:

class LocalVariables : Variables
{
    Variables next;
    AstEvalVisitor eval;
    AstExpr[char[]] vars;
    Value[char[]] vals;

    this(AstEvalVisitor eval, Variables next = null)
    {
        this.eval = eval;
        this.next = next;
    }

    bool resolve(char[] ident, out Value value)
    {
        auto ptr = ident in vars;
        if( ptr !is null )
        {
            if( auto vptr = ident in vals )
                value = *vptr;
            else
            {
                value = eval.visitBase(*ptr);
                vals[ident] = value;
            }
            return true;
        }
        else
            return nextResolve(ident, value);
    }

    bool define(char[] ident, ref Value value)
    {
        if( ident in vars )
            return false;

        return nextDefine(ident, value);
    }

    int iterate(int delegate(ref char[], ref Value) dg)
    {
        char[][] names = vars.keys;
        names.sort;

        int r = 0;
        foreach( nextName, nextValue ; &nextIterate )
        {
            char[] name;
            Value value;

            while( names.length > 0 && names[0] < nextName )
            {
                name = names[0];
                if( auto vptr = name in vals )
                    value = *vptr;
                else
                {
                    value = eval.visitBase(vars[name]);
                    vals[name] = value;
                }
                names = names[1..$];
                r = dg(name, value);
                if( r != 0 )
                    return r;
            }

            name = nextName;
            value = nextValue;

            r = dg(name, value);
            if( r != 0 )
                return r;
        }

        foreach( name ; names )
        {
            auto tmpN = name;
            Value tmpV;
            if( auto vptr = name in vals )
                tmpV = *vptr;
            else
            {
                tmpV = eval.visitBase(vars[name]);
                vals[name] = tmpV;
            }
            r = dg(tmpN, tmpV);
            if( r != 0 )
                return r;
        }

        return r;
    }

    bool nextResolve(char[] ident, out Value value)
    {
        if( next !is null )
            return next.resolve(ident, value);
        return false;
    }

    bool nextDefine(char[] ident, ref Value value)
    {
        if( next !is null )
            return next.define(ident, value);
        return false;
    }

    int nextIterate(int delegate(ref char[], ref Value) dg)
    {
        if( next !is null )
            return next.iterate(dg);

        return 0;
    }
}

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
    else if( lhs.isString && rhs.isString )
    {
        auto l = lhs.asString;
        auto r = rhs.asString;

        // TODO: more efficient comparison
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
    {
        auto l = lhs.asReal;
        auto r = rhs.asReal;
        auto l_div_r = l/r;
        auto l_intdiv_r = floor(l_div_r);
        return Value(l_intdiv_r);
    }
    
    else
        err("invalid types for division: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value binMod(OpErr err, Value lhs, Value rhs)
{
    if( lhs.isReal && rhs.isReal )
    {
        auto a = lhs.asReal;
        auto b = rhs.asReal;
        return Value(a-b*floor(a/b));
    }
    else
        err("invalid types for modulus: {} and {}",
                lhs.tagName, rhs.tagName);
}

Value binRem(OpErr err, Value lhs, Value rhs)
{
    if( lhs.isReal && rhs.isReal )
    {
        auto a = lhs.asReal;
        auto b = rhs.asReal;
        return Value(a-b*trunc(a/b));
    }
    else
        err("invalid types for remainder: {} and {}",
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

Value binAnd(OpErr err, Value lhs, Value delegate() rhsDg)
{
    if( lhs.isLogical )
    {
        auto l = lhs.asLogical;
        if( !l ) return Value(false);

        auto rhs = rhsDg();
        if( !rhs.isLogical )
            err("invalid right-hand type for logical and: {}", rhs.tagName);

        return Value(rhs.asLogical);
    }
    else
        err("invalid left-hand type for logical and: {}", lhs.tagName);
}

Value binOr(OpErr err, Value lhs, Value delegate() rhsDg)
{
    if( lhs.isLogical )
    {
        auto l = lhs.asLogical;
        if( l ) return Value(true);

        auto rhs = rhsDg();
        if( !rhs.isLogical )
            err("invalid right-hand type for logical or: {}", rhs.tagName);

        return Value(rhs.asLogical);
    }
    else
        err("invalid left-hand type for logical or: {}", lhs.tagName);
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


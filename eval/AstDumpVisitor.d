/**
    AST Dump Visitor.

    This will print the AST as a nested S-expression.

    Authors: Daniel Keep <daniel.keep@gmail.com>
    Copyright: See LICENSE.
*/
module eval.AstDumpVisitor;

import eval.Ast;
import eval.StructuredOutput;
import eval.Util : toStringLiteral;

class AstDumpVisitor
{
    StructuredOutput so;

    this(StructuredOutput so)
    {
        this.so = so;
    }

    void visitBase(AstNode node)
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

    void defaultVisit(AstNode node)
    {
        assert(false, "missing visit for "~node.classinfo.name);
    }

    void visit(AstScript node)
    {
        so
            .push("(script")
            .seq(
            {
                foreach( stmt ; node.stmts )
                    visitBase(stmt);
            })
            .pl(")")
            .pop
        ;
    }

    void visit(AstLetVarStmt node)
    {
        so
            .fl("(let-var {}", node.ident)
            .push
            .seq(
            {
                visitBase(node.expr);
            })
            .pl(")")
            .pop
        ;
    }

    void visit(AstLetFuncStmt node)
    {
        so
            .f("(let-func {} (", node.ident)
            .seq
            ({
                if( node.args.length > 0 )
                {
                    auto sep = ""[];
                    foreach( arg ; node.args )
                    {
                        so.f("{}{}", sep, arg);
                        sep = " ";
                    }
                }
            })
            .pl(")")
            .push
            .seq(
            {
                visitBase(node.expr);
            })
            .pl(")")
            .pop
        ;
    }

    void visit(AstExprStmt node)
    {
        so
            .push("(expr")
            .seq(
            {
                visitBase(node.expr);
            })
            .pl(")")
            .pop
        ;
    }

    void visit(AstNumberExpr node)
    {
        so.f("{}", node.value);
    }

    void visit(AstStringExpr node)
    {
        so.f("{}", toStringLiteral(node.value));
    }

    void visit(AstLambdaExpr node)
    {
        so
            .p("(lambda (")
            .seq
            ({
                so.p(node.args[0]);
                foreach( arg ; node.args )
                    so.p(" ").p(arg);
            })
            .p(")")
            .push
            .seq({ visitBase(node.expr); })
            .pop
        ;
    }

    void visit(AstBinaryExpr node)
    {
        so
            .fl("(binary {}", AstBinaryExpr.opToString(node.op))
            .push
            .seq(
            {
                visitBase(node.lhs);
                so.l;
                visitBase(node.rhs);
            })
            .pl(")")
            .pop
        ;
    }

    void visit(AstUnaryExpr node)
    {
        so.f("(unary {} ", AstUnaryExpr.opToString(node.op))
            .seq({ visitBase(node.expr); }).p(")");
    }

    void visit(AstVariableExpr node)
    {
        so.p(node.ident);
    }

    void visit(AstFunctionExpr node)
    {
        so
            .fl("(call {}", node.ident)
            .push
            .seq(
            {
                if( node.args.length > 0 )
                {
                    foreach( arg ; node.args[0..$-1] )
                    {
                        visitBase(arg);
                        so.l();
                    }
                    visitBase(node.args[$-1]);
                }
            })
            .pl(")")
            .pop
        ;
    }

    void visit(AstUniformExpr node)
    {
        so
            .pl("(uniform")
            .push
            .f("{} ", node.li ? "inclusive" : "exclusive")
            .seq({ visitBase(node.le); }).l()
            .f("{} ", node.ui ? "inclusive" : "exclusive")
            .seq({ visitBase(node.ue); })
            .pl(")")
            .pop
        ;
    }

    void visit(AstSharedExpr node)
    {
        so
            .fl("(shared 0x{:x,8}", cast(void*) node)
            .push
            .seq({ visitBase(node.expr); })
            .pl(")")
            .pop
        ;
    }
}


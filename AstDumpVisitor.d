module AstDumpVisitor;

import Ast;
import VisitorCtfe;
import StructuredOutput;

class AstDumpVisitor
{
    StructuredOutput so;

    this(StructuredOutput so)
    {
        this.so = so;
    }

    mixin(visitorDispatch_ctfe("AstNode", AstNodeNames, "void"));

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

    void visit(AstLetStmt node)
    {
        so
            .fl("(let {}", node.ident)
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

    void visit(AstUniformExpr node)
    {
        so.f("(uniform {} {} {} {})",
                node.li, node.l, node.u, node.ui);
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
                foreach( arg ; node.args[0..$-1] )
                {
                    visitBase(arg);
                    so.l();
                }
                visitBase(node.args[$-1]);
            })
            .pl(")")
            .pop
        ;
    }
}


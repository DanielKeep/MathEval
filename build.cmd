@ECHO OFF
call dmdenv 1.057-tango-0.99.9
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/LexerTest.deps +O.xf/LexerTest.objs +oLexerTest LexerTest.d
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/AstTest.deps +O.xf/AstTest.objs +oAstTest AstTest.d
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/EvalTest.deps +O.xf/EvalTest.objs +oEvalTest EvalTest.d
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/ReplTest.deps +O.xf/ReplTest.objs +oReplTest ReplTest.d

call dmdenv 1.057-tango-0.99.9
xfbuild -g -debug -unittest -version=Unittest +D.xf/LexerTest.deps +O.xf/LexerTest.objs +oLexerTest LexerTest.d
xfbuild -g -debug -unittest -version=Unittest +D.xf/AstTest.deps +O.xf/AstTest.objs +oAstTest AstTest.d

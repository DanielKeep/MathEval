@ECHO OFF
call dmdenv 1.057-tango-0.99.9
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/Cli.deps +O.xf/Cli.objs +oMathEval -version=MathEval_Lists Cli.d
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/Cli-lists.deps +O.xf/Cli-lists.objs +oMathEval-lists Cli.d

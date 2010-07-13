@ECHO OFF
call dmdenv 1.057-tango-0.99.9
xfbuild -g -debug +xtango +D.xf/GitVerGen.deps +O.xf/GitVerGen.objs +oGitVerGen GitVerGen.d
GitVerGen
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/Cli.deps +O.xf/Cli.objs +oMathEval -J. -version=MathEval_Lists -version=MathEval_Units Cli.d

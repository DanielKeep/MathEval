@ECHO OFF
call build.cmd
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/Cli-units.deps +O.xf/Cli-units.objs +oMathEval-units -J. -version=MathEval_Lists Cli.d
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/Cli-lists.deps +O.xf/Cli-lists.objs +oMathEval-lists -J. -version=MathEval_Units Cli.d
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/Cli-lists-units.deps +O.xf/Cli-lists-units.objs +oMathEval-lists-units -J. Cli.d

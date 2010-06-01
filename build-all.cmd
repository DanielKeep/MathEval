@ECHO OFF
call build.cmd
xfbuild -g -debug -unittest -version=Unittest +xtango +D.xf/Cli-lists.deps +O.xf/Cli-lists.objs +oMathEval-lists -J. Cli.d

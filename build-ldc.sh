#!/bin/bash

xfbuild +cldc -d-debug +xtango +D.xf/GitVerGen.deps +O.xf/GitVerGen.objs +oGitVerGen GitVerGen.d
./GitVerGen
xfbuild +cldc -d-debug -unittest -d-version=Unittest +xtango +D.xf/Cli.deps +O.xf/Cli.objs +oMathEval -J=. -d-version=MathEval_Lists -d-version=MathEval_Units Cli.d


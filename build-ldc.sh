#!/bin/bash

xfbuild +cldc -d-debug -unittest -d-version=Unittest +xtango +D.xf/Cli.deps +O.xf/Cli.objs +oMathEval -d-version=MathEval_Lists Cli.d



=========
Math Eval
=========

:author: Daniel Keep <daniel.keep@gmail.com>

.. contents::

The REPL
========

REPL stands for "Read, Evaluate, Print, Loop" and is used to describe programs
that read some input, evaluate it, display the result and then repeat.

The math eval REPL does exactly this: it reads a line of input from you,
evaluates it, displays the result (if any) to you and then repeats.

To start the REPL, execute the ``MathEval`` program.

The REPL has a few differences from other methods of invoking math eval.
Firstly, there are a few commands it handles itself.  The two most important
of these are ``.quit`` which exits the REPL and ``.help`` which displays a
list of all the commands it understands.

.. note::

    You can also use ``.q`` or ``.h`` in place of ``.quit`` and ``.help``.

Secondly, the REPL allows you to re-define variables; you cannot normally do
this.

Thirdly, the REPL does not support sub-expression line continuations.  This
will be explained later; suffice to say that each line must contain a complete
statement or expression.

The Language
============

The language math eval understands is relatively simple.  It is line-oriented,
meaning that each line must contain a complete statement (although there is an
exception to this).

Math eval understands the following kinds of statements:

* Empty statements - these are lines which have nothing except whitespace on
  them.

* Expression statements - this is simply an expression by itself; see
  `Expressions`_.

* `Let statements`_ - these are used to define variables.

Expressions
-----------

Expressions in math eval are built out of the following constructs:

* `Number Expressions`_,
* `Sub-Expressions`_,
* `Binary Expressions`_,
* `Unary Expressions`_,
* `Function Expressions`_,
* `Variable Expressions`_ and
* `Uniform Expressions`_.

Number Expressions
``````````````````

These are simply literal numbers.  For example, the following are all valid
numbers::

    1
    2.3
    .45
    67.

Additionally, you may use underscores (\ ``_``\ ) anywhere where a digit would
be valid and will be ignored.  They are included to allow you to more easily
write large numbers.  For example, one could write π as::

    3.141_592_653_589_793_238

Numbers can also have trailing exponents, like so::

    4.3657e-7
    9.7812e+9

Note that the exponent sign is optional.

Finally, it is worth noting that, depending on your platform, numbers will
internally represented with (roughly) at least 16 decimal digits of precision;
possibly as many as 20 decimal digits.

Sub-Expressions
```````````````

You can represent sub-expressions using parentheses.  For example::

    (1+2)*3

These are used to force a specific order of evaluation.

Sub-Expressions also suppress math eval's line-oriented nature.  Whilst inside
a sub-expression, line endings will be ignored.  For example, this::

    1 + 2 * 3

Could be rewritten as::

    1 + (2
        * 3)

Or::

    (1 +
        2*3)

Note that this does not apply in the REPL.

Binary Expressions
``````````````````

Math eval supports the standard notation for infix binary operations.  For
example::

    1 + 2*3

For a complete list of binary operators, see `Binary Operators`_.

Unary Expressions
`````````````````

Unary expressions are those where the operator immediately precedes its
argument.  For example::

    -(3*5)

For a complete list of unary operators, see `Unary Operators`_.

Function Expressions
````````````````````

Functions in math eval can be invoked using standard mathematical notation.
For example, to compute the sine of 1.6::

    sin(1.6)

If a function accepts multiple arguments, each argument is separated by a
comma.  For example::

    min(1.4, 7.3)

For a complete list of supported functions, see `Functions`_.

Variable Expressions
````````````````````

Variables are used simply by naming them.  For example, to compute π
multiplied by five::

    5*pi

Note that the specific case of a number literal being multiplied by a variable
can be simplified by removing the multiplication symbol.  For example, the
above could also be written::

    5pi

This cannot be used in any other circumstances; for instance, none of the
following are valid::

    5(pi+1)
    (2+3)pi
    (2+3)(pi+1)

For a list of pre-defined constants, see `Constants`_.  You can also define
your own variables; see `Let statements`_.

Uniform Expressions
```````````````````

In order to allow you to succinctly sample uniform distributions, math eval
supports a special syntax for them.  For example, to sample a real number
between 0 and 1::

    uniform [0, 1]

You can use any combination of ``[``, ``(``, ``]`` and ``)`` to represent
ranges which are closed/open on either end.  Some examples::

    uniform(0,1)
    uniform[0,10)

Let statements
--------------

A ``let`` statement allows you to define your own variables.  For example, if
you wanted to compute the area of a circle with radius 3.5, you could write::

    let r = 3.5
    let area = pi*r**2

Variable names can contain letters and underscores.  They can also contain
digits and primes (\ ``'``\ ) but cannot *start* with them.  For example::

    let a = 42
    let a' = 1/a

Note that you cannot re-define variables once defined.

Unary Operators
===============

All unary operators have, in effect, infinite precedence; this means that they
are applied to the smallest possible expression immediately following them.
Another way of putting it: they are always evaluated before any binary
operators.

======= ===========================
Symbol  Meaning
======= ===========================
``+``   Positive [*]_
``-``   Negation
``not`` Logical negation
======= ===========================

.. [*] This operator exists both to provide symmetry with ``-`` and to
       allow for positive number literals to be written with a leading ``+``.

Binary Operators
================

Operator precedence is expressed as a decimal number.  Operators are evaluated
before other operators with lower precedence.  For example, addition and
multiplication have precedences of 6.2 and 6.5 respectively; multiplication is
always evaluated before addition.

Also of note is the associativity (or fixity) of the operators.  This
determines whether they are left-associative or right-associative.  For
example, assuming a generic operator ∗:

=================== =================== ===================
Expression          Left-Associative    Right-Associative
=================== =================== ===================
*a* ∗ *b* ∗ *c*     (*a* ∗ *b*) ∗ *c*   *a* ∗ (*b* ∗ *c*)
=================== =================== ===================

Algebraic
---------

======= =========================== ======= ======= ===============
Symbol  Meaning                     Prec.   Assoc.  Alternatives
======= =========================== ======= ======= ===============
``**``  Exponentiation              6.7     right
``*``   Multiplication              6.5     left
``/``   Division                    6.5     left
``//``  Integer division [*]_       6.5     left
``+``   Addition                    6.2     left
``-``   Subtraction                 6.2     left
======= =========================== ======= ======= ===============

.. [*]  *x* // *y* is effectively *floor*\ (\ *x* ÷ *y*\ )

Comparative
-----------

======= =========================== ======= ======= ===============
Symbol  Meaning                     Prec.   Assoc.  Alternatives
======= =========================== ======= ======= ===============
``=``   Equality                    4.0     right
``<>``  Inequality                  4.0     left    ``!=`` ``/=``
``<``   Less-than                   4.0     left
``<=``  Less-than or equal-to       4.0     left
``>=``  Greater-than or equal-to    4.0     left
``>``   Greater-than                4.0     left
======= =========================== ======= ======= ===============

.. note::

    The ``<``, ``<=``, ``>=`` and ``>`` operators support "ternary
    form".  That is, you can rewrite the following expression::

        a <= x and x < b

    as::

        a <= x < b

    Note that for this to work, both comparison operators must be "pointing"
    in the same direction.  That is, you can mix ``<`` and ``<=`` or
    ``>`` and ``>=``, but you cannot mix ``<`` and ``>``.

Logical
-------

======= =========================== ======= ======= ===============
Symbol  Meaning                     Prec.   Assoc.  Alternatives
======= =========================== ======= ======= ===============
``and`` Logical conjunction         3.9     left
``or``  Logical disjunction         3.8     left
======= =========================== ======= ======= ===============

Constants
=========

The following constants are pre-defined for you.

=============== ======================= ================================
Name            Meaning                 Value (to 19 decimal digits)
=============== ======================= ================================
``e``           Euler's number          2.718,281,828,459,045,235
``pi``, ``π``   Pi                      3.141,592,653,589,793,238
``phi``, ``φ``  Golden ratio            1.618,033,988,749,894,848
``true``        Tautology               ⊤
``false``       Contradiction           ⊥
=============== ======================= ================================

Functions
=========

Functions are defined using the following placeholder variables:

* ``a``, ``b``, ``c`` - arbitrary values of any type.
* ``x``, ``y``, ``z`` - arbitrary real numbers.
* ``l`` - a logical value.
* ``...`` - indicates that the function takes "more of the same": an arbitrary
  number of additional parameters.

Other names may be used if they have a specific, well-defined meaning for that
function.

Algebraic
---------

=================== ===========================================================
Name                Description
=================== ===========================================================
``sqrt(x)``         Computes √\ *x*
=================== ===========================================================

Transcendental
--------------

=================== ===========================================================
Name                Description
=================== ===========================================================
``erf(x)``          The error function.
``erfc(x)``         The complementary error function.
``log(x)``          Computes the natural logarithm of *x*.
``log2(x)``         Computes the base-2 logarithm of *x*.
``log10(x)``        Computes the base-10 logarithm of *x*.
=================== ===========================================================

Trigonometric
`````````````

=================== ===========================================================
Name                Description
=================== ===========================================================
``cos(x)``          Cosine of *x*.
``sin(x)``          Sine of *x*.
``tan(x)``          Tangent of *x*.
``acos(x)``         Arccos of *x*.
``asin(x)``         Arcsine of *x*.
``atan(x)``         Arctangent of *x*.
``atan2(y,x)``      Arctangent of *y* ÷ *x* such that
                    *-π* ≤ *atan2*\ (*y*, *x*) ≤ *π* holds.
``cosh(x)``         Hyperbolic cosine of *x*.
``sinh(x)``         Hyperbolic sine of *x*.
``tanh(x)``         Hyperbolic tangent of *x*.
``acosh(x)``        Area hyperbolic cosine of *x*.
``asinh(x)``        Area hyperbolic sine of *x*.
``atanh(x)``        Area hyperbolic tangent of *x*.
=================== ===========================================================

Miscellaneous Numerical
-----------------------

======================= =======================================================
Name                    Description
======================= =======================================================
``abs(x)``              Computes the absolute value of *x*.
``clamp(y, x, z)``      Clamps *y* such that *x* ≤ *y* ≤ *z* holds.
``max(x, y, ...)``      Determines the largest value in the sequence
                        *x*, *y*, ...
``min(x, y, ...)``      Determines the smallest value in the sequence
                        *x*, *y*, ...
======================= =======================================================

Probability
-----------

=================== ===========================================================
Name                Description
=================== ===========================================================
``normal(μ,σ)``     Samples a normal distribution.
``poisson(λ)``      Samples a Poisson distribution.
``poisson(λ,x,y)``  Samples a Poisson distribution, clamped between *x*
                    and *y*.
=================== ===========================================================

Control Flow
------------

=================== ===========================================================
Name                Description
=================== ===========================================================
``if(l,a,b)``       Returns *a* if *l* is true, *b* otherwise.  Note
                    that this function is *lazy*; that is, it does not
                    evaluate a parameter unless it is used.
=================== ===========================================================

Specification
=============

This section contains the formal specification for the math eval language.

Lexical Structure
-----------------

Whitespace
``````````

::

    whitespace
        >>─┬─U+20───┐
           ├─U+09─┘ ╧
           ├─U+0B─┘
           └─U+0C─┘

Note that whitespace does not form a distinct lexeme; it is simply discarded.

End-of-Source
`````````````

::

    eos
        >>─┐
           ╧

``eos`` should only match at the end of the input.

End-of-Line
```````````

::

    eol
        >>─┬─U+0D─U+0A───┐
           ├────U+0D───┘ ╧
           └────U+0A───┘

Symbol
``````

::

    symbol
        >>─┬─'='────┐
           ├─'('──┘ ╧
           ├─')'──┘
           ├─'['──┘
           ├─']'──┘
           ├─','──┘
           ├─'+'──┘
           ├─'-'──┘
           ├─'!='─┘
           ├─'/='─┘
           ├─'//'─┘
           ├─'/'──┘
           ├─'**'─┘
           ├─'*'──┘
           ├─'<>'─┘
           ├─'<='─┘
           ├─'<'──┘
           ├─'>='─┘
           └─'>'──┘

Literal
```````

::

    literal
        >>─┬───'and'─────┐
           ├───'let'───┘ ╧
           ├───'not'───┘
           ├───'or'────┘
           └─'uniform'─┘

Identifier
``````````

::

    identifier
        >>─┬─╢ ident start ╟───╢ ident ╟─┬───┐
           │                 └───────────┘ │ ╧
           └─'$'─╢ nested ╟────────────────┘

    ident start
        >>─┬─╢ letter ╟───┐
           ├─────'_'────┘ ╧
           └─────'$'────┘

    ident
        >>─┬─╢ ident start ╟───┐
           ├────╢ digit ╟────┘ ╧
           └───────`'`───────┘

    nested
        >>─'('─┐ ┌────────────────┐ ┌─')'─┐
               └───┬─╢ nested ╟───┴─┘     ╧
                   ├─╢ ident ╟──┘
                   └─────'-'────┘

The form beginning with ``$`` is included for accessing "external" variables
as defined by the host program.

``letter`` and ``digit`` are defined by the Unicode standard.

Number
``````

::

    number
        >>─┬─╢ digit seq ╟─┬─'.'─┬─╢ digit seq ╟─┐
           │               │     └───────────────│
           │               └─────────────────────│
           └─'.'─╢ digit seq ╟─────────────────────┬─╢ exponent ╟─┐
                                                   └────────────────┐
                                                                    ╧

    digit seq
        >>─digit─┬───digit or '_'─┬───┐
                 │ └──────────────┘ │ ╧
                 └──────────────────┘

    exponent
                           ┌───────┐
        >>─┬─'e'───┬─────────digit─┴─┐
           └─'E'─┘ ├─'+'─┘           ╧
                   └─'-'─┘

Grammar
-------

Note that this grammar is **not** complete.  Specifically, it does not specify
the end-of-line suppression behaviour which sub-expressions cause; this aspect
of the grammar is context-dependent and as such cannot be directly
represented.

The grammar is otherwise complete.

::

    <script> = { <statement> };

    <statement> = <empty statement>
                | <let statement>
                | <expression statement>
                ;

    <term> = <eol>
           | <eos>
           ;

    <let statement> = "let", <identifier>, "=", <expression>, <term>;

    <expression statement> = <expression>, <term>;

    <expression> = <expression atom>, { <binary op>, <expression atom> };

    <expression atom> = <number expression>
                      | <unary expression>
                      | <function expression>
                      | <variable expression>
                      | <uniform expression>
                      | <sub expression>
                      ;

    <number expression> = <number>, [ <variable expression> ];

    <unary expression> = <unary op>, <expression atom>;

    <function expression> = <identifier>, "(", ")"
                          | <identifier>, "(",
                                <expression>, { ",", <expression> }
                            ")"
                          ;

    <variable expression> = <identifier>;

    <uniform expression> = "uniform", ( "[" | "(" ),
                               <expression>, ",", <expression>,
                           ( "]" | ")" );

    <sub expression> = "(", <expression>, ")";

    <binary op> = "=" | "/=" | "!=" | "<>"
                | "<" | "<=" | ">" | ">="
                | "+" | "-" | "*" | "/" | "//"
                | "**"
                | "and" | "or"
                ;

    <unary op> = "+" | "-" | "not";


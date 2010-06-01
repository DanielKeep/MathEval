
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

* `Function Expressions`_,
* `Number Expressions`_,
* `String Expressions`_,
* `List Expressions`_,
* `Lambda Expressions`_,
* `Sub-Expressions`_,
* `Unary Expressions`_,
* `Binary Expressions`_,
* `Variable Expressions`_ and
* `Uniform Expressions`_.

Function Expressions
````````````````````

Functions in math eval can be invoked using standard mathematical notation.
For example, to compute the sine of 1.6::

    sin(1.6)

If a function accepts multiple arguments, each argument is separated by a
comma.  For example::

    min(1.4, 7.3)

You can also place a number literal immediately before a function call; this
will be interpreted as an implicit multiplication.  For example::

    3cos(pi/3)

This is equivalent to::

    3*cos(pi/3)

For a complete list of supported functions, see `Functions`_.

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

String Expressions
``````````````````

Strings are represented literally between double quotes.  For example::

    "Strings are represented literally between double quotes."

To include a double quote inside a string, you must "escape" it like so::

    "If you wish to include a double quote inside a string, you must \"escape\" it like so:"

There are a number of other special escapes you can use inside string
literals.  A non-self-referential list is:

======= =======================================================
Escape  Meaning
======= =======================================================
``\a``  Plays an audible bell when displayed literally.
``\b``  A backspace; deletes the previous character.
``\f``  Form feed.
``\n``  New line.
``\r``  Carriage return.
``\t``  Tab.
``\v``  Vertical tab.
``\'``  Single quote.
``\"``  Double quote.
``\?``  Escape escape sequence.
``\\``  Backslash.
======= =======================================================

Most of these have no practical use whatsoever.

Additionally, you can insert an arbitrary character provided you know its
numerical value in hexadecimal.

=============== ===============================================
Escape          Meaning
=============== ===============================================
``\xNN``        Character between 00 and FF.
``\uNNNN``      Character between 0000 and FFFF.
``\UNNNNNNNN``  Character between 00000000 and 0010FFFF.
=============== ===============================================

Again, you will quite likely never, ever need these.

List Expressions
````````````````

**Note**: Lists may not be available.

Lists are ordered sequences of values.  They are written between square
brackets with a comma between each element like so::

    [1, 2, 3]

The empty list is written thus::

    []

Lists can contain any value including other lists.  This can be used to build
complex structures::

    [[1,"one"],[2,"two"],[3,"other"]]

Lists are an optional feature and may not be available.

Lambda Expressions
``````````````````

A lambda is the literal form of a function.  For example::

    \x:2x

The above represents a function with a single argument that returns its
argument doubled.  You can also have multiple arguments::

    \x,y,z: x+y*z

Or no arguments::

    \: 42

Since function application binds more tightly than lambda expressions, if you
wish to invoke a lambda directly, you need to surround the lambda in
parentheses::

    (\x:2x)(4)

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

Unary Expressions
`````````````````

Unary expressions are those where the operator immediately precedes its
argument.  For example::

    -(3*5)

For a complete list of unary operators, see `Unary Operators`_.

Binary Expressions
``````````````````

Math eval supports the standard notation for infix binary operations.  For
example::

    1 + 2*3

For a complete list of binary operators, see `Binary Operators`_.

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

You may also use ``let`` to define a function::

    let area(r) = pi*r**2

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
``mod`` Modulus [*]_                6.5     left
``rem`` Remainder [*]_              6.5     left
``+``   Addition                    6.2     left
``-``   Subtraction                 6.2     left
======= =========================== ======= ======= ===============

.. [*]  *x* // *y* is effectively *floor*\ (\ *x* ÷ *y*\ )

.. [*]  *x* mod *y* = *x* - *y* × *floor*\ (\ *x* ÷ *y*\ )

.. [*]  *x* rem *y* = *x* - *y* × *trunc*\ (\ *x* ÷ *y*\ )

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

Note that both logical operators are short-circuited; that is, they will only
evaluate their right-hand side if the result cannot be determined by the
left-hand side.

For example, ``and`` will short-circuit at the first false encountered and
``or`` will short-circuit at the first true encountered.

Miscellaneous
-------------

======= =========================== ======= ======= ===============
Symbol  Meaning                     Prec.   Assoc.  Alternatives
======= =========================== ======= ======= ===============
``.``   Function composition        9.0     left
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
``inf``         Infinity                ∞
``nan``         Not-a-Number [*]_
``nil``         Nil [*]_
``true``        Tautology               ⊤
``false``       Contradiction           ⊥
=============== ======================= ================================

.. [*]  Not-a-Number is a special value in computer hardware that is used to
        represent the result of undefined calculations.  For example,
        *sqrt*\ (-1), in contexts without imaginary numbers, evaluates to
        ``nan``.  As does *inf* − *inf*.

.. [*]  Nil is used to represent the complete *absence* of a value.

Functions
=========

Functions are defined using the following placeholder variables:

* ``a``, ``b``, ``c`` - arbitrary values of any type.
* ``x``, ``y``, ``z`` - arbitrary real numbers.
* ``l`` - a logical value.
* ``s`` - a string.
* ``f`` - a function.
* ``li`` - a list.
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
``bind(...,a)``     Creates a number of local variable bindings and then
                    evaluates *a* and returns its value.  Each binding is
                    written as [*v*, *expr*] where *v* is the variable name,
                    and *expr* its value.  For example::

                        bind( [a, 6], [b, 7], a*b )

                    Would result in 42.
``case(a,...)``     Matches its first argument against a number of rules and
                    returns the result of the associated expression.
                    Each rule is written as [*m*, *expr*] where *m* is the
                    value to match against and *expr* is the expression to
                    evaluate.  For example::

                        case(1, [0, "foo"], [1, "bar"], [else, "?"])

                    Would result in "bar".  Note that in the last rule, *else*
                    can be used to match anything.
``cond(...)``       Attempts to match a sequence of rules, returning the
                    result of the associated expression.  Each rule is written
                    as [*m*, *expr*] where *m* is a logical-yielding expression
                    and *expr* is the expression to evaluate.  For example::

                        cond([pi<3, "foo"], [pi=3, "bar"],
                             [pi>3, "qux"], [else, "?"])
                    
                    Would result in "qux".  Note that in the last rule, *else*
                    can be used to match anything.
``do(a,...)``       Forcibly evaluates its arguments in strict left-to-right
                    order.
``if(l,a,b)``       Returns *a* if *l* is true, *b* otherwise.  Note
                    that this function is *lazy*; that is, it does not
                    evaluate a parameter unless it is used.
=================== ===========================================================

Sequence
--------

These functions, unless specified, apply to all sequences: lists and settings.

======================= =======================================================
Name                    Description
======================= =======================================================
``concat(s1,s2,...)``   Concatenates two or more sequences together.
``join(s,s1,s2,...)``   Concatenates two or more sequences together, placing
                        *s* between each argument.
``split(a,s)``          Splits *s* once using *a*.  *a* may be of the same type
                        as *s* or a function which takes a slice of *s* and
                        returns *true* if a split should occur.
======================= =======================================================

List
````

**Note**: List support may not be available.

======================= =======================================================
Name                    Description
======================= =======================================================
``apply(f,li)``         Calls *f* with the contents of *li* as its arguments.
``cons(a,li)``          Constructs a new list with *a* in front of the
                        elements of *li*.
``filter(f,li)``        Returns all elements *e* of *li* for which the result
                        of *f*\ (*e*) is *true*.
``head(li)``            Returns the first element of the list *li*.
``map(f,li)``           Transform the elements of *li* by passing each through
                        *f*.
``nth(n,li)``           Returns the *n*\ th element of the list.  Note that
                        this takes O(*n*) time.
``reduce(f,li)``        Reduces *li* to a single value by computing
                        *f*\ (*f*\ (*f*\ (*li*\ :sub:`0`, *li*\ :sub:`1`),
                        *li*\ :sub:`2`), ...).
``tail(li)``            Returns everything after the first element of the list
                        *li*.
======================= =======================================================

Input/Output
------------

======================= =======================================================
Name                    Description
======================= =======================================================
``print(a,...)``        Prints its arguments to the terminal.
``printLn(a,...)``      Prints its arguments to the terminal, adding a line
                        break at the end.
``readLn()``            Reads a line of input and returns it as a string.
======================= =======================================================

Types
-----

=================== ===========================================================
Name                Description
=================== ===========================================================
``type(a)``         Returns the type of *a* as a string.
``logical(a)``      Returns *a* converted to a logical value.
``real(a)``         Returns *a* converted to a real value.
``string(a)``       Returns *a* converted to a string value.
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
           ├─'>'──┘
           ├─'\'──┘
           ├─':'──┘
           └─'.'──┘

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
        >>─┐ ┌────────────────────────┐
           └───┬─'('─╢ nested ╟─')'───┴─┐
               ├─────╢ ident ╟──────┘   ╧
               └─────────'-'────────┘

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
        >>─┬─'e'───┬─────────digit─┬─┐
           └─'E'─┘ ├─'+'─┘ └───────┘ ╧
                   └─'-'─┘

String
``````

::

    string
        >>─'"'───+─'\'─╢ escape ╟─┬─'"'─┐
               │ └────── * ───────┐     ╧
               └──────────────────┘

    escape
        >>─┬─'U'─╢ hex digit * 8 ╟───┐
           ├─'u'─╢ hex digit * 4 ╟─┘ ╧
           ├─'x'─╢ hex digit * 2 ╟─┘
           ├──────────'a'──────────┘
           ├──────────'b'──────────┘
           ├──────────'f'──────────┘
           ├──────────'n'──────────┘
           ├──────────'r'──────────┘
           ├──────────'t'──────────┘
           ├──────────'v'──────────┘
           ├──────────'''──────────┘
           ├──────────'"'──────────┘
           ├──────────'?'──────────┘
           └──────────'\'──────────┘

    hex digit
        >>─┬─ digit ───┐
           ├──'a..f'─┘ ╧
           └──'A..F'─┘

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

    <let statement> = "let", <identifier>, "=", <expression>, <term>
                    | "let", <identifier>, "(",
                          [ <identifier>, { ",", <identifier> } ],
                      ")", "=", <expression>, <term>
                    ;

    <expression statement> = <expression>, <term>;

    <expression> = <expression atom>, { <binary op>, <expression atom> };

    <expression atom> = <number expression>
                      | <string expression>
                      | <list expression>
                      | <lambda expression>
                      | <unary expression>
                      | <function expression>
                      | <variable expression>
                      | <uniform expression>
                      | <sub expression>
                      ;

    <number expression> = <number>
                        | <number>, <function expression>
                        | <number>, <variable expression>
                        ;

    <string expression> = <string>;

    <list expression> = "[", [ <expression>, { ",", <expression> } ], "]";

    <lambda expression> = "\", [ <identifier>, { ",", <identifier> } ], ":",
                          <expression>;

    <unary expression> = <unary op>, <expression atom>;

    <function expression> = ( <identifier>
                              | <sub expression>
                              | <function expression> ),
                            "(",
                                [ <expression>, { ",", <expression> } ]
                            ")";

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
                | "."
                ;

    <unary op> = "+" | "-" | "not";


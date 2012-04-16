Flobnar
=======

_Version 0.1, Chris Pressey, Oct 28 2011_

One day in September of 2011 -- though I'm not sure precisely which
one -- marked Befunge-93's 18th birthday.  That means that Befunge is
now old enough to drink in its native land of Canada.

To celebrate this, I thought I'd get Befunge-93 drunk to see what
would happen.

What happened was _Flobnar_, an esolang which is in many respects a
functional dual of Befunge-93; most of the symbols have analogous
meanings, but execution proceeds in a much more dataflow-like fashion.

This document describes Flobnar with a series of examples, presented
in the format of Falderal 0.7 tests.

Concepts
--------

A familiarity with Befunge-93 is assumed in this document.  Also,
some concepts need to be explained before the description of the
examples will make much sense.

Like Befunge-93, Flobnar programs are held in a playfield -- a
two-dimensional Cartesian grid of cells, each of which contains a
symbol.

Any cell in a Flobnar playfield may be evaluated.  The meaning of
the evaluation of a cell depends on the symbol it contains.  In the
context of execution, this symbol is called a term.

Except for the first term to be evaluated, all terms are "evaluated
from" one of the four cardinal directions: north, south, east, and
west.  The direction provides context: a term may evaluate to a
different value depending on what direction it is evaluated from.

When we say something about "what the cell to the /d/ evaluates to",
where /d/ is a direction, it is implied that that cell is evaluated
from the direction opposite to /d/.  So, "what the cell to the north
evaluates to" means "what the cell to the north evaluates to, when
evaluated from the south."

In addition, when we say "what the cell on the other side evaluates
to", we mean this to be relative to the direction the current term
was evaluated from.  So, if the term was evaluated from the east,
the "cell on the other side" refers to the cell to the west, as
evaluated from the east.

Flobnar is not a purely functional language; it permits input and
output, as well as self-modification, just like Befunge-93 does.
For this reason, order of evaluation should be completely defined.

Flobnar Tests
-------------

    -> Tests for functionality "Interpret Flobnar program"

    -> Functionality "Interpret Flobnar program" is implemented by
    -> Haskell function Flobnar:showRun

Basics of Execution
-------------------

Whereas in Befunge-93 `@` indicates a stopping point of the program,
in Flobnar, `@` indicates the starting point.  The program evaluates
to whatever the `@` it contains evaluates to.  The `@` evaluates to
whatever is west of it evaluates to.

    | 4@
    = Result: 4

The program must contain one and only one @.

    | 4
    ? Program does not contain exactly one @

    | 4@@
    ? Program does not contain exactly one @

Simple Constant Data
--------------------

As in Befunge-93, single digits evaluate to the common decimal
interpretation of themselves as numbers.  You've already seen this
for 4, but it's true for all of them.

    | 0@
    = Result: 0

    | 1@
    = Result: 1

    | 2@
    = Result: 2

    | 3@
    = Result: 3

    | 5@
    = Result: 5

    | 6@
    = Result: 6

    | 7@
    = Result: 7

    | 8@
    = Result: 8

    | 9@
    = Result: 9

Playfield Traversal
-------------------

Whereas in Befunge-93 `><^v` change the direction of the motion
of the IP, in Flobnar these characters evaluate to what the
appropriate adjacent cell evaluates to:

    < evaluates to whatever is west of it evaluates to
    > evaluates to whatever is east of it evaluates to
    v evaluates to whatever is south of it evaluates to
    ^ evaluates to whatever is north of it evaluates to

    | 4<<<<<@
    = Result: 4

    | >>>>>v
    | ^    v
    | ^    4
    | ^<<<<@
    = Result: 4

Also, ' ' (blank space) evaluates to whatever the cell on the other
side of it evaluates to.  So, for example, if evaluated from the
south, it evaluates to what the north of it evaluates to.

    | 4    @
    = Result: 4

    | >    v
    |       
    |      4
    | ^    @
    = Result: 4

Cells which are not specified are considered to contain blank space.
(In the example below, the two middle lines have nothing in them, not
even blank space.)

    |     v@
    | 
    | 
    | 4   <
    = Result: 4

Like Befunge-93, there is toroidal wrapping of evaluation: if we try
to evaluate something outside the bounds of the playfield, we end up
evaluating whatever is directly on the other side of the playfield.
Unlike Befunge-93, however, the bounds of the playfield are determined
solely by the minimal bounding box that encompasses all the non-' '
terms in the playfield.

    | @4
    = Result: 4

    | v@
    | <  v
    |   ^<
    |   4
    = Result: 4

There's a "Bridge" term, similar to Befunge's `#` instruction.  It
evaluates to whatever is one cell past the other side of it.

    | 5     6#@
    = Result: 5

    |  7v @
    | v8#<
    | >#9 v
    |   >^ 
    |  ^  <
    = Result: 7

And `#` is compatible with wrapping.

    | #@   56
    = Result: 5

And we were serious when we said that thing about how the bounds of
the playfield are computed.

    |             
    |     v   @   
    |    #<  17   
    |             
    = Result: 1

Arithmetic
----------

The `+` term evaluates whatever is to the north of it, then evaluates
whatever is to the south of it, and evaluates to the sum of those
two resulting values.

    | 5
    | +@
    | 7
    = Result: 12

    | 5<<    
    |   +<<  
    | 7<< +<@
    |    6<  
    = Result: 18

The `*` term evaluates whatever is to the north of it, then evaluates
whatever is to the south of it, and evaluates to the product of those
two resulting values.

    | 5
    | *@
    | 7
    = Result: 35

The `-` term evaluates whatever is to the north of it (and we call that
/a/), then evaluates whatever is to the south of it (and we call that /b/).
It evaluates to the difference, /a/ - /b/.

    | 7
    | -@
    | 5
    = Result: 2

Subtraction resulting in a negative value.

    | 1
    | -@
    | 9
    = Result: -8

The `/` term evaluates whatever is to the north of it (and we call that
/a/), then evaluates whatever is to the south of it (and we call that /b/).
It evaluates to the quotient of dividing /a/ by /b/.

    | 8
    | /@
    | 2
    = Result: 4

Integer division rounds down.

    | 9
    | /@
    | 2
    = Result: 4

Division by zero evaluates to whatever the cell on the other side
of the `/` term evaluates to.

    |  9
    | 7/@
    |  0
    = Result: 7

    | v9#@
    | >/7
    |  0
    = Result: 7

The `%` term evaluates whatever is to the north of it (and we call that
/a/), then evaluates whatever is to the south of it (and we call that /b/).
It evaluates to the remainder of dividing /a/ by /b/.  This operation is
called "modulo".

    | 8
    | %@
    | 3
    = Result: 2

Modulo of a negative value has the sign of the dividend.

    |  7
    | 0%@
    | +<
    | 3
    = Result: 1

    |  7
    | 0%@
    | -<
    | 3
    = Result: 1

Modulo by zero evaluates to whatever the cell on the other side
evaluates to.

    |  9
    | 7%@
    |  0
    = Result: 7

    | v9#@
    | >%7
    |  0
    = Result: 7

Decision Making
---------------

'Horizontal if', denoted `_`, checks what the cell on the other side
of it evaluates to.  If that value is nonzero, it evaluates to what
the cell west of it evaluates to; otherwise, it evaluates to what the
cell east of it evaluates to.  In either case, at most two evaluations
are made.

    |  0
    | 5_9
    |  ^@
    = Result: 9

    |   7
    | 
    | 5 _ 9
    | 
    |   ^@
    = Result: 5

    |   v<
    | 
    | 5 _ 9
    | 
    |   7^@
    = Result: 5

'Vertical if', denoted `|`, checks what the other side of it evaluates to.
If that value is nonzero, it evaluates to what the cell north of it
evaluates to; otherwise, it evaluates to what the cell south of it
evaluates to.  In either case, at most two evaluations are made.

    |  3
    | 0|@
    |  4
    = Result: 4

    |   3
    | 
    | 9 | @
    | 
    |   4
    = Result: 3

    |   3
    | v   @
    | > | 9
    | 
    |   4
    = Result: 3

These "if"s can be used to evaluate a cell for its side-effects only.
In the following, the sum is evaluated, but the result is effectively
thrown out, in preference to the zero.

    | 90 <
    | +|@
    | 9> ^
    = Result: 0

Like Befunge-93, `!` is logical negation: it evaluates to zero if the
cell on the other side evaluates to non-zero, and to one if the cell on
the other side evaluates to zero.

    | 0!@
    = Result: 1

    | >  v
    | ^@ !
    |    9
    = Result: 0

We don't need greater than, because we can subtract one value
from other, divide the result by itself (specifying a result of 0
if the division is by zero), then add one, and check if that is
non-zero or not with a horizontal or vertical if.

But because Befunge-93 has it, we have it too.  The <code>`</code> term
evaluates whatever is to the north of it (and we call that /a/), then
evaluates whatever is to the south of it (and we call that /b/).  It
evaluates to 1 if /a/ is greater than /b/, 0 otherwise.

    | 8
    | `@
    | 7
    = Result: 1

    | 8
    | `@
    | 8
    = Result: 0

    | 8
    | `@
    | 9
    = Result: 0

`?` picks one of the cardinal directions at random and evaluates
to whatever the cell in that direction evaluates to.  `?` should
use a fair distribution of the four possible choices, and should
be difficult to predict.  We will not present this as a testable
example program, because the Falderal test framework doesn't
provide a way to test that, currently.  (And it's not implemented
yet, but never mind that.)  Instead, here is a plain example.

     1
    2?3#@
     4

The above program should evaluate to 1 25% of the time, 2 25% of
the time, 3 25% of the time, and 4 the rest of the time.

Introspection and Self-Modification
-----------------------------------

Just like Befunge-93, program introspection and self-modification
are fully supported.

The `g` term evaluates to the north to get an x coordinate, then
to the south to get a y coordinate, and evaluates to the ASCII value
of the symbol that's found in that cell in the playfield.  The origin
(coordinates (0,0)) of the playfield is the upper-left corner of that
bounding box I mentioned above, and x values increase to the right,
and y values to the south.

    | A0
    |  g@
    |  0
    = Result: 65

The `p` term evaluates to the north to get an x coordinate, then
to the south to get a y coordinate.  It then evaluates what is on
the other side of it to get a value.  It then alters the playfield
in effect, by placing that value at that (x,y) coordinate.  The
coordinate system is the same as that used by `g`.  The `p` term
always itself evaluates to zero.

    |    0
    |   5p  @
    |    0
    = Result: 0

    |    0
    |  5 p  <
    |    0  +@
    |    g  <
    |    0
    = Result: 5

    |    0
    |  > p 5
    |  +@
    |    0
    |  > g
    |    0
    = Result: 5

Writing a space over an existing cell deletes that cell, and affects
the calculation of the bounds of the playfield.

    | 85   5
    | *p<
    | 40+@
    |   >  +
    |      9
    |      9
    = Result: 18

    |      5
    | 85   #
    | *p<
    | 40+@
    |   >  ^
    |      6
    |      9
    = Result: 6

Writing outside the bounds of the playfield expands those bounds.
Since only cardinal directions are allowed in evaluation, the space
is still topologically a torus; no Lahey-space-like construction
is necessary.

    |  99> v  
    | 7p*^@ >>#
    |  16  >+
    |       <^
    = Result: 7

Every cell in the playfield can hold a signed, unbounded integer.

    | c 00
    |   -p  <
    |   90  +@
    |    g  <
    |    0
    = Result: -9

    |  9
    |  *< 0
    |  9* p  <
    |  *< 0  +@
    |  9  g  <
    |     0
    = Result: 6561

(One consequence of the above two facts is that there are at least
two tactics available for demonstrating that Flobnar is Turing-
complete; the playfield could be used as a tape in the simulation
of a Turing machine, or two cells could be used as registers in
the simulation of a Minsky machine.)

Evaluating a cell whose value is not the ASCII value of any of the
characters which denote terms defined in this document is a
runtime error, which results in the immediate termination of the
program, without producing a result value.

    9  
    *<5
    9*p<
    *<0+@7
    9  > v

The above program will result in a runtime error.

Functions
---------

There's no real equivalent to Befunge-93's `:`, because there's no
need.  Common subexpressions can be shared geometrically.

    | v<
    | 5+@
    | ^<
    = Result: 10

Likewise, there are no equivalents for `\` and `$`.  Therefore, these
symbols have different meanings in Flobnar.

Originally, my idea for Flobnar included function values (lambda
functions.)  But eventually these struck me as un-Befunge-like.
A function is just some code you want to be able to evaluate more
than once without repeating verbatim.  And in the context of Befunge,
a function is just a part of the playfield.  It's already possible
to execute the same part of the playfield from different points in
your program, using arrows; and in Flobnar this is even easier,
since evaluation of a part of th playfield "remembers" where it was
"evaluated from".

What's really useful in a function is that it can take an argument.
So I retained the idea of having arguments available -- a call stack.
Surprisingly, it turned out to be similar to Befunge-93's stack, so I
consider that a bonus.

The `\` term takes what to the south of it evaluates to, and uses
that as the argument as it "applies" the "one-argument" "function" on
the other side of it.  The `:` term evaluates to the current argument.

    | 5\@
    |  0
    = Result: 5

    | :
    | +\@
    | 54
    = Result: 9

    | v 1#  \ @
    | > +      
    |       
    |   :   7  
    = Result: 8

    | > v :
    | ^@>\*
    |    7:
    = Result: 49

If no function is being applied, `:` evaluates to zero.

    | :@
    = Result: 0

A function can call another function.  The outer function retains its
argument after the inner function returns.

    | 1
    | +\<
    | :4+\@
    |   :7
    = Result: 12

Hellooooo, factorial!

    | >     v
    | ^\ <   
    |        
    | :v    v   \<@
    | -<      : 6
    | 1 :   > *
    |   -|    <
    |   11
    = Result: 720

The `$` term removes the top value from the call stack and "calls" the
"function" on the other side with this reduced call stack.  This, in
effect, lets you write functions which take multiple arguments.

    | :
    | +\<<\@
    | :7  9
    = Result: 14

    | :
    | $
    | +\<<\@
    | :7  9
    = Result: 16

Input and Output
----------------

Flobnar supports input and output of ASCII characters, although
because the Falderal test framework doesn't handle tests with
input very well (and because I would have to refactor my beautiful
implementation in a major way, either threading an IO monad
through all the evaluation functions, or converting those
functions to continuation-passing style), they are only briefly
covered here, with only plain examples.  My apologies if they are
not very well defined; a future version of the language and the
test suite may attempt to rectify that.

The `,` term evaluates what is on the other side of it and
outputs the character with that ASCII value to standard output.
The `,` term itself evaluates to zero.  So, the following
example should output the two-character string 'Hi', and evaluate
to a result of zero.

    8
    *,<  5
    9 +@>*
      >,*7
        3

Note that the convention of the result of each program being
printed after "Result: ", in the tests here, is merely a convention.
What the implementation does with the result of the main Flobnar
expression is outside the domain of Flobnar proper.  (Of course,
it is extremely useful if it can make this value available to the
outside world somehow, for example by outputting it after the
string "Result: ".)

In similar vein, attempting to output and integer outside the range
of ASCII is, as of this writing, undefined.

The `~` term reads a character from standard input and evaluates
to the ASCII value of that character.  So, the following program
reads two characters, and evaluates to 1 if they are the same
character, and 0 if they are not.

    ~
    -!@
    ~

Putting these two together, the following program should be the
virtual equivalent of the Unix `cat` utility:

    ~,<
      +<@
      >^

Other Things
------------

The terms denoted by all characters not mentioned in the above
sections are undefined.  For maximum compatibility with future
versions of Flobnar, they should not appear in a Flobnar program.

Specifically, I have a vague idea that extensions to Flobnar
may be indicated by the presence of a certain characters or
combination of characters immediately and non-wrappingly to
the east of the `@` term.  So, best to leave that cell blank or
make it an arrow.

As you've probably noticed, I've referred to the character set
as ASCII in this entire document.  I actually mean "printable
ASCII" -- control characters and whitespace (aside from space
and linefeed) are not defined, and (except for specific cases
addressed in this document) an implementation is not expected
to load them into the playfield.  If at some point Flobnar is
ever extended into the realm of Unicode, source files will be
expected to be encoded in UTF-8.

To be really true to Befunge-93, Flobnar should support `.` for
outputting integers formatted in conventional decimal notation,
and `&` for inputting integers in that format too.  They may
appear in a future version of the language.  On the other hand,
they may not.  I can't see the future.

After all that, the only thing from Befunge-93 that's missing a
counterpart in Flobnar is stringmode.  I originally added it to
Flobnar, having each string evaluate to a string value, but that
complicated evaluation rules by adding a new type that would have
to be handled everywhere.  I afterwards considered making it more
like ':', pushing the ASCII value of each character onto the call
stack, but decided that was a little awkward too.  So, for
simplicity, I just left it out of this version.

That's All
----------

Happy bar-hopping!  
Chris Pressey  
Evanston, Illinois  
October 28, 2011

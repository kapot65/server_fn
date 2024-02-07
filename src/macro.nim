# to work with Nim syntax trees, we need an API that is defined in the
# `macros` module:
import std/macros

macro debug(args: varargs[untyped]): untyped =
  # `args` is a collection of `NimNode` values that each contain the
  # AST for an argument of the macro. A macro always has to
  # return a `NimNode`. A node of kind `nnkStmtList` is suitable for
  # this use case.
  result = nnkStmtList.newTree()
  # iterate over any argument that is passed to this macro:
  for n in args:
    # add a call to the statement list that writes the expression;
    # `toStrLit` converts an AST to its string representation:
    result.add newCall("write", newIdentNode("stdout"), newLit(n.repr))
    # add a call to the statement list that writes ": "
    result.add newCall("write", newIdentNode("stdout"), newLit(": "))
    # add a call to the statement list that writes the expressions value:
    result.add newCall("writeLine", newIdentNode("stdout"), n)

var
  a: array[0..10, int]
  x = "some string"
a[0] = 42
a[1] = 45

debug(a[0], a[1], x)
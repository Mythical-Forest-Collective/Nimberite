## MIT License
##
## Copyright (c) 2020 Andy Davidoff
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

## NOTE: THIS FILE HAS BEEN MODIFIED BY THE MYTHICAL FOREST COLLECTIVE TO ADD BASIC VERY UUID SERIALISATION

import std/macros
import std/strutils

import ./uuid4

type
  Jason* = distinct string   ## Serialized JSON.

  JasonArray = concept j
    for v in j:
      v is Jasonable

  Jasonable* = concept j   ## It should be serializable to JSON.
    jason(j) is Jason

  Rewrite = proc(n: NimNode): NimNode

func `$`*(j: Jason): string =
  ## Convenience for Jason.
  result = j.string

proc rewrite(n: NimNode; r: Rewrite): NimNode =
  ## Rewrites a node; twice, if necessary.
  result = r(n)
  if result.isNil:
    result = copyNimNode n
    for kid in items(n):
      result.add rewrite(kid, r)
    let second = r(result)
    if not second.isNil:
      result = second

proc combineLiterals(n: NimNode): NimNode =
  ## Stolen from my testes and more important here.
  proc combiner(n: NimNode): NimNode =
    case n.kind
    of nnkCall:
      case $n[0]
      of "$":
        if n[1].kind == nnkStrLit:
          result = n[1]
      of "&":
        if len(n) == 3 and {n[1].kind, n[2].kind} == {nnkStrLit}:
          result = newLit(n[1].strVal & n[2].strVal)
      else:
        discard
    else:
      discard
  result = rewrite(n, combiner)

proc add(js: var Jason; s: Jason) {.borrow.}
proc `&`(js: Jason; s: Jason): Jason {.borrow.}

proc join(a: openArray[Jason]; sep = Jason""): Jason =
  for index, item in a:
    if index != 0:
      result.add sep
    result.add item

# these are copied from stdlib so that we can be certain we match output
# without having to import json and all of its dependencies...  i know.

proc escapeJsonUnquoted(s: string; result: var string) {.used.} =
  ## Converts a string `s` to its JSON representation without quotes.
  ## Appends to ``result``.
  for c in s:
    case c
    of '\L': result.add("\\n")
    of '\b': result.add("\\b")
    of '\f': result.add("\\f")
    of '\t': result.add("\\t")
    of '\v': result.add("\\u000b")
    of '\r': result.add("\\r")
    of '"': result.add("\\\"")
    of '\0'..'\7': result.add("\\u000" & $ord(c))
    of '\14'..'\31': result.add("\\u00" & toHex(ord(c), 2))
    of '\\': result.add("\\\\")
    else: result.add(c)

proc escapeJsonUnquoted(s: string): string {.used.} =
  ## Converts a string `s` to its JSON representation without quotes.
  result = newStringOfCap(s.len + s.len shr 3)
  escapeJsonUnquoted(s, result)

proc escapeJson(s: string; result: var string) =
  ## Converts a string `s` to its JSON representation with quotes.
  ## Appends to ``result``.
  result.add("\"")
  escapeJsonUnquoted(s, result)
  result.add("\"")

proc escapeJson(s: string): string =
  ## Converts a string `s` to its JSON representation with quotes.
  result = newStringOfCap(s.len + s.len shr 3)
  escapeJson(s, result)

when false:
  proc cmd(caller: NimNode; callee: NimNode): NimNode =
    nnkCommand.newTree(caller, callee)

  proc cmd(caller: string; callee: NimNode): NimNode =
    cmd(ident caller, callee)

func jason*(node: NimNode): NimNode =
  ## Convenience for jason(...) in macros.
  result = newCall(ident"jason", node)

macro jason*(js: Jason): Jason =
  ## Idempotent Jason handler.
  runnableExamples:
    let j = 3.jason
    let k = jason j
    assert $k == "3"

  result = js

proc jasonify*(node: string): NimNode =
  ## Convenience for Jason(...) in macros.
  result = nnkCallStrLit.newTree(ident"Jason", newLit node)

proc jasonify*(node: NimNode): NimNode =
  ## Convenience for Jason(...) in macros.
  result = combineLiterals(node)
  case result.kind
  of nnkStrLit:
    result = jasonify result.strVal
  else:
    result = newCall(ident"Jason", result)

macro jason*(s: string or cstring): Jason =
  ## Escapes a string to form "JSON".
  runnableExamples:
    let j = jason"goats"
    assert $j == "\"goats\""

  let escapist = bindSym"escapeJson"
  result = s
  # convert cstring into string, first
  if s.getType.strVal == "cstring":
    result = newCall(bindSym"$", result)
  result = jasonify newCall(escapist, result)

macro jason*(uuid: Uuid): Jason =
  ## Turns a Uuid to a string to form "JSON".

  let escapist = bindSym"escapeJson"
  # Turn the uuid to a string first
  result = newCall(bindSym"$", uuid)
  result = jasonify newCall(escapist, result)

macro jason*(b: bool): Jason =
  ## Produce a JSON boolean, either `true` or `false`.
  runnableExamples:
    let j = jason(1 == 2)
    assert $j == "false"

  result = nnkIfExpr.newNimNode(b)
  result.add newTree(nnkElifExpr, b, jasonify"true")
  result.add newTree(nnkElseExpr, jasonify"false")

func jason*(e: enum): Jason =
  ## Render any `enum` type as a JSON number, by default.
  result = Jason $ord(e)

func jason*(i: SomeInteger): Jason =
  ## Render any Nim integer as a JSON number.
  result = Jason $i

func jason*(f: SomeFloat): Jason =
  ## Render any Nim float as a JSON number.
  result = Jason $f

proc jasonSquare(a: NimNode): NimNode =
  ## Render an iterable that isn't a named-tuple or object as a JSON array.
  let adder = bindSym"add"
  result = newStmtList()

  var js = gensym(nskVar, "js")
  result.add newVarStmt(js, jasonify"[")      # the leading [

  # add a loop over the items in the iterable
  result.add:
    var index = gensym(nskForVar, "index")    # make loop var
    var value = gensym(nskForVar, "value")    # make loop var

    var body = nnkStmtList.newNimNode         # make body of a loop
    body.add:
      newIfStmt (infix(index, "!=", newLit 0),    # if index != 0
                 adder.newCall(js, jasonify","))  # js.add Jason","

    body.add adder.newCall(js, value.jason)   # add the json for value

    var loop = nnkForStmt.newNimNode          # for loop
    loop.add index                            # add loop var
    loop.add value                            # add loop var
    loop.add a                                # add any iterable
    loop.add body                             # add loop body
    loop

  result.add adder.newCall(js, jasonify"]")   # add the trailing ]
  result.add js    # the last statement in the stmtlist is the json

macro jason*[I, T](a: array[I, T]): Jason =
  ## Render any Nim array as a series of JSON values.
  # make sure the array ast has the form we expect
  let typ = a.getType
  # support for nim-1.2
  if typ.kind == nnkBracket:
    return jasonSquare a
  expectKind(typ, nnkBracketExpr)
  if len(typ) < 3 or typ[0].strVal != "array":
    error "unexpected array form:\n" & treeRepr(typ)
  else:
    # take a look at the range definition for the array
    let ranger = typ[1]
    when false:
      if ranger.kind == nnkBracketExpr:
        echo treeRepr(ranger)
        echo "get type1: ", treeRepr(ranger.getType)
        echo "get inst1: ", treeRepr(ranger.getTypeInst)
        echo "get impl1: ", treeRepr(ranger.getTypeImpl)
        var ranger = ranger.getTypeInst
        echo "get type2: ", treeRepr(ranger.getType)
        echo "get inst2: ", treeRepr(ranger.getTypeInst)
        echo "get impl2: ", treeRepr(ranger.getTypeImpl)

    # okay, let's do this thing
    let js = ident"jason"
    let s = genSym(nskVar, "jason")
    var list = newStmtList()

    # we'll make adding strings to our accumulating string easier...
    template addString(x: typed): NimNode {.dirty.} =
      # also cast the argument to a string just for correctness
      add list:
        s.newDotExpr(bindSym"add").newCall:
          ident"string".newCall x

    template composeIt(iter: typed; body: untyped) {.dirty.} =
      var first = true
      for it {.inject.} in iter:
        #var it {.inject.} = it
        if first:
          first = false
        else:
          addString newLit","   # comma between each element
        let index = body
        # s.add jason(a[index])
        addString js.newCall(nnkBracketExpr.newTree(a, index))

    list.add newVarStmt(s, newLit"[")

    # iterate over the array by index and add each item to the string
    case ranger.kind
    of nnkBracketExpr, nnkInfix, nnkSym:
      # type A = array[0..10, string]
      # type A = array[foo..bar, string]
      expectKind(ranger[1], nnkIntLit)     # 0
      expectKind(ranger[2], nnkIntLit)     # 10
      composeIt ranger[1].intVal .. ranger[2].intVal:
        newLit it.int
    of nnkEnumTy:
      # type A = array[Enum, string]
      composeIt 1 ..< ranger.len:
        ranger[it]
    else:
      error "expected infix or enum:\n" & treeRepr(ranger)

    addString newLit"]"
    list.add s      # final value of the stmtlist is the string itself
    result = newCall(ident"Jason", list)

when false:
  macro jason[T](j: T{lit|`const`}): Jason =
    ## Create a static JSON encoder for T.
    var j = j
    result = jason(j)
else:
  template staticJason*(typ: typedesc) =
    ## Create a static JSON encoder for type `typ`.
    when not defined(nimdoc):
      macro jason(j: static[typ]): Jason {.used.} =
        ## Static JSON encoder for `typ`.
        jasonify jason(j).string

  staticJason cstring
  staticJason string
  staticJason bool
  staticJason float
  staticJason float32
  staticJason int
  staticJason int8
  staticJason int16
  staticJason int32
  staticJason int64
  staticJason uint
  staticJason uint8
  staticJason uint16
  staticJason uint32
  staticJason uint64

proc composeWithComma(parent: NimNode; js: NimNode): NimNode =
  # whether we need to add a comma before the next element
  let adder = bindSym"add"
  var comma = gensym(nskVar, "comma")
  parent.add newVarStmt(comma, ident"false")         # var comma = false

  var cond = nnkElifExpr.newNimNode
  cond.add comma                                     # if comma:
  cond.add adder.newCall(js, jasonify",")            # js.add ","

  var toggle = nnkElseExpr.newNimNode                # else:
  toggle.add newAssignment(comma, ident"true")       # comma = true

  var sep = nnkIfExpr.newNimNode
  sep.add cond                                       # if comma: js.add ","
  sep.add toggle                                     # else: comma = true

  sep

proc jasonTuple(t: NimNode): NimNode =
  ## Render an anonymous tuple as a JSON array.
  let adder = bindSym"add"
  let typ = t.getTypeInst
  result = newStmtList()

  var js = gensym(nskVar, "js")
  result.add newVarStmt(js, jasonify"[")      # the leading [

  for index in 0 ..< typ.len:
    if index != 0:
      result.add adder.newCall(js, jasonify",")
    result.add adder.newCall(js, jason newCall(ident"[]", t, newLit index))

  result.add adder.newCall(js, jasonify"]")   # add the trailing ]
  result.add js    # the last statement in the stmtlist is the json

macro jason*(a: JasonArray): Jason =
  ## Render an iterable that isn't a named-tuple or object as a JSON array.
  runnableExamples:
    let j = jason @[1, 3, 5, 7]
    assert $j == "[1,3,5,7]"
    let k = jason (1, 3, 5, 7)
    assert $k == "[1,3,5,7]"

  case a.kind
  of nnkTupleConstr:
    result = jasonTuple a
  else:
    result = jasonSquare a

proc jasonCurly(o: NimNode): NimNode =
  let adder = bindSym"add"
  result = newStmtList()

  var js = gensym(nskVar, "js")
  result.add newVarStmt(js, jasonify"{")

  # make a loop over the items in the iterable
  let loop = block:
    var key = gensym(nskForVar, "key")             # loop var for key
    var val = gensym(nskForVar, "val")             # loop var for val

    var body = nnkStmtList.newNimNode              # make body of a loop
    body.add composeWithComma(result, js)          # maybe add a separator
    body.add adder.newCall(js, key.jason)          # "somekey" (json)
    body.add adder.newCall(js, jasonify":")        # : (json)
    body.add adder.newCall(js, val.jason)          # someval (json)

    var loop = nnkForStmt.newNimNode               # make for loop
    loop.add key                                   # add key to the loop
    loop.add val                                   # add val to the loop
    loop.add newCall(ident"fieldPairs", o)         # object fieldPairs
    loop.add body                                  # loop body

    loop

  result.add loop                                  # add the loop
  result.add adder.newCall(js, jasonify"}")        # add the trailing ]

  # the last statement in the statement list is the json
  result.add js

func jason*(o: ref): Jason =
  ## Render a Nim `ref` as either `null` or the value to which it refers.
  if o.isNil:
    result = Jason"null"
  else:
    result = jason o[]

macro jason*(o: tuple): Jason =
  ## Render an anonymous Nim tuple as a JSON array;
  ## named tuples become JSON objects.
  runnableExamples:
    let j = jason (1, "too", 3.0)
    assert $j == """[1,"too",3.0]"""
    let k = jason (one: 1, two: "too", three: 3.0)
    assert $k == """{"one":1,"two":"too","three":3.0}"""

  case o.getTypeInst.kind
  of nnkTupleConstr:
    result = jasonTuple o
  else:
    # use our object construction code for named tuples
    result = jasonCurly o

macro jason*(o: object): Jason =
  ## Render an object as JSON.
  runnableExamples:
    let j = jason Exception(name: "jeff", msg: "bummer")
    assert $j == """{"parent":null,"name":"jeff","msg":"bummer","trace":[],"up":null}"""
  result = jasonCurly o

export jason
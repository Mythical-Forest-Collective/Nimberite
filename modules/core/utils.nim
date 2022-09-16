import std/[logging, macros]

# No astrick since we wanna keep this local -Solaris
const PREFIX = "[Nimberite]: "

# This code reminds me of once I spent 5 hours writing a python logging system - Pyris
let logger* = newConsoleLogger(fmtStr="[$date/$time] [$levelname] ")

# Just nifty aliases to make it 'pretty', and somewhat easy to swap it out with a custom impl later on -Solaris
template debug*(args: varargs[untyped]) = unpackVarargs(logger.log, Level.lvlDebug, PREFIX, args)
template info*(args: varargs[untyped]) = unpackVarargs(logger.log, Level.lvlInfo, PREFIX, args)
template warn*(args: varargs[untyped]) = unpackVarargs(logger.log, Level.lvlWarn, PREFIX, args)
template error*(args: varargs[untyped]) = unpackVarargs(logger.log, Level.lvlError, PREFIX, args)
template fatal*(args: varargs[untyped]) = unpackVarargs(logger.log, Level.lvlFatal, PREFIX, args)

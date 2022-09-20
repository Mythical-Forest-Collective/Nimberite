# Copyright 2022 "Ecorous System", "Mythical Forest Collective"
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import std/[logging, macros, terminal, os, tables, strutils]

type Logger* = object
  source*: string 

var loggers = newSeq[Logger]()


proc createLoggingSource*(input: varargs[string]): string =
     var temp: string = ""
     for inp in input:
         
         if inp == input[^1]:
          var n = temp & inp
          temp = n
         else:
          var n = temp & inp & "|"
          temp = n
     result = temp

proc getLogger*(source: string = "nimberite"): Logger =
  for logger in loggers:
    if logger.source == source:
      return logger

  var temp = Logger(source:source)
  loggers.add temp
  result = temp

# This code reminds me of once I spent 5 hours writing a python logging system - Pyris
proc log(logger: Logger, level: Level=Level.lvlInfo, input: string) =
  var levelColour: ForegroundColor
  var levelString: string
  if level == Level.lvlInfo:
    levelColour = fgWhite
    levelString = "info"
  elif level == Level.lvlDebug:
    levelColour = fgBlue
    levelString = "debug"
  elif level == Level.lvlWarn:
    levelColour = fgYellow
    levelString = "warn"
  elif level == Level.lvlError or level == Level.lvlFatal:
    levelColour = fgRed
    if level == Level.lvlError: levelString = "error"
    else: levelString = "fatal"
  stdout.styledWriteLine(fgCyan, logger.source & " ", levelColour, levelString, fgDefault, " " & input)

proc info*(logger: Logger, input: varargs[string]) = log(logger, Level.lvlInfo, input.join(""))
proc debug*(logger: Logger, input: varargs[string]) = log(logger, Level.lvlDebug, input.join(""))
proc warn*(logger: Logger, input: varargs[string]) = log(logger, Level.lvlWarn, input.join(""))
proc error*(logger: Logger, input: varargs[string]) = log(logger, Level.lvlError, input.join(""))
proc fatal*(logger: Logger, input: varargs[string]) = log(logger, Level.lvlFatal, input.join(""))
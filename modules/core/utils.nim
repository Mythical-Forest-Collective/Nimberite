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

import std/[logging, macros, terminal, os]

# This code reminds me of once I spent 5 hours writing a python logging system - Pyris
proc log*(input: string, level: Level=Level.lvlInfo) = # Default logging level
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
  stdout.styledWriteLine(fgCyan, "nimberite ", levelColour, levelString, fgDefault, " " & input)


template info*(input: string) = log(input, Level.lvlInfo)
template debug*(input: string) = log(input, Level.lvlDebug)
template warn*(input: string) = log(input, Level.lvlWarn)
template error*(input: string) = log(input, Level.lvlError)
template fatal*(input: string) = log(input, Level.lvlFatal)


export Level
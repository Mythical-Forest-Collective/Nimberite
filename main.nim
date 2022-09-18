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

import std/[asyncdispatch]  # Async!~

import modules/core/utils

import modules/core/packets as cpackets
import modules/java/packets as jpackets

import modules/java/server as jserver

# Adding astricks to identifiers exports them as public -Solaris
type
  PacketReciever = proc() # Alias type -Solaris
  PacketHandler* = proc(packet: BasePacket)

  NimberiteServer* = object # General object for the Nimberite core - Solaris
    address*: string  # Address the server should bind to -Solaris
    port*: int # The port of the server -Solaris
    packetRecievers*: PacketReciever
    packetHandlers*: PacketHandler
    packetQueue*: seq[BasePacket]


proc start*(address: string, port: int) {.async.} =
  log("Starting server at " & address & ":" & $port & "!", Level.lvlInfo)

  asyncCheck jserver(address, port)  # Run in parallel with any other server impls

  while true: # Just a small timer to keep the code running
    await sleepAsync 1000  # await makes us wait for for the completion of an async method


asyncCheck start("0.0.0.0", 25565)
runForever()
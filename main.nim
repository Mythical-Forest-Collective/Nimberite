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
import modules/core/utils

import modules/core/packets as cpackets
import modules/java/packets as jpackets

# Adding astricks to identifiers exports them as public -Solaris
type
  PacketHandler* = proc(packet: BasePacket) # Alias type -Solaris

  NimberiteServer* = object # General object for the Nimberite core -Solaris
    address*: string  # Address the server should bind to -Solaris
    port*: int # The port of the server -Solaris
    packetHandlers*: PacketHandler


proc start(address: string, port: int): NimberiteServer =
  info("Starting server at " & address & ":" & $port & "!")

  fatal("WE DON'T HAVE ANYTHING IMPLEMENTED LMAO -Solaris")

var server = start("0.0.0.0", 25565) # yay!!!!
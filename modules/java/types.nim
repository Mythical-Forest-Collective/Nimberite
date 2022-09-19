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

import std/strformat
import ../external/uuid4

# TODO: Make it so Java packets can be converted to Generic packets and vice versa

type
  ClientDisconnectError* = object of IOError

  VarInt* = int32
  VarLong* = int64

  NextState* = enum
    Status = 1
    Login = 2

  ListPlayer* = object
    name: string
    uuid: Uuid

# The base java packet, is here to represent packets easily in the Java impl -Solaris
type
  JavaBasePacket* = ref object of RootObj
    length*: VarInt  # The length of the packet
    id*: VarInt      # The id of the packet
    data*: seq[byte] # The raw byte data

  HandshakePacket* = ref object of JavaBasePacket
    protocolVersion*: VarInt # Protocol version
    serverAddress*: string   # Not useful to us really
    port*: uint16            # The port number, also not useful to us
    nextState*: NextState    # Login state, 1 for Status, 2 for Login


proc `$`*(jbp: JavaBasePacket): string =
  return "(Length: {jbp.length}, ID: {jbp.id}, Data: {$jbp.data})".fmt
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

import std/[asyncdispatch, asyncnet, strformat]
import ../types as jtypes
import ../decoders
import ../../core/utils
import ../../external/jason # An effecient JSON serialisation (only!) module


# Construct the Status Response JSON object
proc statusResponseJson(protocolVersion: int, serverVersion: string, 
  maxPlayers, onlineCount: int=999, players: openArray[ListPlayer]=[],
  description: string="A Nimberite-powered server!",
  chatPreview, secureChatEnforced: bool=false): Jason =

  return (
    version: (
      name: serverVersion,
      protocol: protocolVersion
    ),
    players: (
      max: maxPlayers,
      online: 999,
      sample: players
    ),
    description: (
      text: description
    ),
    previewsChat: chatPreview,
    enforcesSecureChat: secureChatEnforced
  ).jason


proc unpackHandshakePacket(length, id: int32, byteArray: seq[byte]): HandshakePacket =
  debug $length
  result = HandshakePacket(length:length, id:id, data:byteArray)

  if length == 1:
    return # This indicates that the packet is a ping packet

  var pos = 0
  var dat = byteArray

  result.protocolVersion = readVarInt(dat, pos)

  dat = byteArray[pos..^1]
  result.serverAddress = readString(dat, pos)

  dat = byteArray[pos..^1]
  result.port = readUnsignedShort(dat, pos)

  var nextState = byteArray[pos]
  if nextState == 1:
    result.nextState = NextState.Status
  elif nextState == 2:
    result.nextState = NextState.Login

  debug $result


proc readPacket*(client: AsyncSocket): Future[JavaBasePacket] {.async.} =
  let length = await readVarInt(client)
  let id = await readVarInt(client)

  let byteArray = readBytes(await client.recv(length))

  case id
    of 0:
      return unpackHandshakePacket(length, id, byteArray)
    else:
      return JavaBasePacket(length:length, id:id, data:byteArray)
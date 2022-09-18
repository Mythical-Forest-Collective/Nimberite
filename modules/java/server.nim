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

import std/[asyncdispatch, asyncnet, sequtils]

import ../core/utils

const SEGMENT_BITS = 0x7F
const CONTINUE_BIT = 0x80


type ClientDisconnectError = object of IOError


proc toByteArray(data: string): seq[byte] =
  # Cast string to bytes!~
  var chars = data.toSeq

  for c in chars:
    result.add c.byte


proc readVarInt(client: AsyncSocket): Future[int32] {.async.} =
  var value: int32 = 0
  var position = 0
  var currentByte: int32 # Represent a byte as an int32

  while true:
    var byteArray = toByteArray(await client.recv(1))
    echo $byteArray
    # Aaaaaaaaaaa windows sucks
    var byt = byteArray[0]
    if byt == "": 
      log("Byte buffer is empty?", lvlDebug)
      raise newException(ClientDisconnectError, "Client disconnected!")

    currentByte = byt[0].int32 # Read one byte at a time

    var res = currentByte and SEGMENT_BITS
    res = res shl position.SomeInteger
    value = value or res

    if (currentByte and CONTINUE_BIT) == 0:
      break

    position += 7

    if position >= 32:
      raise ValueError.newException("The VarInt is too big! Is it valid?")

  return value


var clients:seq[AsyncSocket]

proc handle(client: AsyncSocket) {.async.} = # Handle client
  log("Client handler was called!", Level.lvlDebug)

  var bytes:seq[byte] = newSeq[byte]() # Bytes in buffer

  try:
    while true:
      var future = readVarInt(client)

      var packetLength = await future

      if future.failed:
        raise newException(Exception, "Hm... Something went wrong")

      if packetLength == 0:
        break

  except:
    log("Client disconnect!", Level.lvlDebug)

  clients.del(clients.find(client)) # Should only be called on exit
  log("Client removed from clients list!", Level.lvlDebug)


proc jserver*(address: string, port: int) {.async.} =
  clients = @[]  # All connected java clients
  log("Starting the Java server...", Level.lvlInfo)

  let server = newAsyncSocket(buffered=false)
  server.setSockOpt(OptReuseAddr, true) 
  server.bindAddr(Port(port), address) 
  # I found a simple tut for async logging? (link here: https://hookrace.net/blog/writing-an-async-logger-in-nim/)
  #, also live share is sharing the listener for nimberite, so I could join it locally , yeah, just saying that I could theoretically
  server.listen() # Make it so we can listen to connections
  log("Java server ready!", Level.lvlInfo)

  while true:
    let client = await server.accept()

    clients.add client # Global list of clients

    asyncCheck client.handle # Run client handler in background

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

import ./types as jtypes

import ./packet/unpackers as junpackers

import ../core/utils as cutils


var clients:seq[AsyncSocket]


proc handle(client: AsyncSocket) {.async.} = # Handle client
  log("Client handler was called!", Level.lvlDebug)

  var bytes:seq[byte] = newSeq[byte]() # Bytes in buffer

  try:
    while true:
      var future = readPacket(client)
      var packet:JavaBasePacket = await future

      case packet.id
        of 0:
          packet = packet.HandshakePacket
        else:
          debug "Unimplemented functionality packet of ID {packet.id}!".fmt

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

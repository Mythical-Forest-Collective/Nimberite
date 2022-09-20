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
import ./fields as jfields

import ./packet/unpackers as junpackers

import ../core/logging as logging


var clients:seq[AsyncSocket]

let logger: Logger = getLogger(logging.createLoggingSource("nimberite", "java", "server"))

#[
proc handler(client: AsyncSocket) {.async.} =
  var packetQueue = client.packetQueue
  while true:
    if packetQueue.len != 0:
      #await client.send()
      discard
]#

proc reciever(client: AsyncSocket) {.async.} = # Handle client
  logger.debug("Client handler was called!")

  var bytes:seq[byte] = newSeq[byte]() # Bytes in buffer

  try:
    while true:
      var future = readPacket(client)
      var packet:JavaBasePacket = await future

      case packet.id
        of 0:
          packet = packet.HandshakePacket
        else:
          logger.debug "Unimplemented functionality packet of ID {packet.id}!".fmt

  except:
    logger.debug("Client disconnect!")
    

  clients.del(clients.find(client)) # Should only be called on exit
  logger.debug("Client removed from clients list!")
  


proc jserver*(address: string, port: int) {.async.} =
  clients = @[]  # All connected java clients
  logger.info("Starting the Java server...")
  #log("Starting the Java server...", Level.lvlInfo)

  let server = newAsyncSocket(buffered=false)
  server.setSockOpt(OptReuseAddr, true) 
  server.bindAddr(Port(port), address) 
  # I found a simple tut for async logging? (link here: https://hookrace.net/blog/writing-an-async-logger-in-nim/)
  server.listen() # Make it so we can listen to connections
  logger.info("Java server ready!")

  while true:
    let client = await server.accept()

    clients.add client # Global list of clients

    asyncCheck client.reciever # Run client reciever in background

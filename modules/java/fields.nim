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

#[
import std/[asyncdispatch, asyncnet, tables]
import ./types as jtypes

var packetQueues: Table[AsyncSocket,seq[JavaBasePacket]]

# Allows for us to pretend we have a custom field on the type, only here for queueing packets
proc packetQueue*(client: AsyncSocket): ref seq[JavaBasePacket] =
  if packetQueues.hasKey(client):
    return ref packetQueues[client]

  packetQueues[client] = newSeq[JavaBasePacket]()
  return packetQueues[client]
]#
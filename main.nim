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

import modules/core/packets  # Packets

# Adding astricks to identifiers exports them as public
type
  NimberiteServer* = object
    address*: string  # Address the server should bind to
    port*: int # The port of the server
    packetHandlers*: seq[proc(packet: BasePacket)]

# colours pretty
# yeet

proc start(address: string, port: int): NimberiteServer =
  
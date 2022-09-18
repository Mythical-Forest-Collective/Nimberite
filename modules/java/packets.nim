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

# TODO: Make it so Java packets can be converted to Nim and vice versa

import ../core/packets as cpackets # that annoyed me lmao, no the jpackets instead of cpackets
# Aah fair xD
# I'ma try implementing a neater way of adding implementation... backends? handlers?


# The base java packet, so we can make others aware of this -Solaris
type
  JavaBasePacket* = object of BasePacket
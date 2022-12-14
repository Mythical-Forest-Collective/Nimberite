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

import std/[asyncdispatch, asyncnet]
import ./types as jtypes


const SEGMENT_BITS = 0x7F
const CONTINUE_BIT = 0x80

template readByte*(data: char): byte = data.byte
template readByte*(data: string): byte = data[0].byte

proc readBytes*(data: string): seq[byte] =
  for c in data:
    result.add readByte(c)

proc toString*(bytes: seq[byte]): string =
  result = newString(bytes.len)
  copyMem(result[0].addr, bytes[0].unsafeAddr, bytes.len)


# Read the bytes directly from the socket
proc readVarInt*(client: AsyncSocket): Future[int32] {.async.} =
  var value: VarInt = 0
  var position = 0
  var currentByte: int32 # Represent a byte as an int32

  while true:
    currentByte = readByte(await client.recv(1)).int32

    var res = currentByte and SEGMENT_BITS
    res = res shl position.SomeInteger
    value = value or res

    if (currentByte and CONTINUE_BIT) == 0:
      break

    position += 7

    if position >= 32:
      raise ValueError.newException("The VarInt is too big! Is it valid?")

  return value

proc readVarLong*(client: AsyncSocket): Future[int64] {.async.} =
  var value: VarLong = 0
  var position = 0
  var currentByte: int32 # Represent a byte as an int32

  while true:
    currentByte = readByte(await client.recv(1)).int32

    var res = (currentByte and SEGMENT_BITS).int64
    res = res shl position.SomeInteger
    value = value or res

    if (currentByte and CONTINUE_BIT) == 0:
      break

    position += 7

    if position >= 64:
      raise ValueError.newException("The VarLong is too big! Is it valid?")

  return value


# Read the bytes from a buffer
proc readVarInt*(bytes: openArray[byte], pos: var int): int32 =
  var value: VarInt = 0
  var position = 0
  var currentByte: int32 # Represent a byte as an int32

  for byt in bytes:
    pos += 1 # Use a position counter to keep track of where we are in the packet
    currentByte = byt.int32

    var res = currentByte and SEGMENT_BITS
    res = res shl position.SomeInteger
    value = value or res

    if (currentByte and CONTINUE_BIT) == 0:
      break

    position += 7

    if position >= 32:
      raise ValueError.newException("The VarInt is too big! Is it valid?")

  return value

proc readVarLong*(bytes: openArray[byte], pos: var int): int64 =
  var value: VarLong = 0
  var position = 0
  var currentByte: int32 # Represent a byte as an int32

  for byt in bytes:
    pos += 1
    currentByte = byt.int32

    var res = (currentByte and SEGMENT_BITS).int64
    res = res shl position.SomeInteger
    value = value or res

    if (currentByte and CONTINUE_BIT) == 0:
      break

    position += 7

    if position >= 64:
      raise ValueError.newException("The VarLong is too big! Is it valid?")

  return value

# Only used in the` readString` method so it can slice off the correct amount of bytes
proc readByteLength*(bytes: openArray[byte]): int64 =
  var length: int = 0
  var position = 0
  var currentByte: int32 # Represent a byte as an int32

  for byt in bytes:
    length += 1

    currentByte = byt.int32

    if (currentByte and CONTINUE_BIT) == 0:
      break

    position += 7

    if position >= 64:
      raise ValueError.newException("The length of the VarInt or varLong is too big!")

  return length

proc readString*(bytes: openArray[byte], pos: var int): string =
  var length = readVarInt(bytes, pos) 
  var varIntBytes = readByteLength(bytes)

  var bytes = bytes[varIntBytes-1..(varIntBytes-1)+length]
  pos += int(varIntBytes + length) - 1

  result = toString(bytes)

# Equivalent in other langs is typically `bytes[0] | bytes[1] << 8`
# We're messing with bitwise operations here to do stuff to get sane values
# -Solaris
proc readUnsignedShort*(bytes: openArray[byte], pos: var int): uint16 =
  pos += 2
  result = bytes[0] or bytes[1] shl 8
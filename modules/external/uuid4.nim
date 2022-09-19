## MIT License
##
## (c) 2022 Matt Cooper
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

import std / [sysrand, strformat, strutils, parseutils, hashes]

type
  Uuid* = object
    bytes: array[16, uint8]
  UuidVariant* {.pure.} = enum
    ApolloNcs, Rfc4122, ReservedMicrosoft, ReservedFuture

proc uuid4*(): Uuid =
  ## Generate a version-4 (random) UUID.
  let success = urandom(dest = result.bytes)
  if success:
    # set version to 4
    result.bytes[6] = (result.bytes[6] and 0x0F) or 0x40
    # set variant to 1 (byte 8 = 10xx xxxx)
    result.bytes[8] = (result.bytes[8] and 0x3F) or 0x80

proc isNil*(self: Uuid): bool =
  ## Determine if this UUID is "nil" (all 0s).
  for byte in self.bytes:
    if byte == 0: continue
    return false
  return true

proc hash*(self: Uuid): Hash =
  for byte in self.bytes:
    result = result !& byte.hash()
  result = !$result

proc `==`*(uuid1, uuid2: Uuid): bool {.inline.} =
  result = uuid1.bytes == uuid2.bytes

proc bytes*(self: Uuid): array[16, uint8] {.inline.} =
  ## Get the big-endian raw bytes of a UUID.
  result = self.bytes

proc normalizeUuidStr(candidateStr: string): string =
  let uuidStr = candidateStr.split('-').join()
  if len(uuidStr) != 32:
    raise newException(ValueError, "expected 8-4-4-4-12 or 32 characters format")
  result = uuidStr

proc initUuid*(uuidStr: string): Uuid =
  ## Parse a UUID from a string (with or without hyphens, any casing).
  let uuidStrClean = normalizeUuidStr(uuidStr)

  # idx is the index into the result's bytes array; it must be doubled
  # to index into the string. We know that the string is 32 characters
  # because we normalized it above.
  assert uuidStrClean.len == 32
  for idx in 0 .. 15:
    let byteStr = uuidStrClean[2*idx .. 2*idx+1]
    if parseHex(byteStr, result.bytes[idx]) != 2:
      raise newException(ValueError,
                          "could not parse a hex character from " &
                          fmt"'{byteStr}' at index {2*idx}")

proc initUuid*(uuidBytes: array[16, uint8]): Uuid =
  ## Create a UUID directly from 16 bytes.
  result.bytes = uuidBytes

proc variant*(self: Uuid): UuidVariant =
  ## Determine the variant of the UUID. Most in the wild are RFC-4122.
  # borrowed tricks from CPython's uuid library
  let invByte = not self.bytes[8]
  if (invByte and 0x80) == 0x80:
    return UuidVariant.ApolloNcs
  elif (invByte and 0x40) == 0x40:
    return UuidVariant.Rfc4122
  elif (invByte and 0x20) == 0x20:
    return UuidVariant.ReservedMicrosoft
  return UuidVariant.ReservedFuture

proc version*(self: Uuid): int =
  ## Determine the version of an RFC-4122 UUID.
  if self.variant == UuidVariant.Rfc4122:
    result = int((self.bytes[6] and 0xF0) shr 4)

proc hexify(bytes: openArray[uint8]): string =
  for byte in bytes:
    result = result & fmt"{byte:02x}"

proc `$`*(self: Uuid): string =
  result =
    hexify(self.bytes[0..3]) &
    "-" &
    hexify(self.bytes[4..5]) &
    "-" &
    hexify(self.bytes[6..7]) &
    "-" &
    hexify(self.bytes[8..9]) &
    "-" &
    hexify(self.bytes[10..15])
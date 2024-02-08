import options, asyncdispatch
import std/strformat

# these imports must be applied to make macro work
import httpbeast
import unibs

import ../iso_server

isomorphic:
  proc read(a: string, b: string, time: int): string = 
    # readFile("src/isoread.nim")
    return fmt"from backend -> {a}; {b}; {time}"

# type
#   ReadReq = object
#     a: string
#     b: string
#     time: int

# proc read(a: string, b: string, time: int): string = 
#   return

run(onApi, initSettings(port=Port(8880), bindAddr="0.0.0.0"))
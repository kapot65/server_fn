import std/asyncjs

import api

# isomorphic:
#   proc read(a: string, b: string, time: int): string =
#     # readFile("src/isoread.nim")
#     return fmt"from backend -> {a}; {b}; {time}"

proc main(): void {.async.} = 
  let resp = await read("AAA", "BBB", 1500)
  echo resp

main()
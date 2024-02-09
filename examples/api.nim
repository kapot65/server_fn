## Sample API that will be used both on server and client side
## 

import std/strformat
import ../src/server_fn

isomorphic:
  proc read*(a: string, b: string, time: int): string =
    # readFile("src/isoread.nim")
    return fmt"from backend -> {a}; {b}; {time}"
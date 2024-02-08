import std/strformat
import ../iso_client

isomorphic:
  proc read(a: string, b: string, time: int): string =
    # readFile("src/isoread.nim")
    return fmt"from backend -> {a}; {b}; {time}"

import std/asyncjs
from std/jsffi import JsObject
import unibs

proc text*(self: JsObject): Future[cstring] {.importjs: "#.$1()".}
const FETCH_CODE = "fetch(#, {method: \"POST\", body: #})"
# custom fetch function (standart not working with POST)
func cFetch(url: cstring, body: cstring): Future[JsObject] {.importjs: FETCH_CODE.}

proc read(a: string, b: string, time: int): Future[string] {.async.} =
  let reqMsg = block:
        let msg = ReadReq(a: a, b: b, time: time)
        msg.serialize

  let resp = await cFetch(
    "http://127.0.0.1:8880/api/read".cstring,
    reqMsg.cstring
  )
  let text = $(await resp.text())
  let outMsg = text.deserialize string
  result = outMsg

proc main(): void {.async.} = 
  let resp = await read("AAA", "BBB", 1234)
  echo resp

main()
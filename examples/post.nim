## Native client for tests

import std/[asyncdispatch, httpclient]

import ../src/server_fn

import unibs

isomorphic:
  proc read(a: string, b: string, time: int): string =
    # readFile("src/isoread.nim")
    return fmt"from backend -> {a}; {b}; {time}"


let message = ReadReq(a: "A_field", b: "B_field", time: 1234).serialize

var client = newHttpClient()
client.headers = newHttpHeaders({ "Content-Type": "application/octet-stream" })
try:
  let response = client.request("http://127.0.0.1:8880/api/read", httpMethod = HttpPost, body = message)
  echo response.body
finally:
  client.close()
import std/strformat

import asyncdispatch, options
import httpbeast

import api
# after using macro:
# 1. all procs defined under macro will be available for calls
# 2. additional proc `onApi(Request)` for use with httpbeast will be created

block:
  let res = read("A", "B", 123) # native call example
  echo fmt"native read call: {res}"

proc onRequest(req: Request): Future[void] =
  # register api routes
  # if call returns false -> api route for path not found
  let api_processed = req.onApi 

  if api_processed == false: # that was not api request -> continue process
    if req.httpMethod == some(HttpGet):
        case req.path.get()
        of "/":
            let indexPage = readFile("examples/index.html")
            req.send(
                Http200, 
                indexPage, 
                "Content-Type: text/html"
            )
        of "/client.js":
            let clientScript = readFile("bin/client.js")
            req.send(
                Http200, 
                clientScript, 
                "Content-Type: application/javascript"
            )
        else:
            req.send(Http404)

run(onRequest, initSettings(port=Port(8880), bindAddr="0.0.0.0"))
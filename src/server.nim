import options, asyncdispatch

import httpbeast

proc onRequest(req: Request): Future[void] =
  if req.httpMethod == some(HttpGet):
    case req.path.get()
    of "/":
        req.send("Hello World")
    of "/api/execfunc":
        req.send(Http200, "{\"a\": 123, \"b\": 345}", "Content-Type: application/json")
    else:
      req.send(Http404)

run(onRequest, initSettings(port=Port(8880), bindAddr="0.0.0.0"))
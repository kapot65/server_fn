import std/macros

import server_fnpkg/base
when defined(js):
    import server_fnpkg/client
else:
    import server_fnpkg/server

when not defined(js):
    proc createServerApi(procDef: NimNode): NimNode =
        
        # TODO: add multiple functions implementation
        let funcName = procDef.extractProcName

        let reqType = createReqType(procDef)
        let reqTypeName = newIdentNode(funcName.makeReqName)
        let reqIdent = newIdentNode("reqMsg")
        let call = createReqCall(reqIdent, procDef)
        let apiPath = newLit(createApiPath(funcName))

        quote do:
            # add required imports
            import httpbeast
            import unibs
            import options, asyncdispatch

            `reqType` # define request type

            `procDef` # define function

            # define api
            proc onApi*(req: Request): Future[void] =
                if req.httpMethod == some(HttpPost):
                    case req.path.get()
                    of `apiPath`:
                        let `reqIdent` = req.body.get().deserialize `reqTypeName`
                        let resp = `call`
                        req.send(
                            Http200, 
                            resp.serialize, 
                            "Content-Type: application/octet-stream"
                        )
                    else:
                        req.send(Http404)

when defined(js):
    proc createApi(procDef: NimNode): NimNode =
        ## Create RPC for given procs
        # TODO: add multiple functions implementation
        
        let reqType = createReqType(procDef)
        let remoteCallProc = createRemoteCall(procDef)

        quote do:
            # required imports
            import std/asyncjs
            from std/jsffi import JsObject
            import unibs

            # add required required procs
            proc text(self: JsObject): Future[cstring] {.importjs: "#.$1()".}
            const FETCH_CODE = "fetch(#, {method: \"POST\", body: #})"
            # custom fetch function (standart not working with POST)
            func cFetch(url: cstring, body: cstring): Future[JsObject] {.importjs: FETCH_CODE.}

            `reqType` # define request type
            `remoteCallProc`

macro isomorphic*(args: untyped): untyped =
    # extract proc definition from block
    var procDef = args[0].copyNimTree

    procDef.expectKind nnkProcDef

    when defined(js):
        createApi(procDef)
    else:
        createServerApi(procDef)

    
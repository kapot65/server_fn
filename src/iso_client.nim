import std/macros
import std/strformat
import std/strutils

import server_fnpkg/base
import server_fnpkg/client


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

        # required procs
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
    createApi(procDef)
import std/macros

import base

func createReq(procDef: NimNode): NimNode = 
    ## Create request params object
    ## 
    ## ex: `ReadReq(a: a, b: b, time: time)` for `read` as function
    let funcParams = procDef[3].copyNimTree

    var call = nnkObjConstr.newTree(
        newIdentNode(makeReqName(procDef.extractProcName)
    ))
    for param in funcParams[1..^1]:
        call.add(
            nnkExprColonExpr.newTree(param[0], param[0])
        )
    nnkStmtList.newTree(call)

proc createRemoteCall(procDef: NimNode): NimNode =
    ## Transform procDef into remote rest API call
    ## 
    ## This func will replace proc body with
    ## serialize req -> send -> receive -> deserialize resp routine
    ## 
    ## ex: for `proc read(a: string, b: string, time: int): string`:
    ## ```nim
    ## proc read(a: string, b: string, time: int): Future[string] {.async.} =
    ##   let reqMsg = block:
    ##      let msg = ReadReq(a: a, b: b, time: time)
    ##      msg.serialize
    ##   let resp = await cFetch("/api/read".cstring, reqMsg.cstring)
    ##   let binary = $(await resp.text())
    ##   let outMsg = binary.deserialize string
    ##   result = outMsg
    ## ```
    
    let funcName = procDef[0].copyNimTree
    let funcRetType = procDef[3][0].copyNimTree

    # make request from initial proc
    var request = procDef.copyNimTree
    request.del(request.len - 1, 1) # delete function body
    # add async pragma
    request[4] = nnkPragma.newTree(newIdentNode("async"))
    # wrap return type into Future
    request[3][0] = nnkBracketExpr.newTree(
        newIdentNode("Future"),
        funcRetType
    )

    # TODO: remove hostname
    let api = createApiPath(procDef.extractProcName)
    
    let recObj = createReq(procDef)

    # and add custom instead
    request.add quote do:
        let reqMsg = block:
            let msg = `recObj`
            msg.toJson()

        let resp = await cFetch(
            `api`.cstring,
            reqMsg.cstring
        )
        let binary = $(await resp.text())
        let outMsg = binary.fromJson(`funcRetType`)
        result = outMsg

    request

proc createApi*(procDefs: NimNode): NimNode =
        ## Create RPC for given procs

        var reqTypes = nnkStmtList.newTree()
        var remoteCallProcs = nnkStmtList.newTree()
        for procDef in procDefs:
            reqTypes.add(createReqType(procDef))
            remoteCallProcs.add(createRemoteCall(procDef))

        quote do:
            # required imports
            import std/asyncjs
            from std/jsffi import JsObject
            import jsony

            # add required required procs
            proc text(self: JsObject): Future[cstring] {.importjs: "#.$1()".}
            const FETCH_CODE = "fetch(#, {method: \"POST\", body: #})"
            # custom fetch function (standart not working with POST)
            func cFetch(url: cstring, body: cstring): Future[JsObject] {.importjs: FETCH_CODE.}

            `reqTypes` # define request type
            `remoteCallProcs`
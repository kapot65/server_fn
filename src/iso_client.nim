import std/macros
import std/strformat
import std/strutils

func makeReqName(funcName: string): string = 
    ## Makes a request parameters type name from proc name
    ## capitalise first letter and adds `Req` to the end
    ## ex: read -> ReadReq 
    # TODO: switch to NimNode arg?
    fmt"{funcName.capitalizeAscii}Req"


func createApiPath(funcName: string): string =
    ## Makes api path for given proc
    ## ex: read => /api/read
    # TODO: switch to NimNode arg?
    fmt"/api/{funcName}"


func createReqType(procDef: NimNode): NimNode =
    ## Create a type from given function input arguments
    ## ex: read(a: string, b: string, time: int) =>
    ## type
    ##   ReadReq = object
    ##     a: string
    ##     b: string
    ##     time: int
    # TODO: make public
    let funcName = procDef[0]
    let funcParams = procDef[3]

    let typeName = funcName.strVal.makeReqName

    var records = nnkRecList.newTree()
    for arg in funcParams[1..^1]:
        records.add(nnkIdentDefs.newTree(
            arg[0], arg[1], newEmptyNode()
        ))

    nnkStmtList.newTree(
        nnkTypeSection.newTree(
            nnkTypeDef.newTree(
                newIdentNode(typeName),
                newEmptyNode(),
                nnkObjectTy.newTree(
                    newEmptyNode(),
                    newEmptyNode(),
                    records
                )
            )
        )
    )

func createReqCall(reqIdent: NimNode, procDef: NimNode): NimNode = 
    ## Create native function call with arguments, taken from 
    ## parameters object.
    ## 
    ## ex: `read(a=reqMsg.a, b=reqMsg.b, time=reqMsg.time)` for
    ## `read` as function and `reqMsg` as reqIdent
    let funcName = procDef[0].copyNimTree
    let funcParams = procDef[3].copyNimTree

    var call = nnkCall.newTree(funcName)
    for param in funcParams[1..^1]:
        call.add(
            nnkExprEqExpr.newTree(
                param[0],
                nnkDotExpr.newTree(
                    reqIdent,
                    param[0]
                )
            )
        )
    nnkStmtList.newTree(call)


func createReq(procDef: NimNode): NimNode = 
    ## Create request params object
    ## 
    ## ex: `ReadReq(a: a, b: b, time: time)` for `read` as function
    let funcName = procDef[0].copyNimTree
    let funcParams = procDef[3].copyNimTree

    var call = nnkObjConstr.newTree(
        newIdentNode(makeReqName(funcName.strVal)
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
    let api = fmt"http://127.0.0.1:8880{createApiPath(funcName.strVal)}"
    let recObj = createReq(procDef)

    # and add custom instead
    request.add quote do:
        let reqMsg = block:
            let msg = `recObj`
            msg.serialize

        let resp = await cFetch(
            `api`.cstring,
            reqMsg.cstring
        )
        let binary = $(await resp.text())
        let outMsg = binary.deserialize string
        result = outMsg

    request


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
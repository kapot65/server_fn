## Helper functions to generate server 

import std/macros

import base

func createReqCall(reqIdent: NimNode, procDef: NimNode): NimNode = 
    ## Create native function call with arguments, taken from 
    ## parameters object.
    ## 
    ## ex: `read` function with `reqMsg` as reqIdent ->
    ## `read(a=reqMsg.a, b=reqMsg.b, time=reqMsg.time)` for
    ## 
    let funcParams = procDef[3].copyNimTree

    var call = nnkCall.newTree(newIdentNode(procDef.extractProcName))
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

func createProcBlocks(procDef: NimNode): (NimNode, NimNode) = 
    ## Create nessessary code blocks for proc
    
    let funcName = procDef.extractProcName

    let reqType = createReqType(procDef)
    let ofBranch = block:
        let reqTypeName = newIdentNode(funcName.makeReqName)
        let reqIdent = newIdentNode("reqMsg")
        let call = createReqCall(reqIdent, procDef)

        nnkOfBranch.newTree(
            newLit(createApiPath(funcName)),
            quote do:
                let `reqIdent` = req.body.get().deserialize `reqTypeName`
                let resp = `call`
                req.send(
                    Http200, 
                    resp.serialize, 
                    "Content-Type: application/octet-stream"
                )
                result = true
        )

    (reqType, ofBranch)

proc createServerApi*(procDefs: NimNode): NimNode =
    # TODO: add docstring
    # case req.path.get()
    # of `apiPath`:
    #     let `reqIdent` = req.body.get().deserialize `reqTypeName`
    #     let resp = `call`
    #     req.send(
    #         Http200, 
    #         resp.serialize, 
    #         "Content-Type: application/octet-stream"
    #     )
    #     result = true
    # else:
    #     result = false

    let req = newIdentNode("req")

    var reqTypes = nnkStmtList.newTree()
    var apiSwitch = nnkStmtList.newTree( # case req.path.get()
        nnkCaseStmt.newTree(
            quote do:
                `req`.path.get()
        )
    )

    for procDef in procDefs:
        let procs = createProcBlocks(procDef.copyNimTree)
        let reqType = procs[0]
        let ofBranch = procs[1]

        reqTypes.add(reqType)
        apiSwitch[0].add(ofBranch)

    apiSwitch[0].add(nnkElse.newTree( # add else: return false
      nnkStmtList.newTree(
        nnkAsgn.newTree(
          newIdentNode("result"),
          newIdentNode("false")
        )
      )
    ))

    quote do:
        # add required imports
        import httpbeast
        import unibs
        import options, asyncdispatch

        `reqTypes` # define request type

        `procDefs` # define function

        # define api
        proc onApi*(`req`: Request): bool =
            if `req`.httpMethod == some(HttpPost):
                `apiSwitch`
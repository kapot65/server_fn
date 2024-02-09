## Helper functions to generate server 

import std/macros

import base

func createReqCall*(reqIdent: NimNode, procDef: NimNode): NimNode = 
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
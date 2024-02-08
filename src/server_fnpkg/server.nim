## Helper functions to generate server 

import std/macros
import std/strformat
import std/strutils

import base

func createReqCall*(reqIdent: NimNode, procDef: NimNode): NimNode = 
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
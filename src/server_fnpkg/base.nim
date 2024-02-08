## Common functions for server_fn macro

import std/macros
import std/strformat
import std/strutils

func makeReqName*(funcName: string): string = 
    ## Makes a request parameters type name from proc name
    ## capitalise first letter and adds `Req` to the end
    ## ex: read -> ReadReq 
    # TODO: switch to NimNode arg?
    fmt"{funcName.capitalizeAscii}Req"

func createApiPath*(funcName: string): string =
    ## Makes api path for given proc
    ## ex: read => /api/read
    # TODO: switch to NimNode arg?
    fmt"/api/{funcName}"

func createReqType*(procDef: NimNode): NimNode =
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
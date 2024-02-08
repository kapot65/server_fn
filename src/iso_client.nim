import std/macros
import std/strformat
import std/strutils

# TODO: switch to NimNode arg?
func makeReqName(funcName: string): string = 
    fmt"{funcName.capitalizeAscii}Req"

# TODO: switch to NimNode arg?
func createApiPath(funcName: string): string =
    fmt"/api/{funcName}"

# create Request type that is used for serialization of function arguments
func createReqType(procDef: NimNode): NimNode =
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

# create native function call
# 
# example: `read(a=reqMsg.a, b=reqMsg.b, time=reqMsg.time)` for
# `read` as function and `reqMsg` as request container 
func createReqCall(reqIdent: NimNode, procDef: NimNode): NimNode = 
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

func createServerApi(procDef: NimNode): NimNode =
    let funcName = procDef[0].strVal

    let reqType = createReqType(procDef)
    let reqTypeName = newIdentNode(funcName.makeReqName)
    let reqIdent = newIdentNode("reqMsg")
    let call = createReqCall(reqIdent, procDef)
    let apiPath = newLit(createApiPath(funcName))

    quote do:
        `reqType` # define request type


func createApi(procDef: NimNode): NimNode = 
    let funcName = procDef[0].strVal
    let funcParams = procDef[3].copyNimTree


macro isomorphic*(args: untyped): untyped =
    # extract proc definition from block
    var procDef = args[0].copyNimTree

    procDef.expectKind nnkProcDef

    createServerApi(procDef)

# dumpAstGen:
#     proc read(a: string, b: string, time: int): string = 
#     # readFile("src/isoread.nim")
#         return fmt"from backend -> {a}; {b}; {time}"
import std/macros
import std/strformat
import std/strutils

import unibs

func makeReqName(name: string): string = 
    fmt"{name.capitalizeAscii}Req"

func createReqType(name: string, params: seq[(NimNode, NimNode)]): NimNode =
    let typeName = name.makeReqName

    var records = nnkRecList.newTree()
    for arg in params:
        let name = arg[0]
        let argType = arg[1]
        records.add(nnkIdentDefs.newTree(
            name, argType, newEmptyNode()
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

func fillReq(name: string, params: seq[(NimNode, NimNode)]): NimNode = 
    let typeName = name.makeReqName

    var objConstr = nnkObjConstr.newTree(newIdentNode(typeName))
    for arg in params:
        let name = arg[0]
        let argType = arg[1]
        objConstr.add(nnkExprColonExpr.newTree(
            name, name
        ))

    nnkStmtList.newTree(
        objConstr
    )

macro isomorphic(args: untyped): untyped =
    # extract proc definition from block
    var firstProc = args[0].copyNimTree

    firstProc.expectKind nnkProcDef

    var funcName: string
    var funcReturn: NimNode
    var funcParams = newSeq[(NimNode, NimNode)](0)

    for child in firstProc:
        case child.kind:
            of nnkIdent:
                funcName = child.strVal
            # of nnkEmpty:
            #     echo "empty" 
            of nnkFormalParams:
                funcReturn = child[0].copyNimTree
                for arg in child[1..child.len-1]:
                    case arg.kind:
                        of nnkIdentDefs:
                            funcParams.add((
                                arg[0].copyNimTree, arg[1].copyNimTree
                            ))
                        else:
                        #     echo "unknown argument node"
                            continue
            else:
                # echo "unknown"
                continue

    echo fmt"""
    name: {funcName}
    arguments: {funcParams}
    return: {funcReturn.astGenRepr}
    """

    let reqType = createReqType(funcName, funcParams)
    let fillCmd = fillReq(funcName, funcParams)

    # make request from initial proc
    var request = firstProc.copyNimTree
    # just delete function body
    request.del(request.len - 1, 1)
    # and add custom instead
    request.add quote do:
        let req = `fillCmd`
        let serialized = req.serialize
        return serialized
    quote do:
        `reqType` # define request type
        `request`

proc read_inner(a: string, b: string) = 
    echo fmt"{a}: {b}"


isomorphic:
    # proc status(): string =
    #     return "OK"

    proc read(a: string, b: string, time: int): string = 
        # readFile("src/isoread.nim")
        return "from backend"

let serialized = read("aaa", "bbb", 123)

let deserialized = serialized.deserialize ReadReq
echo deserialized

dumpAstGen:
    case req.path.get()
    of "/":
        req.send("Hello World")
    of "/api/read":
        req.send(Http200, "{\"a\": 123, \"b\": 345}", "Content-Type: application/json")
    else:
      req.send(Http404)

# dumpAstGen:
#     ReadReq(a: "aaa", b: "bbb", time: 123)

# let req = ReadReq(a: "aaa", b: "bbb", time: 123)
# debugEcho req

# let serialized = req.serialize
# echo serialized


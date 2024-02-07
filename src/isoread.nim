import std/macros
import std/strformat
import std/strutils

func createReqType(name: string, params: seq[(NimNode, NimNode)]): NimNode =
    let typeName = fmt"{name.capitalizeAscii}Req"

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
    
    # var resFunc  = nnkCall.newTree(
    #         newIdentNode(fmt"{funcName}_inner"),
    #     )

    # for arg in funcParams:
    #     resFunc.add(newLit(arg[0].strVal))


    # nnkStmtList.newTree(resFunc)

    # echolastProc.astGenRepr

    # dumpTree:
    #     proc read(filename: string): string = 
    #         readFile("src/isoread.nim")

    # let firstProc = sequence.pop
    # quote do:
    #     `firstProc`

    createReqType(funcName, funcParams)

proc read_inner(a: string, b: string) = 
    echo fmt"{a}: {b}"


dumpAstGen:
    type Foo = object
        i: int

isomorphic:
    proc read(a: string, b: string, time: int) = 
        # readFile("src/isoread.nim")
        echo "AAAA"


let req = ReadReq(a: "aaa", b: "bbb", time: 123)
debugEcho req

import unibs

let serialized = req.serialize
echo serialized

let deserialized = serialized.deserialize ReadReq
echo deserialized
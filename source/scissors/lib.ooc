import structs/[ArrayList, HashMap]

use scissors

use rock

import rock/frontend/[BuildParams, AstBuilder, Token, PathList]
import rock/middle/[Module, FunctionDecl, TypeDecl, Scope, Block, ControlStatement]
import rock/middle/tinker/[Tinkerer, Errors]

use llvm

import llvm/[Core, ExecutionEngine, Target]

Scissors: class {

    params: BuildParams

    init: func {
        params = BuildParams new("rock")
        params verbose = false
        params sourcePath add(params sdkLocation path)
        params errorHandler = ScissorsErrorHandler new() as ErrorHandler
    }

    addPath: func (s: String) {
        params sourcePath add(s)
    }

    swap: func (oldModule: String, newModule: String, type: String, method: String) {
        oldie := parseModule(oldModule)
        oldie parseImports(null)

        kiddo := parseModule(newModule) 

        swapper := Swapper new(oldie, kiddo, type, method, params)
        swapper resolve()
    }

    parseModule: func (moduleName: String) -> Module {
        (moduleFile, pathElement) := params sourcePath getFile(moduleName)
        if (!moduleFile) {
            "File not found: %s" printfln(moduleName)
            exit(1)
        }

        modulePath := moduleFile path
        fullName := moduleName[0..-5]
        module := Module new(fullName, pathElement path, params, nullToken)

        AstBuilder new(modulePath, module, params)
        module
    }

}

Swapper: class {

    oldie, kiddo: Module
    methodDef: FunctionDecl
    params: BuildParams
    tinkerer: Tinkerer

    init: func (=oldie, =kiddo, type: String, method: String, =params) {
        tinkerer = Tinkerer new(params)

        typeDef := oldie getTypes() get(type)
        methodDef = typeDef getMeta() getFunctions() get(method)

        oldBody := methodDef body
        newBody := kiddo body list[0]

        "---------------------------" println()
        "old body = %s" printfln(oldBody toString())
        "new body = %s" printfln(newBody toString())
        "---------------------------" println()

        if (!newBody instanceOf?(Block)) {
            "[scissors] Error: new body is a %s, not a Block" printfln(newBody class name)
            return false
        }

        // Swap bodies. For proof, refer to Keeler's Theorem.
        methodDef body = (newBody as Block) body
    }

    resolve: func {
        tinkerSuccess := tinkerer process(oldie collectDeps())
        if (!tinkerSuccess) {
            "[scissors] Could not tinker!" println()
        }
        "[scissors] Done tinkering" println()

        // now print the body again
        "[scissors] resolved body = %s" printfln(methodDef body toString())
    }

}

ScissorsErrorHandler: class implements ErrorHandler {

    onError: func (e: Error) {
        "Compilation error: " println()
        e format() println()
    }

}



import structs/[ArrayList, HashMap]

use scissors

use rock

import rock/frontend/[BuildParams, AstBuilder, Token, PathList]
import rock/middle/[Module, FunctionDecl, TypeDecl, Scope, Block, ControlStatement]
import rock/middle/tinker/Tinkerer

use llvm

import llvm/[Core, ExecutionEngine, Target]

Scissors: class {

    params: BuildParams

    init: func {
        params = BuildParams new("rock")
        params verbose = true // cool for debugging
        params sourcePath add(params sdkLocation path)
    }

    addPath: func (s: String) {
        params sourcePath add(s)
    }

    swap: func (oldModule: String, newModule: String, type: String, method: String) {
        oldie := parseModule(oldModule)
        oldie parseImports(null)

        kiddo := parseModule(newModule) 

        typeDef := oldie getTypes() get(type)
        methodDef := typeDef getMeta() getFunctions() get(method)

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

        // type to swap bodies!
        methodDef body = (newBody as Block) body

        // now resolve all that...
        tinkerSuccess := Tinkerer new(params) process(oldie collectDeps())
        if (!tinkerSuccess) {
            "[scissors] Could not tinker!" println()
        }

        "[scissors] Done tinkering" println()

        // now print the body again
        "[scissors] resolved body = %s" printfln(newBody toString())

        // now JIT compile it :)
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


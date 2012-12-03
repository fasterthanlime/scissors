use scissors
use rock

import structs/[ArrayList, HashMap]

import rock/frontend/[BuildParams, AstBuilder, Token, PathList]
import rock/middle/[Module, FunctionDecl, TypeDecl]

Scissors: class {

    params: BuildParams

    init: func {
        params = BuildParams new("rock")
        params verbose = true // cool for debugging
    }

    addPath: func (s: String) {
        params sourcePath add(s)
    }

    swap: func (oldModule: String, newModule: String, type: String, method: String) {
        oldie := parseModule(oldModule)
        kiddo := parseModule(newModule) 

        typeDef := oldie getTypes() get(type)
        methodDef := typeDef getMeta() getFunctions() get(method)

        oldBody := methodDef body
        newBody := kiddo body list[0]

        "---------------------------" println()
        "old body = %s" printfln(oldBody toString())
        "new body = %s" printfln(newBody toString())
        "---------------------------" println()
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



use scissors
use rock

import structs/ArrayList

import rock/frontend/[BuildParams, AstBuilder, Token]
import rock/middle/[Module, FunctionDecl, TypeDecl]

main: func (args: ArrayList<String>) {

    if (args size < 2) {
	"Usage: scissors FILE.ooc" printfln()
        "(Note: the file path has to be relative)" println()
	exit(1)
    }

    params := BuildParams new("rock")
    params sourcePath add(".")

    moduleName := args[1]
    (moduleFile, pathElement) := params sourcePath getFile(moduleName)
    if (!moduleFile) {
	"File not found: %s" printfln(moduleName)
	exit(1)
    }

    modulePath := moduleFile path
    fullName := moduleName[0..-5]
    module := Module new(fullName, pathElement path, params, nullToken)

    ast := AstBuilder new(modulePath, module, params)

    walkModule(module)

}

walkModule: func (module: Module) {
    "## %s" printfln(module fullName)

    println()
    "### Functions" println()
    for(f in module functions) {
	walkFunction(f)
    }

    println()
    "### Types" println()
    for(t in module types) {
	walkType(t)
    }
}

walkFunction: func (f: FunctionDecl) {
    " - %s" printfln(f toString())
}

walkType: func (t: TypeDecl) {
    " - %s" printfln(t toString())
}


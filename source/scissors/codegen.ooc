
use llvm

import llvm/[Core, ExecutionEngine, Target]

use rock

import rock/middle/[FunctionDecl]

Generator: class {

    init: func {
        LLVMLinkInJIT()
        Target initializeNative()
    }

    compile: func (fd: FunctionDecl) -> Pointer {
        module := Module new("scissors")

        int_ := Type int32()
        function := module addFunction("random", Type function(int_))

        // dump our module for debugging purposes
        module dump()

        provider := ModuleProvider new(module)
        engine := ExecutionEngine new(provider)

        addr := engine recompileAndRelinkFunction(function)
        addr
    }

}


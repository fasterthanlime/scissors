
use llvm

import llvm/[Core, ExecutionEngine, Target]

use rock

import rock/middle/[FunctionDecl, Type, Scope, Return, Statement, Cast, IntLiteral,
        Expression]

Generator: class {

    method: FunctionDecl

    module: LModule
    builder: LBuilder
    function: LFunction

    provider: LModuleProvider
    engine: LExecutionEngine

    initialize: static func {
        LLVMLinkInJIT()
        LTarget initializeNative()
    }

    init: func (=method) {
        module = LModule new("scissors")

        fType := LType function(toLType(method getReturnType()))
        function = module addFunction("scissors", fType)

        builder = function builder()

        provider = LModuleProvider new(module)
        engine = LExecutionEngine new(provider)
    }

    compile: func -> Pointer {
        walkFunction(method)

        // dump our module for debugging purposes
        module dump()

        addr := engine recompileAndRelinkFunction(function)
        addr
    }

    toLType: func (t: Type) -> LType {
        if (t getName() == "Int") {
            LType int32()
        } else {
            Exception new("[scissors] Unsupported type: %s" format(t toString())) throw()
        }
    }

    walkFunction: func (method: FunctionDecl) {
        for (stat in method body list) {
            walkStatement(stat)
        }
    }

    walkStatement: func (stat: Statement) {
        match stat {
            case ret: Return =>
                builder ret(walkExpression(ret expr))
            case =>
                Exception new("[scissors] Unsupported statement: %s" format(stat toString())) throw()
        }
    }

    walkExpression: func (expr: Expression) -> LValue {
        match expr {
            case cast: Cast =>
                // TODO: support other types of casts
                builder intCast(walkExpression(cast inner), toLType(cast getType()), "casted")
            case ilit: IntLiteral =>
                LValue constInt(LType int64(), ilit value, true)
            case =>
                Exception new("[scissors] Unsupported expression: %s" format(expr toString())) throw()
                // That's stupid, but rock won't leave us alone otherwise..
                // (It doesn't detect that we throw an exception)
                LValue constPointerNull(LType pointer(LType void_()))
        }
    }

}



import structs/[ArrayList, HashMap]

use scissors
import scissors/Set

use llvm
import llvm/[Core, ExecutionEngine, Target]

use rock
import rock/middle/[FunctionDecl, Type, Scope, Return, Statement, Cast, IntLiteral,
        Expression, BinaryOp, Parenthesis, VariableDecl, VariableAccess]

TypeKind: enum {
    INT
    FLOAT
    OBJECT
    STRUCT
    UNKNOWN
}

Generator: class {

    method: FunctionDecl

    module: LModule
    builder: LBuilder
    function: LFunction

    provider: LModuleProvider
    engine: LExecutionEngine

    passManager: LPassManager

    varmap := HashMap<VariableDecl, LValue> new()

    init: func (=method) {
        module = LModule new("scissors")

        fType := LType function(toLType(method getReturnType()))
        function = module addFunction("scissors", fType)

        builder = function builder()

        provider = LModuleProvider new(module)
        engine = LExecutionEngine new(provider)

        passManager = module createFunctionPassManager()
        passManager addPromoteMemoryToRegisterPass()
        passManager addConstantPropagationPass()
    }

    compile: func -> Pointer {
        walkFunction(method)

        // first, verify our module
        success := function verify(LVerifierFailureAction printMessage)
        if (success != 0) {
          "Invalid code generated, bailing out" println()
          Exception new("Invalid code generated") throw()
        }

        // dump our module for debugging purposes
        module dump()

        // optimize!
        passManager run(function)

        // dump again after optimization
        println()
        "==================================" println()
        "Post-optimization, module = " println()
        "==================================" println()
        println()

        module dump()

        addr := engine recompileAndRelinkFunction(function)
        addr
    }

    toLType: func (t: Type) -> LType {
        match (t getName()) {
            // Standard integer types
            case "Char" || "Int8" || "UChar" || "UInt8" || "Octet" || "Bool" =>
                LType int8()
            case "Int16" || "UInt16" =>
                LType int16()
            case "Int32" || "UInt32" =>
                LType int32()
            case "Int64" || "UInt64" =>
                LType int64()

            // Variable-sized integer types
            case "SizeT" || "SSizeT" =>
                toIntLType(SizeT size)
            case "Short" || "UShort" =>
                toIntLType(Short size)
            case "Int" || "UInt" =>
                toIntLType(Int size)
            case "Long" || "ULong" =>
                toIntLType(Long size)
            case "LLong" || "ULLong" =>
                toIntLType(ULLong size)

            // Floating point types
            case "Float" =>
                LType float_()
            case "Double" =>
                LType double_()
            case "LDouble" =>
                // Disclaimer: there's a chance 128-bit
                // floating point numbers just won't work at all.
                LType fp128()

            case =>
                Exception new("[scissors] Unsupported type: %s" \
                    format(t toString())) throw()
                LType void_()
        }
    }

    toIntLType: func (byteWidth: Int) -> LType {
        match byteWidth {
            case 1  => LType int8()
            case 2  => LType int16()
            case 4  => LType int32()
            case 8  => LType int64()
            case =>
                Exception new("[scissors] Unsupported byte width for int: %d" \
                    format(byteWidth)) throw()
                LType void_()
        }
    }

    typeKind: func (t: Type) -> TypeKind {
        if (intTypes contains?(t getName())) {
            TypeKind INT      
        } else {
            TypeKind UNKNOWN
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
            case vDecl: VariableDecl =>
                var := builder alloca(toLType(vDecl getType()), vDecl name)
                varmap put(vDecl, var)

                if (vDecl expr) {
                    builder store(cast(walkExpression(vDecl expr), toLType(vDecl getType())), var)
                }
            case =>
                Exception new("[scissors] Unsupported statement: %s" \
                    format(stat class name)) throw()
        }
    }

    walkExpression: func (expr: Expression) -> LValue {
        match expr {
            case cast: Cast =>
                cast(walkExpression(cast inner), toLType(cast getType()))
            case ilit: IntLiteral =>
                LValue constInt(LType int64(), ilit value, true)
            case binop: BinaryOp =>
                walkBinaryOp(binop) 
            case paren: Parenthesis =>
                walkExpression(paren inner)
            case vAcc: VariableAccess =>
                walkVariableAccess(vAcc) 
            case =>
                Exception new("[scissors] Unsupported expression: %s" \
                    format(expr class name)) throw()
                nullValue()
        }
    }

    walkVariableAccess: func (vAcc: VariableAccess) -> LValue {
        ref := vAcc getRef()

        match ref {
            case vDecl: VariableDecl =>
                if (!varmap contains?(vDecl)) {
                    Exception new("[scissors] Variable decl accessed before it's declared: %s" \
                        format(vDecl toString())) throw()
                }
                builder load(varmap get(vDecl), vDecl getName() + "Load")
            case =>
                Exception new("[scissors] Unsupported type of access ref: %s" \
                    format(ref class name)) throw()
                nullValue()
        }
    }


    cast: func (val: LValue, type:  LType) -> LValue {
        // TODO: support other types of casts
        builder intCast(val, type, "castResult")
    }

    walkBinaryOp: func (binop: BinaryOp) -> LValue {
        kind := typeKind(binop getType())
        match kind {
            case TypeKind INT =>
                walkIntBinaryOp(binop)
            case =>
                Exception new("[scissors] Unsupported typekind: %d" \
                    format(kind)) throw()
                nullValue()
        }
    }

    walkIntBinaryOp: func (binop: BinaryOp) -> LValue {
        lhs := cast(walkExpression(binop left ), toLType(binop getType()))
        rhs := cast(walkExpression(binop right), toLType(binop getType()))

        match (binop type) {
            case OpType add =>
                builder add(lhs, rhs, "add")
            case OpType sub =>
                builder sub(lhs, rhs, "sub")
            case OpType mul =>
                builder mul(lhs, rhs, "mul")
            case OpType div =>
                // TODO: handle unsigned div
                builder sdiv(lhs, rhs, "sdiv")
            case =>
                Exception new("[scissors] Unsupported int binary operator: %s" \
                    format(opTypeRepr[binop type])) throw()
                nullValue()
        }
    }

    nullValue: func -> LValue {
        LValue constPointerNull(LType pointer(LType void_()))
    }

    intTypes: static Set<String>

    initialize: static func {
        LLVMLinkInJIT()
        LTarget initializeNative()

        initializeTypes()
    }

    initializeTypes: static func {
        intTypes = Set<String> new()
        intTypes add("Int")
        intTypes add("UInt")
        intTypes add("Int32")
        intTypes add("UInt32")
        intTypes add("Int64")
        intTypes add("UInt64")
        intTypes add("SizeT")
        intTypes add("SSizeT")
        intTypes add("Char")
        intTypes add("UChar")
        intTypes add("Short")
        intTypes add("UShort")
        intTypes add("Long")
        intTypes add("ULong")
        intTypes add("LLong")
        intTypes add("ULLong")
    }

}


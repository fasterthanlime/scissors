
doStaff: func (s: Something) {
    "manually swapped" println()
}

Something: class {

    doStuff: func {
	"doStaff" println()
    }

}

main: func {
    s := Something new()
    s doStuff()

    Something doStuff = doStaff as Pointer
    s doStuff()

    s2 := Something new()
    s doStuff()
}


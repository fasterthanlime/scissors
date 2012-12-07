
use scissors
import scissors/lib

import dice

App: class {

    s: Scissors

    init: func {
        s = Scissors new()
        s addPath("samples")
    }

    run: func {
        d := Dice new()
        "===========================" println()
        d roll()
        "===========================" println()
        println()

        Dice generate = s swap("dice.ooc", "newdice.ooc", "Dice", "generate")

        println()
        "===========================" println()
        d roll()
        "===========================" println()
        println()
    }

}

main: func {

    app := App new()
    app run()

}



use scissors
import scissors/lib

import dice

main: func {

    d := Dice new()
    "===========================" println()
    d roll()
    "===========================" println()
    println()

    // do the scissors stuff
    s := Scissors new()
    s addPath("samples")

    s swap("dice.ooc", "newdice.ooc", "Dice", "generate")

    println()
    "===========================" println()
    d roll()
    "===========================" println()
    println()

}


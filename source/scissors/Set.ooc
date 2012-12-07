
import structs/HashMap

Set: class <T> {

    map := HashMap<T, Pointer> new()

    init: func {

    }

    add: func (t: T) {
        map put(t, null)
    }

    contains?: func (t: T) -> Bool {
        map contains?(t)
    }

}


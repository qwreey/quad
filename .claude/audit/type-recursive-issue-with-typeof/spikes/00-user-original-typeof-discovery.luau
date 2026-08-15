--!strict

const function Apply<T, U>(self: State<T>, func: (State<T>) -> U): U
    return nil :: any
end
const function Compute<T, U>(self: State<T>, func: (State<T>) -> U): State<U>
    return nil :: any
end
const function Get<T>(self: State<T>): T
    return nil :: any
end

type State<T> = {
    read Apply: typeof (Apply),
    read Get: typeof (Get),
    read Compute: typeof (Compute),
    read value: T,
}

const test = (nil :: any)::State<number>

-- TypeError: Expected this to be 'string', but got 'number'
const testres_1: string = test:Apply(function(a0)
    return 0
end)

-- TypeError: Expected this to be
-- 'State<boolean>'
-- but got ...
const testres_2: State<boolean> = test:Compute(function(a0)
    return 0
end)

-- OK. no type error
const testres_2: State<boolean> = test:Compute(function(a0)
    return true
end)
-- But every a0 is unknown. so we must bind it. i will find out more

function Mapper(a0: State<boolean>): number
    return 1
end
-- TypeError: Expected this to be 'boolean', but got 'number'
-- error in upstream test, not Compute(Mapper)
-- red line under 'test'
-- i think this is might be ok
test:Compute(Mapper)
-- Same error
test:Compute(function(a0: State<boolean>)
    return 1
end)

-- OK
const testres_3 = test:Compute(function(a0: State<number>)
    return 1
end)
-- TypeError: Expected this to be 'string', but got 'number'
const testres_4: string = testres_3:Get()

-- Error
-- TypeError: Expected this to be
-- 'State<boolean>'
-- but got ...
const testres_5: State<boolean> = test:Compute(function(a0: State<number>)
    return 1
end)

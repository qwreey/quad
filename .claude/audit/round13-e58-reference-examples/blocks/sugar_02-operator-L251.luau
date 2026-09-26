local optionalName = q.Source<<string?>>(nil)
local safeName: State<string> = optionalName:Apply(Op.Alternative("Guest")) -- "Guest"

type Palette = { Primary: string, Size: number }
local palette = q.Source<<Palette>>({ Primary = "red", Size = 10 })

local primary: State<string> = palette:Apply(Op.Indexed<<string>>("Primary"))
local size: State<number> = palette:Apply(Op.Indexed<<number>>("Size"))
local missing: State<string?> = palette:Apply(Op.Indexed<<string?>>("Nope")) -- nil

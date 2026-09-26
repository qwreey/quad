-- source: SKILL.md:236-248
type ThemeStore = QuadTypes.Store<{ Accent: QuadTypes.Source<Color3> }>
local themeStore = q.Store { Accent = q.Source(Color3.fromRGB(0, 120, 255)) }

-- 1. provider keys: distinct table identities, use an explicit type argument to give them a type
local ThemeProvider = q.Context.Provider<<ThemeStore>>("Theme")

-- 2. populate at the root; :Set mutates the bag and returns it
local ctx = q.Context():Set(ThemeProvider, themeStore)

-- 3. leaves read with :Get (errors when unset) or :Peek (nil when unset)
local theme = ctx:Get(ThemeProvider)

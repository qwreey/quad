--!nonstrict
-- GS 15#5 그대로
const q = require("./Quad")
export type Theme = { Accent: Color3 }
return {
    Provider = q.Context.Provider("Theme") :: q.Provider<Theme>,
}

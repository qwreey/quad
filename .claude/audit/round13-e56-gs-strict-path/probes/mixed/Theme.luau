--!strict
-- GS 15#1 + 15#5 타입판(GS 15 "ctx:Get(...)의 타입은 어디서 오나요?" — 문서 안)
const q = require("./Quad")
export type Theme = { Accent: Color3 }
return {
    Provider = q.Context.Provider("Theme") :: q.Provider<Theme>, -- [GS15 §typed / 08§7]
}

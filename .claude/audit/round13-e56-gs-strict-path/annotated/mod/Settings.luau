--!strict
-- GS 16#3 — E56 주석판. 가방 값은 q.Store(...)인데 설정 모듈이 Store<T>를 재수출하지 않는다 → 값 모양만 적는다
const q = require("./Quad")
export type Settings = { Step: q.Source<number> } -- Store<T> = T & {...}이므로 Store 값은 이 모양의 하위 타입
return {
    Provider = q.Context.Provider("Settings") :: q.Provider<Settings>, -- [GS15 패턴 적용]
}

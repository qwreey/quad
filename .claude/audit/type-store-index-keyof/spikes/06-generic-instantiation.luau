--!strict
type Source<T> = { Value: T, Revision: number }
type Store = {
	GetDynamic: <T>(self: Store, name: string) -> Source<T>,
	[string]: any,
}

local store = (nil :: any) :: Store

-- 양성: 명시 인스턴스화가 T를 묶는가
local ok: Source<number> = store:GetDynamic<<number>>("x")
-- 음성 대조군: 묶였다면 여기서 반드시 걸려야 한다
local bad: Source<string> = store:GetDynamic<<number>>("y")
-- 인스턴스화 생략하면?
local none: Source<number> = store:GetDynamic("z")

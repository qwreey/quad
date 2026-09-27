--!strict
-- E70 strict (generated) — how-to_01-component-conventions-L93
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_01-component-conventions-L14) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local None = q.None

-- 값이 아니라 '타입 이름'을 가져오는 모듈
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.StateMarker<T>` 등)
-- 클래스별 Modifier·요소 타입(`TextButtonModifier`/`IntoTextButton`/`FrameElem` 등)은 quad_roblox 패키지 루트가 내보낸다
local RobloxModule = require("../../../../quad-roblox/src")
--[[E70 보강 pre]]
local props: { Modifier: RobloxModule.TextButtonModifier?, Ref: q.Ref<TextButton?>? } = {}
-- ==== doc block how-to/01-component-conventions.md:93 ====
-- ❌ props.Modifier가 없으면 1번 자리가 구멍이 된다 — 그 자리에서 에러
D.TextButton { props.Modifier, props.Ref, Text = "x" }

-- ✅ None이 자리를 지킨다 — 기여는 0이지만 위치는 그대로
D.TextButton { props.Modifier or None, props.Ref or None, Text = "x" }

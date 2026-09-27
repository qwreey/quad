--!strict
-- E70 strict (generated) — how-to_01-component-conventions-L250
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
-- ==== doc block how-to/01-component-conventions.md:250 ====
local function CharacterBadge(props: { read Name: string, read Level: QuadTypes.StateMarker<number> }): Frame
    return D.Frame {
        -- [1] CollectionService 태그 (여러 자리의 요구를 합집합으로 관리)
        q.Tag("PlayerBadge", "Interactable"),

        -- [2] 어트리뷰트 그룹 — 값은 리터럴이어도 State여도 된다
        q.Attr {
            CharacterName = props.Name,
            Level = props.Level,
            Guild = "Alpha",
        },

        D.TextLabel {
            Text = props.Name,
        },
    }
end

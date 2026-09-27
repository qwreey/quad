-- GoldDisplay.luau (UI 레이어)
local q = require("@game/ReplicatedStorage/Client/UI/Quad") -- 01장의 설정 모듈
local D = q.Declaration
local ProfileStore = require("./PlayerProfileState")

local function withCommas(n: number): string
    local s = tostring(math.floor(n))
    local replaced = 1
    while replaced > 0 do
        s, replaced = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
    end
    return s
end

local function GoldDisplay()
    -- 파생 상태는 props 테이블 밖에서(함수 인자 테이블 안의 인라인 :Compute는
    -- 에디터 타입 검사에서 무주석 콜백 파라미터를 못 푼다)
    local goldText: q.State<string> = ProfileStore.Gold:Compute(function(gold)
        return `보유 골드: {withCommas(gold:Get())} G`
    end)

    return D.TextLabel {
        Text = goldText,
        TextColor3 = Color3.fromRGB(255, 215, 0),
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
    }
end

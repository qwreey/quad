--!strict
-- E56 (4b): how-to 01의 luau 펜스를 문서 순서대로 이어 붙임(블록 4는 의도된 ❌ 조각이라 제외). 프롤로그 경로만 로컬(한 벌).
-- block 1 (how-to 01:14)
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local None = q.None

-- 값이 아니라 '타입 이름'을 가져오는 모듈
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.StateMarker<T>` 등)
-- 클래스별 Modifier·요소 타입(`TextButtonModifier`/`IntoTextButton`/`FrameElem` 등)은 quad_roblox 패키지 루트가 내보낸다
local RobloxModule = require("../../../../quad-roblox/src")

do -- block 2 (how-to 01:34)
local isHovered = q.Source(false)
local CommonButtonModifier = D.Modifier.Frame {
    BorderSizePixel = 0,
}

D.Frame {
    -- [1] 문자 키: 프로퍼티 바인딩 (정적 값 또는 반응형 State/Tween)
    Size = UDim2.new(0, 200, 0, 50),
    BackgroundColor3 = isHovered:Compute(function(h)  -- 편집기 타입 검사까지 보려면 지역 변수로 빼세요(02 §4)
        return if h:Get() then Color3.fromRGB(80, 120, 240) else Color3.fromRGB(50, 50, 60)
    end),

    -- [2] 문자 키: 이벤트 리스너 (엔진이 주는 인자만 받는다 — self는 안 온다)
    MouseEnter = function() isHovered:Set(true) end,
    MouseLeave = function() isHovered:Set(false) end,

    -- [3] 숫자 키: 재사용 가능한 스타일 (Modifier)
    CommonButtonModifier,

    -- [4] 숫자 키: 자식 요소
    D.TextLabel {
        Text = "클릭하세요",
    },
}

end
do -- block 3 (how-to 01:74)
local function MaterialButton(props: { read Text: string?, read Modifier: RobloxModule.TextButtonModifier?, read Ref: q.Ref<TextButton?>? }): TextButton
    return D.TextButton {
        props.Modifier or None, -- ⭐ 숫자 키 자리에서만 의미가 있는 관용구
        props.Ref or None,

        Text = props.Text or "",
    }
end

end
do -- block 5 (how-to 01:126)
type ButtonProps = {
    read Text: string | QuadTypes.StateMarker<string>,
    read OnClick: () -> (),
    read Modifier: RobloxModule.TextButtonModifier?,
    read Ref: q.Ref<TextButton?>?,
}

local function CustomButton(props: ButtonProps): TextButton
    -- [1] TextButton 전용으로 태그된 기본 스타일
    local baseStyle = D.Modifier.TextButton {
        Size = UDim2.fromOffset(140, 40),
        BackgroundColor3 = Color3.fromRGB(0, 140, 240),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
    }

    return D.TextButton {
        -- [2] 불변식 2 — 뒤에 온 props.Modifier가 baseStyle을 필드 단위로 덮는다
        baseStyle,
        props.Modifier or None,
        props.Ref or None,

        -- [3] 불변식 1 — 문자 키는 어떤 Modifier도 덮지 못한다
        Text = props.Text,
        MouseButton1Click = props.OnClick,   -- 마우스 좌클릭만 받는 엔진 이벤트 — 게임패드·터치까지 받으려면 시작하기의 Activated
        UICorner = 8,
    }
end

-- (block 6 continues block 5)
do -- block 6-inner (how-to 01:161)
-- 기본 스타일 그대로
local btn1 = CustomButton { Text = "확인", OnClick = function() print("기본 버튼") end }

-- 크기와 색상만 위험 버튼으로 커스텀
local btn2 = CustomButton {
    Text = "삭제",
    OnClick = function() print("삭제 버튼") end,
    Modifier = D.Modifier.TextButton {
        BackgroundColor3 = Color3.fromRGB(240, 60, 60),
        Size = UDim2.fromOffset(100, 36),
    },
}

end
end
do -- block 7 (how-to 01:186)
local function ModalDialog(props: { read Title: string, read Children: q.Slot<Instance>? }): Frame
    return D.Frame {
        Size = UDim2.fromOffset(400, 300),
        BackgroundColor3 = Color3.fromRGB(25, 25, 30),

        -- 헤더 타이틀
        D.TextLabel {
            Text = props.Title,
            Size = UDim2.new(1, 0, 0, 40),
        },

        -- 전달받은 Slot을 컨텐츠 영역의 한 자리로 놓는다
        D.Frame {
            Position = UDim2.fromOffset(0, 40),
            Size = UDim2.new(1, 0, 1, -40),
            BackgroundTransparency = 1,

            props.Children or None,
        },
    }
end

end
do -- block 8 (how-to 01:228)
local function Rows(props: { read Items: { string } })
    local rows = q.Slot<<Instance>>()
    for _, text in props.Items do
        rows:Add(D.TextLabel { Text = text })
    end
    return rows
end

local list = D.Frame {
    D.TextLabel { Text = "머리" },
    Rows { Items = { "a", "b" } },   -- 자식 셋: 머리 + a + b
}

end
do -- block 9 (how-to 01:250)
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

end
do -- block 10 (how-to 01:290)
local function newCounter(initial: number)
    local count = q.Source(initial)
    -- --!strict에서는 :Compute 콜백 파라미터에 주석이 필요하다
    local isEven: q.State<boolean> = count:Compute(function(c: q.StateData<number>): boolean
        return c:Get() % 2 == 0
    end)

    local function increment()
        count:Set(count:Get() + 1)
    end

    return { count = count, isEven = isEven, increment = increment }
end

-- 컴포넌트 안에서, 조건문 안에서, 루프 안에서 아무 제약 없이 호출 가능
local left, right = newCounter(0), newCounter(10)

end

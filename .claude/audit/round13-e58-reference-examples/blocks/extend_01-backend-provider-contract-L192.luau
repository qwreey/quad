-- `Quad`는 위 프롤로그에서 require한 quad-base 모듈
local customWidgetNamespace = { -- 이 백엔드가 얹는 고유 표면
    Button = function(props: any): any
        return props
    end,
}

local function CustomProvider(quad: any)
    -- [1] 주입 슬롯을 채운다(§2~§5 전부 — 하나라도 빠지면 그 op는 안내 스텁 에러로 남는다)
    quad.Backend.nativeInsert = function(target: any, _offset: number, elements: { any })
        for _, element in elements do
            element.Parent = target
        end
    end
    -- ... 나머지 19개 슬롯 ...

    -- [2] 백엔드 고유 표면을 확장 테이블로 반환한다
    return {
        Widget = customWidgetNamespace,
    }
end

local q = Quad.New():UseProvider(CustomProvider)

--!strict
-- [P4] "생성 D" 대신 **타입 함수가 클래스 타입에서 직접** props 테이블/Modifier 테이블을 만든다면
-- Studio에서도 같은 진단과 자동완성이 나오는가. 리눅스 luau-lsp 1.69.0에서는 전부 통과했다.
-- 보고할 것:
--   (4-a) 아래 "에러여야 정상" 줄들에 실제로 빨간 줄이 뜨는가(메시지 원문 한두 개).
--   (4-b) ★ 자동완성 ★ — 표시된 자리에서 키를 치기 시작하거나 Ctrl+Space를 눌렀을 때
--         프로퍼티 이름 목록이 뜨는가. 오늘의 생성 D(05번 파일)와 비교해서 목록이 같은가/느린가.
--   (4-c) 체이닝(m:X():Y():Z())에서 메소드 자동완성이 뜨는가.
--   (4-d) 스크립트 분석 창에 "too complex"류 에러가 뜨는가.

type Deny = "AbsolutePosition" | "AbsoluteRotation" | "AbsoluteSize" | "ClippedRect" | "RawRect2D" | "GuiState" | "Parent" | "ClassName" | "SelectionRect2D" | "TotalGroupScale" | "IsNotOccluded"

-- props 테이블 타입: 스칼라는 T | Tween데이터 | State마커 | None | nil
type function ParamOf(cls: type, elem: type, deny: type)
	-- 인라인 테이블 리터럴은 `{read: type?, write: type?}` 주석이 필요해 헬퍼로 뺀다(신 솔버가 본문도 검사한다)
	local function tbl(k1: string, v1: type, k2: string?, v2: type?): type
		local m: { [type]: { read: type?, write: type? } } = {}
		m[types.singleton(k1)] = { read = v1, write = v1 }
		if k2 ~= nil and v2 ~= nil then
			m[types.singleton(k2)] = { read = v2, write = v2 }
		end
		return types.newtable(m)
	end
	local tweenable = {
		number = true,
		boolean = true,
		CFrame = true,
		Rect = true,
		Color3 = true,
		UDim = true,
		UDim2 = true,
		Vector2 = true,
		Vector3 = true,
	}
	local denied: { [any]: boolean } = {}
	if deny.tag == "union" then
		for _, c in deny:components() do
			if c.tag == "singleton" then
				denied[c:value()] = true
			end
		end
	end
	local trueT = types.singleton(true)
	local nilT = types.singleton(nil)
	local noneT = tbl("__quadNone", trueT)
	local props: { [type]: { read: type?, write: type? } } = {}
	local cur = cls
	local depth = 0
	while cur ~= nil and depth < 12 do
		for k, v in cur:properties() do
			local name = k:value()
			if type(name) == "string" and not denied[name] and props[k] == nil then
				local ty = v.write or v.read
				if ty ~= nil and ty.tag ~= "function" then
					local arms: { type } = {}
					local conn = if ty.tag == "table" then ty:readproperty(types.singleton("Connect")) else nil
					if conn ~= nil and conn.tag == "function" then
						local head = conn:parameters().head
						local cb = if head ~= nil then head[2] else nil
						if cb ~= nil then
							arms[#arms + 1] = cb
							arms[#arms + 1] = tbl("__quadState", trueT, "__quadStateValue", cb)
						end
					else
						arms[#arms + 1] = ty
						if tweenable[tostring(ty)] then
							arms[#arms + 1] = tbl("__quadTween", trueT, "Value", ty)
						end
						arms[#arms + 1] = tbl("__quadState", trueT, "__quadStateValue", ty)
					end
					if #arms > 0 then
						arms[#arms + 1] = noneT
						arms[#arms + 1] = nilT
						local u = types.unionof(table.unpack(arms))
						props[k] = { read = u, write = u }
					end
				end
			end
		end
		cur = cur:readparent()
		depth += 1
	end
	return types.newtable(props, { index = types.number, readresult = elem, writeresult = elem })
end

-- Modifier 테이블 타입: setter가 self를 돌려주는 재귀 테이블
type function ModifierOf(cls: type, deny: type)
	-- 인라인 테이블 리터럴은 `{read: type?, write: type?}` 주석이 필요해 헬퍼로 뺀다(신 솔버가 본문도 검사한다)
	local function tbl(k1: string, v1: type, k2: string?, v2: type?): type
		local m: { [type]: { read: type?, write: type? } } = {}
		m[types.singleton(k1)] = { read = v1, write = v1 }
		if k2 ~= nil and v2 ~= nil then
			m[types.singleton(k2)] = { read = v2, write = v2 }
		end
		return types.newtable(m)
	end
	local denied: { [any]: boolean } = {}
	if deny.tag == "union" then
		for _, c in deny:components() do
			if c.tag == "singleton" then
				denied[c:value()] = true
			end
		end
	end
	local t = types.newtable()
	local trueT = types.singleton(true)
	t:setreadproperty(types.singleton("__quadModifier"), types.singleton(tostring(cls)))
	local cur = cls
	local depth = 0
	while cur ~= nil and depth < 12 do
		for k, v in cur:properties() do
			local name = k:value()
			if type(name) == "string" and not denied[name] and t:readproperty(k) == nil then
				local ty = v.write or v.read
				if ty ~= nil and ty.tag ~= "function" and ty.tag ~= "table" then
					local marker = tbl("__quadState", trueT, "__quadStateValue", ty)
					local value = types.unionof(ty, marker)
					t:setproperty(k, types.newfunction({ head = { t, value } }, { head = { t } }))
				end
			end
		end
		cur = cur:readparent()
		depth += 1
	end
	return t
end

type Elem = Instance | string
type FrameParam = ParamOf<Frame, Elem, Deny>
type TextButtonParam = ParamOf<TextButton, Elem, Deny>
type FrameModifier = ModifierOf<Frame, Deny>

local function makeFrame(p: FrameParam): Frame
	return nil :: any
end
local function makeTextButton(p: TextButtonParam): TextButton
	return nil :: any
end
-- (4-b) ★ 자동완성 자리 ★ — 아래 중괄호 안에서 `Back`까지 치면 BackgroundColor3/BackgroundTransparency가 뜨는가?
-- 둘 다 잘 나온다.
local ok1 = makeFrame({ --[[BackgroundTransparency]] BackgroundColor3 = Color3.new(1, 1, 1), Visible = true, Size = UDim2.fromScale(1, 1) })
local ok2 = makeTextButton({ --[[BackgroundColor3]] Text = "hi", TextSize = 18, Activated = function() end })
local ok3 = makeFrame({ --[[BackgroundColor3]] BackgroundTransparency = { __quadTween = true, Value = 0.5 } })

-- 에러여야 정상인 것들
-- Vscode(5): TypeError: Expected this to be '(Color3 | { Value: Color3, __quadTween: true } | { __quadNone: true } | { __quadState: true, __quadStateValue: Color3 })?', but got 'number'
-- Studio(5): Type Error: Expected this to be '(Color3 | { Value: Color3, __quadTween: true } | { __quadNone: true } | { __quadState: true, __quadStateValue: Color3 })?', but got 'number'
local bad1 = makeFrame({ BackgroundColor3 = 5 })
-- Vscode(Bogus, 5): TypeError: Expected this to be 'number', but got '"Bogus"'
-- 	TypeError: Expected this to be 'Instance | string', but got 'number'
-- Studio(Bogus, 1): Type Error:Expected this to be 'Instance | string', but got 'number'
-- Expected this to be 'number', but got '"Bogus"'
local bad2 = makeFrame({ Bogus = 1 })
-- Vscode(AbsoluteSize, Vector2.new(1, 1)): TypeError: Expected this to be 'Instance | string', but got 'Vector2'
--	TypeError: Expected this to be 'number', but got '"AbsoluteSize"'
-- 뭔가 이상함. 에러가 따로 나고, 키를 다르게 보려 함
-- Studio(AbsoluteSize, Vector2.new(1, 1)): Type Error: Expected this to be 'number', but got '"AbsoluteSize"'
-- Expected this to be 'Instance | string', but got 'Vector2
local bad3 = makeFrame({ AbsoluteSize = Vector2.new(1, 1) }) -- 읽기 전용이라 막아야 하는 자리
-- Vscode(5): TypeError: Expected this to be '(string | { __quadNone: true } | { __quadState: true, __quadStateValue: string })?', but got 'number'
-- Studio(5): Type Error: Expected this to be '(string | { __quadNone: true } | { __quadState: true, __quadStateValue: string })?', but got 'number'
local bad4 = makeTextButton({ Text = 5 })

-- (4-c) 체이닝 — m: 뒤에서 메소드 목록이 뜨는가?
local m: FrameModifier = nil :: any
local chained = m:BackgroundTransparency(0.5):Visible(true):Size(UDim2.fromScale(1, 1))
local tag: "Frame" = chained.__quadModifier
-- Vscode("nope"): TypeError: Expected this to be 'number | { __quadState: true, __quadStateValue: number }', but got 'string'
-- Studio("nope"): Type Error: Expected this to be 'number | { __quadState: true, __quadStateValue: number }', but got 'string'
local badChain = m:BackgroundTransparency("nope") -- 에러여야 정상
-- 보이는 바로는 LSP 는 같다, - 근데 정의가 다르다.

return { ok1, ok2, ok3, bad1, bad2, bad3, bad4, chained, tag, badChain }

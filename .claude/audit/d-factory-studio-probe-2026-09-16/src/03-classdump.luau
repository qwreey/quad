--!strict
-- [P3] Studio의 타입 데이터가 리눅스 luau-lsp의 globalTypes.d.luau와 같은 것을 보는가.
-- 이게 이 실측의 핵심이다 — 같은 type function이 두 환경에서 다른 프로퍼티 집합을 보면
-- "생성 D를 타입 함수로 대체"는 성립하지 않는다.
-- 보고할 것: 아래 print들이 낸 줄 전부(스크립트 분석 창 내용을 그대로 복사해 주면 가장 좋다).

-- (3-a) 레벨별 프로퍼티 개수와 상속 체인 — 리눅스 실측: Frame=1(Style), GuiObject=50, GuiBase2d=15, GuiBase=0
type function Chain(cls: type)
	local cur = cls
	local out = {}
	local depth = 0
	while cur ~= nil and depth < 8 do
		local n = 0
		for _ in cur:properties() do
			n += 1
		end
		out[#out + 1] = tostring(cur) .. "=" .. tostring(n)
		cur = cur:readparent()
		depth += 1
	end
	print("[P3-a] " .. tostring(cls) .. " chain: " .. table.concat(out, " > "))
	return types.string
end

-- (3-b) 관심 프로퍼티의 읽기/쓰기 표시 — 리눅스 실측은 **전부 rw**(읽기 전용 표시가 없다).
-- Studio가 AbsoluteSize/ClassName을 읽기 전용(r만)으로 준다면 두 환경이 갈린다.
type function Watch(cls: type)
	local watch = {
		"AbsoluteSize", "AbsolutePosition", "ClassName", "Parent", "Name", "BackgroundColor3",
		"MouseEnter", "Destroy", "Style", "Font", "FontFace", "Transparency", "Archivable",
		"Capabilities", "Sandboxed", "AutomaticSize", "GuiState",
	}
	local found = {}
	for _, name in watch do
		local cur = cls
		local hit = nil
		local depth = 0
		while cur ~= nil and depth < 8 do
			local p = cur:properties()
			local key = nil
			for k, v in p do
				if k:value() == name then
					key = v
					break
				end
			end
			if key ~= nil then
				local ty = key.read or key.write
				hit = (if key.read then "r" else "") .. (if key.write then "w" else "")
					.. ":" .. (if ty then tostring(ty.tag) else "?")
					.. ":" .. (if ty then string.sub(tostring(ty), 1, 28) else "?")
				break
			end
			cur = cur:readparent()
			depth += 1
		end
		found[#found + 1] = name .. "=" .. (hit or "없음")
	end
	print("[P3-b] " .. tostring(cls) .. " :: " .. table.concat(found, " | "))
	return types.string
end

-- (3-c) 이벤트가 리눅스와 같은 모양(Connect를 가진 테이블)인가 — 콜백 시그니처를 캐낼 수 있는지.
type function EventShape(cls: type)
	local cur = cls
	local depth = 0
	while cur ~= nil and depth < 8 do
		for k, v in cur:properties() do
			if k:value() == "MouseEnter" then
				local ty = v.read or v.write
				if ty == nil then
					print("[P3-c] MouseEnter 타입 없음")
					return types.string
				end
				local msg = "tag=" .. tostring(ty.tag)
				if ty.tag == "table" then
					local conn = ty:readproperty(types.singleton("Connect"))
					if conn ~= nil and conn.tag == "function" then
						local head = conn:parameters().head
						local cb = if head then head[2] else nil
						msg = msg .. " Connect콜백=" .. (if cb then tostring(cb) else "못 찾음")
					else
						msg = msg .. " Connect=" .. tostring(conn and conn.tag)
					end
				end
				print("[P3-c] MouseEnter " .. msg)
				return types.string
			end
		end
		cur = cur:readparent()
		depth += 1
	end
	print("[P3-c] MouseEnter 프로퍼티를 못 찾음")
	return types.string
end
-- Vscode: TypeError: [P3-a] Frame chain: Frame=1 > GuiObject=45 > GuiBase2d=11 > GuiBase=0 > Instance=53 > Object=5 > userdata=0
-- Studio: Type Error: [P3-a] Frame chain: Frame=1 > GuiObject=55 > GuiBase2d=16 > GuiBase=0 > Instance=58 > Object=6 > userdata=0
type _1 = Chain<Frame>
-- Vscode: TypeError: [P3-a] TextButton chain: TextButton=23 > GuiButton=14 > GuiObject=45 > GuiBase2d=11 > GuiBase=0 > Instance=53 > Object=5 > userdata=0
-- Studio: Type Error: [P3-a] TextButton chain: TextButton=29 > GuiButton=14 > GuiObject=55 > GuiBase2d=16 > GuiBase=0 > Instance=58 > Object=6 > userdata=0
type _2 = Chain<TextButton>
-- Vscode: TypeError: [P3-a] UICorner chain: UICorner=5 > UIComponent=0 > UIBase=0 > Instance=53 > Object=5 > userdata=0
-- Studio: Type Error: [P3-a] UICorner chain: UICorner=5 > UIComponent=0 > UIBase=0 > Instance=58 > Object=6 > userdata=0
type _3 = Chain<UICorner>
-- Vscode: TypeError: [P3-b] Frame :: AbsoluteSize=rw:extern:Vector2 | AbsolutePosition=rw:extern:Vector2 | ClassName=rw:string:string | Parent=rw:union:Instance? | Name=rw:string:string | BackgroundColor3=rw:extern:Color3 | MouseEnter=rw:table:{ Connect: t1, ConnectParall | Destroy=rw:function:(Instance) -> nil | Style=rw:extern:Enum.FrameStyle | Font=없음 | FontFace=없음 | Transparency=없음 | Archivable=rw:boolean:boolean | Capabilities=rw:extern:SecurityCapabilities | Sandboxed=rw:boolean:boolean | AutomaticSize=rw:extern:Enum.AutomaticSize | GuiState=rw:extern:Enum.GuiState
-- Studio: Type Error: [P3-b] Frame :: AbsoluteSize=rw:extern:Vector2 | AbsolutePosition=rw:extern:Vector2 | ClassName=rw:string:string | Parent=rw:union:Instance? | Name=rw:string:string | BackgroundColor3=rw:extern:Color3 | MouseEnter=rw:extern:RBXScriptSignal | Destroy=rw:function:(Instance) -> () | Style=rw:extern:Enum.FrameStyle | Font=없음 | FontFace=없음 | Transparency=rw:number:number | Archivable=rw:boolean:boolean | Capabilities=rw:extern:SecurityCapabilities | Sandboxed=rw:boolean:boolean | AutomaticSize=rw:extern:Enum.AutomaticSize | GuiState=rw:extern:Enum.GuiState
type _4 = Watch<Frame>
-- Vscode: TypeError: [P3-b] TextLabel :: AbsoluteSize=rw:extern:Vector2 | AbsolutePosition=rw:extern:Vector2 | ClassName=rw:string:string | Parent=rw:union:Instance? | Name=rw:string:string | BackgroundColor3=rw:extern:Color3 | MouseEnter=rw:table:{ Connect: t1, ConnectParall | Destroy=rw:function:(Instance) -> nil | Style=없음 | Font=rw:extern:Enum.Font | FontFace=rw:extern:Font | Transparency=없음 | Archivable=rw:boolean:boolean | Capabilities=rw:extern:SecurityCapabilities | Sandboxed=rw:boolean:boolean | AutomaticSize=rw:extern:Enum.AutomaticSize | GuiState=rw:extern:Enum.GuiState
-- Studio: Type Error: [P3-b] TextLabel :: AbsoluteSize=rw:extern:Vector2 | AbsolutePosition=rw:extern:Vector2 | ClassName=rw:string:string | Parent=rw:union:Instance? | Name=rw:string:string | BackgroundColor3=rw:extern:Color3 | MouseEnter=rw:extern:RBXScriptSignal | Destroy=rw:function:(Instance) -> () | Style=없음 | Font=rw:extern:Enum.Font | FontFace=rw:table:{ Bold: boolean, Family: str | Transparency=rw:number:number | Archivable=rw:boolean:boolean | Capabilities=rw:extern:SecurityCapabilities | Sandboxed=rw:boolean:boolean | AutomaticSize=rw:extern:Enum.AutomaticSize | GuiState=rw:extern:Enum.GuiState
type _5 = Watch<TextLabel>
-- Vscode: TypeError: [P3-c] MouseEnter tag=table Connect콜백=(number, number) -> ()
-- Studio: Type Error: [P3-c] MouseEnter tag=extern
type _6 = EventShape<Frame>

-- (3-d) 내장 타입 연산자가 Studio에서도 도는가(사용자 실측으로 이미 확인된 것의 재확인)
type K = keyof<Frame>
local k1: K = "BackgroundColor3" -- 에러 없어야 정상
-- Vscode("없는프로퍼티"): TypeError: Expected this to be '"TouchLongPress" | "GetActor" | "ChildRemoved" | "SelectionBehaviorRight" | "SelectionImageObject" | "findFirstChild" | "FindFirstChildWhichIsA" | "Parent" | "getChildren" | "TouchTap" | "GetDescendants" | "GetAttributeChangedSignal" | "Selectable" | "AbsoluteRotation" | "TouchRotate" | "Visible" | "RootLocalizationTable" | "StyledPropertiesChanged" | "NextSelectionDown" | "BorderMode" | "AutomaticSize" | "Rotation" | "Size" | "GetAttributes" | "Archivable" | "BackgroundTransparency" | "SizeConstraint"... *TRUNCATED*'	but got	'"없는프로퍼티"'
-- Studio("없는프로퍼티"): Type Error: Expected this to be '"AbsolutePosition" | "AbsoluteRotation" | "AbsoluteSize" | "Active" | "AddTag" | "AncestryChanged" | "AnchorPoint" | "Archivable" | "AttributeChanged" | "AutoLocalize" | "AutomaticSize" | "BackgroundColor" | "BackgroundColor3" | "BackgroundTransparency" | "BorderColor" | "BorderColor3" | "BorderMode" | "BorderSizePixel" | "Capabilities" | "Changed" | "ChildAdded" | "ChildRemoved" | "ClassName" | "ClearAllChildren" | "ClippedRect" | "ClipsDescendants" | "Clone" | "DataCost" | "DescendantAdded" | "DescendantRemoving"... *TRUNCATED*' but got '"없는프로퍼티"'
local k2: K = "없는프로퍼티" -- 에러여야 정상
local sz: index<Frame, "AbsoluteSize"> = Vector2.new(1, 1) -- 에러 없어야 정상
local bad: index<Frame, "BackgroundColor3"> = 5 -- 에러여야 정상

-- 약간 다르고 더 파봐야할 부분이 조금씩 존재함. 특히 Event. Event 부분만 따로 리스트업 해서 Name -> Func 하는 조합기를 만들어야할 가능성이 있을수도

return { k1, k2, sz, bad }

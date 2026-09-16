--!strict
-- [P6] 03번 후속 — Studio에서 이벤트가 `extern:RBXScriptSignal`(테이블이 아님)로 나왔다. 그 extern에서
-- 콜백 시그니처를 캐낼 수 있는가(리눅스 defs에선 테이블의 `Connect` 2번 인자에서 캐냈다).
-- 보고할 것: [P6-*] 줄 전부.

type function EventProbe(cls: type, evName: type)
	local want = evName:value()
	local cur = cls
	local depth = 0
	while cur ~= nil and depth < 8 do
		for k, v in cur:properties() do
			if k:value() == want then
				local ty = v.read or v.write
				if ty == nil then
					print("[P6-0] " .. tostring(want) .. " 타입 없음")
					return types.string
				end
				print("[P6-1] " .. tostring(want) .. " tag=" .. tostring(ty.tag) .. " tostring=" .. string.sub(tostring(ty), 1, 60))
				-- (a) extern이면 자기 프로퍼티(메소드) 목록
				if ty.tag == "extern" then
					local names = {}
					for pk, pv in ty:properties() do
						local pty = pv.read or pv.write
						names[#names + 1] = tostring(pk:value()) .. ":" .. (if pty then tostring(pty.tag) else "?")
					end
					table.sort(names)
					print("[P6-2] extern props: " .. table.concat(names, " "))
					local parent = ty:readparent()
					print("[P6-3] extern parent: " .. tostring(parent))
				end
				-- (b) Connect를 읽어 콜백 파라미터를 꺼내 본다. [Studio 실측 2026-09-16] `readproperty`는
				-- 테이블 전용("expected self to be either a table, but got extern")이라 extern은 properties()로 찾는다.
				local conn: type? = nil
				if ty.tag == "table" then
					conn = ty:readproperty(types.singleton("Connect"))
				else
					for pk, pv in ty:properties() do
						if pk:value() == "Connect" then
							conn = pv.read or pv.write
							break
						end
					end
				end
				if conn == nil then
					print("[P6-4] Connect 없음")
				else
					print("[P6-4] Connect tag=" .. tostring(conn.tag) .. " " .. string.sub(tostring(conn), 1, 80))
					if conn.tag == "function" then
						local head = conn:parameters().head
						local parts = {}
						if head ~= nil then
							for i, h in head do
								parts[#parts + 1] = i .. ":" .. tostring(h.tag) .. "=" .. string.sub(tostring(h), 1, 40)
							end
						end
						print("[P6-5] 파라미터 " .. tostring(if head then #head else -1) .. "개: " .. table.concat(parts, " | "))
					elseif conn.tag == "intersection" then
						for i, c in conn:components() do
							print("[P6-5." .. i .. "] 오버로드 " .. tostring(c))
						end
					end
				end
				return types.string
			end
		end
		cur = cur:readparent()
		depth += 1
	end
	print("[P6-0] " .. tostring(want) .. " 프로퍼티를 못 찾음")
	return types.string
end

type _1 = EventProbe<Frame, "MouseEnter">      -- (number, number) -> ()
type _2 = EventProbe<TextButton, "Activated">  -- (InputObject, number) -> ()
type _3 = EventProbe<Frame, "Destroying">      -- () -> ()

-- (d) 내장 연산자로는 뭐가 나오나 — index<Frame, "MouseEnter">를 그대로 콜백 자리에 쓸 수 있는지
type Ev = index<Frame, "MouseEnter">
local ev: Ev = nil :: any
local fn = function(x: number, y: number) end
-- 아래 두 줄 중 어느 쪽에 에러가 나는지 보고
local c1 = ev:Connect(fn)                  -- 정상이어야 함
-- Expected this to be '(number, number) -> ()' but got '(string) -> ()'; Expected the 1st parameter to be a supertype of `number`, but got `string`
-- TypeError: Expected this to be
-- 	'(number, number) -> ()'
-- but got
-- 	'(string) -> ()'; 
-- it takes the 1st entry in the type pack is `string` in the latter type and `number` in the former type, and `string` is not a supertype of `number`
local c2 = ev:Connect(function(s: string) end) -- 에러여야 정상(인자 타입 불일치)

return { ev, c1, c2 }

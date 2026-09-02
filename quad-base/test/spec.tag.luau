--[[
	Tag 계약 (M10, round16 spike) — 값 API(`base/tag-plan.md` "값 모양") +
	TagFallbackHandler 참조 카운트(같은 문서 "메커니즘" 절: addTag는 process,
	removeTag는 retractor, 위치(k) 기준 홀더 집합, 배치 호출, 깜빡임 방지) +
	미주입 스텁 안내 에러. mock의 tag op(`installTagAttributeOps`)와 호출
	로그로 "실제 엔진 호출은 진짜 바뀐 이름에만"을 직접 관측한다.
]]

local Quad = require("../src")
local mock = require("./mock")
local newQuad = mock.newQuad
local Instance = mock.Instance

print("=== 1. 값 API — immutable clone 체이닝, Merged 합집합, 빈 Tag 유효 ===")
do
	local q = newQuad()
	local a = q.Tag("selected", "primary")
	assert(q.isTag(a), "brand")
	assert(a:Contains("selected") and a:Contains("primary") and not a:Contains("x"), "Contains")
	local b = a:Added("hover")
	assert(b ~= a and b:Contains("hover") and not a:Contains("hover"), "Added clones — original untouched")
	local c = b:Removed({ "selected", "primary" })
	assert(c:Contains("hover") and not c:Contains("selected"), "Removed takes {string} too")
	local d = a:Added({ "x", "y" })
	assert(d:Contains("x") and d:Contains("y"), "Added takes {string}")
	local m = q.Tag.Merged(a, c)
	assert(m:Contains("selected") and m:Contains("primary") and m:Contains("hover"), "Merged = lossless union")
	assert(q.isTag(q.Tag()), "empty Tag is valid")
	local n = 0
	for _ in a:Names() do
		n += 1
	end
	assert(n == 2, "Names iterates exactly the held names")
	assert(a:Apply(function(self: any)
		return self:Contains("selected")
	end) == true, "Apply sugar")
	assert(not pcall(function()
		(a :: any).x = 1
	end), "frozen")
	print("PASS")
end

print()
print("=== 2. 미주입 스텁 — 백엔드 없는 quad에서 Tag를 걸면 안내 에러(blame은 사용자 줄) ===")
do
	local q = Quad.New() -- 생명주기/ops 미설치
	mock.installLifetime(q) -- 생명주기만 — tag op는 여전히 스텁
	local inst = Instance.new("Frame")
	local ok, err = pcall(function()
		q.Dispatch.drive(inst, { q.Tag("a") })
	end)
	assert(not ok, "must error without a backend")
	assert(string.find(tostring(err), "addTag is not available", 1, true) ~= nil, "guidance message: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.tag.luau", "stub blame")
	print("PASS")
end

local function newTagQuad(log: { string }?)
	local q = newQuad()
	mock.installTagAttributeOps(q, log)
	return q
end

print()
print("=== 3. process/retractor 왕복 — Tag(A)→Tag(B) 깜빡임 방지, Tag(A)→nil 전량 제거 ===")
do
	local log: { string } = {}
	local q = newTagQuad(log)
	local inst = Instance.new("Frame")
	local src = q.Source(q.Tag("a", "b"))
	q.Dispatch.drive(inst, { src })
	assert(table.concat(mock.getTags(inst), ",") == "a,b", "initial names applied")
	assert(#log == 1 and log[1] == "addTag:a,b", "one batched addTag: " .. table.concat(log, " | "))

	src:Set(q.Tag("b", "c")) -- a 빠지고 c 들어옴, b 생존
	assert(table.concat(mock.getTags(inst), ",") == "b,c", "diffed to b,c")
	-- 진짜 바뀐 이름에만 엔진 호출: remove a → add c (b는 어느 쪽에도 없음)
	assert(#log == 3 and log[2] == "removeTag:a" and log[3] == "addTag:c", "no flicker on survivor: " .. table.concat(log, " | "))

	src:Set(nil) -- 핸들러 교체(NilHandler) — 전량 제거
	assert(#mock.getTags(inst) == 0, "all names removed on nil")
	assert(log[4] == "removeTag:b,c", "batched removal: " .. table.concat(log, " | "))
	print("PASS")
end

print()
print("=== 4. 참조 카운트 — 겹친 이름·같은 객체 재사용(위치 기준)이 합집합으로 안전 ===")
do
	local log: { string } = {}
	local q = newTagQuad(log)
	local inst = Instance.new("Frame")
	local SHARED = q.Tag("a") -- immutable 재사용 관례 — 두 위치에 같은 객체
	local s1 = q.Source(SHARED)
	local s2 = q.Source(q.Tag("a", "b"))
	q.Dispatch.drive(inst, { s1, s2 })
	assert(table.concat(mock.getTags(inst), ",") == "a,b", "union")
	assert(log[1] == "addTag:a" and log[2] == "addTag:b", "second position adds only the new name: " .. table.concat(log, " | "))

	s2:Set(q.Tag()) -- 위치 2가 a,b를 놓음 — a는 위치 1이 아직 잡고 있다
	assert(table.concat(mock.getTags(inst), ",") == "a", "a survives via position 1")
	assert(log[3] == "removeTag:b", "only b actually removed: " .. table.concat(log, " | "))

	s1:Set(q.Tag()) -- 마지막 홀더가 놓음
	assert(#mock.getTags(inst) == 0, "now a is gone too")
	assert(log[4] == "removeTag:a", "refcounted removal: " .. table.concat(log, " | "))
	print("PASS")
end

print()
print("=== 5. H-39 부기 — Tag를 자식보다 앞에 둬도 recompute가 죽지 않는다 ===")
do
	local q = newTagQuad()
	local inst = Instance.new("Frame")
	local sources = {}
	local leafLog: { string } = {}
	mock.addSpecLeaf(q, sources, leafLog) -- 문자열 leaf(자리 기여 1)
	q.Dispatch.drive(inst, { q.Tag("card"), "child" }) -- Tag 앞, leaf 뒤
	-- Tag 자리(k=1)가 None/0으로 등록됐으므로 offset 산술이 성립한다
	assert(q.Dispatch.getOffsetAt(inst, 2) == 0, "Tag contributes 0 to the offset math")
	print("PASS")
end

print()
print("=== 6. 같은 객체 재발행(no-op emit) — 홀더 유지, 엔진 호출 0 ===")
do
	local log: { string } = {}
	local q = newTagQuad(log)
	local inst = Instance.new("Frame")
	local t = q.Tag("a")
	local src = q.Source(t)
	q.Dispatch.drive(inst, { src })
	local before = #log
	src:Set(t) -- 같은 immutable 객체 — retractor가 v == nextValue로 순수 스킵
	src:Emit()
	assert(#log == before, "no engine calls on identical re-emission: " .. table.concat(log, " | "))
	assert(table.concat(mock.getTags(inst), ",") == "a", "state intact")
	print("PASS")
end

print()
print("=== ALL PASS ===")

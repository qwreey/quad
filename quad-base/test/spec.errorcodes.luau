--!strict
--[[
	에러 식별자(`QuadNNNN`) — 사용자 결정 2026-09-22(`base/error-id-plan.md`): 모든 quad 에러 메시지는
	Luau의 `파일:줄: ` 접두 바로 뒤 첫 토큰으로 4자리 식별자를 단다. 여기서는 (1) 던진 문자열의 모양,
	(2) `Fallback`이 그 문자열을 그대로 넘겨 `err`에서 번호로 분기할 수 있다는 것만 본다 — 번호의 유일성과
	문서 절 존재는 `scripts/error-codes.py`(test.sh 게이트)가 검사한다.
]]

local Quad = require("../src")

local q = Quad.New()

print("=== 1. 던진 문자열은 `파일:줄: QuadNNNN 주어: …` 모양이다 ===")
do
	local ok, err = pcall(function()
		return q.StringAttr("", "x") -- 빈 이름 — 백엔드 없이도 나는 검증 에러
	end)
	assert(not ok, "must raise")
	local s = tostring(err)
	local id = string.match(s, "^[^\n]-:%d+: (Quad%d%d%d%d) StringAttr: ")
	assert(id ~= nil, "id right after the blame prefix: " .. s)
	print("PASS", id)
end

print()
print("=== 2. Fallback의 err에서 번호로 분기할 수 있다(문자열일 때) ===")
do
	local guarded = q.Fallback(function()
		return q.StringAttr("", "x")
	end, function(err: any)
		if type(err) == "string" then
			return string.match(err, "Quad%d%d%d%d")
		end
		return nil
	end)
	local got = guarded()
	assert(type(got) == "string" and #got == 8, "Fallback hands the tagged string through: " .. tostring(got))
	print("PASS", got)
end

print()
print("=== ALL PASS ===")

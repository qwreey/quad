--[[
	GC 완료를 간접 관찰하는 헬퍼 — Roblox Studio(실제 게임 스크립트) 환경 전용.

	배경: Roblox는 `collectgarbage()`를 스크립트에 노출하지 않음(순수 `luau`
	CLI/`lune`과 다른 점 — `07-relate-weak-table-gc.luau`는 그쪽 환경에서
	`collectgarbage()`를 직접 부름). 그래서 예전엔 "Studio에서는 GC 타이밍
	검증 자체가 불가능하다"고 봤는데, incremental GC가 "충분한 할당 압력 +
	충분한 시간"이 주어지면 결국 한 사이클을 완료한다는 성질을 이용하면
	간접적으로 관찰 가능함 — 죽었어야 할 객체를 weak-value 테이블(canary)에
	넣어두고 그게 사라지는 시점을 기다리면 됨. 2026-08-13 사용자가 gcconn
	트릭 검증 중 직접 확인(`audit/gcconn-trick-verification.md` 참고).

	주의:
	- 정확한 트리거가 아니라 **간접 관찰**임 — "이 시점에 정확히 GC가
	  끝났다"를 보장하지 않음, "이 루프가 끝났다면 적어도 GC 사이클 한 번은
	  지나갔다" 정도의 신호로만 쓸 것.
	- `task.wait`가 필요해서 Roblox 런타임(Studio/게임) 전용 — 순수 `luau`
	  CLI엔 `task` 라이브러리가 없음(그쪽은 그냥 `collectgarbage()`를 직접
	  부르면 됨, `07` 참고).
	- 실행 시간이 김(관찰 대상 크기/환경에 따라 GC 사이클 하나당 수 초~
	  수십 초) — 다른 Studio 스파이크(`10` 등)에서 GC 완료를 기다려야 할
	  때 아래 `waitForGC`를 그대로 복붙해서 쓰면 됨.

	사용 예:
		local weak = setmetatable({}, {__mode = "v"})
		weak[1] = someValueExpectedToDie
		-- ... someValueExpectedToDie에 대한 다른 참조를 전부 없앤 뒤 ...
		waitForGC("someValue 해제 대기")
		assert(weak[1] == nil, "여전히 살아있음 — GC 안 됐거나 다른 곳에서 참조 중")
]]

local function waitForGC(label: string?)
	print(`[GC] {label or "GC"} 대기 시작`)
	local canary = setmetatable({ {} }, { __mode = "v" }) -- 이 canary 하나만 참조하는 빈 테이블
	local epoch = 0
	while canary[1] do
		task.wait(0.1)
		table.create(5000, true) -- 할당 압력 생성 — incremental GC 진행을 강제
		epoch += 1
		if epoch % 100 == 0 then
			print(`[GC] {label or "GC"} 대기 중: {epoch}`)
		end
	end
	print(`[GC] {label or "GC"} 완료로 추정(epoch ~{epoch})`)
end

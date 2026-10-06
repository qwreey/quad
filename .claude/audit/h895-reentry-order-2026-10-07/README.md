# H-895 후속 조사 — 동기 엔진 신호 재진입 아래 "엔진 쓰기 → quad 기록" 순서 (2026-10-07)

opus 하나, 01:41~01:53 KST, 레포 무수정 — HEAD 사본(스크래치)에서 실행했다. 이 폴더는 그 사본에서 옮겨 온 산출물이라 **여기서 바로 돌지 않는다**(프로브의 require는 사본 안 `quad-base/test`·`quad-roblox/test` 위치 기준; 다시 돌리려면 HEAD를 `cp -rL`로 떠서 그 안 같은 자리에 두고 실행). 판정·결정은 원장 `qa-request/post-implementation-review-round14.md` §6.

- `probes/env.luau` — round13 E79 Deferred 셔임(`audit/round13-e79-deferred-signals/env.luau`) + `UICorner`·`ChildAdded` 동기/지연 발화.
- `probes/probe.luau`·`probe2.luau`·`probe3.luau` — mock·imm·def 세 모드로 Property 경로 A(plain)·B(Finish)·C(zero-time)·D/E(첫 세팅)·F(plain 위 plain)·G/J(`Completed` 잇기)·I(Dedup 겹침), Slot SL2~SL8, InstanceChild(IC), InstanceShorthand(IS). `trace-d.luau`는 후보 D 콜백 순서 추적.
- `probes/zz_c1.luau`·`zz_c2.luau`(H-895 첫 재현)·`zz_b1.luau`(H-896) — 수렴 확인 탐사의 것.
- `patches/candD.patch`(Property — 쓰기 직후 기록 신원 재확인, 권고), `candR.patch`(settle → 기록 → 쓰기 — 콜백 순서가 뒤집혀 비권장), `candS4.patch`(candD + Slot 넷·IS 재정렬).
- `out/out3-{base,candD,candR,candS4}.txt` — 같은 프로브의 사본별 출력. 후보 사본 전부 spec 62/62 통과, 신 솔버 클린(조사자 보고).

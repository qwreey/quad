# round13 Slot-A 합본 재검증 r2 (2026-09-30, HEAD `682e2301`)

2026-09-27 `round13-slot-bundle/`(HEAD `5d299c6c`)에서 검증한 Slot 여섯 문항 합본(Q74·Q76 A1+A1b·Q111 A+B·Q112·Q113·Q114 A/A′)을
묶음 3′(`682e2301` — Observer 설치 루프·`_seenRevision`·Effect 직접 구독)·`2c8ac68a`(Compute 세대 가드)·`0d131b60`(`Quad0259`/`0260` 게이트 등)
뒤의 HEAD 위에 다시 얹어 같은 퍼저·프로브·벤치를 돌린 기록이다. 결정 아님, 코드 변경 제안 아님. 판정은 전부 CLI mock(엔진 미측정).

## 사본

| 이름 | 내용 |
|---|---|
| base | HEAD `682e2301` 그대로 |
| q74 | base + `round13-e1b-probe-patches/Raw.owner-chain.diff`(Q74 단독) |
| q76 | base + `round13-q76-proto/List.keygone-first-descending.diff`(Q76 A1+A1b 단독) |
| A | base + `bundle.A.r2.diff`(합본, Q114 (a)) |
| Ap | base + `bundle.Aprime.r2.diff`(합본, Q114 (a′) — `_withheld` 예외) |
| pre3p | `bc8c8329`(3′ 직전)의 quad-base/src — `probe.bundle.interact*` 대조군으로만 |

Q75: 원장 처방 (b)+(c)는 계약 문장 한 줄(문서)이라 코드 diff가 없다. 갈래 (a)(`getOffsetAt` 조회) diff도 레포 어디에도 없다(`.claude/audit` 전수 grep) —
그래서 "A 위에 Q75를 얹은 변형"은 만들지 않았고, Q75 입구 프로브(`probe-q75`·`probe.q75a/b`·`probe.e19.stale-destroywalk`)만 다섯 사본에서 돌렸다.

## 충돌 해소 (`bundle.A.full.diff`를 HEAD에 `patch -p0`)

두 hunk가 실패했고 둘 다 원인은 Q90(2026-09-28 메시지 정규화 — `Quad0070` 주어 `StoreBind:` → `State:`, 부연 구분자 em-dash → ASCII ` - `)이다. 손으로 푼 내용:

1. `Dispatch/StoreBind.luau` hunk 2(observer 본문): HEAD의 인라인 순환 검사(`Quad0070 State: the value chain is circular … - a State …`)를
   프로토타입대로 `StoreBind.assertAcyclicChain(realv, state, Err.errorBefore, "State")` 호출 + Q114 인계 업밸류 코드로 바꿨다. hunk 1(헬퍼)은
   적용됐지만 옛 문구를 들고 있어 헬퍼 문구를 HEAD 문구로 맞췄다: `"Quad0070 " .. subject .. ": the value chain is circular (a State that eventually holds itself) - a State may hold another State, but not a cycle"`.
   **주어 인자 값**: StoreBind 호출은 `"State"`(HEAD 메시지와 바이트 동일 유지), Slot 쪽 호출 둘(`Elements.luau`·`List.luau`)은 옛 프로토타입대로 `"Slot"` 그대로.
   (Q90이 `0070` 주어를 `State:`로 정했으므로 Slot 경로 주어를 `Slot:`로 둘지 `State:`로 둘지는 새로 생긴 결정 재료 — 이 사본은 옛 프로토타입을 따랐을 뿐.)
2. `Slot/init.luau` hunk 5(선행 패스 `Quad0170`~`0173` 블록, P-Q111 B): HEAD의 `0170`/`0172` 문구가 ASCII ` - `로 바뀌어 문맥이 안 맞았다. 로직은 프로토타입 그대로,
   문구는 HEAD의 ASCII 문구로 손 적용.
3. 추가로 `Slot/List.luau`의 새 꼬리 문구 `" — here through a State element: …"`를 `" - here through a State element: …"`로(Q90 ASCII 규칙에 맞춤 — 동작 무관).
4. `bundle.A-to-Aprime.diff`는 A 위에 `patch -p3`로 그대로 적용(충돌 없음).
나머지(Elements·List KeyGone 패스·Raw `raiseChain`/`stateSeat`)는 오프셋만으로 적용. `Quad0259`/`0260` 게이트는 reconcile의 키 계산 루프 안이라 Q113/Q111 검사(그 뒤·게이트 on 앞)와 겹치지 않는다.
`PATCH_RAW` 계측 카운터는 옛 합본과 같게 남겨 두었다(채택 시 제거 대상).

## 게이트

| 사본 | `./scripts/test.sh; echo $?` | `error-codes.py check` | `--next` |
|---|---|---|---|
| HEAD | 0 (스펙·스모크 62) | 258 ids / 252 raise / 0 untagged / 0 errors | Quad0262 |
| A | 0 (62) | 258 / 252 / 0 / 0 | Quad0262 |
| Ap | 0 (62) | 258 / 252 / 0 / 0 | Quad0262 |

합본은 새 raise ID를 만들지 않는다(추가된 raise 줄은 전부 기존 `0070`·`0147`·`0156`·`0170`~`0173`의 이동·재작성). 로그 `gate/`.

## 결과 요약 (옛 합본 → 지금)

- **E19/q111 퍼저** 여섯 설정 × 6000시드(`fuzz.e19-q111.summary.txt`): HEAD는 옛 base와 불일치 종류·수가 같다(plain `ErrCycleViaST` 1 / q111 모드 109+81+9+2 / q111ss 53+48+1); A·Ap는 전부 6000/6000 ok(옛 bundle·bundlep와 같음). A vs Ap 비perf 줄 바이트 동일.
- **List 퍼저** 2000시드 plain/rowgrow(`list.compare.txt`, `list.positional-diff.txt`): 모든 수치가 옛 비교와 같다 — plain stale 스텝 9651 → 200, move 843,209 → 409,397, 논리 최종 상태 불일치 0; rowgrow physWrong 16,270 → 21,250(Q75 (b) 입구), stale 28,753 → 26,842. q76 = A = Ap 바이트 동일, base = q74 바이트 동일.
- **재진입 퍼저** anc/unm/excl × 6000(`reent.summary.txt`): HEAD anc 433 / unm **0** / excl 0(옛 base 448 / 22 / 0 — unm 0은 Q73 코어 반영 효과), q74 0/0/0, q76 427/0/0, **A 0/0/0, Ap 0/0/0**(옛 bundle은 Q73 없이 21/22, Q73 사본에서 0/0 — 이제 구분 없이 0). `rej0167` A 23,903 / HEAD 19,264.
- **E23 분포**(`probes/e23.dist.3runs.txt`): HEAD e2 빠진 가지 먼저 쓰임 약 44~47%, e3 `Quad0160` 129~145/300, e4 `0160`/`0156` 127~152 — 옛 base와 같은 범위. A·Ap e2 0%(그래프당 쓰기 약 1.58), e3·e4 에러 0 — 옛 bundle과 같음.
- **프로브**: `probe.bundle.interact2`·`probe.q111`·`probe.q113`·`probe.e19.state-occupant`·`spec.q76b.draft`는 A/Ap가 옛 bundle/bundlep와 동일(문구 ASCII 차이 제외). `probe.e19.boundary`의 A는 옛 bundle-A와 같게 106행 미포착 `Quad0170`에서 멈춘다(프로브가 pcall 안 한 자리 — 옛 출력도 같음). `probe.throwstate` base 차이는 프로브 파일이 옛 base 출력 뒤에 바뀐 것(`three items` 줄 삭제)이라 동작 차이 아님.
- **e1b(C3x 제외)**(`probes/e1b.noc3x.out.txt`): HEAD는 `round13-3prime-apply/e1b.C.noc3x.txt`와 동일(A1~F no-loss, Q74 GHOST 둘). q74·A·Ap에서 GHOST 둘 → `clean`(`Quad0167` 거부). 다른 줄 변화 없음.
- **Q75 입구**: `probe-q75`(E72 A·B·C)·`probe.q75a/b`·`probe.e19.stale-destroywalk` 전부 다섯 사본에서 옛 출력과 동일.
- **벤치**(`bench.summary.txt`, -O2, base/A/Ap는 6회·q74/q76은 3회 최소값): 전체 교체 0.10×, 절반 교체 0.39×, 전체 역순 1.00×, 잎 Add 0.97×, State 잎 Add 1.16×, nil State Add 1.31~1.34×, 1000단 사슬 53×·State 경유 38× — 옛 수치(0.09/0.38/1.00/0.98/1.14/1.35/60/36)와 같은 모양. B10/B11(중첩 Set)은 1.1~1.35×로 흔들림(잡음 범위 추정 — 반복마다 달라짐).

## 3′ 뒤에 달라진 것 (HEAD base 쪽)

- `probe.bundle.interact` I1/cycle-outer: 옛 base `outerLen 1`(자식 2, 영구 1 부족) → HEAD `outerLen 2`(정합). `pre3p`(`bc8c8329`)에선 옛과 같으므로 3′ 효과.
- I1/self: 옛 base는 Add가 `invalid argument #2 to 'min'`으로 실패·잎 고아 → HEAD는 Set만 stack overflow로 던지고 Add 성공·길이 정합. `pre3p`에서도 이미 이렇게 바뀌어 있으므로 3′가 아니라 `5d299c6c..bc8c8329` 사이의 다른 변경 효과(좁히지 않음).
- 재진입 unm 22 → 0(Q73 코어).

## 상호작용 (옛 넷 → 지금)

1. **Q74 × Q113(Q74만 있으면 영구 동결)**: 그대로. q74 단독에서 `interact2` I8 `mat true,true`·`outer:Add Quad0167`, `interact` I1/self `outer.mat true`·이후 Add `Quad0167`, `probe.q113` C1도 이후 `sl:Add`/`Remove`가 `Quad0167`(HEAD base는 회복). A/Ap에선 `Quad0070`으로 거부·회복.
2. **Q76 I2(지운 키의 State가 새 키로 이동 — `Quad0156` → 통과)**: 그대로(q76·A·Ap 통과, base·q74 `Quad0156`; I2c는 모두 `Quad0156`).
3. **Q74 I7 동결 확대(owner 사슬 전체)**: 그대로(q74·A·Ap `top:Add Quad0167`, base·q76은 직접 부모만).
4. **Q74 I1 State 경로 잔여 유령**: 그대로 — I1/nil `outerLen 1`인데 자식 `head,leaf`, I1/otherleaf `outerLen 2`인데 자식 셋, 다섯 사본 모두(3′도 못 닫음).
5. **새로 보인 것 — Q74 단독 × 3′**: I1/cycle-outer에서 HEAD base는 3′ 덕에 `outerLen 2`(정합)인데 **q74 단독은 옛값 `outerLen 1`(뒤 Add 뒤에도 1 부족)** — Q74가 attach 창에서 조상 `_materializing`을 올리는 것이 3′가 고친 길이 갱신을 이 모양에선 가린다. A·Ap는 Q111 A가 Set을 먼저 `Quad0173`으로 거부해 `outerLen 2`(정합). 즉 Q74를 Q111 없이 채택하면 이 모양에서 HEAD보다 나빠진다(원인 추적은 안 함).

## Q114 A 대 A′

`probe.q114`·`probe-e23e`의 A/A′ 차이는 옛과 같다 — A는 K4·K5·K6·E4 유보 중 멈춤, A′는 K4·K6·E4 유보 중 base처럼 옛 선택을 따르고 K5(상류 게이트)는 멈춤, K7 300/300 ok 둘 다, K9 약 45% `Quad0156` 셋 다(잡음 범위). **E4 `OffWithoutEmit` 뒤 `b:Set`**: base `B3`, A `B2`, **A′도 `B2`**(옛 C2 출력도 `B2`) — 원장 §0 v2 의존 문단의 "A′는 `H-717` 문장이 그대로 맞다"는 이 측정과 어긋난다(유보가 풀려 `_withheld`가 비면 A′ 예외가 꺼져 A와 같이 건너뜀).

## 재현

스크래치 루트 `S=/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r2`(스크립트 안에 하드코딩 — 옮기면 `S` 수정).
1. 사본 base/A/Ap: 워크트리에서 해당 diff를 적용 → `./scripts/relink.sh` → `cp -rL quad-base quad-roblox quad-types quad-error type-version-check scripts mise.toml pesde.toml $S/<v>/` + `cp -rL .claude/audit $S/<v>/.claude/`. q74/q76은 `scripts/mkvariants.sh`(base 사본에서 파생). 퍼즈 사본 `fz/<v>` = `<v>/quad-base` + `round13-q111-proto/HOOKS.scratch-probe.diff`(`patch -p1`) + 퍼저·프로브를 `test/`로 복사.
2. E19/q111: `scripts/rf.sh <v> fuzz.e19|fuzz.q111 <tag> <from> 6000 <flags>`(plain 1.., ss·q111ss 20001..; flags "", ssheavy, q111, "q111,ssheavy") → `scripts/summ.py`.
3. List + 재진입: `scripts/runlist-anc.sh`(list 1..2000 plain/rowgrow, reent 1..6000 anc/unm/excl) → `scripts/listcompare.sh`(`round13-q76b-proto/compare.py`), `scripts/listcmp.py`.
4. 프로브: `scripts/runprobes.sh`(quad-base 로컬 프로브), `scripts/runroot.sh`(q113·q114·probe-q75·E23 e2~e4 3회 — 사본 루트에서), `scripts/rune23e.sh`, `scripts/rune1b.sh`(C3x를 `sed 's/^T("C3x", function()/local _c3x = (function()/'`로 뺌), 대조군 `scripts/mkpre3p.sh`. 비교는 `scripts/cmpold.py`(옛 출력과)·`scripts/cmpsec.py`(사본끼리).
5. 벤치: `scripts/runbench.sh`(다른 작업 없을 때) → `scripts/benchsum.py`.

## 미완

List 퍼저는 옛과 같게 2000시드(1만 아님). yield·다중 코루틴·Debounce 유보·Q114 A0 빌드·실기기 없음. I1 유령·I7 동결 확산·새 상호작용 5의 처방 프로토타입 없음. 상호작용 5의 원인(어느 recompute가 가려지는지) 미추적.

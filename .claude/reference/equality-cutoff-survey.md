# 같은 값 쓰기의 조기 종료·파생 cutoff — 다른 반응형 라이브러리 조사 (2026-10-01)

**[2026-10-01 신설 — 사용자 요청]** *"같은 값에 멈추는 되쓰기는 나도 괜찮다고 보는데, 문제는 quad 의 파동 방식인것 같아. vide / preact 의 같은 값 쓰기를 일찍 끝낸다가 뭔지 알려줄래? 다른 라이브러리들의 접근을 파보고 더 생각해봐야할 것 같아."* — sonnet 리서치 2차(1차는 `feedback-path-survey.md` — 되먹임 한도·파생 안 쓰기). 로컬 클론(`/code/Projects/quad-scratch/refs/` — `centau/vide@452060a`, `dphfox/Fusion@2790f7b`, `littensy/charm@b05f3a9`)은 줄까지 직접, 웹 소스는 각 레포 main을 2026-10-01 WebFetch(요약 거침 — 근거로 쓸 땐 다시 열 것). 결론이 아니라 재료다. 사용자 결정 대기.

## 1. 원천 쓰기의 같은 값 판정 — 전부 입구에서 끊는다

Vide `src/source.luau` 19행 `node.cache == v and (type(v) ~= "table" or table.isfrozen(v))`면 조기 반환 / Fusion `State/Value.luau` `set`은 `isSimilar`(`Utility/isSimilar.luau` — 비테이블 `==`·NaN, 테이블은 frozen이거나 메타테이블 있을 때만 `==`, 평범한 가변 테이블은 같은 참조여도 "다름") 아닐 때만 `change` / Charm `packages/charm/src/init.luau` 489행 `signalSetter`는 `pendingValue`와 비교(사용자 `equals` 옵션) / Preact `value !== this._value` / Solid `writeSignal`의 comparator(기본 `===`, `equals: false`면 늘 전파) / Vue `RefImpl` setter `hasChanged`(Object.is — 추정) / Svelte `source.equals`(기본 `===`, `safe_equals`는 객체·함수를 늘 다름) / MobX `prepareNewValue_`의 `equals_`(`UNCHANGED`면 통지 없음, `comparer` 옵션) / Angular `signalSetFn`의 `node.equal`(signal별 `equal` 옵션) / TC39 `Signal.State` `equals`(기본 Object.is) / Jotai `!Object.is(prev, new)`일 때만 에폭 `n` 증가. Recoil 미완.

## 2. 가변 테이블과 강제 통지

Vide·Fusion: 가변 테이블은 같은 참조여도 늘 전파 — 같은 테이블 재`Set`이 곧 강제 통지. Charm: 얕은 비교, 테이블은 불변으로(Studio에선 deepFreeze), 강제 통지 `trigger()`. Vue: 깊은 프록시(추정) + `triggerRef`(소스 주석 "typically used after making deep mutations"). Solid: `equals: false`. Preact·Angular·Jotai·TC39: 새 값을 만들어 쓰기. **Angular 선례**: `signal.mutate`를 지원하려고 기본 equality를 "비원시 값은 늘 다름"으로 뒀다가 v17(angular/angular PR #51821)에서 `mutate` 제거 — 이유 중 하나가 불변 데이터 사용자의 `computed` 메모이제이션 약화. Vide·Fusion·Svelte의 "테이블은 늘 다름" 예외가 같은 대가를 치른다(코드로 확인, 문제 보고 여부는 미확인).

## 3. 파생 노드의 같은 값 차단(equality cutoff) — 전부 있다

Vide: push로 즉시 재평가하고 `cur_value ~= new_value`일 때만 자식 큐잉(`graph.luau`). Fusion: `change.lua`가 의미 있게 변했을 때만 BFS로 `invalid` 표시, `evaluate.luau`가 `lastChange` 비교로 필요할 때만 재계산 — 결과가 `isSimilar`면 하류는 깨끗. Charm: `updateComputed`가 `oldValue ~= newValue`일 때만 직계 구독자 전파. Preact: `_refresh`가 값이 달라질 때만 `_version++`, 하류는 pull로 버전 확인. Solid: memo도 `writeSignal` comparator, STALE/PENDING + `lookUpstream`. Vue 3.5: `hasChanged`일 때만 `dep.version++`, pull `isDirty`. MobX: POSSIBLY_STALE을 뿌리고 결과가 바뀌면 STALE 확정, 같으면 재실행 없이 되돌림. Angular: 버전 미증가 + `consumerPollProducersForChange`. Jotai: 읽을 때 의존 `n` 비교(추정). 공통 패턴은 Reactively의 세 색(Clean/Check/Dirty — 직계만 Dirty, 그 아래는 Check, 결과가 같으면 하류를 Dirty로 만들지 않음).

## 4. 되쓰기 고리와의 관계

원천 입구 차단이 고리를 자연히 끊는다 — effect가 자기 입력에 `f(x)`를 쓰면 두 번째 실행의 같은 `f(x)`에서 setter가 조기 반환해 재큐되지 않는다. 파생 cutoff만으로는 effect가 원천을 직접 읽고 그 원천에 되쓰는 고리가 안 끊긴다(사이에 파생이 없으므로 — 논리). 같은 값도 전파하는 경로(강제 통지 API, 가변 테이블 늘 전파)에서 고리를 끊는 건 횟수 한도·재진입 플래그뿐(1차 기록 표).

## 5. 글리치·배치(요약)

pull 확인이 있는 계열(Preact·Vue·Angular·Solid·MobX·Jotai·Fusion)은 다이아몬드에서 D를 한 번 계산하고 B·C 결과가 같으면 건너뛴다. Vide는 FIFO라 길이가 다른 경로에서 한 번 더 도는 글리치가 가능해 보임(추정, 미실행). 배치 중 0→1→0: Charm은 pending/current 비교로 통지 없음(코드 확인), Preact는 돌 것으로 보임(추정).

## 6. quad 쪽 사실(메인 실측, 2026-10-01 mock)

quad는 **원천에서도 파생에서도 같은 값을 끊지 않는다** — `Source:Set`은 같은 값이어도 리비전을 올리고 전파(`base/source-state-plan.md`의 "`Source:Set(v)`는 동일값이어도" 절, `H-68`), 그리고 `s:Compute(function() return s:Get() > 5 end, s)`를 보는 Observer는 결과가 `false` 그대로인 `Set` 세 번에 세 번 돌았고, 같은 Compute를 보는 Effect도 결과가 그대로인 `Set`에 한 번 돌았다. 중복을 접는 자리는 지금 맨 끝 — Property 핸들러가 목표 `Value`를 비교하고(`H-478`, Q25), 엔진은 같은 값 재대입에 신호를 내지 않고, `q.Out`은 같은 값을 거른다. 즉 지금 quad는 리서치의 갈래 (c)("지금처럼 두고 하류가 값 비교")를 소비자 쪽이 아니라 엔진 경계에서만 하고 있다.

## 7. 갈래별 재료(리서치 소견 + 메인 보충)

- **(a) 원천에서 같은 값을 끊고 가변 테이블은 예외(Vide·Fusion식)** — `H-68` 근거 ② 테이블 제자리 수정과는 부딪히지 않는다(예외로 정확히 그 문제를 푼다, `:Emit`은 사실상 재`Set`으로 대체 가능 — 추정). 근거 ① Epoch 일관성과도 구조상 공존한다 — 리비전·버전 계열(Preact `_version`, Angular `epoch`, Jotai `n`, Vue `dep.version`, Fusion `lastChange`)은 전부 "실제로 바뀐 쓰기에만 리비전을 올린다". 대가: 불변 테이블의 cutoff를 잃고(Angular `mutate` 철회 이유), 가변 테이블을 매번 새로 쓰는 되쓰기 고리는 여전히 한도로만 멈춘다. quad 쪽 확인 필요(미조사): `Set(같은 값)`의 리비전 증가에 기대는 소비자(Gate/Debounce·`q.Out` 메아리 판정·Property 재대입 등)가 있는가.
- **(b) 파생 cutoff만** — 선례가 풍부(전원). Compute를 보는 Observer/Effect의 헛실행을 없앤다. 다만 원천을 직접 읽는 되쓰기 고리는 안 끊고, 원천 `Set(같은 값)`이 무효화를 서브트리에 뿌리는 비용은 남는다. quad는 lazy pull이라 cutoff를 넣으려면 "push로 표시 → 소비자가 pull할 때 값 비교 → 같으면 실행 안 함"(세 색) 모양이 필요 — 새 메커니즘(사용자 결정).
- **(c) 지금 그대로 + 소비자별 값 비교** — 리비전 정의는 안 건드리지만 매 `Set`마다 무효화·재계산·소비자 실행이 다 돈다(위 실측 — Observer가 결과 그대로인 Set마다 돈다).

# E40 — 반응형 그래프 참조 모델 차등 퍼저 (2026-09-27, HEAD `30510fcd`)

범위: quad-base 순수 반응형 층 — `Source`/`:Compute`/`:Depend`/`:Gate`(수동 정책)/`Blocker`/`Observer`/`Effect`. mock 백엔드 없이
`quad-base/src` 한 벌만 require(생명주기 hold op 넷은 "아무것도 인스턴스에 묶이지 않음" 스텁 — 전역 구독 경로만 씀).
레포 파일 무변경, 이 폴더만 새로 만듦.

## 파일

| 파일 | 내용 |
|---|---|
| `fuzz.e40.luau` | 모델 + 퍼저 + 축소기. `luau .claude/audit/round13-e40-reactive-fuzz/fuzz.e40.luau -a <from> <count> [flags] [verboseSeed]` |
| `results.txt` | 본 실행(아홉 플래그 조합 × 5만 시드) 요약 |
| `probe.e40.axes.luau` | 축 (a)~(d) 지정 프로브 P1~P8 |
| `probe.e40.rule1.luau` | 발견 (b)-1 최소 재현 |

플래그: `throw`(던지는 Compute), `late`(노드를 시퀀스 도중 생성), `reent`(콜백 안 `Set` — 축 (d)), `dfs`(아래),
`gate-rule1`(아래), `inj1`/`inj2`/`inj3`(하네스 자기 검증용 결함 주입), `shrink`.

## 모델 (State.luau를 읽지 않고 문서 규칙으로 따로 짬)

- **값**: 매 원시 변경(Set/Emit) 뒤 전체 위상 순서로 처음부터 재계산 — 글리치 없는 정답. Compute 함수는 양쪽이 같은 순수 함수
  (정수 산술 mod 9973, 문자열 모드, 조건부 읽기 — `docs/reference/core/03-state.md:76`, 던짐 모드). 던진 노드와 그걸 읽은 노드는 `ERR`.
- **통지**: 노드마다 "이미 통지한 (원천, 리비전)" 집합. 파동의 페이로드 집합 P 중 새것이 하나라도 있으면 전달, 모두 기록
  (quadnomicon `01-revision-and-epochmap.md:102-112` 규칙 1~3, `base/state-epoch-plan.md:308-345`). 새 노드의 집합은 빈 채 시작
  (`state-epoch-plan.md:287-290`). Source는 같은 값 Set/Emit도 언제나 전달(`core/02-source.md:78`, `:105`).
- **게이트**: 새것이 있을 때만 흡수 집합에 합침, 열려 있으면 즉시 스왑·기록·전달, 닫혀 있으면 보유; `emit(false)`는 버림
  (`core/03-state.md:207-211`, `base/gate-plan.md:266-276`). **Blocker**: On은 플래그만, Off는 등록 게이트마다 배치 한 번,
  OffWithoutEmit는 버림(`sugar/06-blocker.md:83-103`). 핸들 순회 순서는 계약상 미정이라 **quad의 `blocker._handles` 순서만 읽어** 맞춤.
- **Observer**: 설치 즉시 1회(`emitFrom=nil`), 대상이 전달할 때마다 1회(값 비교 dedup **없음** — 아래 "브리프 전제 정정"),
  미구독이면 보류 → 구독 시 정확히 1회 재생(`core/05-observer-effect.md:101-103`). `emitFrom`은 Set 파동이면 그 Source,
  게이트를 지나면 배치 집합, 설치·재생이면 nil(`core/05:95`) — 집합 내용까지 대조.
- **Effect**: 생성 시 1회, 자기 epoch 집합(생성 시 라이브로 시드)으로 파동당 최대 1회 재실행, 재실행 전 저장된 cleanup 1회,
  미구독이면 보류(`core/05:218-231`, `state-epoch-plan.md:486-497`). 강한 `:Unsubscribe`는 cleanup 소진 + "재설치 필요"
  → 재구독 시 변경 없어도 1회 재실행(`base/gate-plan.md:523` "재구독 시 소진돼 있었으면 … 재설치로 한 번 돌고"). `:WeakUnsubscribe`는 cleanup 불변(`core/05:300`).

**두 해석을 둔 곳**:
1. *파동 안 방문 순서* — 기본 모델은 위상 순서, `dfs` 모델은 quad의 `_subs` 반복 순서(읽기만)로 재귀. 문서는 순서를 미정으로 둔다
   (`core/02-source.md:81`, `core/05:110`). 결과: 위상 모델은 5만 시드당 2~6건 어긋나고 전부 순서 효과(발견 (c)-1), dfs 모델은 0.
2. *게이트 수신 판정* — 이상형은 "emit 맵(`Peek`)에 새것이 있을 때만"; `gate-rule1`은 구현의 규칙 1(값 맵이 뒤처져 있어도 수용, 값 맵은 수신과
   게이트 `:Get()`으로만 라이브화)까지 모델링. 실 구현은 **후자**(발견 (b)-1).

하네스 자기 검증: `inj1`(다이아몬드 삼킴 제거) 300시드 중 77 실패, `inj2`(`Get` 루프의 Refresh 제거) 177 실패 — 통지·값 대조 둘 다 감지함.
`inj3`(게이트가 Peek 무시)은 0 — 게이트는 부모가 하나라 부모 쪽 dedup 뒤에서 Peek가 결정적인 경우가 없어서(하네스 사각이 아님).

## 숫자 (results.txt)

| 플래그 | 시드 | 스텝 | 차등 |
|---|---|---|---|
| dfs | 50,000 | 2,750,844 | 0 |
| dfs,throw | 50,000 | 2,749,398 | 1 — (b)-1 (seed 28545, `gate-rule1`로 돌리면 0) |
| dfs,late | 50,000 | 2,748,984 | 0 |
| dfs,throw,late | 50,000 | 2,746,026 | 0 |
| dfs,gate-rule1,throw,late | 50,000 | 2,746,026 | 0 |
| (위상 모델) 기본 | 50,000 | 2,750,731 | 4 — 전부 순서 효과 (c)-1 |
| (위상 모델) throw,late | 50,000 | 2,746,002 | 2 — 순서 효과 1 + (b)-1 1 |
| reent | 50,000 | 2,750,844 | 0 (값·최종 일관성) |
| reent,throw,late | 50,000 | 2,746,026 | 0 |

값 대조(명시 `Get`·콜백 안 읽기·Effect 안 읽기) 차등은 전 조합 0. 실행마다 해시 순서가 달라 순서 효과 시드는 재현이 들쭉날쭉하다(같은 시드 6회 중 2~3회).

### Compute 재계산 횟수 (축 a)

- 한 변경 스텝에서 노드별 fn 실행 횟수 분포(dfs, 5만 시드): **0회 5,135,232 / 1회 1,750,096 / 2회 이상 0**.
- "상류 리비전이 안 움직였는데 fn이 돈" 경우(spurious) 전 조합 0 — throw·late·reent 포함.
- 다이아몬드 하단 노드(서로 다른 dep 둘이 원천을 공유) 75,568개, 단일 Set 스텝 930,718 노드-스텝에서 fn 568,284회(읽지 않은 스텝은 0회 — lazy).
- P1 격자 다이아몬드(폭×깊이 2×1·2×4·4×4·8×6, 모든 노드가 부모 전부 읽음): Set 5회 → 모든 노드 정확히 5회, 하단 Observer 5회.
- P1b: 읽는 쪽이 없으면 0회, 한 세대에 `Get` 두 번은 1회, 같은 값 재Set은 다음 읽기에서 1회(`core/03:48`과 일치).

### 다른 축

- (b) `previous`: 퍼저 전체에서 `previous ≠ 직전 성공 결과` 0건. P2: `nil, 10, 20, 20`(던진 회차는 `previous`를 옮기지 않음 — `core/03:75`와 일치; Q98 갈래 무관).
- (c) 던짐: throw 조합 누계 fn 던짐 233k·회복 99k, 값 차등 0. P3: 같은 세대 재읽기 `Quad0184`(하류 포함), 같은 나쁜 값 재Set에도 fn 재실행,
  닫힌 Blocker 뒤 상류 수정으로 회복(`H-540`) — `core/03:77`과 일치.
- 순환(별도 소량, P4): fn이 하류 State를 거쳐 자기 값을 읽으면 `Quad0184`, 상류 Set 뒤에도 순환이 남아 있으니 계속 `Quad0184`. 정적 그래프로는 순환을 만들 수 없음(생성 시 dep이 이미 있어야 함).
- (d) 재진입: 콜백이 다른 Source를 Set(스텝당 최대 3). 값 차등 0, 게이트 없는 대상의 "구독된 핸들의 마지막 읽기 = 최종값" 위반 0 —
  **단, Observer 설치 발화 안에서(자기 읽기 뒤) 전이적으로 대상이 바뀌면 그 Observer는 다음 변경까지 옛 값에 머묾**(5만 시드 중 22,769 관측-스텝).
  문서가 적은 동작(`core/05:102`, `Observer.luau` "ORDER IS THE CONTRACT")이고 round13 Q73과 같은 계열이라 발견으로 올리지 않고 검사에서 제외(`installWindowSkips`).
  P5: Effect fn 안 자기 dep Set → `cl fn1 cl fn2`(`core/05:231`), cleanup 안 Set → `cl fn9` 한 사이클(`core/05:225`), Observer가 자기 대상 Set → 재귀 `1,2,3,4`(`core/05:107`, 수렴 조건 둠).

## 발견

### (b)-1 게이트 뒤 게이트가 이미 흘려보낸 리비전을 다시 통지 — 통지 횟수가 "누가 읽었나"에 달림 [LOW]
`probe.e40.rule1.luau`. `S → G1(b1) → G2(b2)`, G2에 값을 안 읽는 Observer. `b2:On(); S:Set(1)`(G1 열림 → G2 보유, G2 값 맵 S@r1) →
`b1:On(); S:Set(2)`(G1 보유) → `b2:Off()`(G2가 {S}를 흘리고 emit 맵을 **라이브 r2로** Sync, Observer 1회) → `b1:Off()`(G1이 {S}를 흘림 →
G2 `_receive`에서 값 맵 r1≠r2라 규칙 1로 수용 → 열려 있으니 {S}를 **다시** 흘림, Observer 2회째). 콜백이 `t:Get()`을 부르면 그 읽기가 G2 값 맵을 라이브로
당겨 두 번째가 삼켜져 1회 — 같은 조작인데 콜백이 값을 읽느냐에 따라 1회/2회. G2 하류 State는 emit 맵으로 삼키므로 값·Effect 재실행에는 영향 없고,
**게이트 노드에 직접 붙은 Observer**(와 그 자리에 바로 묶인 핸들러)만 같은 리비전을 두 번 본다. 약속과의 차이: 게이트의 emit 맵은 "내가 하류로 던진 리비전"
(`base/gate-plan.md:272-276`, `quad-base/src/State.luau:285`)이고 문서가 무해하다고 적은 재수용은 "유보 중 같은 리비전이 다른 경로로" 오는 경우뿐인데,
여기선 이미 던진 리비전을 규칙 1(`State.luau:287-296` — `valueChanged or emitChanged`)로 다시 던진다. `core/03-state.md:210`·`sugar/06-blocker.md:94`의
"한 번의 통지로 합쳐진다"와도 어긋남. 퍼저가 자연 발생으로도 잡음(seed 28545 `dfs,throw` — 실행마다 재현 여부 다름; `gate-rule1` 모델로는 0).

### (c)-1 한 번의 `blocker:Off()`에서 Observer/Effect 발화 횟수가 미정 순서에 따라 1 또는 2
`probe.e40.axes.luau` P7. `G = S2:Apply(b)`, `A = G:Compute(id)`, `C = G:Compute(id)`, `H = C:Depend(S1):Apply(b)`, `Effect(fn, A, H)`, H에 Observer.
`b:On(); S1:Set(1); S2:Set(1); b:Off()` — 새로 만든 그래프 300개에서 Effect 재실행 **1회 71 / 2회 229**, H Observer **1회 146 / 2회 154**.
G가 먼저 풀리고 그 안에서 C 경로가 A보다 먼저 가면 H가 {S1,S2}를 한 배치로 흘려 1회, H가 먼저 풀리면 {S1}·{S2} 두 번. 값은 언제나 최신이고 어느 쪽도
문서 위반은 아니다(구독자 순서 미정 `core/02-source.md:81`, Blocker 핸들 순서 미정). 다만 문서는 통지 **횟수**가 순서와 해시 배치에 따라(같은 코드, 실행마다) 달라질 수
있다는 말이 없고, `sugar/06-blocker.md:58`의 "두 게이트가 각각 한 번씩 통지"·`:94` "게이트마다 … 한 번의 통지"는 하류가 한 번만 본다고 읽힐 수 있다.
판단 필요: 횟수를 미정으로 명시할지(문서), 그대로 둘지. 위상 모델 불일치 12건(5만×2 시드 조합에서 6, 10만 시드 1차 실행에서 6)이 전부 이 부류였음(dfs 모델은 0).

### (c)-2 게이트 유보 중 새로 만든 노드는 Off 때 같은 값을 다시 통지 (관측)
P8. 닫힌 게이트 뒤에서 Set한 다음 그 게이트 하류에 노드 D와 Observer를 만들면, Observer는 설치 때 최신값을 읽고 `Off` 때 **같은 값으로 한 번 더** 발화한다
(Effect는 epoch을 라이브로 시드해서 재실행 없음). `state-epoch-plan.md:287-290`이 의도한 동작("새로 생성된 노드에서 들어온 emit은 한번도 받아본적 없는 emit")이라
결함 아님 — Observer와 Effect가 이 창에서 다르게 보인다는 점만 기록.

### (a) 문서 오류 — 없음
값·재계산 횟수·`previous`·던짐 회복·Effect cleanup 순서·emitFrom 모양 모두 문서 문장과 일치.

### 브리프 전제 정정
브리프가 적은 "Observer의 값 비교 dedup"은 문서·코드 어디에도 없다 — Observer는 대상이 전달할 때마다 발화하고 같은 값 재Set에도 발화한다
(P6, `core/02-source.md:78`, `core/05:101-103`). 값 비교 dedup은 Property 핸들러(`H-478`)·Tween `Dedup` 쪽 개념. 모델은 문서대로 dedup 없이 짰다.

## 미완
- 축소기(`shrink`)는 구현했지만 dfs 모델 차등이 (b)-1 한 건(재현이 해시 순서 의존이라 축소가 불안정)뿐이라 쓰지 않고 지정 프로브로 대신했다.
- Ref dep을 가진 Effect, `Dispatch.drive`/인스턴스 바인딩 경로, `Debounce`/`Throttle` 게이트, yield(Q93·Q98 영역)는 범위 밖.
- 재진입 모드는 통지 횟수를 대조하지 않는다(콜백 순서 미정) — 값과 최종 일관성만.

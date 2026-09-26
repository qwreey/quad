# E63 — 의존성 집합 계약 퍼저 (`q.Effect(fn, ...deps)` · `:Observer` · `:Depend` · `:Compute` 후행 deps)

2026-09-27, HEAD `50f639c6`. 레포 파일 무변경 — 이 폴더만 새로 만듦. 하네스는 `round13-e44-ref-statemachine/`의
`harness.luau`·`engine-globals.luau` 사본(quad-roblox `luau_packages` 한 벌 — `typing-limits.md` 8.34). `./scripts/relink.sh` 뒤
이 폴더에서 `luau <파일>`.

| 파일 | 무엇 |
|---|---|
| `fuzz.luau` | 참조 모델 + 퍼저. `luau fuzz.luau -a <첫 시드> <개수> [late\|inj1\|inj2\|inj3\|inj4] [verboseSeed]` |
| `results.txt` | 본 실행(기본 5만 + `late` 5만 시드) 요약 |
| `axes.luau` / `out-axes.txt` | 축 프로브 A1~A14(다이아몬드·중복·Ref·Depend·후행 dep·잘못된 dep ID·수명 주기·Blocker·재진입·순서·GC·파괴·유보 중 시드) |
| `axes2.luau` / `out-axes2.txt` | A15~A20(Declaration 안 Ref+Effect 순서, Slot 원소 안 Ref, `slot.Length` dep, 0 dep, 던지는 dep, 에러 번호 위치) |
| `probe-lifecycle-ids.luau` / `out-lifecycle-ids.txt` | 구독·바인딩 전이 에러 ID 표(Effect/Observer 각 13칸) |
| `perf.luau` / `out-perf.txt` | 축 (d) 넓은 dep 집합 |
| `types-pos.luau` / `types-neg.luau` / `out-types.txt` | 축 (e) strict(luau-lsp 신 솔버 + test.sh 한도 플래그 셋) |

## 참조 모델 (문서에서 따로 짬, 규칙 18)

1. 루트는 Source·Ref. 같은 값 재Set도 새 리비전·전파(`core/02-source.md:78`, `core/07-ref.md:190`, `:239`).
2. Ref가 묶인 인스턴스의 `Destroy`는 Set이 아니다 — 전파 없음(`core/07-ref.md:92`). 숫자 키 자리 재구동은 `:Set(nil)`(`:91`).
3. 노드는 한 루트 리비전을 한 번만 전달(다이아몬드 흡수 — quadnomicon 01 §3.2 규칙 1~3). 새 노드의 emit 맵은 빈 채 시작.
4. `:Depend(...)` 값 = 리시버, 어느 dep이든 전파(`core/03-state.md:112-120`); 중복 dep 허용.
5. `:Compute` 후행 deps는 fn이 안 읽어도 전파·재계산 트리거(`core/03:68`); fn 인자 순서 = 넘긴 순서(`core/03:74`).
6. 게이트(`:Apply(blocker)`): 유보 중 루트 집합 보유, `Off`는 게이트마다 배치 하나(순서는 계약상 미정 — `blocker._handles` 순서를 읽어 맞춤, E40과 같음), `OffWithoutEmit`는 버림(`sugar/06-blocker.md:83-107`). 값은 가리지 않음(`core/03:207`).
7. Effect: 생성 즉시 fn 1회(`core/05:218`).
8. Effect: 본 적 없는 루트 리비전이 실린 전달마다 (cleanup → fn) 1회 — 같은 Set이 여러 dep으로 와도 1회. seen 집합은 생성 시 라이브로 시드.
9. 같은 dep 여러 번 → 하나(`core/05:219`).
10. 실행 자격 없으면 보류 → 살아날 때 1회(`core/05:227`).
11. `:Unsubscribe()` = cleanup 1회 소진 + 다음 구독에서 재설치 1회(`core/05:290`, `base/gate-plan.md:523`).
12. `:WeakUnsubscribe()`는 cleanup 불변(`core/05:300`).
13. 호스트 Destroy = cleanup 1회(`dying=true`) 뒤 정지(`core/05:226`, `:32`).
14. `Rerun()`은 자격 없으면 보류(`core/05` `effect:Rerun` 절).
15. Observer: 대상 하나, 설치 발화 1회, 대상 전달마다 1회, 보류 → 재생 1회(`core/05:101-103`).
16. dep 검증: `nil` → `Quad0095 #i`, State/Source/Ref 아님 → `Quad0096 #i`(`core/05:221-222`); Compute/Depend는 `Quad0186 #i+1`/`Quad0183 #i+1`(`core/03:81`).
17. 구독 전이 에러: 이미 구독 `Quad0091/0089`(Obs `0114/0111`), 묶임 `Quad0231/0230`(Obs `0235/0234`), 강한 해제 아님 `Quad0093`(`0115`), 약한 해제인데 강함 `Quad0092`(`0112`), 구독 중 바인드 `Quad0104`, 중복 바인드 `Quad0233`.
18. fn이 읽은 값 = 그 시점 전 그래프를 처음부터 계산한 값.

## 숫자

| 실행 | 시드 | 스텝 | 차등 |
|---|---|---|---|
| 기본 | 50,000 | 2,799,719 | 0 |
| `late`(소비자 도중 생성) | 50,000 | 2,798,040 | 0 |
| 자기 검증 `inj1`(다이아몬드 흡수 제거) | 500 | — | 314 |
| `inj2`(Ref 같은 값 Set 무전파) | 500 | — | 48 |
| `inj3`(WeakUnsubscribe가 cleanup 소진) | 500 | — | 205 |
| `inj4`(읽은 값 대조 +1) | 300 | — | 238 |

두 본 실행 누계: Effect 실행 1,615,783 · Observer 발화 742,940 · cleanup 744,799(그중 `dying=true` 46,724) · 중복 dep Effect 81,058 ·
0 dep Effect 62,981 · Ref Set 241,497(같은 값 69,963) · Ref 호스트 파괴 10,329 · 소비자 호스트 파괴 47,581 · 게이트 배치 25,924 ·
보류 재생 88,486 · 기대된 에러 ID 705,530 · 잘못된 생성자 559,696(ID와 번호 전부 일치).

축 결과 요약: A1 다이아몬드 `Effect(fn, a, a:Compute, a:Depend())` Set 2회 → 실행 3(설치+2). A2 `Effect(fn,a,a,a)` 1회, `a:Compute(fn,a,a)`는 fn이
같은 핸들을 세 번 받고 1회 계산. A3 Ref dep은 같은 값·`nil→nil` Set마다 재실행, 호스트 Destroy엔 없음, 자리 철거(`State<Ref?>`)엔 1회.
A8 재구독 뒤 dep 집합 유지. A9 `Effect(fn, a, a|blocker)`는 `Off`에 재실행 없음(이미 a로 봤음). A10 `fn0 cl fn1 cl fn1`(`core/05:231`).
A12 인라인 `a:Depend(b)`를 dep로 둔 약한 구독 Effect·바인드 Effect는 GC 두 번 뒤에도 발화(수명은 핸들이 쥠). A14 유보 중 만든 Effect는 `Off`에 재실행
없음(라이브 시드), 같은 자리 Observer는 같은 값으로 한 번 더(E40 (c)-2와 같음). A15 `D.Frame{ref, effect}`·`{effect, ref}`·Pre/PostRef 여섯 조합 모두
`nil cl:false inst` → Destroy `cl:true`. A16 Slot 원소 파괴에 Ref dep 재실행 없음. A18 dep Compute가 던지면 Set 줄로 올라오고 Effect는 죽음(`core/03:77`).

(d) 성능(`out-perf.txt`): 1000 distinct dep Effect 생성 1.1ms, dep 하나 Set 100회 0.12ms(실행 100); 1000개 같은 dep 0.06ms; 999 후행 dep Compute는
Set+Get 1회 0.13ms(dep 수에 선형 — 재계산 전 전 dep 스탬프); 7000 dep까지 정상, 10000은 호출 측 `table.unpack` 한계(quad 밖).

(e) strict(`out-types.txt`): `types-pos` 클린(`q.Effect(fn, a, b, r)`·`Depend` 결과 `State<number>`·후행 dep 주석 Compute·Observer 콜백).
`types-neg`: `a:Depend(b)`를 `State<string>`에 주석하면 에러(리시버 타입 유지 — 문서대로), `Observer(fn, b)` 여분 인자 에러, fn이 숫자 반환 에러;
`q.Effect(fn, 5, "str", {})`·`a:Compute(fn, q.Ref(0))`·`a:Depend(q.Ref(0))`는 정적으로 통과(deps가 `...any` — `core/05` 시그니처·`core/03:83`에 적힌 대로, 런타임 ID가 잡음).

## 발견

### (a) 문서 오류
1. **`core/05-observer-effect.md:35` — 구독된 핸들을 숫자 키 자리에 놓을 때의 문구가 틀림 [LOW].** 문서는 "이미 한쪽으로 살아 있는 핸들을 다른 쪽으로
   다시 살리려 하면 `Observer: already subscribed` 또는 `Observer: already bound to an Instance`(Effect도 같은 문구)"라고 하지만, 구독된 핸들을 `D.Frame { h }`에
   놓는 방향은 `Quad0104 bindLifetime: value is already subscribed`로 던진다(Observer·Effect, 강·약 구독 넷 다 — `out-lifecycle-ids.txt`). 문서의 두 문구는
   반대 방향(묶인 핸들에 `:Subscribe()`)에서만 난다. `Quad0104`는 `extend/01-backend-provider-contract.md:139`와 에러 페이지에만 있다.
2. **`core/05:212`(`...deps` "이것들이 움직일 때마다 `fn`이 다시 돕니다")가 다이아몬드 흡수를 말하지 않음 [LOW, 누락].** 한 `Set`이 여러 dep을 거쳐
   도착해도(`Effect(fn, a, a:Compute(…), a:Depend())`) 1회, 게이트를 거친 사본이 나중에 풀려도 이미 본 리비전이면 0회다(A1·A9, 퍼저 규칙 8 — 5만×2 시드 차등 0).
   중복 dep 합침(`:219`)은 적혀 있지만 "서로 다른 dep이 같은 원천을 공유"하는 경우는 페이지 어디에도 없어 dep 수만큼 돈다고 읽힐 수 있다. Blocker 페이지
   `sugar/06-blocker.md:97`이 여러 게이트 합류의 1~2회만 적었다.

### (b) 코드 결함
없음 — 모델 차등 0(두 본 실행 10만 시드, 약 560만 스텝), 축 프로브 전부 문서와 일치.

### (c) 판단 필요
1. **Compute/Depend의 dep 검증은 nil 검사를 먼저 전부 돌린 뒤 타입 검사를 한다 — 보고되는 번호가 첫 번째 잘못된 인자가 아닐 수 있음 [LOW].**
   `a:Depend(5, nil)`·`a:Compute(fn, {}, nil)`은 앞의 `#2`가 아니라 `Quad0186 State: dep #3 is nil`을 낸다(`State.luau:247-256` `collectDeps`가 nil 전수 →
   `newNode` `:108-113` 타입 검사). 같은 모양의 `q.Effect(fn, 5, nil)`은 자리 순서대로 검사해 `Quad0096 … dep #1`(A20). 어느 쪽도 문서(`core/03:81`, `core/05:221-222`)
   위반은 아니고 둘 다 결정적이다. 사용자가 보는 효과는 "고친 뒤 다시 돌리면 다른 자리를 가리키는" 정도라 그대로 둘지, `core/03:81`에 순서를 한 줄 적을지만의 문제.

## 미완
- 재진입(Effect fn이 dep을 Set)은 축 프로브(A10)로만 보고 퍼저에 넣지 않았다(구독자 순서 미정 — E40 `reent`가 값 일관성까지 봄).
- 퍼저의 게이트는 한 층뿐(게이트 뒤 게이트는 E40 (b)-1 영역이라 제외), Observer 대상에 Ref 없음(Ref엔 `:Observer`가 없음).
- 약한 구독 핸들의 GC 수거 경로는 퍼저가 핸들을 모두 쥐고 있어 다루지 않음(A12 한 칸만).
- Slot 원소 파괴는 축 프로브(A13·A16)로만 — 퍼저의 호스트 파괴는 맨 `D.Frame`.

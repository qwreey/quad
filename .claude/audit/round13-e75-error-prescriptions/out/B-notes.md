# E75 그룹 B — `docs/reference/errors/02-dispatch-bookkeeping.md`

실행: `mise exec -- luau .claude/audit/round13-e75-error-prescriptions/cases/B.luau` → `out/B.txt`(케이스 69줄, `<<END>> 69`). 보조 프로브 `cases/B_probe.luau` → `out/B_probe.txt`(문자 키에 놓인 quad 값별 에러 id), `cases/B_probe2.luau` → `out/B_probe2.txt`(Quad0023 반쯤 지어진 인스턴스 재시도). 러너 출력의 blame 접두가 `cases/B.luau:N`이면 사용자, `quad_base/src/…`이면 내부.

## (i) id별 표

| id | 페이지:줄 | 판정 | blame | 한 줄 메모 |
|---|---|---|---|---|
| Quad0019 | 02:10 | 정확 | 사용자(B.luau:13·19) | setEmpty(f,0)·getOffsetAt(f,1.5) 둘 다 |
| Quad0020 | 02:18 | 정확 | 사용자(B.luau:23) | |
| Quad0021 | 02:26 | 정확 | 사용자(B.luau:27·37) | State 값 1.5도 `len:Set` 줄 blame |
| Quad0022 | 02:34 | **불충분** | 사용자(B.luau:48 등) | 고치려면 첫 갈래 "setLength로 먼저 등록"을 글자대로 하면 Quad0023. E28 기추적(setOffsetSource 권고) — **고쳐짐** |
| Quad0023 | 02:42 | 정확 | **내부**(Bookkeeping.luau:248) | `{a, q.None, b}`로 해결. blame 내부는 E28 기추적(남음) |
| Quad0024 | 02:50 | 정확 | **내부**(Bookkeeping.luau:288) | E28 기추적 blame(남음) |
| Quad0025 | 02:58 | 정확 | 사용자(B.luau:106) | |
| Quad0229 | 02:66 | 정확 | 사용자(B.luau:119) | 차단기 켠 동안만 도달(페이지 서술과 일치) |
| Quad0049 | 02:74 | 정확 | 사용자 | |
| Quad0050 | 02:82 | 정확 | 사용자 | |
| Quad0051 | 02:90 | 정확 | 사용자 | 이름 문자열·생략 두 갈래 |
| Quad0052 | 02:98 | 정확 | 사용자 | TypedFactory·DefineSubtype 두 갈래 |
| Quad0053 | 02:106 | 정확 | 사용자 | 콜론 형태 무에러 주장도 실측 확인(TRIG=noerr) |
| Quad0054 | 02:114 | 정확 | 사용자 | Overridden에 Modifier / q.Modifier(...)로 평범한 테이블 |
| Quad0055 | 02:122 | 정확 | 사용자 | 페이지가 `:As(name)`도 Quad0052라고 적음 — E28 기추적 **페이지 고쳐짐**, 메시지 꼬리 힌트 "(or use :As(name) for an unchecked cast)"는 **남음** |
| Quad0056 | 02:130 | 정확 | 사용자 | `:As(name)` 강제·간선 바로잡기 둘 다(다운캐스트 방향만 통과) |
| Quad0057 | 02:138 | 정확 | 사용자 | PreRef를 배열부로 옮기면 채워짐 |
| Quad0058 | 02:146 | 정확 | 사용자 | `[AttrKey]=5` → 속성 설정됨 |
| Quad0059 | 02:154 | 정확 | 사용자 | 숫자 키·빈 문자열 둘 다 |
| Quad0060 | 02:162 | 정확 | 사용자 | 이름 바꾸기(원래 의도가 불법) |
| Quad0061 | 02:170 | 정확 | 사용자 | 〃 |
| Quad0062 | 02:178 | 정확 | 사용자 | 〃 |
| Quad0063 | 02:186 | 정확 | 사용자 | 인라인 키·State로 감싸기(Modifier 안 `q.Source(fn)`도 이벤트 연결됨)·`mod:k(fn)` 변환 셋 다 |
| Quad0064 | 02:194 | 정확 | 사용자 | |
| Quad0065 | 02:202 | 정확 | 사용자 | |
| Quad0066 | 02:210 | 정확 | 사용자 | TypedFactory·DefineSubtype 두 자리 |
| Quad0067 | 02:218 | 정확 | 사용자 | |
| Quad0068 | 02:226 | 정확 | 사용자 | 문자 키·`[5]` 둘 다 |
| Quad0069 | 02:234 | 정확 | 사용자 | PreRef 다른 인스턴스·PostRef 같은 props 두 자리 |
| Quad0070 | 02:242 | 정확 | 사용자 | 순환 없는 사슬은 반응성 유지 |
| Quad0071 | 02:250 | **도달**·불충분(처방 미정) | **내부**(Dispatch/init.luau:238) | E28 "정적만" → 공개 API로 도달: retractor가 같은 (inst,key)에 `retractFrom` 재진입 |
| Quad0072 | 02:258 | 정확 | 사용자 | process·getHandler |
| Quad0073 | 02:266 | 정확 | 사용자 | |
| Quad0074 | 02:274 | 정확 | 사용자 | |
| Quad0075 | 02:282 | 정확 | 사용자(B.luau:344, 위임 핸들러의 `process` 줄) | 위임 핸들러 index+2 → index+1 |
| Quad0076 | 02:290 | **불충분**(Store 갈래) | 사용자 | 오타·Parent·Tag 문자 키는 정확, Store는 페이지 처방대로 숫자 키로 옮겨도 같은 에러. E28 기추적(흔한 원인 누락) — **페이지 고쳐짐**, 프로바이더 설치 상태의 "provider … initialized" 꼬리는 **남음** |
| Quad0077 | 02:300 | 정확 | 사용자 | |
| Quad0079 | 02:308 | 정확 | 사용자 | |
| Quad0080 | 02:316 | 정확 | 사용자 | |
| Quad0081 | 02:324 | 정확 | 사용자 | |
| Quad0082 | 02:332 | 정확 | 사용자 | |
| Quad0083 | 02:340 | **불충분**(예시) | 사용자 | 페이지의 고친 예시 `D.Frame { q.Source(1) }` 자체가 Quad0076. 일반 처방(중괄호)은 Attr·자식 사례에서 정확 |
| Quad0084 | 02:348 | 정확 | 사용자 | |
| Quad0085 | 02:356 | 정확 | 사용자 | |

## (ii) 발견 문단

**B-1 Quad0022 — 첫 갈래 "setLength로 먼저 등록"을 글자대로 따르면 Quad0023으로 바뀐다(불충분).** 페이지 39행은 "조회나 `setOffsetSource` 전에 그 앞 위치들을 `setLength`(또는 `setEmpty`)로 먼저 등록하세요 — 위치를 등록하는 것은 이 둘뿐"이라고 한다. 새 owner에서 `getOffsetAt(f, 3)`이 Quad0022를 낸 프로그램에 `setLength(f, 1, 2); setLength(f, 2, 3)`만 앞에 넣으면, 첫 `setLength`의 재계산이 `sourceList[1]`이 비었다고 Quad0023을 던진다(`cases/B.luau:47` 케이스 a, 출력 `FIX=err … Bookkeeping.luau:248: Quad0023 Bookkeeping.recompute: sourceList[1] is nil`). `setLength`는 위치를 "등록"하지만 같은 위치의 `setOffsetSource`가 먼저 와 있어야만 재계산을 통과한다 — 계약 순서(`setOffsetSource` 다음 `setLength`, extend/02 376행)를 지킨 케이스 c(`B.luau:61`, offset@3=5)와 `setEmpty` 갈래 b(`B.luau:54`)·d(`B.luau:69`)는 정확하다. 문구 대안: "그 앞 위치마다 `setOffsetSource`(발행 채널이 없으면 `q.None`) 다음 `setLength`를 부르거나, 빈 자리면 `setEmpty`를 부르세요". E28이 적은 옛 문제(`setOffsetSource`로 등록하라는 권고)는 현재 문구에서 고쳐졌다.

**B-2 Quad0071 — 공개 API로 도달한다(E28은 정적만).** `q.Dispatch.addHandler`로 두 층 핸들러를 등록하고(바깥 층이 `index + 1`로 위임), 안쪽 층의 retractor가 같은 `(inst, key)`에 `q.Dispatch.retractFrom(inst, key, 1)`을 부르게 한 뒤 바깥에서 `retractFrom(f, key, 1)`을 부르면, 안쪽 호출이 체인을 먼저 비우고 바깥 루프가 `list[1] == nil`을 만나 `Dispatch/init.luau:238: Quad0071 Dispatch.retractFrom: no slot at index 1 …`을 던진다(`cases/B.luau:305`). 이 경로는 `base/dispatch-core-plan.md` 1389행이 "같은 `(inst, k)`의 간접 재진입도 UB"(Q5 (a))로 확정한 부류다 — 즉 페이지 254행 "정상 경로로는 나지 않는 내부 불변식 위반"은 틀리진 않지만, 원인이 quad 버그가 아니라 사용자 핸들러의 재진입일 수 있다. 255행 "(문서 미정) 재현되면 리포트하세요"에 문구 후보를 더할 수 있다: "직접 쓴 핸들러의 retractor(또는 process)가 같은 요소·같은 키에 `retractFrom`/`process`를 다시 부르지 않는지 확인하세요 — 같은 자리 재진입은 정의되지 않은 동작입니다". 부수: 공개 문서(`docs/`)에는 같은 자리 재진입 UB 서술이 없다(`grep -rn "간접 재진입\|같은 \`(inst, k)\`" docs` 0건; `docs/skills/quad-ui-dev/SKILL.md`만 "같은 키 재진입" 언급) — extend/02 "한계와 주의" 절에 없는 것이 사용자 문항 후보. blame은 `error(…, 1)`이라 quad 내부 줄이다.

**B-3 Quad0076 — Store 갈래는 페이지 처방으로 못 벗어난다(불충분).** 페이지 297행 고치려면은 "quad 값이라면 올바른 종류의 키(숫자/문자) 자리에 놓으세요"인데, `Store`는 어느 키에도 핸들러가 없다: 문자 키 `Info = store`(Quad0076, 꼬리 "a Store is not a value for any key …")를 숫자 키 `{ store }`로 옮기면 같은 Quad0076이 다시 난다(`cases/B.luau:366`, 출력 `FIX=err … B.luau:370: Quad0076 Dispatch: no handler matched key 1 (value: table, brand: Store)`). 메시지 꼬리가 권하는 `store.Name`/`q.Attr(store)`는 정확하다(`B.luau:363`·`B.luau:374`, `Hp=3`). 페이지 294행 힌트 문단은 Store 꼬리를 옮겨 적었지만 고치려면 문장이 Store를 예외로 빼지 않는다 — 문구 대안: "…자리에 놓으세요(`Store`는 어느 자리에도 놓을 수 없습니다 — 필드(`store.Name`)를 쓰거나 `q.Attr(store)`로 감싸세요)". 오타(`Visibel`)·`Parent`·Tag의 문자 키는 처방대로 정확하다(`B.luau:354`·`357`·`360`). E28이 적은 "흔한 원인 누락"은 현재 문구에서 고쳐졌고, 프로바이더가 설치된 상태에서 오타·`Parent`에 "check that the provider for this value (e.g. quad-roblox) is initialized" 꼬리가 붙는 것은 메시지 쪽에 남아 있다(출력 a·b 줄).

**B-4 Quad0083 — 페이지의 고친 예시가 그 자체로 다른 에러를 낸다(불충분, 예시).** 345행 고치려면 "항상 중괄호로 감싼 평범한 테이블을 넘기세요 — `D.Frame { q.Source(1) }`"를 글자대로 실행하면 Quad0083은 사라지지만 `Quad0076 Dispatch: no handler matched key 1 (value: number) — check that the provider … is initialized`가 난다(`cases/B.luau:416`) — 숫자 키 자리에 놓인 `Source<number>`는 StoreBind가 벗긴 뒤 `number`를 받아 줄 핸들러가 없다(`out/B_probe.txt`의 `srcArr`, `Source("x")`도 같음). 344행 "언제"의 예시 `D.Frame(q.Source(1))`도 원래 성립하지 않는 의도를 담는다. 일반 처방 자체는 맞다 — `D.Frame(q.Attr{Hp=1})` → `D.Frame { q.Attr{Hp=1} }`(`B.luau:419`, Hp=1)과 `D.Frame(D.TextLabel{})` → `D.Frame { child }`(`B.luau:422`)는 정확. 문구 대안: 예시를 `D.Frame(q.Attr { Hp = 1 })` → `D.Frame { q.Attr { Hp = 1 } }`처럼 실제로 배열부에 놓일 수 있는 값으로 바꾸기. 부수: 이 Quad0076의 "provider … initialized" 꼬리도 오도(프로바이더는 설치돼 있고 원인은 값의 종류).

**B-5 blame 이상(모두 E28 기추적, 현재도 남음).** Quad0023(`Bookkeeping.luau:248`)·Quad0024(`Bookkeeping.luau:288`)·Quad0071(`Dispatch/init.luau:238`)은 `error(msg, 1)`이라 사용자 줄이 아니라 quad 내부 줄을 blame한다. Quad0023은 사용자 입력(`{ a, nil, b }`)이 대표 원인인데도 blame이 내부다(`cases/B.luau:81` 출력). 페이지는 blame에 대해 아무 말도 하지 않는다. 나머지 41개 id는 전부 케이스 파일(사용자) 줄을 blame했다.

**B-6 부수 — Quad0023의 반쯤 지어진 인스턴스(정보).** `{ a, nil, b }` 실패 뒤 `a`와 `b` **둘 다** 반쯤 지어진 Frame에 앉아 있다(`out/B_probe2.txt`: `a.Parent Frame b.Parent Frame`) — 메시지의 "the children placed before this raise"는 구멍 **앞** 자식만 뜻하는 것처럼 읽히지만 뒤 자식도 앉는다. 같은 자식으로 `{ a, q.None, b }`를 다시 만들면 Quad0160(이미 다른 곳에 마운트), 그 Frame을 `q.dispose`한 뒤 같은 자식을 쓰면 Quad0219(claim 안 됨) — 메시지가 말하는 "build the retry with new ones"와 일치. 페이지 47행 고치려면은 새 프로그램 기준으로는 정확하나 이 재시도 주의(메시지에만 있음)를 옮기지 않았다 — 판정은 바꾸지 않음.

## (iii) 개수

| 페이지 | 섹션 | 시도 | 정확 | 불충분 | 틀림 | 미도달 |
|---|---|---|---|---|---|---|
| 02-dispatch-bookkeeping.md | 44 | 44 | 40 | 4 (0022·0071·0076·0083) | 0 | 0 |

(0071은 "처방 미정" 절이라 fix를 적용할 수 없었다 — 도달은 했고 처방 부재로 불충분에 넣었다.)

## (iv) 미완

- 없음. 단 Studio/엔진 실측은 하지 않았다(이 페이지 id는 전부 mock에서 닿았다).

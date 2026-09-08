# 구현 뒤 리뷰 round7 — 사용자 반입 RFC 다섯(값싼 모델 다패스 취합)의 메인 판정·실측 원장 (2026-09-08 오전)

> **입력**: 사용자가 값싼 모델을 여러 번 돌려 시각을 합쳐 둔 무시 파일 다섯(루트 `*-ignoreme.md`, 커밋 제외 —
> 원문은 그대로 사용자 손에 있다). 코드 품질 하나(code-quality-and-doc-structure)와 성능 넷(slot-list-seen-swap /
> slot-list-reorder-technical-analysis / rfc-minor-optimizations / bookkeeping-abs-ondemand). 사용자 지시: *"저 의견들이
> 사실인지, 문제가 없는지, 더 나아갈 수 있는지, 여럿 고려해서 읽어봐야해 … 타당한 적용 가능한게 있는지, 더 확장해 나아갈
> 수 있을지, 내 결정이 더 필요할지 보며 작업을 진행해보자"*. 판정은 전부 메인이 코드 대조 + CLI mock 실측으로 했다
> (quad-base/test 아래 임시 프로브 파일 — 돌리고 삭제, 관례대로 커밋 안 됨). 발견 번호는 `H-479`~`H-483`, 문항은 Q37~Q39(round3 §4의 번호를 잇는다).
> 세션 원문: `session/2026-09-08-02-rfc-triage.md`.

## §1 실측 — 판정의 근거 (CLI mock, N = 1000, 변경 전 → 변경 뒤)

| 항목 | 변경 전 | 변경 뒤 |
|---|---|---|
| `Slot:Clear()` 1000개 | 129.8 ms | 3.5 ms |
| `Slot:ExtractAll()` 1000개 | 130.9 ms | 1.1 ms |
| `Slot:Splice(1, 1000)` (비교군) | 2.3 ms | — |
| `Slot:List` 1000개 마운트 | 4.7 ms | 4.1 ms |
| `Slot:List` 1000개 **역순** 재정렬 | 83.2 ms | 81.6 ms (미변경 — Q38) |
| `Slot:List` 1000개 같은 순서 재발행 | 0.8 ms | 0.8 ms |
| `Slot:List` 100개 역순 | 1.0 ms | — |
| flat `recompute` 1000자리 | 0.42 ms (그중 `getOffsetAt` 채우기 0.18) | 0.11 ms |
| `Slot:IndexOf` (마지막 요소) | O(n) 선형 | 0.000 ms ×1000회 |
| `D.Frame` 문자열 프로퍼티 10개 (quad-roblox 핸들러 22개) | 46.5 µs, 그중 `getHandler` 9.2 µs, `isHandlable` 호출 150회 | 미변경 — Q37 |

## §2 적용한 것 — 다섯 (`H-479`~`H-483`, 코드 + spec + base 문서를 이 원장과 한 커밋으로)

- **`H-479` `Slot:Clear`/`Slot:ExtractAll`이 O(N²)였다** (rfc-minor-optimizations 1번). 두 메소드가 요소마다 `rawRemove`/`rawUnmount`를 부르고 그 꼬리 `vacate`가 매번 `maybeRecompute`를 돌려 N번의 recompute(각 O(N)) — 실측 1000개 130ms, `Splice(1, N)`은 2ms. 문서 RFC의 진단("Length가 N번 발화")은 맞고, 처방 중 `ExtractAll → self:Splice(1, n)` 위임은 **태그된 공개 메소드가 태그된 공개 메소드를 부르면 안쪽 raise의 blame이 위임 줄로 간다**(`H-385`)는 규약 때문에 그대로 안 쓰고 `S.rawSplice(self, 1, n, {})`를 직접 부른다(Splice가 하는 언랩까지 동일). `Clear`는 `rawSplice`와 같은 배치 Blocker 꼬리로 감쌌다(recompute 1회, `Length` emit 1회; `nativeRemove`는 요소마다 — 파괴 자체가 요소 단위라 그대로). **두 메소드에 spec이 하나도 없었다** — `spec.slot` 26절 신설(순서 보존, 추출 요소 재사용 가능, 중첩 Slot, `Length` emit 1회, 빈 Slot no-op, 미실체화 형태). **[2026-09-08 감사 C-3 기록]** 이 항목은 전날 회신 1차에서 사용자가 Q3 ⑨로 **보류**했던 것이다(*"반영은 쉬울것 같긴 함 … 보류하고 추후 최적화 요소로 백로깅"*, round1 §15) — 이번엔 사용자가 그 RFC를 직접 반입하며 *"타당한 적용 가능한게 있는지 … 보며 작업을 진행해보자"*고 새로 지시해 열렸다(round1 §4 Q3 ⑨ 행·`ROADMAP.md` 백로그 줄에 상호 포인터). 보류가 조용히 뒤집힌 게 아니라 새 지시로 재개된 것.
- **`H-480` `Slot:List` reconcile의 `table.clone(prevKeys)`** (slot-list-seen-swap). RFC 분석 그대로 — 루프 1의 `prevKeys[key] = true`와 루프 2의 `prevKeys[key] = nil` 때문에 있던 방어적 복제이고, 선행 패스가 `seen`을 같은 집합으로 이미 채우므로 두 쓰기를 지우고 사이클 꼬리에서 `prevKeys = seen`으로 교체하면 키 집합이 수학적으로 동일하다. 메인 추가 확인: `prevKeys`는 `_activateList`의 업밸류로 `reconcile`만 읽고 다른 클로저(`settle`/`_detachCleanup`)는 안 본다; Detach 수명은 `_detached`가 쥔다; **재진입은 옛 코드도 방어하지 않았으므로 동등**(clone은 순회 중 변형만 막았다 — 그리고 Lua/Luau의 `pairs`는 순회 중 기존 키를 nil로 지우는 걸 허용하므로 그 clone은 애초에 불필요했다). **[2026-09-08 오후 정정 — round8 `H-486`]** 괄호 안은 반쪽만 맞다: `pairs` 순회 중 UB인 **삽입**을 clone이 막고 있었고, 삽입 경로(재진입 reconcile의 첫 루프)는 실재한다. 다만 그 재진입이 `slot-plan.md` "재진입성" UB 범주라 clone 복원은 안 한다 — 근거는 round8. RFC 4절의 더블 버퍼링은 안 한다(사이클당 `seen` 할당 하나 남는 게 전부). **[같은 날 오후 정정 — `H-485`, `/code-review`]** 꼬리의 `prevKeys = seen` 통째 교체는 **`H-38`이 없앤 "마지막 일괄 교체" 그 자체**였다 — `updateFn`이 중간에 던지면 교체가 안 일어나 그 사이클에 마운트된 새 키가 `mounted`/`_elements`에 남은 채 다음 KeyGone이 영영 안 묻는다(`H-38` 계약 "중단된 지점까지는 정합"이 거짓이 됨; 완화 요인은 던진 뒤 배치 Blocker·Observer `_running`이 남아 그 List가 어차피 죽는 것). 위 "같은 `H-38` 이유" 논거도 뒤집혀 있었다. **정정**: `prevKeys[key] = true`(settle 앞)와 `prevKeys[key] = nil`(KeyGone 뒤)의 증분 갱신을 되돌리고 **clone만 제거** — Lua/Luau `pairs`는 순회 중 기존 키 nil 대입을 허용하므로 스냅샷은 애초에 불필요했다. 남는 이득은 clone 제거 하나이고 `H-38` 계약은 그대로.
- **`H-481` `Slot:IndexOf`의 O(1) 경로** (rfc-minor-optimizations 4번). `bk.indexOfElement` 역맵을 모든 raw* 변경이 유지하는데 공개 `IndexOf`만 선형이었다. raw 요소는 역맵 그대로(`S.indexOfRaw`), State 요소는 슈가 래퍼가 키라 역맵에 없으므로 옛 언랩 선형을 폴백으로 남긴다(`spec.slot` 26절 — State 요소는 State로 찾히고 그 값으로는 안 찾힌다). RFC의 `self._elements[idx] == element` 재확인은 안 넣었다 — `settle`이 같은 역맵을 무검증으로 신뢰하고, 어긋나면 그건 raw* 층의 버그다("드문 오용 방어에 구조를 쓰지 않는다").
- **`H-482` Modifier setter 클로저의 필드 이름별 캐시** (rfc-minor-optimizations 2번). 클로저가 잡는 건 `key`뿐이라 같은 파일의 `castClosures`와 같은 모양으로 캐시(`setterClosures[key]`). `H-250`(테이블 경유가 아닌 함수는 태그 안 함)과 `error(..., 2)` blame은 그대로 — 캐시돼도 `__index`가 돌려주는 값이지 테이블에 저장되는 게 아니다. 관측 가능한 차이는 `mod.Size == mod.Size`가 참이 되는 것뿐. 선례: `H-365`/`H-390`이 호출당 클로저 할당을 같은 이유로 걷어냈다.
- **`H-483` `recompute`의 abs 온디맨드** (bookkeeping-abs-ondemand). **메인은 처음 기각 쪽이었다** — 이득 상한이 `getOffsetAt` 채우기 0.18ms/1000자리이고 그 채움은 숫자를 실제로 뽑는 곳(`nativeInsert` offset, List의 physIndex)이 어차피 다시 하므로 "제거"가 아니라 "이동"이며, `spec.lengthoffset` 6절이 "recompute가 캐시를 재구축한다"를 단언하고 있었다. **사용자 판정**: *"abs 온디맨드는 큰 부작용이 없고, 바로 적용 가능하고 20줄 이내 패치라 기각할 이유는 없어보이는데?"* → 적용. 정확성은 RFC 3절 그대로 확인 — None 자리는 진입 스냅샷 뒤 사용자 코드 창이 없어 검사 ①을 건너뛰고 커서를 바로 올려도 `H-240` 되감기 신호를 못 덮는다; `contribution` 뒤의 검사 ②는 그대로. 실측 0.42 → 0.11ms. 6절 단언은 "당겨진 채 남고 값 읽기가 온디맨드로 채운다"로 바꿨다. `dispatch-core-plan.md` recompute 의사코드 동기화.

- **`H-484` `getHandler` 키 타입 버킷 — Q37 (a) 사용자 확정 후 반영(같은 날 오후, 둘째 커밋).** `Handler` 계약에 선택 필드 `keyType: ("number" | "string")?`; `Dispatch.addHandler`가 등록마다 number/string/그 밖 세 목록(각 = 선언 ∪ 미선언, priority 순)을 재구축하고 `getHandler`는 `type(k)`에 맞는 목록 하나만 돈다. 잘못된 값은 등록 시 표면 에러. 선언한 핸들러 열둘(`H-52` 가드를 가진 리프 아홉 + Property/Event/InstanceShorthand — 커밋 메시지·초판 문서의 "열셋"은 오기, code-review 발견), 미선언은 키 무관인 것들(센티널 셋·StoreBind·None·AttrKey·폴백 가드 — `addProcessedHandler`의 셋도 `v == sent`뿐이라 미선언, 동작 불변). `spec.dispatch` 19절(버킷 라우팅·미선언 전 버킷·버킷 안 priority·등록 게이트). 실측: `D.Frame`(문자열 프로퍼티 10개) 46.5 → 37.1µs, `getHandler` 9.2 → 6.2µs.

## §3 판정만 한 것 — 사실 확인·기각 (반영 없음)

- **code-quality-and-doc-structure 2.1 (모듈 최상위 함수 일괄 `setFuncLevel`)** — 기각. 근거 셋: (1) 각 서브시스템이 자기 Init에서 자기 표면을 태그한다(quad-base 28곳) — `quad-base/src/init.luau`의 셋은 모듈 조립 층의 것뿐이고 "일부만 수동 열거"가 아니다. (2) 일괄 태깅은 `H-434`가 보여준 함정을 전면화한다 — 태그된 함수가 태그된 함수를 부르면 nearest가 안쪽 본문으로 밀린다(`setEmpty` 사례). 술어(`isState`류)나 프로바이더가 얹은 함수까지 태그되면 그 조합이 늘어난다. (3) 사용자가 round6 기각 3에서 자동 탐색 태깅을 이미 거부했고, list drift의 실제 구멍(`H-410`)은 `H-475`가 닫았다.
- **2.2 (명명 4계층 공식화)** — 이미 `base/architecture.md` "코드 스타일 — 네이밍 케이싱" 절이 규정한다(PascalCase 넷·camelCase 셋·경계 판단 기준). 문서의 표는 `EpochMap:Sync()`를 소문자 계층에 넣는 오류가 있다(실제는 PascalCase 메소드). 반영 없음.
- **2.3 (Weak Relate + `bindLifetime` 앵커 이디엄 문서화)** — 이미 있다: `base/lifecycle-pattern.md` (0.5) `bindLifetime` 확장 계약, `base/relate-plan.md` `H-71` 정정 배너, `base/dispatch-core-plan.md` `H-229` 확정 문단. 플러그인 작성자용 가이드는 문서 사이트 백로그(`research/documentation-plan.md`)의 몫.
- **2.4 (마커 입력/출력 자리 규칙)** — `base/typing-limits.md` 8.11이 소스이고 생성기가 그 규칙으로 D를 낸다. "린트화"는 관측된 위반이 없어 안 한다.
- **§1 "성능 탐색 종결" 서술** — `State._emitDown` 스냅샷과 `D.Frame` 사전 굽기 서술은 맞다. "미적용 최적화만으로 프로덕션급 효율"은 근거 없는 수사라 인용하지 않는다.
- **§3.2가 인용한 규약 "파일당 200줄 권장"은 존재하지 않는다** — `conventions.md`·`project-context.md`·`architecture.md`·`README.md` grep 0건. 수치 자체(README 151줄/163KB, 27행 16,636자·56행 8,915자·31행 6,382자; session-summary 2,438줄/200KB; slot-plan 303KB·dispatch-core-plan 235KB·source-state-plan 151KB·ref-plan 102KB — 바이트이고 한글 3바이트라 글자 수는 1/3)는 맞다. 처분은 Q39.
- **slot-list-reorder-technical-analysis** — 병목 자체는 맞고 실측이 더 크다(1000개 역순 82ms, RFC 추정 19.6ms). 원인 서술도 맞다(`settle`의 요소별 `rawMove`가 4배열 `rotateInPlace` + `reindexFrom`을 span 길이만큼). **그러나 난제 2·5는 현재 코드의 문제가 아니다** — `rawMove`는 `bk.observers`를 같은 순열로 돌리므로 옵저버는 요소와 함께 이동하고 "옛 자리에 잔류"하지 않으며, `releaseElement`는 `indexOfRaw`(역맵)로 인덱스를 얻지 stale 인덱스를 쓰지 않는다. 그 둘은 문서가 제안한 "덮어쓰기" 중간 상태에서만 생기는 문제다. 처방(2-pass 순열 `rawPermute`)은 새 raw op + 백엔드 op 의미 결정이라 Q38.
- **rfc-minor-optimizations 3번 (getHandler 키 타입 버킷)** — 사용자가 방향은 이미 승인한 항목(그 문서 인용). 핸들러 계약에 선택 필드가 하나 필요하므로 Q37. 실측: quad-roblox 핸들러 22개, 문자열 프로퍼티 10개짜리 `D.Frame` 한 번에 `isHandlable` 150회(프로퍼티당 15회), `getHandler`가 `D.Frame` 46.5µs 중 9.2µs(약 20%). 22개 중 숫자 키 전용이 12개(Slot/Tag/Attr/Ref 리프/Observer·Effect 리프/Nil/OnChange/InstanceChild/Tag·Attr 폴백…)라 문자열 스캔이 대략 15 → 6회로 줄 것으로 추산(절감 5µs 안팎, `D.Frame`의 10% 남짓). RFC 예시 코드의 `return nil` 뒤 "전체 폴백 순회" 주석은 코드가 없는 빈말이다 — 버킷은 "그 타입 선언 ∪ 미선언"으로 짜야 서드파티가 안 빠진다.

## §4 사용자 문항 (평문 한 문단씩)

**Q37 — `getHandler` 키 타입 버킷: 핸들러 계약에 어떤 필드로 선언하나.** 상황: `Dispatch.getHandler`는 우선순위순 단일 배열을 전수 스캔하고, 사용자는 앞서 *"number용 핸들러와 string용 핸들러 배열을 둘로 나누는 건 좋아 보임. isHandlable은 그대로 둠"*이라 했다. 막히는 것: 핸들러가 자기 키 타입을 **선언**해야 나눌 수 있는데(`isHandlable`을 미리 찔러볼 수는 없다) 그 선언은 `Handler` 계약(`isHandlable`/`priority`/`process`/`name`)에 새 선택 필드를 더하는 일이라 이름과 값 모양이 사용자 몫이다. 갈래: (a) `keyType: "number" | "string"?` — 없으면 모든 버킷에 든다(서드파티·k-무관 핸들러는 지금처럼 전수 스캔 대상), 버킷은 number/string/그 밖(AttrKey 같은 테이블 키)의 셋이고 각 버킷 = 그 타입 선언 ∪ 미선언, 정렬은 버킷마다 priority 순. 메인 권고. (b) 이름을 달리(`keys`, `keyKind` …) — 값 모양은 (a)와 같게. (c) 안 한다 — 실측 절감이 `D.Frame` 한 번에 5µs 안팎이라 관측된 병목이 아니다.

**Q38 — `Slot:List` 대량 재정렬의 O(N²)(`rawPermute`): 지금 설계를 열 것인가, 백로그인가.** 상황: 역순 재정렬이 1000개에 82ms, 100개에 1ms, 같은 순서 재발행은 0.8ms(실측표). 원인은 `settle`이 이동 요소마다 `rawMove`를 부르고 그것이 `_elements`·`lengthList`·`sourceList`·`observers` 네 배열을 span만큼 돌리고 `reindexFrom`으로 역맵을 다시 쓰는 것 — Roblox에선 `nativeMove`가 no-op이라 이 전부가 Luau 부기 비용이다. 막히는 것: 처방은 사이클 끝에 순열 하나로 네 배열을 한 번에 재배치하는 새 raw op(`rawPermute`)이고, 그건 (1) raw* 규약(부기 커서 무효화 인덱스 표, `H-113`)에 행을 더하고 (2) mock·다른 백엔드의 `nativeMove` 의미(요소별 이동 vs 일괄 순열)를 정해야 하는 설계라 발견≠결정 규약에 걸린다. 갈래: (a) 백로그 — 실사용 사례가 정렬 토글 정도이고 1000행에 80ms는 관측된 병목이 아니다(메인 권고; `ROADMAP.md` 백로그 최적화 후보에 실측과 함께 적어 둔다). (b) 지금 `research/`에 설계 문서를 열고 문항으로 세분한다.

**Q39 — 문서 거버넌스 넷(code-quality 문서 §3): 무엇을 언제.** 상황: 수치는 §3에 적은 대로 사실이나 그 문서가 근거로 든 "파일당 200줄 규약"은 없다. 각각의 메인 의견: (1) `.claude/README.md`의 `qa-request/`·`audit/` 행 비대(한 셀 16,636자) — **한다** 쪽 권고: 라운드별 서술을 각 라운드 파일 머리 배너로 내리고(이미 round6가 그 모양) README 행은 파일당 한 줄, 또는 `qa-request/README.md` 하위 색인. `doc-check.py`의 색인 검사는 base/research/archive/reference 파일명만 보므로 어느 쪽도 검사를 안 깨뜨린다. 다만 "개수·목록의 소스는 하나" 규칙대로 하위 색인을 두면 README 행은 가리키기만. (2) `base/` 대형 계획서를 "순수 계약서"로 재작성하고 논쟁·손 트레이싱을 `reference/`로 — **반대** 권고: base는 결정과 근거를 함께 두는 정본이고 뒤집힌 원문은 이미 `archive/`로 가는 규칙이 있다; 수만 자 재작성은 에이전트가 부정확 서술을 새로 만드는 선례(핸드오버 워크플로 폐기, `66281ab` 치환 부수 피해)를 그대로 재현할 위험이 크다. 크기 부담은 절 인용으로 필요한 절만 여는 지금 방식이 답이다. (3) `session-summary.md` 분할 — **안 함** 권고: 그 문서는 import 안 되고 "grep 한 곳"이 쓰임새라 둘로 가르면 grep이 둘이 된다. (4) 루트 `README.md`(사용자 대면) 신설 — 문서 사이트 백로그(`research/documentation-plan.md`)와 같은 항목이고 표면이 아직 흔들린다(오늘도 `Attribute → Attr`). **지금 안 함** 권고, 시점은 사용자 몫. 갈래는 항목별로 "한다/안 한다/나중"이면 된다.

## §5 검증

코드 다섯 + spec 둘(`spec.lengthoffset` 6절 단언 교체, `spec.slot` 26절 신설) + base 문서 셋(`slot-plan.md` CRUD 표·reconcile 의사코드·raw 절, `dispatch-core-plan.md` recompute 의사코드, `modifier-plan.md` `H-482` 문단): `./scripts/test.sh` exit 0(스펙 50, gen-d check), doc-check ERROR 0, 감사자 1패스(sonnet, diff 범위) 확실 5·판단 1·의심 1 — 전부 반영(세션 파일 §6).

## §7 `/code-review`(단일 맥락, 서브에이전트 없음 — 사용자 지시 "쪼개기 금지·opus 이하") — `b7917f7..13d197a`, 발견 6·미완 0, 전부 반영

질문 항목(None 분기의 검사 ① 생략 안전성, 캐시 미가열의 소비자 영향, Clear 역순 `getOffsetAt`, ExtractAll 세 상태 동등, IndexOf 역맵 경계, setter 캐시의 모듈 인스턴스 공유, keyType과 `listHandlers`/동률/`retractFrom`, spec 세 절의 공허 여부)은 전부 "문제 없음"으로 닫혔다. 발견: (1) **`H-485`** `prevKeys = seen`이 `H-38` 계약과 정면 충돌 — 위 `H-480` 항목의 정정 문단, 코드·`slot-plan.md` 의사코드 되돌림. (2) "선언 열셋"은 열둘(number 9 + string 3) — 문서 넷 정정(커밋 메시지는 그대로 남는다). (3) quad-types 주석 "어긋나게 선언하면 매치 실패 에러로 드러난다"는 과장 — 조용히 그 버킷에서 빠지고 더 낮은 priority의 미선언 핸들러가 대신 매치할 수 있다고 고침. (4) 동률 경고가 버킷을 몰라 다른 `keyType`을 선언한 쌍(절대 경쟁하지 않음)에도 찍히고, `keyType` 게이트가 그 print 뒤에 있었다 — 게이트를 앞으로, 동률 비교는 "둘 다 미선언이거나 하나가 미선언이거나 같은 선언"일 때만. (5) spec 26절의 IndexOf 단언이 폴백 스캔으로도 통과해 역맵 경로를 고정하지 못함 — `indexOfElement` 직접 단언 추가. (6) `Clear` 주석의 "~120 ms"가 표(130.9)와 다름 — 130으로.

## §6 사용자 회신 (2026-09-08 오후)

- **Q37 → (a)** *"Q37 권고대로 괜찮은듯."* — `keyType` 필드, 반영 `H-484`(§2).
- **Q38 → (a) 백로그** *"아직 더 봐야할 부분이 많고, 내가 전부 이해하고 큰 틀에서 보고 나서 작업을 수행하는게 맞아서, 순수 최적화이고 외부 표면은 나오지 않고, 또 아직 정식 릴리즈를 할 생각은 없어서 (폴리싱, 문서화 기간 끝에 정식 릴리즈 예정) 권고대로 백로그 대상."* — `ROADMAP.md` 백로그 최적화 후보 목록에 실측과 함께.
- **Q39** *"문서 거버넌스는 나도 보고 애매했어. 루트 readme 는 그냥 백로깅에 두고싶음. 다만, README.md 를 분리해 각 폴더 내에 두어 폴더가 뭐하는지 설명하는건 괜찮은것 같아."* — (1) `.claude/README.md` 분리: **한다** — 반영(셋째 커밋): `base/`·`reference/`·`research/`·`archive/`·`qa-request/`·`audit/`·`session/`에 자기 `README.md`(폴더 기준 전문 + 옮겨온 파일 표), 루트는 폴더당 한 줄(151줄/163KB → 51줄/8KB), `doc-check.py` 색인 검사가 루트 + 폴더 README를 합쳐 봄(음성 프로브 확인); (2) `base/` 계약서화·(3) `session-summary.md` 분할: 결정 없음 → 메인 권고대로 **안 함**(사용자 "애매"); (4) 루트 `README.md`: **백로그**(문서 사이트 항목과 함께).
- 추가 지시: 코어를 건드린 만큼 `/code-review`를 한 번 — *"쪼개기 금지로 opus초과 모델 사용 금지로"*(단일 맥락, 팬아웃 없이, opus 이하).

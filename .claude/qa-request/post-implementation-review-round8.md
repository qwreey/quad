# 구현 뒤 리뷰 round8 — 누적 변경 감사: 회귀·archive 근거 누락 (2026-09-08 오후, 감사자 다섯 병렬)

> **입력**: 사용자 지시 *"각 변경이 누적되어서, 다시 생긴 문제나 에이전트가 archive 에서 못 본 근거들로 잘못 처리된게
> 있는지 sonnet 또는 하위 에이전트들을 여럿 굴려서 audit … 결과를 네가 받아 검증하는걸 하고, 여러 서브에이전트를
> 굴려도 좋아"*. 대상은 2026-09-07~08 리뷰 순회 56커밋(`4111299..438790a`), 특히 오늘 커밋 넷(`4fe318d`·`13d197a`·
> `eb51010`·`438790a`). 감사자 다섯을 각도별로 병렬로 띄웠다(전부 읽기 전용, 마지막 메시지 하나): **A** Slot/Bookkeeping
> vs 옛 계약(opus), **B** Dispatch/Modifier vs 옛 계약(opus), **C** archive 옛 결정 vs 리뷰 라운드 결정(opus), **D** 순회
> 반영분(`H-344`~`H-485`)이 뒤 커밋에서 유실됐는지(opus), **E** 문서 정합(`quad-doc-auditor`, sonnet). 발견은 전부 메인이
> grep·코드 대조·CLI 실행으로 검증한 뒤 반영했다. 발견 번호 `H-486`~`H-491`. 세션 원문: `session/2026-09-08-03-cumulative-audit.md`.
> 판정: test.sh exit 0(스펙 50), doc-check ERROR 0.

## §1 결론 한 줄

동작 회귀 0건(D 각도가 53커밋의 `.luau` 추가 줄 2160개를 현재 트리와 대조 — 유실 0, 전부 의도된 상위 대체). archive 옛
**사용자 결정**이 모르게 뒤집힌 사례 0건(C 각도 — 문항마다 옛 근거를 인용했음을 확인). 남은 것은 반영 누락·논거 오류·주석
잔재·spec 커버리지 구멍이고, 아래 §2에서 전부 닫았다. 판단이 필요한 항목 하나(§4)만 사용자 몫.

## §2 반영한 것

- **`H-486` `H-480`의 원장 논거가 틀렸다 — clone은 순회 중 "삭제"가 아니라 "삽입"을 막고 있었다** (A-1·B-1, 둘이 독립적으로
  같은 발견). 상황: round7 §2 `H-480` 항목은 *"Lua/Luau의 `pairs`는 순회 중 기존 키를 nil로 지우는 걸 허용하므로 그 clone은
  애초에 불필요했다"*고 적었는데, `pairs` 순회 중 허용되는 건 기존 키의 nil 대입뿐이고 **없던 키의 삽입은 UB**다. 삽입이
  일어나는 경로가 실재한다 — KeyGone 루프 안의 사용자 코드(`updateFn`, 또는 파괴되는 요소의 cleanup)가 같은 List의 data
  State를 `:Set`하면 State emit이 동기라 `reconcile`이 재진입하고, 재진입한 첫 루프가 `prevKeys[key] = true`로 바깥
  `pairs(prevKeys)`가 도는 테이블에 새 키를 넣는다(항목 건너뜀·중복 방문). 옛 코드는 스냅샷을 돌아 이 순회 자체는 안전했다.
  메인 검증: `Observer._receive`의 `_running`은 save/restore라 재진입 fn 실행을 막지 않고(`H-332`), `State.emitDown`은 동기.
  **판정: clone 복원은 안 한다** — 그 재진입 자체가 `slot-plan.md`의 "재진입성" 절이 못박은 범주("Observer/store-bind 재실행
  콜백 안에서 CRUD 재호출은 별도 가드 불필요, provider 버그로 간주")이고, 옛 코드도 재진입 뒤 바깥 루프가 낡은 `keys`/`seen`으로
  계속 돌아 의미론은 이미 깨져 있었다(그 부분의 "옛 코드도 방어하지 않았다"는 참). 반영: round7 §2 `H-480` 문장에 정정
  배너, `Slot/List.luau` KeyGone 루프 주석에 "삽입이 가능한 유일한 경로 = 재진입 reconcile = UB 범주" 명시.
- **`H-487` Q6(native* 조합 폴백 약속 철회)가 `claim-plan.md` §9에 닿지 않았다** (C-1). 상황: 회신 4차 Q6로 "미주입이면
  조합 폴백" 약속이 철회돼 `native*` 여섯 전부 필수·미주입 스텁 에러가 됐고 반영 목록은 `slot-plan.md`·`architecture.md`·
  `dispatch-core-plan.md`·`debounce-throttle-plan.md` 넷이었는데, `claim-plan.md`는 `nativeClaim`을 "조합 폴백 예외 — 셋업이라
  조합 불가", `nativeFindChild`를 "조합 폴백의 예외 — 조회라 조합 불가"로 현재형 서술하고 있었다. 폴백 규칙이 없어진 지금
  "예외"라는 분류 자체가 성립하지 않는다. 반영: 두 자리에 정정 마커 + `slot-plan.md` 배너 포인터.
- **`H-488` Q14 (a)로 되살아난 `destroySlotTree`의 `releaseOwner`를 `slot-plan.md` 의사코드 두 자리가 여전히 부정했다**
  (C-2). 상황: `H-450`이 C-4 문단과 두 의사코드는 갱신했으나, 소유권 호출 지점 의사코드 블록의 `-- [삭제됨, 2026-08-20 C-4]
  destroySlotTree에는 명시적 releaseOwner가 없다` 주석과 3600행대 "(3) destroySlotTree가 반납 … 그 수정 자체가 되돌려졌다"
  문장이 코드(`Slot/Tree.luau` 두 루프 모두 `releaseOwner`)와 정반대로 남았다. 반영: 의사코드에 `releaseOwner(element, slot)`
  호출 지점과 재역전 경위, 뒤 문장에 재역전 마커. 같은 부류 소소한 것 넷도 같이: `slot-plan.md` 언래핑 절의 *IndexOf 비교가 O(n)인 건 원래 계약* 문장(C-5 — `H-481` 역맵 뒤 stale), round3 §12 Q26 행의 첫 스냅 `{ Value, Source }`(C-6 — 같은 표 Q25 `H-478`로
  `Source` 폐기; §4의 문항 원문은 그대로 둠), `bind-system-plan.md` `H-142`의 "props에서 `Parent` 제외"에 읽기 표면 Q35 (a)
  포인터(C-7), `module-lifecycle-plan.md` `H-305` (d′)의 "구조적으로 차단"에 `AddPlugin(providerFn)` 우회 UB(Q10 (c)) 단서(C-8).
- **`H-489` 루트 README 분리(`eb51010`) 뒤 옛 표·행을 가리키던 포인터 일곱** (E 다섯 + 메인 둘). `CLAUDE.md`(라운드 목록의
  소스)·`project-context.md`·`todos.md`(`base/`·`research/` 표)·루트 `.claude/README.md` 자기모순 행("상세 색인은 이 README가
  소스")·감사자 메모리(`audit/` 행)·`question.md`(`base/` 표)·외부 모델 진입점 `external-review-entry.md`(`qa-request/` 행 —
  외부 모델이 처음 읽는 자리라 가장 아팠다). 전부 폴더별 `README.md`로.
- **`H-490` 주석 잔재 넷** — `Bookkeeping.luau` `setLength` 상수 팔의 "State 값은 contribution에서 검사"(D-1 — `H-445`가 검사를
  Observer 콜백으로 옮긴 뒤 반대 문장이 됐고, 같은 파일 `contribution`이 정반대를 말하고 있었다), `Animate.luau` Q8 주석의
  끊긴 문장(D-2, `the the`), `spec.store` 8절 번호 누락(D-3), `Dispatch/init.luau` `listHandlers`의 "in scan order"(B-3 —
  버킷 도입 뒤 단일 스캔 순서가 없다; 반환은 세 목록의 합집합 = priority 순). `Slot:Clear` 주석에 "가까운 유사체는 List의
  KeyGone 패스(게이트 안에서 요소 파괴 = 사용자 cleanup 창)" 한 줄(A-2, 아래 §3).
- **`H-491` `H-483` None 분기의 되감기 커버리지 0이었다** (A-3). 상황: 되감기를 발동시키는 `spec.lengthoffset` 5절·10절은 모든
  자리가 `Source`라 `H-483`이 새로 가른 None 분기(검사 ① 생략, 커서만 전진)를 되감기 경로에서 한 번도 밟지 않았고, 교체된 옛
  6절 단언은 "recompute가 캐시를 데운다"를 고정하던 유일한 자리였다. 반영: **14절 신설** — None/Source 혼합 다섯 자리에서 3번
  Source의 Observer가 `setLength(inst, 2, 5)`로 커서를 정확히 None 자리 2로 내리고, 검사 ②가 잡아 i=2에서 재개해 뒤 Source들이
  새 베이스(7, 9)로 Set되며 차단기가 풀린 채 끝나는 것을 단언. 메인이 돌려 통과(test.sh exit 0).

## §3 확인만 한 것 (코드 변경 없음 — 재발견 금지)

- **A-2 `Slot:Clear` 배치 게이트 안의 raise → 게이트 영구 On(레이아웃 동결)**. 감사자는 `H-445`(검사는 창 밖에서)와 같은
  모양의 새 실패 모드라 했다. 메인 판정: 새 부류가 아니다 — `rawSplice`도 창 안에서 `rawUnmount`·`nativeExtract`를 돌리고,
  더 가까운 유사체인 List의 KeyGone 패스는 창 안에서 요소를 **파괴**(사용자 cleanup 창)하며 던지면 게이트가 남는 것을
  round7 `H-485`가 "완화 요인 — 그 List는 어차피 죽는다"로 이미 수용했다. Clear의 raise 원천은 내부 불변식 에러(`releaseOwner`),
  Q9 좀비 UB 위의 `nativeRemove`, 사용자 cleanup 던짐 — 셋 다 UB·내부 버그 범주. 다만 `H-479` 전엔 같은 raise가 배열을
  부분 상태로 남길 뿐 Slot은 살아 있었다는 점(심각도 상승)은 사실이라 §4에 사용자 판단으로 올린다.
- **A-4 `H-483` 뒤 `getOffsetAt`이 `recomputeBlocker` 창 안에서 None 런 전체를 한 번에 채우므로 사용자 코드 창(길이 `Get`)의
  개수가 자리 하나에서 런 길이만큼 늘었다** — 창의 종류·검사(①·② + 자가치유 재시작)는 그대로라 신규 결함 아님, 기록만.
- **B-2 `canCompete`(서로 다른 keyType 선언 동률은 경고 안 함) 분기에 spec이 없다** — 동률 경고가 `print`라 CLI에서 캡처가
  안 되는 기존 제약(10절 "육안 확인") 그대로. 새 훅을 만드는 건 새 메커니즘이라 안 한다. 알려진 구멍으로 기록.
- **`H-483` vs `H-240`/`H-113`/`H-124` 커서 계약**: 두 커서를 읽는 자리 전수(라이브 소스 `Raw.luau` 셋·`Tree.luau` 둘 — 전부
  `math.min` 내리기/0 대입)에서 상대 대소를 전제하는 곳 없음, None 분기의 검사 ① 생략은 진입 스냅샷 뒤 사용자 코드 창이
  없어 안전, 검사 ②는 그대로(A·B·C 셋이 독립 확인).
- **`H-484` keyType**: 선언 열둘 전부 `isHandlable` 첫 항이 `type(k)` 가드와 일치, 미선언 열은 전부 실제 키 무관(기계 삽입 잔재
  0), 버킷 안 상대 순서 = 전역 priority 순의 부분열, 등록 게이트 blame은 등록 호출자(`AddPlugin` 경유 포함), `Processed*`
  센티널 셋은 선언해도 됐지만 동작 동일(B). `H-214`(선택 필드 `name`) 선례와 동형이고 그때 기각된 건 등록 **인자** 안(C).
- **`H-482` setter 클로저 캐시**: 캡처 업밸류는 `key`뿐, 인스턴스 상태 없음, `castClosures`와 같은 수명, `H-250` 프레임 산술
  불변(B).
- **`H-479`/`H-481`**: ExtractAll ≡ 옛 경로(마운트/실체화/미실체화 세 상태 + 빈 Slot), 역맵 갱신 raw* 일곱 자리 전수 정합,
  `H-385` 태그 목록에 raw*/`indexOfRaw` 없음(A). `H-38` 복원은 의사코드·원문 요구 순서와 일치(A·B).
- **C 각도 대조 무충돌**: `H-478` 값 비교 vs 전파 dedup 아카이브 둘(층이 다름), `H-467` None==nil, `H-403` isSlot→Brand vs
  공유 레지스트리 역전, Q9 좀비 UB, Q7 `_assertBindable` 세 자리, Q17 `numberOnly`(옛 원장 0건), `H-406` Create 선행 vs
  tween-plan 불변식, Q10~Q16·Q19·Q22~Q29·Q35·Q37 각 문항의 옛 근거 인용. C-3: `H-479`는 전날 Q3 ⑨로 사용자가 보류한
  항목이었고 새 지시로 열렸다 — round7 `H-479` 항목에 그 경위를 기록. C-4: round1 `H-352` 행("의도된 것")의 절반이 Q33 (a)로
  역전됐는데 행에 표시가 없었다 — 행 꼬리에 표시(사용자 결정이 아니라 메인 판정이었으므로 결정 역전 아님).
- **D 각도 생존 확인**: `H-256` (a) 세 자리(`H-392`/`H-406`/`H-425`·`H-471`), `H-393`·`H-396`·`H-407`·`H-410`~`H-412`·
  `H-417`~`H-421`·`H-427`·`H-431`·`H-433`·`H-434`·`H-440`~`H-443`·`H-445`~`H-449`·`H-451`·`H-463`~`H-465`·`H-467`~`H-470`·
  `H-472`~`H-475`·`H-479`~`H-485` 본문 생존; 의도된 상위 대체 일곱(`H-397`→`H-408`/`H-427`, `H-370`/`H-373`→`H-378`,
  `H-444`→`H-474`, `H-380`/`H-389`→`flattenInto`, Q12→`H-478`, `H-476`→`H-478`, `H-480`→`H-485`); 구조 재편 이동 무결성
  (`Slot.luau` → `Slot/` 여섯 파일 함수 집합 유실 0, `S` 배선 44필드 전부 대입, Tween·Brand 술어 손실 0, `Attr` 개명 오치환 0);
  spec 절 존재 전수; `gen-d.py check` 통과.
- **E 각도**: `H-483`·`keyType`·`H-479`~`H-481`·`H-485`의 정본 서술 정합, round7 Q37~Q39 닫힘 상태 세 곳 일치, `session-summary`의
  "열셋→열둘"은 이력이라 그대로.

## §4 사용자 문항 (평문 한 문단)

**Q40 — `Slot:Clear`가 배치 게이트 안에서 요소를 파괴하므로, 파괴 도중 raise가 나면 그 Slot의 레이아웃이 영구 동결된다.**
상황: `H-479`로 `Clear`가 Blocker 창 하나 안에서 `rawRemove` N회를 돌리게 됐다. 창 안에서 raise가 나면(요소 cleanup Effect가
던짐, 마운트 타깃이 quad 밖에서 `Destroy`된 뒤의 `nativeRemove`, 소유권 불변식 에러) 게이트가 On인 채 남아 이후 이 Slot의
recompute가 전부 조기 반환한다. `H-479` 전엔 같은 raise가 배열을 부분 상태로 남길 뿐 Slot은 계속 쓸 수 있었다. 무엇이 막히나:
raise 원천 셋이 전부 UB·내부 버그 범주이고 List의 KeyGone 패스가 이미 같은 모양(창 안 파괴, 던지면 그 List는 죽음)을 수용하고
있어서 메인은 "같은 부류, 그대로 둔다"로 봤지만, 이건 실패 시 심각도를 올린 결정이라 사용자 확인이 필요하다. 갈래: (a) 그대로
— List와 같은 톤으로 "창 안에서 던지면 그 Slot은 죽는다"를 `slot-plan.md`에 한 줄 명시(메인 권고). (b) `Clear`만 파괴를 창
밖으로 — 창 안에선 `rawUnmount`(언마운트만)로 비우고 게이트를 닫은 뒤 모아둔 요소를 파괴(cleanup이 창 밖에서 돎; 코드 열
줄 안팎, 파괴 순서는 그대로 역순). (c) 옛 요소별 recompute로 되돌림(O(N²) 복귀 — 권하지 않음).

## §5 교훈 (다음 감사 각도)

1. 등가 증명은 언어 계약의 **양쪽**(허용되는 것/UB인 것)을 다 적어야 한다 — `H-480`은 "삭제 허용"만 보고 "삽입 UB"를 안 봤고,
   그 위에 `H-485`가 반쪽만 되돌렸다. 같은 줄을 두 번 고칠 땐 첫 논거를 다시 읽을 것.
2. 사용자 회신을 반영할 때 "반영 목록"은 grep 결과여야지 기억이어선 안 된다 — Q6은 넷을 고치고 `claim-plan.md`를 빠뜨렸고,
   Q14는 문단은 고치고 의사코드 주석을 빠뜨렸다. 핵심 명사(`조합 폴백`, `releaseOwner`)로 `base/` 전수 grep이 반영의 마지막 단계.
3. 새로 가른 분기는 그 분기가 **기존 회귀 spec의 경로 위에 있는지** 확인할 것 — 되감기 spec 둘이 전부 `Source`라 None 분기는
   커버리지 0이었다.
4. 감사자 다섯을 각도로 갈라 병렬로 돌린 것은 유효했다(A·B가 같은 발견을 독립적으로 냈고, C·D·E는 서로 겹치지 않았다) —
   다만 발견의 심각도 판정(A-1 "MED", A-2 "새 실패 모드")은 메인이 옛 결정 범주와 대조해 낮췄다. 감사자의 심각도는 입력이지
   결론이 아니다.

## §6 사용자 회신 (2026-09-08 오후, 대화형)

| 문항 | 결정 | 반영 |
|---|---|---|
| **Q40** | (a) — *"권고 동의해. 그건 외부 버그라서 어떻게든 어딘가 죽는게 맞고, 마찬가지로 UB가 되는거 맞아보임. 권고대로 하면 될듯 하고, 명시만 잘 해둬줘"* | `slot-plan.md` CRUD 표 `Clear` 행에 "창 안 파괴 도중 raise → 그 Slot 동결, UB — List KeyGone과 같은 톤" 명시. 코드 0 |

같은 회신에서 사용자가 Q6·Q14의 맥락을 물어 채팅으로 설명했다(Q6: 정본이 약속하던 "미주입 `native*`는 조합으로 기본
구현" 규칙을 코드가 한 번도 가진 적이 없어 회신 4차에서 약속을 빼고 조합 기본 구현은 백로그로 — 지금은 여섯 전부 필수·미주입
스텁 에러; Q14: 사용자 기억대로 `Owned = false` 요소 Slot이 `destroySlotTree`에서 파괴되지 않고 살아남는 경우를 위해
`releaseOwner`를 두 루프에 되살린 것 — C-4 면제의 전제 "요소는 어차피 죽는다"가 그 요소엔 불성립).

## §7 2차 감사 — 실행 기반 탐사 다섯 (2026-09-08 오후~저녁, 사용자 "조금 더 파볼래? 문제가 소진된다면 멈춰보자")

각도를 바꿨다 — 문서 대조가 아니라 **프로브를 실제로 돌리는** 탐사(전부 opus, 병렬, 프로브는 `probe.<X>.tmp.luau` 하나씩 만들어
돌리고 삭제): **F** 반응형 코어(랜덤 DAG 60개×60라운드 차등 검증, 다이아몬드, 깊이 5000/팬아웃 2000, Observer/Effect 순열, GC 1000개),
**G** Slot/Dispatch/Modifier(수동 CRUD 9,600스텝·포털 4,800·List 1,800×4·중첩 List·부기 퍼즈 3,600 — 독립 오라클 대조, 음성 대조 통과),
**H** quad-roblox(Property 3-상태·Event/OnChange·Shorthand·Factory·Animate), **I** 에러 blame 전수(공개 표면 60·오용 191케이스 자동
판정 — blame 정확 166, quad 내부 9, 규약 위반 5자리, 옛 발견 회귀 0), **J** 정본 의사코드 vs 코드(읽기 전용). 값·순서·오프셋·GC
결함은 **0**이었다 — 남은 건 전부 **게이트 부재·blame 누출·메시지 모양·정본 의사코드 stale**이고, 아래에서 닫았다. test.sh exit 0(스펙 50).

### §7.1 반영 — 코드 (`H-492`~`H-502`, 전부 spec 동반)

- **`H-492` `Blocker:Policy(emit)` 인자 게이트** (F-1·I-2 동시 발견). emit이 함수가 아니어도 `_handles`에 들어가 나중 `Off()`에서
  `Blocker.luau:94: attempt to call a nil value`로 죽었다 — 게이트 정책 표면 셋(`State:Gate`/`State:Apply`/`Blocker:Policy`) 중 유일하게
  비어 있었다. 등록 줄에서 `Blocker: Policy emit must be a function (got X)`. `spec.blocker` 9절.
- **`H-493` `Dispatch.addHandler` 모양 게이트** (I-3). 테이블이 아니면 `keyType` 인덱싱 VM 에러, `process`가 없으면 `setFuncLevel`의
  "renamed or missing method?" **자기 진단**이 제공자 입력에 새어 나왔다. `spec.dispatch` 20절.
- **`H-494` 메시지 주어 잔재** (F-2·I-7). `quad.Dispatch:` 셋(no handler matched·no retractor·priority tie → `Dispatch.drive:`/`Dispatch.addHandler:`),
  `UseProvider` 중복 메시지에 주어 없음, `Ref` 동적 경로 메시지의 콜론 누락(형제와 갈림), quad-roblox 버전 게이트의 주어 없음 +
  폐기형 `, got X`. `H-477` "열 곳 손질"이 놓친 여섯 자리(`UseProvider` 것은 코드 주석에 `H-494`로 통일 — 처음 `H-496`으로 적었던 번호는 폐기). **[같은 날 round8 K-3 정정]** `no handler matched`/`no retractor`의 주어를 `Dispatch.process:`로 바꿨다가 **[같은 날 round8 O-1]** 두 raise가 최외곽이라 어느 진입(`D.Frame{}`·`drive`·직접 `process`·위임 핸들러)에서도 오므로 함수 하나를 못 박는 것 자체가 틀렸다는 지적을 받아 네임스페이스 주어 **`Dispatch:`**로(blame 줄이 진입점을 말한다). 메인 판단 — 사용자가 원하면 되돌림. `spec.refhandlers` 단언 갱신.
- **`H-495` `drive` 배열 키 도메인** (H-1). `D.Frame({ [0] = child })`가 값이 매치되면 말단 핸들러의 `setOffsetSource`/`setEmpty`에서
  `Handlers/InstanceChild.luau:42` 같은 내부 줄을 blame하고, 매치 안 되면 사용자 줄을 blame했다 — 같은 키인데 값에 따라 갈렸다.
  `drive`가 flatten 전에 양의 정수 검사(`H-256` (a) "부기 만지기 전에"; 형제 `H-396` Slot 생성자·Tag 리스트). 희소 구멍은 UB 그대로. `spec.dispatch` 20절.
- **`H-497` `Tag:Apply(비함수)` 게이트** (I-4). 형제 `State:Apply`는 막고 `Modifier:Apply`는 정본이 무게이트를 명시("nothing more,
  nothing less")인데 Tag만 근거 없이 비어 `Tag.luau:171`을 blame했다. `spec.tag` 7절.
- **`H-498` `Attr` 그룹 값의 테이블 게이트** (I-5·H-3 동시). 값 게이트가 함수만 막아 Slot/Ref/Tween/Modifier·메타테이블 테이블이
  `setAttr`까지 갔다(mock은 저장, 실엔진은 디스패치 깊이에서 raise → 내부 blame — `H-368` 패밀리). 테이블은 None·State만 허용.
  `spec.attribute` 11절.
- **`H-499` `Relate` nil 게이트 + `Dispatch.getBlocker(nil)`** (I-6). 191케이스 인구조사에서 raise 가능한 공개 표면 중 태그 없는 것은
  `Relate` 넷뿐이었다 — nil inst/key가 `Relate.luau: table index is nil`. 잎 모듈이라 quad-error 태그 없이 level-2 `error`(호출 줄).
  `getBlocker(nil)`은 `H-447`이 형제 셋에 준 게이트가 빠져 같은 자리에서 죽었다 — round3가 "내부 표면"이라 판정했지만 `q.Dispatch.getBlocker`로
  공개·태그돼 있었다. `spec.relate` 7절. **[같은 날 §9 `H-504`에서 정정]** "`H-447`이 형제 셋에 게이트를 줬다"는 틀렸다(`H-447`은 `bindLifetime`만) — 공개 부기 표면 전부에 `checkOwner`.
- **`H-500` Slot 순환 게이트** (G-1 — 2차 감사의 유일한 **동작** 발견). `s:Add(s)`·`a:Add(b); b:Add(a)`·3-순환이 선행 패스를 전부
  통과했다(조상은 루트라 "마운트 안 됨"). 다음 CRUD에서 `teardownTree` 무한 재귀(`Brand.luau:101: stack overflow`) 또는 `releaseOwner`
  불변식 에러. 선행 패스가 이 Slot의 owner 체인을 걸어 후보와 대조. `dispatch-core-plan.md`의 "순환은 UB"는 핸들러 사이의 순환이지
  요소 그래프가 아니라고 판정(기존 게이트가 한 케이스를 빠뜨린 것). `spec.slot` 27절.
- **`H-501` `native*` 여섯의 안내 스텁** (H-2). Q6가 폴백을 철회하며 "미주입이면 안내 스텁 에러"를 약속했는데 여섯은 스텁 없이 `nil`이라
  `attempt to call a nil value`(Raw.luau 113행)였다. 형제 일곱과 같은 `notInstalled`. `spec.lifetime` 1절.
- **`H-502` `Animate` State 옵션의 blame** (I-1 — `H-464` 잔여). 리터럴은 `Animate(info)` 때 끌어올렸지만 State 옵션은 Compute 안에서
  `Tween(opts)`가 nearest로 검증해 `Animate.luau:96`을 blame했다(`spec.animate` 4절이 그 케이스만 blame 단언을 비워둔 채였다).
  `validateFields(opts, raise?)`에 raise 인자를 더해 `Animate`가 최외곽으로 먼저 검증. `spec.animate` 4절에 `assertBlamesUser`.

### §7.2 반영 — 정본 의사코드 (J 아홉, 코드가 사실)

`H-503`으로 묶는다: `dispatch-core-plan.md` `setOffsetSource` 의사코드가 `H-392`(HIGH) 이전의 쓰기→읽기 순서(J-1 — 그대로 짜면 HIGH 재생산),
`getOffsetAt` nil 가드가 `H-397`/`H-408`/`H-427` 이전판(J-7), `setLength`의 `gatedRecompute` 호출별 클로저·State 검사 누락(J-8), 체인
의사코드에 `H-329` `retractRange`/release 분기 없음 + `quad.` 접두(J-9); `slot-plan.md` `SlotHandler.process`에 `H-407` 파괴 사전 검사
없음 + "여기 한 번이면 된다" 현재형(J-2), `releaseElement` `wasDetached` 팔에 `H-393` `releaseOwner` 없음(J-4), `rawReplace` 미마운트
분기의 `H6-23`/`H6-24`(archive M6에만 있던 것) 없음(J-5), `destroySlotTree` `_detached` 루프의 `releaseOwner` — **`H-488`의 반쪽 미이행**
(J-6, 메인 실수); `architecture.md` 에러 계약 표 3행 "제공자 계약 위반 = nearest"가 `H-409`(outermost) 이전판이고 같은 코퍼스의
체크리스트 0번과도 충돌(J-3 — 표 축을 건드리므로 아래 §8에 보고). 전부 코드 기준으로 정정.

### §7.3 확인만 한 것 (재발견 금지)

- F: 랜덤 DAG 값·발화 횟수 불일치 0, 다이아몬드 양 순서 Observer 1회, Effect×게이트 seam(닫힌 채 3회 Set → flush 1회 최신값), Destroy 파동+게이트,
  카운터 랩(`bit32.bnot(-x)`), Observer 진입점 11순열, fn 던짐 뒤 `_running` 잔류(인정된 설계 — `lifecycle-pattern.md`), Compute 안 `:Set` 발산(UB 명시),
  자기참조 Source 스택오버플로(UB 명시), GC 1000개 회수, 교차 quad 인스턴스(`H-186` UB, 조용히 통과).
- G: 위 퍼즈 전부 발견 0; mock은 `nativeInsert` offset을 무시하므로 물리 순서 대신 멤버십+오프셋 산술로 검증; `Owned=false` List Slot 홀더 파괴 뒤 재마운트 OK.
- H: `H-406`·`H-449`·Q25/Q26/Q33/Q8 전부 정본대로; `Tween{ Override = "Finish" }`가 같은 목표로 오면 dedup이 먼저 걸려 Finish 스냅이 무시됨(Q25 "옵션은
  비교 대상 아님" 범위); `D.Frame({ nil, child })` 희소 구멍 UB; Luau weak-key는 ephemeron이 아님(실측, `H-229` 근거); **mock 충실도 메모** — `Handlers/Property.luau`
  헤더의 "weak-keyed by inst … dying instance drops its slots"가 CLI mock에선 성립하지 않는다(mock Tween이 `Instance` 필드로 역참조; 실물 Tween userdata는 다를
  것 — 실기기 미완); 서로 다른 quad 모듈 둘의 같은 Instance `nativeClaim`은 안 막힘(모듈 단위 InstData — 정본 범위 밖).
- I: 옛 blame 발견 전부 회귀 없음(`H-344`·`H-385`·`H-446`·`H-408`·`H-434`·`H-409`·`H-473`·`H-375`·`H-447`·`H-441`/`H-442`/`H-419`/`H-470`·`H-378`),
  디스패치 깊이 outermost 규칙, `-O2`/`--codegen`에서 출력 바이트 동일(스파이크 27 규칙 유지), Event/OnChange 무게이트는 정본 명시.
- J: architecture 소스 트리 표 57파일 1:1, 주입 op 12+1, 메시지 60건 표본 규약 준수, blocker-plan·state-epoch·source-state·tween·onchange·lifecycle·effect 블록 일치.

### §7.4 미완 (실기기 필요 — Studio 없음)

`D.New("Frmae")`류 오타는 엔진의 `Instance.new` 에러가 `D/init.luau`(생성물) 줄을 blame할 것으로 보이나 mock은 아무 이름이나 받아 확인 불가(I-8 — §8 Q41).
`inst[k] = 테이블`·`SetAttribute(name, 테이블)`의 실엔진 문구, Tween userdata의 GC 거동(위 H 메모). J가 문장 단위 대조를 못 한 정본:
`modifier-plan`(`H-448`·`H-469`)·`ref-plan`(`H-473`)·`tag/attribute/claim/relate/module-lifecycle` — 셋 다 `H-nnn`이 `base/`에 0건.

## §8 사용자 문항 (2차)

**Q41 — `D.New(className)`의 클래스 이름 오타.** 상황: `D.New`는 생성기 범위 밖 클래스의 탈출구라 타입 방어가 없는 유일한 생성 경로다.
`D.New(5)`는 타입이 잡지만 `D.New("Frmae")` 같은 문자열 오타는 타입이 못 잡고, 생성된 `D/init.luau`의 `Instance.new(className)`이 엔진
에러를 내며 그 줄(생성물 내부)이 blame될 것으로 보인다 — CLI mock은 아무 이름이나 받아 실측하지 못했다(2차 감사 I-8). 무엇이 막히나:
고치려면 생성기 템플릿(`gen-d.py`)에서 `Instance.new`를 `pcall`로 감싸 사용자 줄로 다시 던지는 모양이 되는데, 이건 새 코드 경로이고
엔진 문구도 아직 못 봤다. 갈래: (a) Studio 실측 뒤 판단(권고 — `HUMAN_TODO`에 실측 항목으로) / (b) 지금 pcall 재던지기 / (c) 안 함(엔진
메시지가 클래스 이름을 이미 말해주므로).

**Q42 — Instance를 매개로 한 Slot 순환(round8 K-7, 실기기 필요).** 상황: `H-500`은 Slot–Slot 순환만 닫는다. `drive(F, { s })`로 `s`를 `F`에
마운트한 뒤 `s:Add(F)`를 하면 후보가 Instance라 owner 체인 검사가 안 돌고, `F`는 quad 소유 기록이 없어 "already mounted"도 안 걸린다(mock 통과 실측).
실엔진에선 `F.Parent = F`가 되어 엔진의 "circular reference" 에러가 `EngineOps.luau` 줄에서 날 것으로 보인다 — mock은 부모만 갈아끼워 확인 불가.
갈래: (a) Q41과 함께 Studio 실측 뒤 판단(권고) / (b) 지금 게이트 — 후보가 Instance면 이 Slot의 마운트 타깃 조상 체인(`_mountedInst`와 그 `Parent` 사슬)에
있는지 확인(엔진 순회, 새 코드 경로) / (c) 엔진 에러에 맡김(UB).

**J-3 보고(결정 아님, 정정 완료).** `architecture.md` 에러 계약 표 3행 "제공자(핸들러 작성자) 계약 위반 → 2(가장 가까운 프레임)"이
`H-409`(디스패치 깊이라 outermost)와 같은 문서의 체크리스트 0번("디스패치·발행 깊이에서 raise할 땐 `errorBefore`")과 어긋나 있었다.
코드(`H-409`)와 규칙에 맞춰 행을 "최외곽"으로 고쳤다 — 표의 축(입력/불변식/제공자/스텁)은 그대로다. 되돌리길 원하면 말해달라.

## §9 3차 — 2차 반영 커밋 `c06f94c`의 리뷰(K, 단일 맥락 opus) + 문서 감사자(N) (2026-09-08 저녁)

- **`H-504` K-2 — `Relate` nil 게이트가 잎 모듈 이름을 사용자 메시지로 새게 했다.** `H-499`가 `getBlocker` 하나만 고른 근거("`H-447`이 형제 셋에 게이트를
  줬다")가 틀렸다 — `H-447`은 `bindLifetime`만 닿았고, `Dispatch.getBookkeeping`/`getOffsetAt`/`setLength`/`setOffsetSource`/`setEmpty`에 nil owner를
  주면 `Bookkeeping.luau:112: Relate:GetWeak: inst must not be nil`, `process`/`retractFrom`은 `Dispatch/init.luau` 줄 — 주어가 사용자가 부른 적 없는
  `Relate:`가 됐다("메시지 모양" 규약 위반, 전엔 `table index is nil`이라 회귀는 아님). 반영: `checkOwner(fnName, ownerKey)`를 `checkPosition` 옆에
  두고 다섯 + `getBlocker`에, `checkInst`를 `process`/`retractFrom`에(`drive`의 `H-442`와 같은 게이트). `spec.relate` 7절 확장.
- **K-1 (HIGH — 정본, 코드 무관)** — 2차 §7.2 J-4 정정이 **오독**이었다: `releaseElement`의 `releaseOwner`를 `if wasDetached` **위**(두 팔 공통)로 올렸는데
  코드(`Slot/Raw.luau`)는 detached 팔 **안**에서만 부르고, 비-detached 팔은 `rawRemove`/`rawUnmount`가 각자 반납한다 — 정본대로 짜면 `:List` KeyGone의
  상시 경로에서 `releaseOwner` 불변식 에러. 인용한 `_detachCleanup`의 "두 분기 공통"은 `isSlot`/`else` 두 분기였다. 정본을 코드에 맞춰 되돌림(1차 J-1이
  경계한 "그대로 짜면 HIGH 재생산"을 정정 패스 자신이 냈다 — 교훈 §7.5에 추가).
- **K-3** 위 `H-494` 정정 문단. **K-5** `module-lifecycle-plan.md` 의사코드의 raise가 `errorBefore`로 남아 있었다(코드는 직접 호출 표면 = `errorBeforeNearest`,
  `H-349`) — 정정. **K-4/K-6** `H-496` 번호 폐기(코드 주석 `H-494`로 통일, N도 같은 지적), "다섯 자리" → 여섯, 커밋 메시지의 "spec 8절 신설"은 실제 여섯
  신설 + 셋 보강(커밋 메시지는 못 고침 — 여기 기록). **K-9** `spec.animate` 4절의 blame 단언은 직접 `:Get()` 팔뿐이라 `spec.tweenproperty` 9절에 `D.Frame`
  경유(drive 깊이) blame 단언 추가.
- **N(문서 감사자)** — `architecture.md` 405행 "사용자 입력 검증·제공자 계약 위반(2행·3행)은 `errorBeforeNearest`"가 오늘 고친 표 3행과 같은 파일 안에서
  모순(배너만 갱신·본문 방치의 전형) → 정정; `dispatch-core-plan.md` 체인 의사코드의 retractor 생략 raise 둘이 아직 `errorBeforeNearest`(J-3의 형제 — J가 아홉에
  못 넣은 것) → `errorBefore` + `H-409` 마커, 그 절의 `H-222` (a) 사용자 확정 문단에 "그 `2`는 실제로 `Dispatch/init.luau` 자신을 찍었다" 경위 추가;
  session-summary 중복 문장; "메시지 모양" 규약의 "열 곳" 뒤에 `H-494` 포인터.
- **확인만(K)**: `H-500` 게이트 정확성(Instance owner에서 멈춤, `_wrapped` 래퍼가 마디로 들어감, `:List` 우회 없음 — 마운트 뒤라 "already mounted"가 먼저),
  `H-495`가 flatten·prePass·getBlocker 전부보다 앞이라 `H-445`류 재발 없음·`Claim` 경로 무해·Modifier가 숫자 키를 못 만듦, `H-493` in-tree 16 핸들러 priority
  전부 숫자, `H-501` 스텁이 실제 op를 못 가림(`UseProvider`가 뒤에 덮음), `H-498` Roblox 속성 합법 타입은 전부 userdata, `H-502` 타입 정합, 정본 아홉 중
  여덟 일치. **관측(반영 없음)**: K-8 `H-495`의 `pairs` 전수 순회는 `flatten`이 리뷰 근거로 피했던 배열 파트 재방문이고 대상 키는 정의상 해시 파트에만 산다
  (Frame당 한 번, 비용 미미 — 다음 최적화 순회 후보); `Frame { [AttrKey("X")] = 테이블 }` 직접 경로는 `H-498` 범위 밖(정본이 "raw AttrKey 경로는 untyped by
  design"으로 명시).
- **미완(실기기)**: **K-7** Instance를 매개로 한 순환 — `drive(F, { s })` 뒤 `s:Add(F)`는 occupant가 Instance라 `H-500`의 체인 검사가 안 돌고 F는 OWNER
  기록이 없어 "already mounted"도 안 걸린다(mock 통과 실측). 실엔진에선 `F.Parent = F`로 "circular reference" 엔진 에러가 `EngineOps.luau` 줄에서 날 것
  — Q41과 같은 "실기기 실측 뒤 판단" 묶음(**Q42**로 §8에 추가).

### §7.5 교훈 추가
5. 정정 패스도 리뷰를 받아야 한다 — K-1은 "정본을 코드에 맞춘다"는 패스가 코드를 잘못 읽어 정본을 반대로 틀리게 만든 사례. 의사코드를 고칠 땐 그
   함수의 **호출자**(여기선 `rawRemove`/`rawUnmount`가 이미 반납하는가)까지 읽을 것.

## §10 3차 — 타입 표면 실측 (M, opus; 사용자 코드 모양을 `luau-lsp` 신 솔버 + `luau-analyze`로) (2026-09-08 저녁)

음성 25건 중 24건 정상 거부, 양성(컴포넌트 props 유니언·이벤트 시그니처·`:Apply(Animate)`·`:List` 콜백 등) 정상, `q.D.Frame` 타입이 `UseProvider`/`AddPlugin`
체인 뒤에도 `any`로 안 무너짐. 남은 다섯은 전부 **타입 모양·패키지 표면의 결정**이라 코드로 닫지 않고 §11 문항으로 올린다. 전부 `--!strict`에서만 난다.

- **M-1 (합법이 막힘)** 무인자 `Store()`가 strict TypeError — `T`가 `unknown`으로 남아 `CheckReservedKeys<keyof<T>>`가 터지고, 스토어를 쓰는 순간(`:Names()`/`:Of()`)
  진단이 난다. 통하는 건 `Store({})`/`Store<<{}>>()`뿐. `store-plan.md`는 무인자를 유효로 확정(`H-83`)했고 `H-157` 실측은 `Store<<{}>>()`만 봤다. 결정적 증거:
  `spec.store.luau` 140행이 무인자 형을 `(Quad.Store :: any)()`로 우회 중(스펙 작성자가 밟았지만 기록 안 됨). → **Q43**.
- **M-2a (합법이 막힘, 탈출구 없음)** 이미 있는 자식 배열 `{ Instance }`(또는 정확히 `{ FrameElem }`)를 `D.Frame(kids)`로 통째로 넘길 수 없다 — Luau 테이블 인덱서
  불변성(`FrameParam<E>`의 `[number]: E`). 통하는 건 `{ table.unpack(kids) }`·개별 나열·변수를 처음부터 `FrameParam<FrameElem>`으로 선언. `Children: { Instance }`
  props를 받는 컴포넌트 모양(`spec.componenttypes`가 안 덮음)에 탈출구가 없다. **M-2b (우회 있음)** 미리 만든 props 변수 `{ Name = "a" }`도 같은 뿌리로 막히나
  `local p: FrameParam<FrameElem> = {...}` 선언으로 통과. → **Q44**.
- **M-3 (strict + 신 솔버 한정)** D 프롭 자리에 **인라인** 무주석 `:Compute`(`ZIndex = n:Compute(function(h) return h:Get() + 1 end)`)가 TypeError — 함수 인자로
  넘기는 테이블 리터럴 **안**에서만 깨지고(typed 파라미터·주석 대입·children 배열·`:With`/`:Gate`/`:Apply` 인라인은 통과), `luau-analyze`(구 솔버)는 통과라
  test.sh는 못 보고 사용자 에디터는 본다. `typing-limits.md` §1②의 "무주석으로 통과"와 어긋남 → §1②에 캐비엇 추가(8.13, 원인은 순수 Luau 최소 재현 실패 —
  M 미완). 부수: 같은 자리 인라인 `:Gate`에서 `emit()` 무인자 호출이 시그니처 추론을 깨뜨림(별도 문장으로 빼면 통과).
- **M-4 (표면 누락)** `quad-base/src/init.luau`엔 `export type`이 없어 `quad_base`만 설치한 사용자는 `Quad.State<number>`를 이름으로 못 쓴다(`quad-types`를 별도
  의존으로 — `quad-types-plan.md`의 설계이긴 하다). 더 아픈 건 quad-roblox: `spec.componenttypes`가 컴포넌트 경계의 정본 관용구로 제시하는 `IntoTextButton`·
  `<Class>Param`·`<Class>Modifier`·`<Class>RefMarker`·`Field<T>`가 `quad-roblox/src/init.luau`의 재노출(D/DMapper/PropTypes/OnChangeFn/Tween류)에 없어 레포 안
  경로 `require("../src/D")`로만 닿는다 — 릴리즈 사용자는 컴포넌트 경계 타입을 못 쓴다. `quad-types-plan.md` "남은 것"의 `quad-roblox-types` 백로그와 같은
  뿌리. → **Q45**.
- **M-5 (`any` 붕괴)** `store:Of("mana")` 무주석이 `Source<any>` — `Of: <U>(self, name) -> Source<U>`의 `U`가 제약이 없다. `store-plan.md` 실측 표는 `Of<<boolean>>`
  명시형만 확인. → **Q46**(주석 강제 vs 그대로 + 문서).

## §11 사용자 문항 (3차 — 타입 표면, 평문 한 문단씩)

**Q43 — 무인자 `Store()`.** 상황: 정본이 유효하다고 한 무인자 형이 strict에서 TypeError고 스펙조차 `any` 캐스트로 우회한다. 무엇이 막히나: 생성자 타입이
`<T>(fields: T?) -> Store<T>` 하나라 인자가 없으면 `T`가 `unknown`이다. 갈래: (a) 생성자를 오버로드 교차(`(() -> Store<{}>) & (<T>(T) -> Store<T>)`)로 — 타입
스파이크 하나 필요(권고) / (b) 무인자 형을 문서에서 빼고 `Store({})`만 유효로(정본 `H-83` 역전, 스펙 140행 정리) / (c) 그대로(사용자가 `Store<<{}>>()`를 쓴다).

**Q44 — 자식 배열·props 변수를 `D.<Class>`에 통째로 넘기기.** 상황: Luau 인덱서 불변성 때문에 `{ Instance }` 변수는 `FrameParam<FrameElem>`이 아니다. 무엇이
막히나: 타입 구조를 바꾸지 않는 한 언어 한계라 우회 관용구를 정하는 문제다. 갈래: (a) 한계로 인정하고 `typing-limits.md`(8.13)와 사용자 문서에 관용구 셋
(`{ table.unpack(kids) }` / 변수를 `FrameParam<FrameElem>`으로 선언 / 컴포넌트 props의 `Children`을 `FrameParam<FrameElem>`으로 받기)을 명시(권고) /
(b) `D.<Class>`가 `{ E }`도 받도록 파라미터를 유니언으로(`FrameParam<E> | { E }`) — 팔이 늘어 `PV73`류 솔버 비용 재측정 필요.

**Q45 — 릴리즈 사용자용 타입 표면.** 상황: `quad_base`만 설치하면 `Quad.State<T>` 이름이 없고(설계상 `quad-types` 별도 의존), quad-roblox는 컴포넌트 경계 타입
(`IntoTextButton`·`<Class>Param`·`<Class>Modifier`·`<Class>RefMarker`·`Field<T>`)을 재노출하지 않는다. 무엇이 막히나: 재노출은 생성기(`gen-d.py`)가 31클래스 ×
여러 별칭을 `quad-roblox/src/init.luau`에 뿜는 일이라 파일 크기·솔버 한도(8.12)를 다시 밟을 수 있고, 백로그 `quad-roblox-types`와 겹친다. 갈래: (a) quad-roblox
`init.luau`에 컴포넌트 경계 별칭만 선별 재노출(`Into<Class>`·`<Class>Param`·`<Class>Elem`·`<Class>Modifier`·`<Class>RefMarker`·`Field<T>`) + 8.12 실측(권고, 릴리즈
전 필수로 보임) / (b) `quad-roblox-types` 패키지를 지금 만든다 / (c) 백로그 그대로(릴리즈 문서에 `require("…/D")` 경로를 안내).

**Q46 — `store:Of(name)` 무주석의 `any`.** 상황: `Of<U>`의 `U`가 제약 없이 `any`로 떨어져 그 뒤 값 타입 검사가 사라진다. 갈래: (a) 그대로 두고 `store-plan.md`
실측 표에 "무주석은 `Source<any>` — 주석 필수"를 적는다(권고 — 동적 이름은 정의상 타입이 없다) / (b) `Of`를 `Of<U>(self, name, sample: U?)`류로 바꿔 추론
근거를 준다(새 인자, 비권장).

## §12 3차 — 성능·메모리 실측 (L, opus; CLI mock, 3회 최소값, `-O2` 대조 동일) (2026-09-08 밤)

반응형 코어(체인 5000·팬아웃 5000·다이아몬드·Gate·Observer/Effect)와 quad-roblox(`D.Frame` 5000·Property·Tween·Event·Destroy)는 **전부 선형**, 장기 루프
메모리(생성+Destroy 30,000회, List Set 10,000회, Compute 100,000회, Observer/Effect 10,000회, Slot 마운트 사이클 10,000회)는 **전부 정체**. 초선형은 Slot 층에
몰려 있었고 둘을 닫았다:

- **`H-505` `rawMove`의 역맵 재작성이 끝까지 갔다** (L-4 절반). `reindexFrom(lo)`가 배열 끝까지 쓰는데 회전은 `[lo, hi]` 밖을 안 건드린다 — `:List`의 "가운데
  한 개 삭제"가 뒤 키마다 한 칸 `rawMove` → 키당 O(N) → 사이클 O(N²)(4000행에서 한 줄 삭제 39ms). `reindexRange(lo, hi)` 신설. `spec.slot` 28절.
- **`H-506` `Slot{ …N개 }` 생성자가 요소마다 선행 패스를 돌렸다** (L-2). `prepareElements`가 호출마다 현재 요소 전수를 훑어 `seen`을 만드는데 생성자가
  요소마다 불러 O(N²)(1000개 38ms vs `Splice(1, 0, …)` 1ms). 배열 인자로 바꿔 생성자는 한 번(nil 구멍 UB는 `ipairs`로 그대로), `Add` 단발은 설계대로
  O(현재 길이)(CRUD 표에 명시). `spec.slot` 28절(중복 검출 유지·300개 배치).
- **백로그로**(ROADMAP 최적화 후보): L-3 마운트된 단발 CRUD의 꼬리 `recompute`가 `i = 1`부터 전 자리(호출당 O(N)) — 커서 재개는 되감기 계약과 대조할
  설계 판단; L-4 나머지(전체 키 교체 O(N²) — `rawPermute`/"KeyGone 먼저" 계열); L-5 `addHandler` O(N²)(실사용 22개); L-6 Modifier 필드 수천 체이닝.
- **L-1 (mock에서 HIGH — 실기기 판정 필요)**: 엔진 Tween이 붙은 채 `Destroy`된 Instance가 회수되지 않는다(10,000회에 30MB 단조 증가, 인스턴스당 3KB).
  기제(L-7 실측): **Luau의 weak-key 테이블은 에페메론이 아니다** — `Relate` 버킷(weak 키 / strong 값)의 값이 자기 키를 되참조하면 항목과 키가 불멸.
  `Handlers/Property.luau`의 `tweenSlots:SetStrong(inst, k, { Tween = engineTween, … })`에서 **mock** Tween이 `.Instance` 필드로 inst를 Lua 참조한다.
  실물 `Tween` userdata의 `.Instance`는 엔진 프로퍼티라 Lua 객체 그래프에 없을 가능성이 크다(H 각도도 같은 메모) — 그러면 실기기에선 회수된다. → **Q47**.
  `SetStrong` 호출부 아홉 중 값이 키를 되참조하는 것으로 확인된 건 이 하나(`InstanceShorthand` 관리 자식은 mock `Parent`가 프록시가 아니라 미확인).
- **L-8 (설계된 핀, 가격만)**: `drive`로 프로퍼티를 받았거나 `bindLifetime`이 걸린 Instance는 `Destroy` 없이는 회수 안 됨(`LifetimeHandle.luau` gcconn 캡처
  계약) — Frame당 ~4.5KB, 요소 1개 Slot 마운트 Folder ~11KB. `Destroy`하면 회수(30,000회 +2KB 평탄).
- **사고 기록**: 메인의 `git add -A`가 L의 프로브 파일을 `649d998`에 휩쓸어 넣었다(L이 삭제, 이 커밋에서 제거). 규약: 프로브가 도는 동안 커밋은
  `git add` 경로를 명시하거나 `':!*probe.*'`를 제외할 것.

## §13 사용자 문항 (3차 — 성능)

**Q47 — 엔진 Tween 슬롯이 Instance 회수를 막는가(실기기 필요).** 상황: `Property` 핸들러가 활성 트윈을 `Relate`에 strong 값 `{ Tween = engineTween, Value }`로
쥔다. Luau weak-key 테이블은 에페메론이 아니라, 값이 키(Instance)를 Lua 참조하면 그 Instance는 `Destroy` 뒤에도 영원히 남는다 — CLI mock에선 mock Tween이
`.Instance` 필드를 갖고 있어 10,000회에 30MB가 샜다(L-1). 실물 `Tween` userdata의 `.Instance`는 엔진 쪽 참조라 Lua GC엔 안 보일 가능성이 크다(그러면 실기기
무해). 무엇이 막히나: Studio 없이 판정 불가하고, 방어를 넣는다면 `onDestroying`에서 그 inst의 트윈 슬롯을 비우는 새 경로(또는 슬롯의 Tween을 weak로)가 된다.
갈래: (a) Studio 실측 뒤 판단 — Q41·Q42와 한 묶음으로 `HUMAN_TODO`(권고; 실측 스크립트는 L-1 재현 코드 그대로) / (b) 지금 `onDestroying` 훅으로 슬롯 비우기
(새 경로, 실기기 무해면 낭비) / (c) mock의 Tween에서 `Instance` 역참조만 빼 mock 충실도 문제로 닫기.

## §14 수렴 확인 — 3차 반영 커밋(`649d998`·`f05a9aa`)의 리뷰(O, 단일 맥락 opus) + 문서 감사자(P) (2026-09-08 밤)

- **O**: `H-504`~`H-506` 코드는 정확 — 내부 호출자 중 nil owner/inst 경로 0(25곳 전수), 게이트 비용 9.6ns/호출, `reindexRange` 정확성(회전은 구간 밖
  불변; 미실체화 3,000스텝 + 마운트 중첩 800스텝 실측), `table.pack` 홀 동작·blame 동일, 생성자 배치 O(N)·List 가운데 삭제 선형 재확인. 반영 넷: **O-1**
  메시지 주어를 `Dispatch:`(네임스페이스)로 — 위 `H-494` 문단; **O-7** `spec.slot` 28절에 마운트 + 중첩 Slot 팔(무효화 위치를 역맵으로 정하는
  `gatedRecompute` 소비자를 실제로 태움); **O-8** `H-506`이 생성자의 반쪽 상태(첫 요소가 버려질 Slot에 소유권 묶임)를 없앤 동작 변화를 `slot-plan.md`
  `H-30`/`H-31` 선행 패스 절에 명시; **O-12** `slot-plan.md`의 지시어 오독 자리 문장 순서.
- **P**: 정본 의사코드 셋(`getOffsetAt`/`setLength`/`setOffsetSource`)과 `process`에 `checkOwner`/`checkInst` 반영, 생성자 의사코드를 배치 선행 패스로(round15
  `H6-19` 이후 계속 stale이던 `self:Add(v)` 루프), §7.1 `H-499` 문단에 정정 포인터, ROADMAP `prepareElements` 항목에 "생성자는 닫음", `store-plan.md`에
  Q43 교차 참조.
- **판정: 소진.** 네 라운드(감사 5 → 탐사 5 → 리뷰/타입/성능/감사 4 → 수렴 2)에서 동작 결함은 2차의 Slot 순환(`H-500`) 하나였고, 이후 라운드의 발견은
  게이트·blame·메시지·정본 정합·성능·타입 표면으로 옮겨갔으며 마지막 라운드는 직전 반영분의 정합만 남겼다. 남은 것은 전부 사용자 결정(Q41~Q47)이거나
  실기기 실측이 필요한 것.

## §15 실기기 실측 — Q41·Q42·Q47 + 부수 발견 (2026-09-08 밤, `audit/round8-studio-2026-09-08.md`)

사용자가 rojo 플러그인을 연결해 줘서(*"rojo serve 띄우면 연결해줄게. 실측 필요한 부분 실측해보자"*) 세 문항을 실물로 돌렸다. 표는 audit 파일.

- **Q47 닫힘 — (c) mock 충실도 문제.** 실물에서 트윈을 돌린 뒤 `Destroy`한 Frame은 GC에 회수된다(plain·관리 자식도). L-1의 30MB 누출은 mock Tween이
  `Instance`를 Lua 필드로 강하게 쥐어 `Relate`의 weak-key/strong-value 항목이 자기 키에 도달한 것. **반영**: mock의 `Instance`를 weak 홀더로(`quad-base/test/mock.luau`
  `newMockTween`). L-7의 일반 위험(`SetStrong` 값이 키를 되참조하면 불멸)은 실물 Tween엔 해당 없으나 Lua 테이블 값에는 여전히 참 — `relate-plan.md`에 그대로 둔다.
- **`H-507` Event 핸들러 값 게이트** (부수 발견). 실물 `signal:Connect(5)`는 던지지 않고 `RBXScriptConnection`을 돌려주며 콘솔에만 "Attempt to connect failed:
  Passed value is not a function"을 남긴다(스택 `Handlers/Event.luau:65`) — 헤더의 "엔진이 raise한다"(정본 무게이트의 근거)가 현재 엔진에서 거짓. `process`가
  `type(v) ~= "function"`이면 최외곽 표면 에러(State 경유 값은 StoreBind가 풀어 주므로 같은 자리). `spec.events` 8절(mock Connect도 아무거나 받으므로 게이트가
  유일한 방어). `OnChange`는 생성자 게이트가 이미 있음(실물 확인).
- **Q41 데이터**: 엔진 문구 `Unable to create an Instance of type "Frmae"`(위치 접두 없음, 스택은 `D/init.luau`). 문구가 클래스 이름을 말하므로 (c)로도 충분해
  보이나 결정은 그대로 사용자 몫.
- **Q42 데이터**: 엔진 `Attempt to set Frame as its own parent` / `… would result in circular reference`. raise 뒤 Slot에 요소는 들어가고(`IndexOf == 1`) 부기·물리는
  안 된 반쪽 상태(`Length == 0`)가 남지만 다음 `Add`는 정상이고 `Remove(1)`로 복구된다. (b) 게이트는 `self._mountedInst`의 조상 사슬 확인이 필요해 새 백엔드
  op(`isAncestorOf`류)가 되므로 사용자 결정 그대로.
- 엔진 문구 표(Attr/Property 테이블·문자열 값)는 audit 파일 — `H-498`이 실물에서도 사용자 줄로 먼저 막는 것 확인.

## §16 사용자 회신 — Q41·Q42·`H-507` (2026-09-08 밤, 실측 직후)

| 문항 | 결정 | 반영 |
|---|---|---|
| **Q41** | (c) 그대로 — *"우리가 무슨 class가 있는지 없는지 확인하기 힘들거든. 문구 자체로 괜찮고, 트레이스도 나와서 괜찮아보여. 닫았는데 재발하지 않게만 기록"* | `bind-system-plan.md` D 생성기 절에 "재개봉 금지" 항목. 코드 0 |
| **Q42** | UB — *"애초에 UB임. 엔진 자체도 UB이고, 그 처리를 만들어야하는가 모르겠음. 에러 난 다음 반쪽짜리 데이터로 정확하지 않게 되어도 그건 quad가 이전부터 허용해왔던 UB 뒤 깨짐은 처리 안 하던 것과 같은 문제"* | `slot-plan.md` 에러 조건 절에 UB 항목(Q9 좀비·재진입성과 같은 범주). 코드 0 |
| **`H-507`** | 게이트 유지 — *"raise가 안 된다면 UI가 안 죽어, fallback 같은 것에서 유저가 보고하기 어렵다는 게 문제 … 단순 type만 보고, state도 풀어져서 바운딩되므로 최종자엔 함수라 확인 가능해보이는데, 에러게이트 넣을래?"* | 이미 `a83ae62`에 들어간 그 모양 그대로(`type(v) ~= "function"` — StoreBind가 State를 푼 뒤의 최종값만 본다). 추가 없음 |

이로써 round8의 열린 문항은 **타입 표면 Q43~Q46**만 남는다.

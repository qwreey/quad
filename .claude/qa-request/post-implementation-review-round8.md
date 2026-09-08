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

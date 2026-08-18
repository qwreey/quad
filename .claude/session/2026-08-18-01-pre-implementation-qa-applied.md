# 2026-08-18 — 구현 전 QA 결과를 `base/`에 일괄 반영

**요청**: "pre-implementation-qa 의 적용을 수행하자."

`.claude/qa-request/pre-implementation-qa-round1.md`(같은 날 앞선 세션이
만든, `base/` 확정
문서를 사용자에게 문항으로 재심사한 결과)의 항목을 실제 문서에 반영한 세션.
그 문서는 "여기서 정정하지 않는다, 사용자 정정 회신이 오면 반영한다"고
적혀 있었지만 **각 항목에 이미 사용자 답변 원문과 논거가 붙어 있었고**,
사용자가 적용을 지시했으므로 그 답변을 정정 근거로 삼아 반영했다.

## 먼저 사용자에게 물은 네 가지

QA 문서가 "결론 없음"으로 남겨둔 항목 중, 임의로 정하면 안 되는 것만
`AskUserQuestion`으로 물었다(나머지는 답변 원문이 이미 방향을 확정함):

1. **SL-3 — `:List` reconcile의 `nil` 리턴** → *"PopOnly 확정. 다만 이름은
   변경될 수 있음. 이름에 대해서는 더 생각해보아야함"* → 파괴가 기본으로
   되돌리고 `PopOnly`(가칭)를 이번 설계에 넣음.
2. **D-7 — base Fallback Handler 등록 주체** → **quad-base 로드 시 등록으로
   재역전**(2026-08-14의 역전을 다시 뒤집음).
3. **N-4/RF-4 — `None`/`nil` 배열 슬롯 처리 책임** → *"NoneHandler는
   재귀만, NilHandler가 실질 담당"*.
4. **ST-2 파급 — 동적 키 경로** → *"동적히는 여전히 그냥 Store.Name 하면
   얻어는 짐. 타입 애러가 난다는 점인데, 이는 GetDynamic<T>(name):
   Source<T> 로 제공하는게 최선으로 보임."*

## 반영한 것 — 성격별

**(1) 그대로 구현하면 반대로 도는 것**

- **S-1 `canBound` 방향 반전**: `canBound(v) == not isBoundAlive(v)`,
  게이트는 전부 `if not canBound(v) then error(...)`. 진원지
  `lifecycle-pattern.md`의 (1)(2)(3) 절을 다시 쓰고,
  `source-state-plan.md`/`ROADMAP.md`/`luau-test`(README·STATUS)/
  `audit/gcconn-trick-verification.md`까지 같은 방향으로 정정.
  **부수 발견**: 열한 번째 세션이 이름 분리의 근거로 적은 "판정 로직도
  같고 값도 항상 같다"가 무너짐 — 실제로는 **서로의 부정**이고, 그게
  오히려 이름 분리의 명분을 강화한다는 쪽으로 절을 다시 씀.
- **RE-1 `SetStrong` → `SetWeak`**: `relate-plan.md`의 "대체하는 것" 절과
  `architecture.md` 소스 트리 주석. 근거 문장("둘 다 존재 이유가 '안 죽는
  것'이므로 strong")까지 통째로 틀렸던 것이라 근거도 교체 — 그대로 짰으면
  같은 문서가 경고하는 두-`Relate` 상호 강참조 누수에 정확히 걸렸다.

**(2) 설계가 바뀐 것**

- **RF-4+N-4**: `Dispatch.drive`의 `None` 스킵 분기 폐기 → `NoneHandler`는
  재귀 전담, **`NilHandler` 신설**(`k=number and v==nil` 말단,
  `setLength(0)`/`setOffsetSource(None)` 등록). 깨진 전제는 "배열 파트의
  `None`은 `process`를 절대 안 탄다"였는데 `Frame{ State<Slot|None> }`이면
  탄다는 것.
- **D-6 파생**: Length/Offset 등록 책임이 "그 위치를 **처음** 매치한
  Handler"에서 **말단 Handler**로 정정(중간 노드는 `inst`에 부작용을 안
  가한다는 D-3 계약과 충돌했음). 같이 검토 대상이던 "모든 핸들러가
  `k=number`일 때 처리" 안은 `NilHandler`가 갭을 닫아 채택 안 함 —
  **이건 사용자 답변에서 바로 나온 결론이 아니라 두 답변을 합친 추론이라
  세션 보고에서 따로 짚었다.**
- **EV-1**: 이벤트 disconnect 센티널 `false` → `None`/`nil`. `EventHandler`가
  `v == nil`에도 매치돼야 한다는 계약이 새로 생김.
- **D-7**: Fallback Handler 등록 주체 재역전. `InitNamespace` 거부 원칙과의
  양립 근거를 새로 씀 — 그 원칙이 금지한 건 *사용자 수동 init*과 *남의
  상태를 건드리는 top-level 부작용*이지, 모듈이 자기 레지스트리를 채우는
  게 아니다. `archive/tag-attribute-load-time-registration-reversed.md`엔
  "절반 재역전" 배너를 달았다(이름 쪽 결론은 그대로 유효).
- **R-1**: `Ref` 내부 구조가 `.Callbacks` 별도 테이블 + 평범한 `.Value`
  필드로 단순화 → `__index` 우회 기법의 존재 이유 자체가 사라짐.
- **SL-3**: `:List` reconcile의 `nil`/키 소멸은 다시 파괴, 값 교체와
  `PopOnly`만 비파괴. `State<Slot>` 교체가 언마운트인 것은 그대로 유지되게
  세 경로를 표로 갈랐다(`:Single` sugar가 교체 경로를 타므로 자동으로 안전).
- **BS-2+N-9**: "이벤트 콜백 시그니처는 Luau가 검증 못 한다"가 거짓 —
  사용자가 반례 코드를 직접 작성해 보여줌. `onchange-plan.md`가 이 전제를
  근거로 쓰던 자리도 근거만 교체(결론은 유지: `OnChange`는 필드가 아니라
  팩토리라 타입을 미리 찍어둘 자리가 없다). 겸해서 `New` 커링 계약과
  "`D`는 전량 코드 생성된 순수 별칭 테이블"을 명문화.

**(3) 이름/표면**

- **N-8 `DI` → `D`(Declarative)** 확정 — 코퍼스 전수 반영(네임스페이스는
  `D`, "특수 DI 키"라는 설명 표현은 "특수 키"로 단순화). 2026-08-08부터
  개명을 미뤄온 유일한 사유(한 글자 식별자의 검색성)는 **"문서에서 처음
  나올 때 항상 `D`(Declarative)로 풀어쓴다"** 표기 규약으로 보완하고
  `architecture.md`의 네이밍 케이싱 절에 4번 항목으로 넣었다.
  `question.md`의 1순위 항목은 `archive/question-resolved.md`로 이전.
- **N-5** `Attribute.Merged`(겹치면 error) / `Attribute.Overridden`(뒤가
  이김) **둘 다 제공** — 열려 있던 "error냐 override냐"가 제3안으로 해소.
  덤으로 `Merged`/`Overridden`이라는 이름 쌍의 의미가 코퍼스에서 재정렬됨
  (연산의 종류 → 충돌 시 정책).

**(4) 나머지** — A-3(`New()` 자동 스코핑이 아니라 `Quad()` + 코드 수정
필요), D-1(방어 가드 "죽은 코드"에 한정 추가), D-5(`PreRef`는 배열 우선
보장 위가 아니라 별도 pre-pass), M-3(예약 필드가 `Apply` 하나가 아니라
셋 + `Overridden`은 콜론도 가능), B-1(`Brand`는 무의존 — `None` 특수 분기
기각), R-3(`ProcessedPreRef` 센티널), SL-1(`RefLeafHandler`에 `k` 체크
추가 + 배열 전용 근거 명문화), E-2(`:Unsubscribe()`는 `:Subscribe()`의
짝으로 축소), N-1(FALLBACK 에러에 `k` 타입), N-2(타입이 방어선), N-3
(`Quad.debug`), N-6(`SetAndDispose` 후보), N-7(UI 숏핸드는 `Relate`로
조회), 부수 오탈자 2건(`.value` 케이싱, `fn(value, previous)` 표기).

## 열어둔 것 (착수 금지 게이트)

`question.md` 3번과 `todos.md` 00번이 소스 — 중간 State GC 미검증(M3),
그룹 `Attribute` 위치별 claim 키 설계(M10), `SetAndDispose` 방향(M3 전),
dedup 경로의 process/retract 대칭 확인(M3 전), `PopOnly` 이름,
`Store` 미선언 키의 타입 에러 실측(M0).

## 커밋 전 검증 — 감사자 1패스 + `/code-review high`

**`quad-doc-auditor` 1패스(base 코퍼스 각도)**: 확실 발견 1건 —
`ref-plan.md`가 "원래부터 빈 자리인 `None`은 **여전히** 두 패스 루프가 직접
건너뜀"이라고 남겨둔 문장이 같은 파일의 2026-08-18 배너와 정면 모순
(정확히 "배너는 고쳤는데 그 배너가 부정하는 본문 bullet은 안 고친" 실패
패턴). 수정 완료.

**감사 비용 이슈로 나머지 각도는 중단** — 한 패스가 서브에이전트 토큰
21만/툴 호출 82회였다. 감사자 정의가 "코퍼스 **전체**를 신선한 맥락에서
다시 읽는다"인 데다(라이브 문서 91개, `base/`만 ~12,000줄) 이번 프롬프트가
바뀐 결정 16개를 교차 검증하라고 시켜서, 계획대로 4개를 돌렸으면 80만
토큰대였을 것. **다음에 큰 변경을 감사할 때는 전 코퍼스가 아니라 diff가
건드린 파일 + 그걸 인용하는 곳으로 범위를 좁혀 프롬프트할 것.**
(부수: `/model`이 opus로 보여 감사자가 opus로 도는지 의심됐는데, 정의
frontmatter는 `model: sonnet`이고 오버라이드도 안 넘겼다. 다만 **이번
실행이 실제 sonnet이었는지는 확인 못 함** — 이 세션 트랜스크립트에
sidechain 레코드가 안 남았다. `todos.md` 7번의 "정의가 언제/얼마나
반영되는지 모른다"가 여전히 유효.)

**사용자가 `/code-review high`를 직접 돌림 — 10건 전부 유효**했고 전부
반영했다. 감사자가 못 잡은 것들이라 **두 도구가 서로를 대체하지 않는다는
게 실측으로 드러난 라운드**(감사자는 코퍼스 전체 정합성, code-review는
diff 자체의 결함):

- **[high] `ROADMAP.md`가 SL-3 역전을 안 따라옴** — `unmountSlotTree`를
  "`:List`의 reconcile"이 쓴다고 그대로 적혀 있었음. M8 체크리스트를 보고
  구현하면 정확히 이번에 되돌린 결함을 다시 만든다.
- **[medium] `modifier-plan.md` §5 / `attribute-plan.md` 근거 문단**이
  기각된 "문자열 폴백"과 "자주 쓰는 ~25개"를 근거로 계속 인용.
- **[medium] `GetDynamic` 콜론 메소드가 Store의 lazy `__index`와 충돌** —
  아무 장치 없이 부르면 `"GetDynamic"`이라는 이름의 Source를 만들어 함수로
  호출하게 됨. 예약 키가 되거나 탑레벨 함수여야 함 → **새 열린 질문**.
- **[medium] ROADMAP에 이번 라운드의 새 표면이 통째로 누락**
  (`Attribute.Overridden`/`Quad.debug`/`GetDynamic`/`PopOnly`) → 전부 추가.
- **[medium] `PopOnly` 계약과 의사코드 불일치** — 키가 사라지면 홀드 중이던
  요소가 파괴도 반환도 안 되고 참조만 끊김 → **새 열린 질문**.
- **[low] `NilHandler`의 `setLength`/`setOffsetSource` 호출 순서가 같은
  문서의 해제 순서 계약과 반대** → 뒤집음. `ProcessedPreRef`/`PostRef`
  핸들러도 같은 순서 오류가 **이번 세션 이전부터** 있어서 같이 고침.
- **[low]** `architecture.md` 정정 배너가 원문을 "콜론"이 아니라 "콜백"
  메서드로 오인용(정정하려는 문장의 뜻이 뒤집힘), ROADMAP 433행에 리네임
  전 "대기 중/잠정 표기" 잔여, `documentation-content-map.md`가 `D` 스윕에서
  누락.

## 도구/절차 메모

- `doc-check.py`: 처음 돌렸을 때 ERROR 6건 — 전부 **내가 절 제목을 바꾸는
  바람에 다른 문서의 인용이 깨진 것**과, ROADMAP blockquote 안에서 인용을
  줄바꿈에 걸친 것(`conventions.md`가 이미 경고한 실패 모드를 그대로 밟음).
  고쳐서 **ERROR 0**, WARN 8은 전부 이 세션 이전부터 있던 것.
- 그 QA 문서는 지우지 않고 **근거 기록으로 격하**(상단
  배너 교체) — 사용자 답변 원문이 그대로 남아 있어야 나중에 되짚을 수 있음.

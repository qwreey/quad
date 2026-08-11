<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-11 네 번째 세션 — `Slot:List`가 형제 순서(`LayoutOrder`)를
자동으로 안 세팅하는 것으로 정정, `updateFn`에 `index`/`offset` 추가

사용자가 "`Slot:List`의 `updateFn`이 자기 자신 Slot을 얻을 방법이
없는데, 그럼 offset을 못 보는 거 아니냐"고 질문하며 시작 — 처음엔
"Handler(quad-roblox `Handlers/Slot.luau`)가 `rawAdd`/`rawMove` 시점에
`localIndex+offset`을 자동으로 계산해 마운트된 원소의 `LayoutOrder`에
직접 바인딩해준다"고 답했으나(2026-08-09 여섯 번째 세션 `bind-system-plan.md`
"Length/Offset" 절의 원 서술 그대로), 사용자가 이건 **매직**이라고
바로 반박 — 컴포넌트가 `Frame { LayoutOrder = 5 }`처럼 자기 프로퍼티로
이미 지정한 값을 Slot이 마운트 시점에 조용히 덮어쓰게 되고, 애초에
"`updateFn`이 동적 요소를 전부 다룬다"는 게 원래 설계 의도였다는 것.

**확정**: Slot/Handler는 `LayoutOrder`를 자동으로 세팅하지 않음 —
`Slot.Offset`(`Slot.Length`와 마찬가지로 공개 필드, Slot 마운트 시점에
`Dispatch.setOffsetSource`가 등록하는 바로 그 Source를 `self.Offset`으로도
저장)과 `index`(이제 `State<number>`, "이 key가 지금 실제로 마운트된
요소들 사이에서 몇 번째냐" — `keyFn`이 받는 raw `data` 배열 인덱스와는
다른, filter로 압축된 값)를 `updateFn`에 값으로 전달만 하고, 실제로
`LayoutOrder`(로블록스)든 CSS `order`(웹, 필요할 때만)든 어디에 어떻게
쓸지는 전부 `updateFn` 작성자 몫 — `index:With(offset):Compute(fn)`을
평범한 프로퍼티 store-bind로 써넣으면 됨, 새 메커니즘 아님. 수동 CRUD로
Slot을 쓰는 사용자도 `slot.Offset`을 직접 읽어 같은 걸 스스로 구성 가능.
부수적으로 `setOffsetSource` 자체가 순수 숫자 계산이라 원래도 엔진 지식이
필요 없었다는 것도 재확인 — `LayoutOrder` 자동 바인딩을 그 옆에 서술했던
게 레이어링(엔진 무관 `Dispatch/Slot.luau` vs Roblox 전용 `LayoutOrder`)
위반이기도 했음.

**`updateFn` 시그니처도 같이 정리**: `offset`/`index`(State화) 추가하면서
파라미터 순서를 반환값 순서와 맞춤(사용자 지적) — 반환이 `(result, ud)`
(`prev`류 먼저, `userdata`류 나중)인데 기존 파라미터는 `userdata`가
`prev`보다 앞이라 뒤집혀 있었음, `prev, userdata` 순서로 정정:

```lua
updateFn<UD = any>(item, index: State<number>, offset: Source<number>, prev: T?, userdata: UD?): (T | nil, UD?)
```

**부수 발견 — 기존 `reconcile` 의사코드에 실제 버그가 있었음.** `index`를
진짜 값으로 노출하려다 보니, `rawAdd(self, result, i)`가 raw `data` 루프
인덱스 `i`를 그대로 위치 인자로 썼던 게 문제로 드러남 — filter로 앞쪽
item이 마운트 안 되면 실제 마운트된 개수가 `i`보다 적어져서, `Add`의
"범위 밖 index는 clamp 없이 error" 규칙에 걸려 그냥 터짐. `reconcile`
안에 "지금까지 실제로 마운트된 개수"만 세는 별도 압축 카운터(`pos`)를
추가해 `rawAdd`/`rawMove`/`keyIndex`/`index` State 전부 이 값 기준으로
통일 — filter 없이 순서대로면 `pos == i`라 흔한 경우엔 체감 차이 없음.

전부 `base/bind-system-plan.md`(`setOffsetSource` 절, "Slot.Length와
Slot.Offset은 별개" 절)/`base/slot-plan.md`(`:List` 파라미터 설명, 신규
"왜 `LayoutOrder`를 Slot이 대신 안 해주는가" 절, `activateList`/`reconcile`
의사코드 전면 수정) 반영 완료.

**같은 세션 후속 — `index`도 State가 아니라 raw number로 재정정,
`candidateIndex`로 이중 write 제거.** 사용자가 "reconcile은 sync라
깜빡임 문제는 없지만, filter로 항목이 새로 보이게 되면 그 뒤 index를
다 밀어줘야 하는데 Set이 반복적으로 도는 게 비효율 아니냐"고 재질문 —
검토 과정에서 사용자가 직접 더 나은 방향을 제시: `index`도 `item`과
똑같이 raw number로 넘기고, 반응형으로 쓸지·언제 `:Set`할지는 전부
`updateFn`이 자기 `userdata` 안에서 알아서 판단하게 두면 되지 않냐는
것 — 채택. 이러면 `:List`가 `indexState`라는 별도 맵을 관리할 필요
자체가 없어짐(`item`을 raw로 넘기는 것과 완전히 같은 원칙으로 통일,
"왜 `Source`를 `:List`가 안 만드는가" 절이 원래도 "item/index" 둘 다를
언급하고 있었던 것과도 재정합).

**`candidateIndex` 트릭으로 chicken-and-egg 문제도 해소**: `updateFn`에
넘기는 `index`가 필요한 시점엔 아직 이 item이 살아남을지(필터 통과
여부) 모르는데, 압축 위치(`pos`)는 원래 "생존자 개수"라 이 item 자신의
생존 여부에 의존하는 것처럼 보였음 — 그런데 실제로는 **"이 item이
살아남으면 차지할 위치"는 직전까지 처리된 item들의 생존 개수만으로
이미 계산 가능**(이 item 자신의 결과와 무관)하다는 걸 확인 —
`candidateIndex = pos + 1`을 `updateFn` 호출 **전에** 계산해서 넘기고,
`result ~= nil`일 때만 `pos = candidateIndex`로 커밋. `updateFn`은 항상
정확한 최종값을 받으므로, 새로 생기는 원소를 처음부터 `Source(index)`로
올바르게 만들 수 있어 "임시값으로 등록 → 나중에 Set으로 정정"하는
이중 write가 구조적으로 없어짐(브랜드 뉴 원소에 대해서도) — look-ahead
(아직 안 본 뒤쪽 item을 미리 훑는 것) 없이 여전히 단일 forward pass.

전부 `base/slot-plan.md`(`updateFn` 시그니처를 `index: number`로 재정정,
신규 "왜 `LayoutOrder`를 Slot이 대신 안 해주는가" 절에 `userdata` 기반
예시 코드 추가, `activateList`/`reconcile` 의사코드에서 `indexState` 맵
전부 제거하고 `candidateIndex` 방식으로 교체) 반영 완료.

**같은 세션 세 번째 후속 — 예시 코드의 남은 낭비 하나를 사용자가 재정정.**
`Source(index)`/`Set(index)` 분기를 `if not layoutOrder ... elseif` 식으로
"Source 재사용 여부"만 갖고 나눴던 첫 예시가, "원소를 다시 그리는지
(`prev == nil`)"와 독립적으로 갈려서 — `prev == nil`(새로 그림)인데
`ud.layoutOrder`는 남아있는 경우(직전에 filter 탈락했다 재등장) 이전
Source를 재사용하며 `:Set()`한 뒤 새 Frame을 만들면, 그 `:Set()` 시점엔
아직 아무도 그 Source를 구독하고 있지 않아 완전히 무의미한 연산이 됨
— 사용자 지적: "updateFn이 실행되기 전까진 이번 item이 버려질지/다시
그려질지/source만 갱신될지 아무도 모르니 미리 Set을 해둘 수 없고,
`updateFn` 자신만 이 세 갈래를 정확히 알아서 효율적으로 나눌 수 있다."
예시를 `if not shouldShow ... return nil / if not prev then <새 Source로
다시 그림> / <기존 Source 재사용, 실제로 다를 때만 Set>` 세 갈래로 재작성
— "다시 그림" 갈래는 이전 Source를 절대 참조 안 하고 항상 `Source(index)`로
새로 만듦.

**같은 세션 네 번째 후속(핸드오버 정리) — 용어 혼동 방지 문서화, 전체
코퍼스 stale 감사·`ROADMAP.md`/`README.md` 동기화.** 사용자가 "`key`와
`index`가 헷갈리지 않게 문서화에 유의, `updateFn`이 명시적 책임이 많은
함수라 문서화가 중요하다, 이 세션 내용 누락/stale 없는지 보고 핸드오버
준비하라"고 요청 — `base/slot-plan.md`의 `Slot:List` 절 최상단에 세
가지 값(1. `keyFn(item, index)`의 raw `index` — 원본 `data` 배열 위치,
2. `key` — `keyFn`이 계산하는 정체성, 3. `updateFn(item, index, ...)`의
`index` — `key`와 무관한 압축된 마운트 위치, 순서 계산 전용)을 이름이
겹치는데 서로 다르다고 명시하는 콜아웃 신설, `keyFn`/`updateFn` 파라미터
설명 각각에도 교차 참조 추가. `updateFn`의 반환 갈래 서술(구 "prev 그대로/
새 값/nil 반환")도 위에서 확정된 "버림/다시 그림/source만 갱신" 세
갈래 이름으로 통일해 같은 개념이 두 가지 다른 말로 서술되던 걸 정리.
`base/bind-system-plan.md`의 `setOffsetSource` 예시(`index:With(offset)`
— `index`가 State인 것처럼 잘못 읽히던 stale 표현)도 `layoutOrder:With(offset)`
(사용자가 `userdata`에 직접 관리하는 Source)로 정정. `ROADMAP.md` M6/
`.claude/README.md`의 `Slot:List` 요약이 이번 세션 이전 시그니처
(`updateFn<UD>(item, index, userdata, prev)`, `offset` 없음, `LayoutOrder`
자동 처리 여부 미언급)로 멈춰 있던 것도 최신 상태로 동기화.

`.claude/luau-test/`류 새 실측 항목은 추가되지 않음(이번 세션은 런타임
로직/시그니처 설계이지 Luau 타입 시스템 경계 확인 대상이 아님) — 기존
`userdata = userdata or {}` lazy-init 제네릭 narrowing 실측 필요 항목은
그대로 유효(M0/M6 착수 시 확인).

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선) — 이번 세션도 `:List` 세부 설계 정정/문서 정리라 M0 착수 우선순위
자체는 그대로.

**같은 세션 다섯 번째 후속 — `key` 타입 무제약 확인, `item.id` 관용구
문서화.** 사용자가 "캐스케이드 갱신을 막고 싶으면 `keyFn`은 string 등
unique하기만 한 값이면 되는 거 맞지, `data` 안에 string 필드가 있으면
그걸 쓰면 된다" 확인 요청 — 맞음(`key`는 Lua 테이블 키로만 쓰여서 타입
제약 없음, 필요조건은 사이클 간 안정성+유일성뿐). `keyFn`이 `item`을
그대로 받으므로 `item.id`처럼 이미 있는 안정적 필드를 그냥 반환하면
됨(새로 뭘 만들 필요 없음). `base/slot-plan.md`의 `keyFn` tradeoff
단락에 이 확인과 `function(item) return item.id end` 관용구 예시를
명시적으로 추가.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선).

**같은 세션 여섯 번째 후속 — 중복 `key` 즉시 `error`로 확정.** 사용자가
"`reconcile`이 이미 `seen[key] = true`를 하니까, 그 앞에 `if seen[key]
then error end`을 두면 거의 공짜로 중복 key를 잡을 수 있지 않냐"고
제안 — 채택. 조용히 넘어가면 두 item이 `mounted`/`userdata`/`keyIndex`의
같은 슬롯을 다투는 조용한 버그가 되므로, 다른 Slot CRUD 에러 조건들과
같은 fail-fast 톤으로 그 자리에서 막음. `base/slot-plan.md`의 `reconcile`
의사코드와 `keyFn` tradeoff 단락에 반영 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, luau-test 결과 확인
우선).


# [역전됨] `StoreSource` 프록시 설계 — Source가 State를 만족하는 서브타입으로 대체됨

**역전 일시**: 2026-08-06 (세 번째 세션). **원 확정 일시**: 2026-08-04
(`component-composition-plan.md` 컴포넌트화 논의 3~4번 항목).
**현재 유효한 설계**: `base/store-semantics.md`의 "Source가 State를
만족함 — 구조적 서브타입" 절이 최종 소스. 이 파일은 더 이상 능동적으로
참고할 필요 없음(구현에 안 씀) — 왜 이 경로를 갔다가 되돌아왔는지가
`quadnomicon`(프레임워크 설계자용 심화 콘텐츠, `research/documentation-plan.md`
0번 항목) 소재로 가치 있어서 사유·원문을 통째로 보존해둔 것.

## 역전된 사례 — 원래 무엇을 확정했었나 (2026-08-04 원문)

`store.key`로 값을 얻을 때, Store가 내부 Source 객체를 **직접 노출하지
않고** 별도의 얇은 프록시 타입 `StoreSource`를 만들어 반환하는 설계였음:

> **Source = 인터페이스이자 구현체**: 독립 생성자 `Source(initial)`가 기본
> 구현체, `store:GetSource("key")`(가칭)류 접근자가 반환하는 값은 같은
> 인터페이스를 구현하는 별도의 얇은 프록시(`StoreSource`) — 읽기는
> `store.key`로, 쓰기는 `store.key = v`로 위임. **내부 Source 객체를 그대로
> 노출하지 않음** — 그러면 "쓰기는 오직 Store의 `__newindex`뿐"이라는 기존
> 확정과 새 쓰기 경로가 충돌하게 됨.
>
> **캐시 안 함**: State가 이미 "매번 새로 만듦, store에 캐시 안 됨"으로
> 확정돼 있어 일관성 + 엔지니어링 비용 둘 다 이쪽이 쌈 — **사용자 확정**
> ("그냥 엔지니어링적으로 비용이 싼거 택해").

같은 논의에서 파생된 핸들러 계약 쪽 결정도 같이 뒤집힘 — Source를 핸들러가
직접 받을 때는 별도 유니온 타입으로 처리하기로 했었음:

> 핸들러가 값을 받을 때 `Source<T> | State<T>` 유니온으로 받고, 내부에서
> 타입 체크만 하면 됨(Source면 인스턴스 변경 이벤트에 걸어 역방향 쓰기까지
> 처리, State면 읽기만) — `isHandlable`/`priority`/`process`/`retract` 4종
> 계약에 5번째 항목을 추가할 필요 없음.

## 역전된 이유

`store.key`의 타입 문제를 다시 들여다보다가 드러남: Store의 정적 타입을
`{key: State<number>}`류 평범한 레코드 타입으로 지으면(2026-08-04 3차
라운드에서 확정했던 방식) Luau 구조적 타이핑상 그 필드의 읽기/쓰기 타입이
같아야 하는데, 실제 쓰기(`store.key = value`, raw `number`)와 읽기
(`State<number>`)가 서로 다른 타입이라 애초부터 정합적이지 않았음 —
`StoreSource` 프록시 설계 시점엔 이 비대칭을 못 잡았던 것.

이걸 풀려고 대안(store를 `store.key`/`store.state.key`로 네임스페이스
분리하는 안, `RefSource<T>`라는 store 전용 타입을 새로 만드는 안)을
검토하다가, 더 근본적인 재구성으로 수렴: **Source 자체가 구조적으로
State를 만족**(Svelte `Writable<T> extends Readable<T>`와 같은 모양)
하게 만들면,애초에 "Source를 감추고 별도 프록시로 감쌀" 이유 자체가
없어짐 — Store가 내부에 갖고 있는 진짜 Source 객체를 그대로 돌려줘도
안전하고, 오히려 프록시 객체를 매번 만들거나 캐싱하는 계층 하나가 통째로
사라져서 더 쌈.

## 이전 것과 지금 것의 차이

| | `StoreSource`(역전됨) | Source가 State를 만족(현재) |
|---|---|---|
| `store.key`가 반환하는 것 | 별도 프록시 `StoreSource`(Source 인터페이스를 구현한 wrapper) | 진짜 `Source<T>` 객체 그대로 |
| 쓰기 문법 | `store.key = value`(`__newindex`) | `store.key:Set(value)` |
| 캐싱 | "매번 새로 만듦"(State와 같은 정책) | Store 생성 시 이미 만들어둔 Source를 그대로 반환 — 별도 캐싱 메커니즘 자체가 불필요 |
| 핸들러가 Source를 받는 방법 | `Source<T> \| State<T>` 명시적 유니온 | `State<T>` 하나만 받아도 서브타입 호환으로 자동 통과, 런타임에 구분하고 싶으면 `isSource`류 판별자 |
| 타입 정합성 | 레코드 필드 읽기/쓰기 타입 비대칭 문제가 잠재해 있었음(발견 안 된 채로 확정됐었음) | 필드 타입이 항상 `Source<T>`로 대칭 — 쓰기가 메소드 호출로 옮겨가며 문제 자체가 해소됨 |

## 왜 완전히 헛수고는 아니었나

`StoreSource`가 짚었던 문제의식(Store 내부 표현을 그대로 노출하면 안
될 수 있다, Source와 State는 다른 쓰기 권한을 가져야 한다)은 여전히
유효함 — "State/Source 경계 규칙: 파생이면 읽기전용, 원본이면 쓰기 가능"
원칙(`base/component-composition-plan.md` 2번)은 살아남았고, 결론만
"별도 프록시 타입을 만든다"에서 "Source 자체를 서브타입으로 승격한다"로
바뀐 것. 이 반전 자체가 "타입이 없던 v1 습관을 재검토 없이 typed 재작성에
그대로 가져오면 안 된다"는 더 큰 교훈의 구체적 사례이기도 함(사용자 회고,
`base/store-semantics.md` 참고) — `quadnomicon`에서 "설계가 왜 이렇게
반전됐는가" 사례로 쓰기 좋음.

# [역전됨] Tween = 우선순위 최상위 store-bind Dispatch 핸들러(`[Tween(key,tweenData...)] = storeValue`) — 값-레벨 `Tween<T>` 래퍼로 대체됨

**역전 일시**: 2026-08-10. **원 확정 일시**: 2026-08-04(로드맵 인수인계
라운드 전후, "확정된 방향: 트윈을 Store/반응 그래프 밖에 둔다" 최초 작성).
**현재 유효한 설계**: `research/tween-plan.md`(전면 재작성됨)가 최종 소스.
이 파일은 능동적으로 참고할 필요 없음(구현에 안 씀) — 왜 "Tween이 곧
범용 store-bind 핸들러"였던 모델에서 "Tween은 PropertyHandler가 소비하는
값-레벨 래퍼"로 넘어갔는지가 `quadnomicon` 소재로 가치 있어서 사유·원문을
통째로 보존해둔 것.

## 역전된 사례 — 원래 무엇을 확정했었나

**메커니즘**: Tween을 `[Tween(key, tweenData...)] = storeValue` 형태의
특수 bind key로 제공. `k`는 무엇이든 받고 `v`가 Store(반응형 값)인 경우를
잡아내는, **우선순위가 매우 높은 Dispatch 핸들러**. 처음 실행될 때는
그냥 바인드로 필드를 쓰지만, 이후에는 store 값을 핸들해서 바뀔 때마다
트윈을 처리:

```
[Tween(key, tweenData...)] = storeValue
```

핸들러 내부에서: (1) 라이프타임(`Connected`) 확인, (2) 사용자가 넘긴
함수들을 거쳐 실제 값(`realv`) 계산, (3) `Dispatch.retractUnder`로 자기
밑을 정리한 뒤 `realv`를 들고 `Dispatch.process(inst, k, realv)`를 재귀
호출 — "store 바인드는 pluggable 바인드를 재실행하는 래핑"이라는 원칙의
구체 사례.

**override 정책**: 기본값 Cancel, 나머지 세 옵션(오버라이드/삭제 후
재시작/끝점 이동 후 재시작)은 `retract(inst, k, v)`가 이전 값을 받아
처리 — 이 부분은 새 모델에서도 그대로 유지됨(PropertyHandler 내부
로직으로 위치만 이동).

## 왜 역전됐나

`research/pre-implementation-audit.md` 우선순위1-1이 지적한 구조적
모호함이 출발점 — 이 문서 전체에서 "`v`가 store인 값을 구독해 `realv`로
재귀 process하는" 범용 메커니즘의 유일한 구체 예시가 항상 "Tween"으로만
등장했음. 그런데 Tween(실제 애니메이션, override/cancel 정책)은 명백히
더 좁고 별개인 기능이라, `Frame { BackgroundColor3 = store.color }`처럼
애니메이션 없이 그냥 반응형으로 값만 바뀌길 원하는 가장 흔한 케이스가
(a) 결국 이름은 "Tween"인 파일을 거쳐가며 "애니메이션 없음"으로 처리되는
건지, (b) 각 핸들러가 범용 `Dispatch/StoreBind.luau` 유틸을 독립적으로
써야 하는 건지 문서가 정하지 않은 상태로 남아있었음.

2026-08-10 세션에서 사용자가 직접 제기한 재설계 방향("Tween 프리미티브를
`V`에 넣는 식, 최종 Property가 알아서 `V`가 `isTween`이면 트윈 넣도록")으로
해소 — State/Source 언랩(범용 StoreBind)과 "이 값이 트윈 대상인가" 판단을
완전히 분리해, 후자를 Dispatch 우선순위 경쟁이 아니라 PropertyHandler
내부의 평범한 값 분기로 옮김.

## 대체 모델과의 비교

| | 구 모델(우선순위 최상위 Dispatch 핸들러) | 신 모델(값-레벨 `Tween<T>` 래퍼) |
|---|---|---|
| 매치 방식 | `isHandlable(inst,k,v) = isState(v)` — Tween이 범용 StoreBind 역할까지 겸함 | 범용 `StoreBind`가 State/Source를 언랩, `Tween` 여부는 `realv`를 받은 PropertyHandler가 직접 판단 |
| "애니메이션 없는 일반 반응형 바인딩"의 정체 | 불명확(이름이 Tween인 파일을 거쳐가는지 문서가 안 정함) | 명확함 — 그냥 `Dispatch/StoreBind.luau`, Tween과 완전히 무관 |
| 핸들러 타입 전환 | Tween↔프로퍼티 핸들러 사이에서 실제로 바뀜 → `retract`가 이 케이스의 대표 예시였음 | 항상 PropertyHandler 하나만 매치 → 이 `retract` 케이스 자체가 사라짐, 전환은 3-상태 릴레이션 슬롯으로 내부 처리 |
| 트윈 대상 값 타입 | Store 전체(`T`뿐 아니라 임의 반응형 값) | `Tween<T> = {Value: T, ease...}` — `Value`는 plain `T`만, 반응성은 바깥 `:Compute`가 전담 |
| 진입 애니메이션 억제 | 별도 논의 없음 | 3-상태 슬롯(`RobloxTween\|true\|nil`)의 `hasBeenSet` 분기로 자동 해결 |

부수적으로, 이 역전은 Tag가 이미 겪었던 것과 같은 종류의 단순화 —
"핸들러 *타입*이 실제로 안 바뀌면 `retract`가 필요 없어진다"는 결론을
Tween에도 적용한 셈. Tag 역전(`archive/tag-hash-key-model-reversed.md`)이
"핸들러 타입이 안 바뀐다는 전제가 실사용에서 깨졌다"는 방향이었다면,
Tween 역전은 반대로 "핸들러 타입을 애초에 안 바뀌게 재설계해서 전제
자체를 성립시켰다"는 방향 — 같은 `retract`/핸들러-전환 문제를 서로
반대 방향에서 접근한 두 사례로 대비해볼 만함(quadnomicon 소재).

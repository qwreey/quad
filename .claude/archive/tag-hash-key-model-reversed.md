# [역전됨] Tag = 해시 파트 boolean DI 키(`[Tag "Name"] = true`) — array-part 값 객체로 대체됨

**역전 일시**: 2026-08-08 (세 번째 세션). **원 확정 일시**: 2026-08-07
여덟 번째 세션(`base/tag-plan.md` 최초 작성, "상태: base — 전부 확정").
**현재 유효한 설계**: `base/tag-plan.md`(전면 재작성됨)가 최종 소스. 이
파일은 능동적으로 참고할 필요 없음(구현에 안 씀) — 왜 "태그 하나당 키
하나"에서 "여러 태그를 조합하는 값 객체"로 넘어갔는지가 `quadnomicon`
소재로 가치 있어서 사유·원문을 통째로 보존해둔 것.

## 역전된 사례 — 원래 무엇을 확정했었나

**값 모양**: `[Tag "Name"] = boolean | State<boolean>` — 태그 이름 하나당
해시 파트 키 하나, 값은 store-bind 가능한 boolean.

**메커니즘**: `isHandlable`이 `[Tag "Name"]` 모양의 키를 매칭하는
`TagHandler` 하나로 충분. `process(inst,k,v)`가 `v`가 참이면 `AddTag`,
거짓/`nil`이면 `RemoveTag`. **`retract` 불필요**로 결론 — "값이 뭐든
(`true`/`false`/`nil`) 항상 같은 `TagHandler`가 이 키를 계속 담당하니
핸들러 *타입*이 안 바뀐다"는 게 근거였음.

## 왜 역전됐나

사용자가 실사용 시나리오를 제시하며 기각: 상호배타적인 스타일 상태
(`btn1`/`btn2`/`btn3`류, 실제로는 20개까지도 가능)를 표현하려면 이 모델은
**태그 이름 개수만큼 boolean 키를 각각 만들어야** 함 — 상태 전환마다
여러 키를 동시에 갱신해야 하고, 스타일 조합(여러 태그를 합쳐 쓰는 것)도
자연스럽게 표현이 안 됨. "하나의 값을 통째로 바꿔서 태그 집합을 바꾼다"는
요구를 이 모델은 구조적으로 못 담음.

## 대체 모델과의 비교

| | 구 모델(해시 파트) | 신 모델(array-part 값 객체) |
|---|---|---|
| 값 모양 | `[Tag "이름"] = boolean` | `Tag(...)`/`Tag.Merged(...)` 값 객체, array 슬롯에 놓임 |
| 상태 전환 | 태그 개수만큼 키 갱신 | 값 하나를 store-bind로 교체 |
| 조합 | 안 됨(키가 독립적) | `:Added`/`:Removed`/`Merged`로 조립 |
| retract | 불필요(핸들러 타입 안 바뀜) | 필요(값이 `nil`이 되면 핸들러 자체가 안 바뀜, 전체 삭제) — `Dispatch` 체인 메커니즘(`bind-system-plan.md` "Dispatch 체인" 절)과 맞물려 재설계됨 |

부수적으로, 이 역전이 `Dispatch.process`/`retract`의 "이전 매치 핸들러
추적" 문제(`pre-implementation-audit.md` 1-2번)를 실제로 파고드는 계기가
됐음 — Tag가 재귀 재-dispatch(`Source<Tag|nil>`가 store-bind를 거쳐
TagHandler로 위임)에 진입하는 첫 구체 사례가 되면서, "핸들러 타입이 안
바뀌니 retract 불필요"라는 구 모델의 전제 자체가 신 모델에서 깨졌고, 그
자리를 메우려다 `Dispatch.retractUnder`(체인 기반 retract 전파) 설계로
이어짐.

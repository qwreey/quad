# Tag 특수 키 — `CollectionService` 얇은 래퍼

**상태**: base — `[Tag "Name"] = true` DI 키의 존재 자체는 `architecture.md`
4번 항목에서 이미 확정. 이 문서는 UICorner 숏핸드(`base/ui-shorthand-plan.md`)/
Tween(`research/tween-plan.md`)처럼 별도 전용 문서가 없던 걸 2026-08-07
여덟 번째 세션에 메꾼 것 — Tag/Attribute도 "1 프리미티브 1 파일" 관례
(Blocker/Effect/Ref/PreRef 분리 선례)를 따라야 한다는 사용자 지적으로 신설.
새 설계 내용은 없음 — 이미 여기저기 흩어져 있던 결정을 한 곳에 모으고,
오늘 논의한 `None`/`process`/`retract` 동작을 반영.

## 값 모양

`[Tag "Name"] = boolean | State<boolean>` — store-bind 가능(일반 프로퍼티와
동일하게 취급). PA님의 `EventDrivenProgramming/Observer.luau`
`subscribeTaggedInstance`도 얇은 `CollectionService` 래퍼일 뿐이라
(`bind-system-plan.md` "PA님 코드와 대조" 절) **Instance 태그는
`CollectionService` 직접 사용 그대로 유지** — 별도 자체 태그 시스템(v1이
검토했던 것 같은) 안 만듦.

## 메커니즘 — 새 아키텍처 개념 불필요

`isHandlable`이 `[Tag "Name"]` 모양의 키를 매칭하는 `TagHandler` 하나로
충분:

- `process(inst, k, v)` — `v`가 참이면(`true`) `CollectionService:AddTag(inst,
  name)`, 거짓/`nil`이면 `RemoveTag(inst, name)`. `None → nil` 재디스패치
  (`base/bind-system-plan.md`의 `None` 센티널 절)가 그대로 이 경로를 탐 —
  `nil`을 "태그 없음"으로 자연스럽게 해석하면 되므로 특별 처리 불필요.
- **`retract` 불필요** — 값이 `true`/`false`/`nil` 무엇이든 항상 같은
  `TagHandler`가 이 키를 계속 담당(핸들러 *타입*이 안 바뀜), 추가/제거를
  전부 `process` 자신이 처리. `retract`는 "매치되는 핸들러 타입 자체가
  바뀌는" 경우에만 의미 있다는 게 확정된 원칙(`bind-system-plan.md`
  "확정된 디스패치 모델" 절, Tween↔일반 프로퍼티가 그 유일한 실사례) —
  Tag는 여기 해당 안 됨. **처음엔 이 문서 없이 "확정된 디스패치 모델"
  절이 Tag를 retract 필요 예시로 잘못 들었던 걸 여기서 바로잡음.**

## 패키지 배치

UICorner 숏핸드/Tween과 같은 판단 재사용 — 작고 항상 켜져 있어도 비용이
무시할 만한 기능은 `quad-roblox` 코어에 직접 포함(`base/ui-shorthand-plan.md`
"패키지 배치" 절 참고, 별도 opt-out 패키지로 안 쪼갬).

## 열린 질문

없음 — 값 모양/메커니즘/retract 여부 전부 확정. 이름 자체(`Tag`)는 이미
쓰기 시작한 v1/PA님 관례와 일치해 특별히 재검토 대상 아님.

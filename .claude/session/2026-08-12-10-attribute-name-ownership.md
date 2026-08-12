# 2026-08-12 열 번째 세션 — Attribute 이름 소유권, `rawNew` 전용 키로 그룹/직접 쓰기 충돌 방지

## 배경

앞선 세션들(여덟/아홉 번째, `Ref`/`Slot`의 store 재바인드 정정)의 흐름을
이어, 사용자가 `Attribute`도 같은 종류의 문제가 있는지 확인 요청 —
그룹 `Attribute(...)`도 `State<Attribute>`로 동적으로 바뀔 수 있는데, 이미
확정된 diff 메커니즘("사라진 이름만 nil, 남은/새 이름은 그대로 설정")
자체는 맞지만, **서로 다른 두 원본(직접 리터럴 `[AttributeKey "name"]=v`와
배열파트 `Attribute(store)`, 또는 서로 다른 두 그룹)이 같은 이름을 동시에
관리하려 하면 어떻게 되는가**가 빠져있다는 지적.

## 진단

`AttributeKey(name)`이 이름별 weak 캐시로 항상 같은 객체를 리턴하고,
그룹의 위임 메커니즘이 `Dispatch.process(inst, AttributeKey(name), source)`로
그 공개 캐시를 그대로 씀 — 즉 서로 다른 원본이 같은 이름을 다루면 정확히
같은 `(inst, k)` 디스패치 자리로 수렴함. Modifier 필드는 override로 정적
충돌이 이미 해소되지만(한 Modifier 안에 같은 해시 키 중복 불가), 그룹의
이름 집합은 런타임에 동적이라 이 해소망 밖에 있다는 게 확인됨 — 실제로
일어날 수 있는 구조적 충돌.

## 설계 논의

1차로 Claude가 별도 `Relate` 기반 `AttributeManageMap`(claimant 타입을
구분해 등록/체크)을 제안했으나, 사용자가 더 단순한 안을 제시: **그룹이
공개 `AttributeKey(name)` 캐시를 안 쓰고, 캐시를 우회하는 `rawNew(name)`로
이름마다 자기 전용 키 객체를 만들어 자기 자신(그룹의 릴레이션)에
캐싱** — 그러면 "이 이름에 지금 어느 키 객체가 적용돼 있는가"를 보는
것만으로 소유권 판정이 되고, `AttributeKeyHandler`에서 바로 처리 가능.
Claude가 이게 별도 claimant 타입 없이 AttributeKey 객체 identity 자체를
재사용하는 더 적은 부품의 설계임을 확인, 채택.

사용자가 추가로 확인 요청한 지점: 그룹 값이 교체될 때 diff가 "진짜
새 셋과 비교해 사라진 것만 nil화, 남은/새 이름은 그대로 갱신"으로
동작해야 이 메커니즘이 충돌 없이 맞물림 — 이미 확정된 diff 로직이 정확히
이 모양이라는 걸 재확인, 단 **전용 키 캐시가 그룹 값 교체를 넘어 계속
유지돼야만** 성립함을 짚음(매 교체마다 키를 새로 만들면 남아있는
이름조차 옛 키와 새 키가 달라 자기 자신과 충돌하는 꼴이 됨).

## 결정

- 그룹의 기존 "(inst, 배열 위치)별 마지막으로 쓴 attribute 이름 문자열
  집합" 릴레이션을 **"이름 → 그 이름 전용 키 객체 맵"**으로 확장(새
  릴레이션 아님, 저장 형태만 바뀜) — 이름이 살아있는 동안 캐싱된 같은
  키 객체를 재사용, 사라지면 그 키로 `retractUnder`, 새로 생기면
  `rawNew`로 새 키.
- `AttributeKeyHandler`는 per-inst `owners: Relate() -- {[inst]={[name]:
  현재 키 객체}}`를 들고, `process`에서 다른 키 객체가 이미 그 이름을
  쓰고 있으면 즉시 error, `retract`/nil 귀결 시 소유권 반납.
- 패키지 경계 문제 없음 — `AttributeKey`도, 그룹의 실제 위임 로직도 이미
  quad-roblox 소속이라 `rawNew` 호출이 새 역의존을 안 만듦.

## 반영

- `base/attribute-plan.md` — "이름 소유권" 새 절 신설(메커니즘 전문),
  "메커니즘 — per-name 전용 키로..." 절 갱신(공개 캐시→그룹 전용 키로
  정정, 캐시 영속성 조건 명시), "retract 불필요" 문단에 정정 각주 추가.
- `base/bind-system-plan.md` — 일반 retract 계약 절의 "Attribute는
  해당 안 함" 서술이 단일 키 경로에만 해당함을 명확화, 그룹의 이름 이탈은
  오히려 `Tag→nil`급 retract 케이스라고 추가.
- 다른 stale 참조(`onchange-plan.md`의 `AttributeKey(name)` 언급 등)는
  이 변경과 무관해 손 안 댐 — 확인만 하고 넘어감.

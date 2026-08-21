# [역전됨, 2026-08-21] `bindLifetime`의 첫 인자가 Slot일 수 있다는 요구사항

**상태**: 역전됨. 2026-08-20 구현 전 QA 4라운드 `D-56`에서 확정돼
`base/lifecycle-pattern.md`의 `(1-1)` 절로 들어갔다가, **2026-08-21 구현 전 QA
5라운드 `C-4`에서 통째로 뒤집혔다.**

**왜 뒤집혔나**: 사용자 지적 — *"애초에 Slot 이 effect 나 다른 요소들을 소유할
수가 없다 … 실제 observer/effect 는 실제 inst 에 불림. slot in slot 에서 slot 을
유지하는건 이미 slot 의 강참조 배열이 해결해주는데, 우리가 왜 slot 을 소유 대상으로
둘 수 있게 한거였는지 다시 생각해봐야할 부분인듯?"* 검토 결과 **부기 키와
생명주기 앵커를 한 인자가 겸하고 있던 게 원인**이었고, `Dispatch.setLength`가
`anchor`를 따로 받도록 바꾸는 것만으로 이 요구사항 전체가 사라졌다. 지금 유효한
결론은 `base/dispatch-core-plan.md`의 "`setLength` 구현" 절 뒤 문단과
`base/lifecycle-pattern.md`의 `(1-1)` 포인터.

**부수 효과**: 이 절이 요구하던 `isBoundAlive`의 "세 번째 분기"(gcconn도
`.Subscribed`도 없는 Slot-owned 바인딩을 판정하는 분기)는 **형태가 미정인 채로
열려 있던 항목**이었는데, 역전과 함께 필요 자체가 없어졌다.

---

## 역전 전 원문

#### (1-1) ⚠️ 첫 인자가 물리 Instance가 아닐 수도 있다 — 백엔드가 반드시 핸들링할 것 (2026-08-20 구현 전 QA 4라운드 `D-56`)

**위 구현 스케치는 `inst`가 항상 Roblox Instance라고 가정하고 `InstData`에서
gcconn/gchold를 찾는데, 실제 호출부 중엔 `inst` 자리에 `Slot`이 오는 경로가
이미 있다.** `Dispatch.setLength(ownerKey, i, len)`이 그것 —
`base/dispatch-core-plan.md`의 "`setLength` 구현" 절이 `bindLifetime(ownerKey,
observer)`를 부르는데, 그 `ownerKey`는 Slot-in-Slot 중첩에서 **Slot 자신**이다
(`base/slot-plan.md`의 "재귀 메커니즘" 절 — `attachSlot`이 `ownerKey`로 자기
자신을 넘겨 최상위/중첩을 같은 함수로 통합한 그 설계).

**사용자 판정(2026-08-20)**: *"ownerKey 가 Slot일 수도 있음. 각 엔진의
bindLifetime 은 이를 잘 핸들링 해줘야함. 즉, Slot안에, 또는 바깥에 SetStrong
으로 gchold 비슷한걸 수행하면 됨."*

- **계약 두 개(위 절)는 그대로 유지된다** — 바뀌는 건 "그 계약을 무엇으로
  구현하는가"뿐. 물리 Instance면 gcconn 트릭이 두 계약을 다 만족시키고,
  Slot이면 **Slot 자신이 살아있는 동안 `value`를 붙잡는 강참조**(Slot 안의
  필드든, `Relate(slot)`에 `SetStrong`이든)와 **`value`가 그 Slot의 생존을
  되물을 수 있는 근거**를 백엔드가 제공하면 된다.
- **왜 gcconn을 못 쓰는가**: gcconn 트릭은
  `inst:GetPropertyChangedSignal("ClassName")`에 의존하므로 엔진 객체가 아닌
  값(Slot은 평범한 Lua 테이블)엔 걸 수가 없다. Slot은 대신 **자기 자신이
  reachable한가**가 곧 생존이라, `Relate(slot)`가 weak-keyed인 것만으로
  "Slot이 죽으면 기록도 같이 사라진다"가 성립한다.
- **`isBoundAlive`의 판정 분기도 이 경로를 알아야 함** — 지금 코드는
  gcconn이 없으면 곧바로 `.Subscribed` 폴백으로 떨어지는데, Slot-owned
  바인딩은 gcconn도 `.Subscribed`도 없어서 **살아있는데 `canBound`가 참으로
  잘못 나온다**(= 이중 바인딩 가드가 이 경로에선 안 걸림). 백엔드 구현이
  세 번째 분기를 추가하거나, Slot 쪽 홀더 존재 자체를 판정 근거로 삼아야 함.
- **⚠️ 정확한 형태는 아직 미확정 — M2/M3 구현 시 확정할 것.** "Slot 안"(필드)
  이냐 "바깥"(`Relate`)이냐, `isBoundAlive`의 세 번째 분기를 어떤 모양으로
  둘지가 열려 있다. 지금 확정된 건 **"첫 인자가 Instance라고 가정하면 안
  된다"는 요구사항 자체**뿐.


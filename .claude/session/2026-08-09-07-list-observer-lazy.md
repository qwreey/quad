<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-09 일곱 번째 세션 — `Slot:List`의 `data:Observer(fn)` 구독도
마운트 시점 lazy `bindLifetime`으로 확정 (Destroy 후 재실행 gap 해소)

사용자가 "Slot이 마운트된 대상이 Destroy로 죽으면 `updateFn` 재실행이
`canExecute`로 막히고 있는 게 맞냐"고 질문하며 시작 — 확인 결과 **두 메커니즘이
다른 상태였음**: `Dispatch.setLength`(Length/Offset, 여섯 번째 세션 확정)는
이미 정확히 그렇게 돼 있었지만(Slot 마운트 시점에 `bindLifetime(inst,observer)`),
`Slot:List`의 `data:Observer(fn)` 구독은 `:List()` 호출 그 자리에서 즉시
만들어져(`inst`를 모르는 시점) `bindLifetime`이 전혀 안 걸려있던 실제 gap —
사용자가 정확히 캐치함. 사용자가 이어서 "실제로 Instance에 바인드되려 시도될
때(=마운트 시점)로 구독 자체를 lazy하게 미루면 되지 않냐"고 제안, 검증 후
확정. `base/slot-plan.md`(`:List`의 "구현"/"구독 시점" 절 재작성 +
"base/roblox 패키지 경계" 절 보강)/`ROADMAP.md`(M6)에 반영 완료:

- **`Dispatch.setLength`가 이미 쓰던 패턴을 그대로 재사용, 새 메커니즘
  없음.** `:List(data,updateFn,keyFn)`는 이제 설정만 저장하고 반환 —
  실제 `data:Observer(fn)` 구독과 최초 `reconcile`은 Slot 컨테이너 자신이
  마운트되는 순간(`Dispatch/Slot.luau`의 `process(inst,k,self)`, `self._mounted`를
  세팅하는 바로 그 자리)에 `activateList(self,inst)`가 수행.
- **`:List()`가 마운트 이후에 불리는 경우 — `self._mounted`면 즉시 활성화로
  확정(사용자 확인, 세 가지 대안 중 1번).** 마운트는 1회성 이벤트라 순서가
  뒤바뀌면 그 이벤트를 못 기다리므로, `:List()`가 `self._mounted`를 직접
  확인해서 이미 참이면 그 자리에서 즉시 `activateList` — 호출 순서 제약을
  새로 추가하지 않음.
- **canExecute와 "등록 즉시 1회 실행"의 관계를 사용자가 직접 짚어 확정**:
  `data:Observer(fn)` 등록 시점(=`bindLifetime` 호출 *이전*)의 최초 1회
  실행은 `canExecute`/`Subscribed` 게이팅과 무관하게 무조건 일어남 — 이
  시점엔 아직 `Subscribed`가 안 세팅돼 `canExecute`를 물으면 거짓이겠지만,
  애초에 최초 실행은 게이팅 대상이 아니라서 상관없음(`Dispatch.setLength`가
  이미 "등록 즉시 1회와 겹쳐도 무해"로 같은 구조를 갖고 있었음). `bindLifetime`은
  등록 직후에 걸려 **이후** 재실행만 게이팅.
- **Destroy 이후 "재실행 막기"+"관측 자체를 관두기"가 새 코드 없이 한 번에
  해결됨** — `inst` Destroy 시 `gcconn`이 죽어 `canExecute`가 거짓이 되고
  향후 재실행이 no-op되는 동시에, `gchold`가 `Relate(inst)`(weak-keyed)
  아래 있어서 `inst`가 죽으면 그 안에 강참조로 잡혀있던 Observer/클로저
  (`mounted`/`userdata`/`keyIndex` 포함)가 전부 GC 대상이 됨 — 명시적
  구독 해제 코드가 안 필요함, `lifecycle-pattern.md`의 "정리는 기본적으로
  GC에 위임" 원칙 그대로.
- **부수 관찰(메모만, 설계 아님)**: 사용자가 "`Relate`로 마운트된 대상을
  weak하게 구할 수도 있겠다"고 언급 — `bindLifetime`이 `Relate(inst)` 기반이라
  나중에 "이 `inst`에 지금 뭐가 붙어있는가" 역조회가 같은 저장소로 가능해
  보임, quad-debug 그래프 UX와 맞닿을 수 있음. 지금 설계 안 함, 필요성
  확인되면 그때.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계 확정이라 M0 착수 우선순위 자체는 그대로.


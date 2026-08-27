# [역전됨] `EffectHandle`의 내부 Observer 바인딩 세부 — `_observers` 배열 + `bindLifetime`/`:Subscribe()` cascade

> **역전일**: 2026-08-25(7라운드 `H-58`/`H-59`). **대체된 곳**:
> `base/effect-plan.md`의 "확정 구조 — 강한 주인은 항상 `Effect`" 절과
> "의사코드 — 생성자 / `bindLifetime`이 부르는 두 훅 / `Rerun`" 절 —
> `bindLifetime`/`unbindLifetime`은 **`Effect` 핸들 하나에만** 적용되고 내부
> Observer로 cascade하지 않는다. dep 등록은 생성자에서 한 번만
> `WeakSubscribe`/`WeakCallback`으로 하고, 발화 여부는 `canExecute(handle)`이
> 전담한다. 아래가 서술하는 `_observers` 배열/cascade/`Subscribe` 순회는
> 전부 `_deps` 하나와 `_blocker`로 대체됐다. **이 문단대로 짜면 `H-58`의
> 중복 `Rerun`이 되살아난다.**
>
> **왜 `archive/`로 왔나 (2026-08-27, 9라운드 `H-130`, 사용자 결정 Q7-(b))**:
> 이 블록은 `base/effect-plan.md` 안에 ⛔⛔ 폐기 배너를 단 채 남아 있었는데,
> 배너 아래 죽은 문단을 **두 번**이나 살아 있는 문장처럼 편집하는 사고가
> 났다(8라운드 2차 #1, 그리고 커밋 `9dd8213`이 아래 40번째 줄 근처의
> *"`.Subscribed`는 구독 경로 전용"*을 날짜 마커 없이 고친 것 — 옛 표기는
> *"전역 `:Subscribe()` 전용"*). `conventions.md`의 핸드오버 체크리스트 3번
> (*"뒤집힌 원문은 `archive/`로 옮기고 포인터만 남길 것"*)이 정확히 이
> 실패 모드를 규정하고 있어 그대로 따랐다. 아래는 **옮기는 시점의 원문
> 그대로**(그 편집 흔적 포함)이고, 더 이상 갱신하지 않는다.

## 옮겨온 원문 (`base/effect-plan.md`, 2026-08-27 시점)

**보강 — `EffectHandle`의 내부 Observer 바인딩 세부(2026-08-09 열한 번째
세션, 재확인 후 명시화)**:

> **⛔⛔ [2026-08-25 폐기, 7라운드 `H-58`/`H-59`] 이 문단 전체는 옛 모델이다.**
> 위 "확정 구조 — 강한 주인은 항상 `Effect`" 절이 **정반대로** 확정했다 —
> **`bindLifetime`/`unbindLifetime`은 `Effect` 핸들 하나에만 적용되고**
> 내부 Observer로 cascade하지 않는다. dep 등록은 **생성자에서 한 번만**
> `WeakSubscribe`/`WeakCallback`으로 하고, 발화 여부는 `canExecute(handle)`이
> 전담한다. 아래가 서술하는 `_observers` 배열/cascade/`Subscribe` 순회는
> **전부 `_deps` 하나와 `_blocker`로 대체됐다**(위 "필드 목록").
> 아래는 히스토리로만 읽을 것 — **이 문단대로 짜면 `H-58`의 중복 `Rerun`이
> 되살아난다.**

**⚠️ [2026-08-24 6라운드 손 트레이싱 `H-8`, 2026-08-25 폐기] 이 문단 전체가 아직 "Observer 하나"
전제로 쓰여 있었다 — `_observer`(단수)를 `_observers`(배열)로 읽을 것.**
아래 절이 확정한 `Effect(fn, ...deps)`(N-deps)와 정면으로 어긋났고, 그대로
구현하면 **2번째 이후 dep의 Observer엔 `canExecute` 판정 근거가 아예 안 실려**
그 Observer의 재실행이 통째로 죽는다 — 바로 이 문단 자신이 경고하는 실패
모드다. 필드를 배열로 바꾸고 cascade/`Subscribe`/`Unsubscribe`를 전부 순회로
고친다(새 결정 없음, 반영 누락). `Ref` dep은 Observer가 아니라 콜백이라 이
배열에 안 들어간다 — 그쪽 해제는 아래 `H-7` 문단이 소스.

- **`EffectHandle`은 내부 Observer를 필드로 강참조** — `handle._observers[i] =
  observer`(dep이 State/Source인 경우만 존재). 이건 GC 방지가 목적이 아니라
  (그건 아래 `bindLifetime`/`gchold`가 담당) `:Unsubscribe()`/`bindLifetime`
  cascade가 이 필드를 통해 내부 Observer에 접근하기 위한 것.
- **`bindLifetime(inst, handle)`은 `state`가 있는 경우 내부 Observer도
  같은 `inst`로 `handle._observers` **전부**에 대해
  `bindLifetime(inst, observer)`를 cascade해야 함** — `Dispatch/Leaf.luau`가 children 배열의 `EffectHandle`을 매치해
  `bindLifetime(inst, handle)`을 부르는 시점(leaf 부착)과, `:Subscribe()`가
  `handle`을 전역 레지스트리에 등록하는 시점(아래) 둘 다 해당. 이유:
  `canExecute(observer)`가 보는 gcconn 참조는 **그 Observer 자신이
  `bindLifetime(inst, observer)`될 때 그 Observer 쪽 릴레이션에
  복사되는 것**이라, `EffectHandle`만 바인드하고 내부 Observer는 안 하면
  그 Observer에겐 판정 근거가 아예 없어서 `canExecute`가 항상 거짓이 됨
  (=재실행이 통째로 죽음). 같은 이유로 `unbindLifetime(handle)`도 내부
  Observer까지 같이 풀어야 대칭이 맞음.
  **[정정, 2026-08-14 다섯 번째 세션]** 이 항목이 원래 근거로 든
  "`canExecute`가 `Subscribed` 필드 + `inst`의 gcconn을 함께 본다"는
  틀렸음 — `.Subscribed`는 구독 경로 전용이고 leaf 경로와
  무관(`archive/canexecute-inst-arg-reversed.md`). cascade가 필요하다는
  결론은 그대로이고 오히려 근거가 더 직접적이 됨.
- **`:Subscribe()`도 마찬가지로 `state`가 있으면 내부 Observer를 같은
  전역 강참조 레지스트리에 같이 등록**(`handle` 자신 + `handle._observers`
  전부, 또는 `handle._observers`만으로 충분한지는 구현 세부 — 어느 쪽이든
  "`EffectHandle`은 등록됐는데 내부 Observer는 등록 안 됨" 상태가 생기면
  안 됨).


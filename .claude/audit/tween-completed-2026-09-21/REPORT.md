# `TweenBase.Completed` 실측 — 2026-09-21

**계기**: `research/docs-review-2026-09-14.md` 1-5(트윈 완료 신호가 없다는 사실) — 사용자 잠정 의견: "흔한 요소이고 breaking 없이
추가해줄 수 있는 부분", `Tween`에 `OnStarted`/`OnCompleted`/`OnCancelled`를 두되 세 가지를 먼저 실측할 것(인스턴스가 죽을 때 연결이
자동으로 끊기는가 / 완료된 트윈을 retract가 무판단 `Cancel`하면 non-running 상태에서 Cancelled가 나는가 / Deferred 이벤트에서
Cancelled→Started→Completed 순서가 안정한가). 사용자 원문은 그 문서 1-5 `->` 줄.

**환경**: Studio Edit 스레드(샌드박스 `Place1.rbxl`), 이벤트 Deferred. 1~6은 sonnet 탐사자(`probe-log.md`가 원문 로그), 7·8은
탐사자 코드가 무효라 메인이 다시 쟀다(아래).

## 사실

1. **자연 완료** — `Completed(Enum.PlaybackState.Completed)`가 정확히 한 번, `PlaybackState`는 `Completed`.
2. **완료된 트윈에 `:Cancel()`** — `Completed`가 **다시** 난다(`Cancelled`). 프로퍼티 값은 목표값 그대로(되돌리지 않음). 그러니
   지금 retractor의 무조건 `prev.Tween:Cancel()`(철거·값 교체)은 이미 끝난 트윈에도 Cancelled 통지를 한 번 더 만든다 — 엔진
   시그널로 `OnCancelled`를 만들면 이 이중 발화를 걸러야 한다.
3. **실행 중 `:Cancel()`** — `Completed(Cancelled)`는 나지만 **deferred**: `Cancel()`은 동기로 돌아오고 통지는 다음 yield에서 온다.
4. **교체 순서** — yield 없이 `A:Cancel()` → 마커 → `B:Play()`를 하면 관측 순서는 **마커(B 시작) → A Cancelled → B Completed**.
   `Cancel`과 `Play` 사이에 `task.wait()`를 끼우면 A Cancelled가 `B:Play()` 전에 온다. 즉 **엔진 시그널만으로는
   Cancelled(이전) → Started(다음) 순서가 보장되지 않는다** — 사용자가 우려한 그 역전이 실제로 난다.
5. **트윈 중 인스턴스 `:Destroy()`** — 엔진 트윈은 영향을 받지 않고 끝까지 돌아 `Completed(Completed)`를 내며 파괴된 인스턴스에
   프로퍼티를 쓴다. 연결은 `.Connected == true`로 남고 `tween.Instance`는 파괴된 인스턴스를 그대로 가리킨다. **자동
   Disconnect는 없다.**
6. **`Parent = nil`** — 5와 같다(끝까지 돌고 씀).
7. **약한 키 테이블은 ephemeron이 아니다** — 값 클로저가 키를 **따로 복사한 업밸류**로 잡으면(`local captured = key;
   wk[key] = function() return captured end`) 키는 150 에포크 안에 수거되지 않는다(대조군은 8 에포크에 수거). 탐사자 판정("true
   ephemeron")은 `key = nil`이 클로저가 잡은 바로 그 업밸류를 비운 코드라 무효 — `Property.luau` 머리 주석("Luau has no
   ephemerons")과 그 위의 `tweenRetractors` 약한 값 설계는 그대로 맞다.
8. **트윈 객체가 살아 있으면 `Completed` 연결 클로저가 잡은 인스턴스는 수거되지 않는다** — 트윈 객체를 강하게 쥔 채(quad의
   `tweenSlots` 레코드가 그렇다) 연결 클로저가 인스턴스를 복사 업밸류로 잡으면 150 에포크 안에 수거 안 됨. 탐사자의 8번도 같은
   이유로 무효. 따라서 콜백 배선은 **인스턴스를 클로저에 잡지 말고, 완료 시 자기 연결을 끊고, Cancel 자리에서도 끊어야** 한다.

## 설계에 주는 함의(문항은 `docs-review-2026-09-14.md` 1-5 닫힘 문단이 소스)

- `OnCancelled`·`OnStarted`는 엔진 시그널이 아니라 **quad가 `:Cancel()`·`:Play()`를 부르는 그 자리에서 동기로** 내야 순서가
  결정적이다(사실 3·4). `OnCompleted`만 엔진 `Completed`에서, `playbackState == Completed`일 때만(사실 2).
- 레코드에 "끝났다" 표시가 필요하다(완료 콜백에서 세움) — 끝난 트윈에 `Cancel`이 갔을 때 `OnCancelled`를 내지 않기 위해(사실 2).
- 철거(retract)는 `Cancel` + 연결 `Disconnect` — 파괴된 인스턴스에서 `OnCompleted`가 나는 것(사실 5)과 클로저 고정(사실 8)을 같이 막는다. **[2026-09-21 round12 `H-593` 정정]** 그건 자리가 retractor를 거쳐 철거될 때만이다 — 파괴 경로(`Destroy`/`q.dispose`/Slot 트리 파괴)는 프로퍼티 체인의 retractor를 돌리지 않으므로 사실 5 그대로 엔진 통지가 온다 — round12 `Q71`(사용자 결정, `H-594`): `isClaimed`가 거짓이면 콜백을 안 부른다.

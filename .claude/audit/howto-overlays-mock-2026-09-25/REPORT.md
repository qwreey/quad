# how-to 09(모달과 토스트) mock 검증 — 2026-09-25

새 `docs/how-to/09-overlays-modal-toast.md`(docs-review 2-4)의 핵심 코드 다섯을 CLI mock으로 확인한 기록.
실측 없음(Roblox Studio를 쓰지 않음) — 여기 적힌 것은 전부 `luau` CLI + `mock.gameShim`(quad-roblox 스펙과 같은 하네스) 결과다.
스크립트는 `probe.luau`(옛 `quad-roblox/test/probe.howto-overlays.luau` — 브리프 지시대로 실행 뒤 여기로 옮기고 test 폴더엔 남기지 않았다).

## 확인된 것 (mock)

- (a) `open` Source -> `Visible` 바인딩 — `D.Frame({ Visible = open })`를 만든 뒤 `open:Set(true)`/`open:Set(false)`를 오가면 `Visible`이 그대로 따라간다.
- (b) 조건부 자식(`State<Instance?>`) — `q.Source(nil)`을 숫자 키 자리에 놓으면 처음엔 자식이 없고, `:Set(a)`/`:Set(b)`로 갈아 끼우면 그 자리 하나만 바뀐다. 갈아 끼운 옛 원소(`a`)는 `.Parent`가 `nil`이 되지만 파괴되지 않는다(`mock.isDestroyed(a) == false`) — 시작하기 11 6절의 서술 그대로.
- (c) `Slot:List` 토스트 큐 + 가상 시계 — push 두 번으로 토스트 두 개가 뜨고, 가상 클록을 각 토스트의 `task.delay(3, ...)` 시점을 넘겨 전진시키면 만료된 토스트만 `Slot:List`의 `KeyGone` 갈래를 타고 제거된다(먼저 넣은 것부터 먼저 사라짐, 남은 토스트의 텍스트도 맞음).
- (d) `q.Context`로 깊은 곳에서 열기 — `ModalProvider`에 `{ Open = open }`을 담은 가방을 만들고, 그 가방만 받는 깊은 컴포넌트가 `props.Ctx:Get(ModalProvider)`로 꺼내 `modal.Open:Set(true)`를 부르면 뿌리의 `open` Source가 실제로 바뀐다.
- (e) `q.Fallback`이 던진 컴포넌트를 잡는다 — 정상 입력이면 결과가 그대로 통과하고 `errorState`는 `nil`로 남는다. 빈 문자열을 주면 `Card`가 던지고, `onError`가 `errorState:Set(err)`를 한 뒤 자리표시 `D.Frame({})`을 돌려준다. 돌아온 인스턴스가 그 자리표시이고, `errorState:Get()`엔 `Card: Text must not be empty`를 포함한 에러 문자열이 들어 있다. `ErrorModal`처럼 `errorState:Compute(...)`로 `Visible`을 잇는 컴포넌트는 에러가 채워지면 열리고 `errorState:Set(nil)`로 지우면 닫힌다.

## 확인 안 된 것(엔진 몫)

- `ZIndex`/`DisplayOrder`에 따른 실제 겹침 순서(Roblox 엔진 렌더링) — 문서도 이 지점은 다루지 않는다고 명시하고 Roblox 공식 문서로만 미룬다.
- 실제 `task.delay`/`task.cancel`의 스케줄러 정밀도, 실물 `Activated` 이벤트 배선(여기서는 `mock.declareEvents`로 이벤트를 선언하고 `:Fire()`로 직접 발화시켰다 — 리플렉션·Deferred 배달 타이밍 자체는 다른 spec/audit 몫).
- Studio에서의 실제 모달/토스트 레이아웃(가려짐, ScreenGui 우선순위, 화면 스케일).

## 실행 출력 요약

`luau probe.luau` — (a)~(e) 다섯 블록 전부 PASS, 마지막 줄 "전부 통과". 사전에 `./scripts/relink.sh`를 한 번 돌렸다(브리프 지시).

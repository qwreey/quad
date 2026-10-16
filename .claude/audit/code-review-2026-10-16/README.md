# 코드 리뷰 2026-10-16 — 10-15 재검사 뒤 리뷰 안 된 코드(`f5a6d802..52dcbdff`)

`/code-review high`(포크가 서브에이전트 없이 단일 맥락에서 판정 — 지시한 opus 파인더·검증자 상한은 쓰이지 않았다). 대상: quad-base `:List` 사라진 키 먼저(795c50f8)·`slot:Lazy`
(fc15c8ad·1c52e663 — 3.3.0에 실림), devui 창 관리, material Menu·TextField·DatePicker, `scripts/publish.py`(같은 날 429 수정). 결함 없음 확인: `:List` 정리(`indexOfRaw` O(1), 높은 자리부터 지워
낮은 인덱스 유효), `slot:Lazy` 재마운트(`teardownTree`가 `_listActivated`를 안 지움), 레지스트리 API 모양(`versions[v].targets[target]`).

## 발견 여덟과 처리 (메인 판정)

1. **[고침 `1673b859`] `slot:Lazy` 공개 타입이 `q.None` 반환을 거부**(런타임은 빈 내용으로 받음) — `fn: () -> (SlotElement<T> | None)?`, strict 스펙 `quad-roblox/test/spec.slottypes.luau` (6),
   변이 확인(되돌리면 `Expected … but got 'None'`). `quad-base/test/spec.slot.luau`는 `--!nocheck`라 타입 판별을 못 한다(첫 스펙은 거기 넣어 변이가 통과했다 — 그래서 strict 스펙으로 옮김).
2. **[고침 `1673b859`] Lazy 슬롯의 중복 마운트 `Quad0156` 문구가 `:List`·`updateFn` 원인만 말함** — 문구와 `docs/reference/errors/03-slot.md`에 `:Lazy` 원인, `spec.slot` (8), 변이 확인.
3. **[고침 `1673b859`] `publish.py`가 출력의 아무 '429'에나 반응** — `\b429 Too Many Requests\b`로 좁힘.
4. **[사용자 결정 대기] Lazy `fn`이 값 둘 이상을 돌려 `Quad0272`로 던질 때 만든 원소를 정리하지 않고, Slot은 빈 채 굳음** — 지금은 사용자 예외 뒤 상태처럼 미정의. quad 자신의 검증 raise라
   결과를 dispose하고 던지는 비용은 작다(리뷰 의견) — 새 동작이라 사용자 몫.
5. **[사용자 결정 대기] devui 전역 누름이 실제로 누름을 받은 GUI를 보지 않고 창 사각형만 대조** — 창 위에 DisplayOrder 높은 HUD나 material 팝업이 겹치면 그 누름에 아래 창이 앞으로 온다
   (옛 창 루트 `InputBegan`은 막힌 누름에 반응하지 않았다). 서로 다른 ScreenGui의 창이 `Manager.default`를 같이 쓰면 화면 순서와 관리자 순서가 다를 수 있다. 처방(`GetGuiObjectsAtPosition`
   류)은 구조 변경 — 관측된 문제가 아니라 원칙상 미룰 수도.
6. **[사용자 결정 대기] 트리에서 뗀(부모 nil) 창 루트도 누름 판정 대상**(`Visibility.isShown`이 LayerCollector를 못 찾으면 true), `succeed()`는 `root.Visible`만 봄 — 숨긴 컨테이너 안 창에 포커스가 갈 수 있다.
7. **[사용자 결정 대기] 전역 누름 연결이 첫 창 훅 때의 `Input.service()`에 고정** — `Input.luau` 머리의 "사용 시점에 묻는다(Input.use 뒤 재라우팅)" 약속과 어긋남(창이 열린 채 `Input.use`를 바꾸면 옛 신호만 듣는다).
8. **[사용자 결정 대기] 툴팁도 PopupHits에 등록돼, 툴팁을 뚫고 뒤 창 버튼을 눌러도 창이 앞으로 안 온다** — `PopupHits.luau` 머리가 툴팁을 일부러 포함한 설계라 결함이 아니라 2026-10-15
   결정("뒤 창 위젯을 누르면 앞으로")과의 충돌. 입력을 실제로 가로채는 팝업(바깥 닫기 받이·버튼 holder)만 등록하는 쪽이 리뷰 제안.

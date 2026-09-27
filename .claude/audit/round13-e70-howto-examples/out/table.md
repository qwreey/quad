| 파일 | 블록(줄) | 분류 | mock | 출력 일치 | strict | 비고 |
|---|---|---|---|---|---|---|
| how-to/01-component-conventions.md | 34 | a | 통과 | 일치 | 1 TypeError — 8.13 인라인 무주석 Compute — 문서 옆 주석이 안내(E56 기지) |  |
| how-to/01-component-conventions.md | 74 | a | 통과 | 일치 | 0 |  |
| how-to/01-component-conventions.md | 93 | c | 통과 | 부분 불일치 → 발견 2(둘 다 nil이면 에러 없음) | 2 TypeError — 의도 — ❌ 줄(구멍 두 자리)을 strict가 잡음 | 보강: props 정의 + ❌ 줄을 pcall로(둘 다 nil / 앞만 nil) |
| how-to/01-component-conventions.md | 126 | a | 통과 | 일치 | 0 |  |
| how-to/01-component-conventions.md | 161 | a | 통과 | 일치 | 0 |  |
| how-to/01-component-conventions.md | 186 | a | 통과 | 일치 | 0 |  |
| how-to/01-component-conventions.md | 228 | a | 통과 | 일치 | 0 |  |
| how-to/01-component-conventions.md | 250 | a | 통과 | 일치 | 0 |  |
| how-to/01-component-conventions.md | 290 | a | 통과 | 일치 | 0 |  |
| how-to/02-form-validation-pattern.md | 39 | a | 통과 | 일치 | 0 |  |
| how-to/02-form-validation-pattern.md | 65 | a | 통과 | 일치 | 0 |  |
| how-to/02-form-validation-pattern.md | 112 | a | 통과 | 일치 | 0 |  |
| how-to/02-form-validation-pattern.md | 179 | c | 통과 | 일치 | 0 | 보강: makeFormState 안 두 판정 대역 |
| how-to/02-form-validation-pattern.md | 196 | a | 통과 | 일치 | 0 | 보강: 엔진 쪽 대입으로 타이핑 흉내(TextBox.Text 순서는 GetChildren 순서에 의존하지 않게 클래스로 모음) |
| how-to/02-form-validation-pattern.md | 283 | a | 통과 | 일치 | 0 |  |
| how-to/02-form-validation-pattern.md | 324 | c | 통과 | 일치 | 0 | 보강: makeFormState 이어 붙임 |
| how-to/03-long-lists-and-windowing.md | 59 | a | 통과 | 일치 | 0 |  |
| how-to/03-long-lists-and-windowing.md | 110 | a | 통과 | 일치 | 0 | 보강: 엔진 쪽 대입으로 스크롤·창 크기 흉내 |
| how-to/03-long-lists-and-windowing.md | 194 | c | 통과 | 일치 | 0 | 보강: viewportHeight 정의(§4 본문 생략 자리는 그대로) |
| how-to/04-network-and-input-bridge.md | 37 | d | 통과 | 일치 | 0 | RemoteEvent·game 셔임 |
| how-to/04-network-and-input-bridge.md | 63 | d | 통과 | 일치 | 0 | RemoteEvent 셔임 |
| how-to/04-network-and-input-bridge.md | 111 | d | 통과 | 일치 | 0 | UserInputService 셔임 |
| how-to/04-network-and-input-bridge.md | 151 | d | 통과 | 일치 | 0 | UserInputService 셔임, UserInputService는 §3 블록에서 |
| how-to/04-network-and-input-bridge.md | 197 | c | 통과 | 일치 | 0 | 보강: SomeSignal 정의 |
| how-to/05-theme-and-dynamic-styling.md | 36 | c | 통과 | 일치 | 0 | 보강: Theme 모듈 이어 붙임 |
| how-to/05-theme-and-dynamic-styling.md | 62 | a | 통과 | 일치 | 0 |  |
| how-to/05-theme-and-dynamic-styling.md | 166 | a | 통과 | 일치 | 0 |  |
| how-to/05-theme-and-dynamic-styling.md | 180 | a | 통과 | 일치 | 0 |  |
| how-to/05-theme-and-dynamic-styling.md | 227 | a | 통과 | 일치 | 0 |  |
| how-to/06-headless-testing.md | 77 | a | 통과 | 일치 | 0 |  |
| how-to/06-headless-testing.md | 96 | a | 통과 | 일치 | 0 |  |
| how-to/06-headless-testing.md | 134 | c | 통과 | 일치 | 0 | 보강: myProvider = mock.mockProvider |
| how-to/06-headless-testing.md | 149 | c | 통과 | 일치 | 3 TypeError — **새로움** → 발견 3(myProvider: any → q가 error-type 유니언) | 보강: host = mock Instance.new |
| how-to/06-headless-testing.md | 180 | c | 통과 | 일치 | 4 TypeError — **새로움** → 발견 3(같은 뿌리) | 보강: makeElement·parent = mock Instance.new |
| how-to/07-studio-ui-binding-and-claim.md | 26 | d | 통과 | 일치 | 2 TypeError — E17 F4 기지(`script.Parent` nil 가능) | 보강: foreign 템플릿 + script 셔임 |
| how-to/07-studio-ui-binding-and-claim.md | 75 | d | 통과 | 일치 | 0 | 보강: ReplicatedStorage 셔임(블록에 정의 없음) + mock에 :Clone 없어 __clone |
| how-to/07-studio-ui-binding-and-claim.md | 121 | a | 통과 | 일치 | 0 |  |
| how-to/07-studio-ui-binding-and-claim.md | 138 | a | 통과 | 일치 | 0 | 보강: mock에 :Clone 없어 __clone(foreign 사본) |
| how-to/07-studio-ui-binding-and-claim.md | 201 | c | 통과 | 일치 | 0 |  |
| how-to/07-studio-ui-binding-and-claim.md | 228 | d | 통과 | 일치 | 0 | 보강: existingScreenGui·rows·player 정의 |
| how-to/07-studio-ui-binding-and-claim.md | 248 | d | 통과 | 일치 | 0 | 보강: ReplicatedStorage 셔임(블록에 정의 없음), :Clone 제거(foreign 원본을 그대로) |
| how-to/08-migrating-from-v1.md | 82 | a | 통과 | 일치 | 0 |  |
| how-to/08-migrating-from-v1.md | 103 | a | 통과 | 일치 | 0 |  |
| how-to/08-migrating-from-v1.md | 130 | a | 통과 | 일치 | 0 |  |
| how-to/08-migrating-from-v1.md | 166 | a | 통과 | 일치 | 0 |  |
| how-to/08-migrating-from-v1.md | 204 | d | 통과 | 일치 | 0 | Players 셔임 |
| how-to/08-migrating-from-v1.md | 238 | a | 통과 | 일치 | 0 | 보강: QuadTypes require(L103에 있음) |
| how-to/08-migrating-from-v1.md | 293 | a | 통과 | 일치 | 0 |  |
| how-to/08-migrating-from-v1.md | 342 | a | 통과 | 일치 | 0 |  |
| how-to/09-overlays-modal-toast.md | 35 | a | 통과 | 일치 | 0 |  |
| how-to/09-overlays-modal-toast.md | 46 | a | 통과 | 일치 | 0 |  |
| how-to/09-overlays-modal-toast.md | 98 | a | 통과 | 일치 | 0 |  |
| how-to/09-overlays-modal-toast.md | 114 | a | 통과 | 일치(떼기만 — 다음 문단이 말함) → 발견 4(예제가 dispose 안 함) | 0 | 보강: activeModal을 자리에 놓는 호스트 |
| how-to/09-overlays-modal-toast.md | 141 | a | 통과 | 일치 | 0 |  |
| how-to/09-overlays-modal-toast.md | 154 | c | 통과 | 일치 | 0 | 보강: DeepPanel 정의(블록이 '몇 층 아래'로 생략), ModalContext require를 앞으로 |
| how-to/09-overlays-modal-toast.md | 174 | c | 통과 | 일치 | 0 | 보강: ModalContext require(L154에 있음) |
| how-to/09-overlays-modal-toast.md | 196 | a | 통과 | 일치 | 0 |  |
| how-to/09-overlays-modal-toast.md | 259 | a | 통과 | 일치 | 0 |  |
| how-to/09-overlays-modal-toast.md | 282 | a | 통과 | 일치 | 0 |  |
| how-to/09-overlays-modal-toast.md | 324 | c | 통과 | 일치 | 0 | 보강: someUnsafeText 정의 |
| how-to/10-debugging-and-troubleshooting.md | 64 | c | 통과 | 부분 불일치 → 발견 2(둘 다 nil이면 에러 없음) | 2 TypeError — 의도 — ❌ 줄(구멍 두 자리)을 strict가 잡음 | 보강: props 정의 + ❌ 줄을 pcall로 |
| how-to/10-debugging-and-troubleshooting.md | 82 | c | 통과 | 일치 | 0 | 보강: myRef 정의(값이 이미 있는 갈래만 — Wait 갈래는 probes/) |
| how-to/10-debugging-and-troubleshooting.md | 111 | a | 통과 | 일치 | 0 |  |
| how-to/10-debugging-and-troubleshooting.md | 141 | a | 통과 | 일치 | 0 |  |
| how-to/10-debugging-and-troubleshooting.md | 164 | a | 통과 | 일치 | 0 |  |
| how-to/10-debugging-and-troubleshooting.md | 176 | c | 통과 | 일치 | 0 | 보강: 호출 |
| how-to/10-debugging-and-troubleshooting.md | 205 | c | 실패 → 발견 1 | 불일치 → 발견 1(✅ 줄이 Quad0076) | 4 TypeError — 발견 1(Frame에 Text 없음) — ❌·✅ 두 줄 다 | 보강: items 정의 + ❌ 줄 pcall |
| overview/01-why-quad.md | 31 | a | 통과 | 일치 | 1 TypeError — 8.13 인라인 무주석 Compute — 문서 옆 주석이 안내(how-to 01 §1과 같은 모양) |  |
| overview/01-why-quad.md | 116 | c | 통과 | 일치 | 0 | 보강: count 정의(앞 블록 문맥) |
| quadnomicon/05-non-destructive-portal-and-ownership.md | 92 | c | 통과 | 일치 | 1 TypeError — 보강 타입 의존(`Source<Instance?>`만 거부 — 확인만 참고) | 보강: myInstanceState 정의 + OwnsElements=false 확인 |
| quadnomicon/07-instance-identity-and-gc-philosophy.md | 106 | c | 통과 | 일치 | 0 | 보강: 자리표시 템플릿 → foreign Frame, mock :Clone 없음 |
| quadnomicon/09-fragment-breakthrough-and-domless-slot.md | 79 | a | 통과 | 일치 | 0 |  |
| quadnomicon/09-fragment-breakthrough-and-domless-slot.md | 139 | a | 통과 | 일치 | 5 TypeError — Q121/E45 기지(무주석 `ctx` 람다, KeyGone `return nil` 먼저) |  |
| quadnomicon/11-static-grepability-and-error-architecture.md | 19 | a | 통과 | 일치 | 0 | 보강: 마지막 호출을 pcall로(주석의 메시지 대조) |
| site/src/content/docs/index.mdx | 58 | a | 통과 | 일치 | 0 |  |

| 폴더 | 블록 | P | b | a | c | d | 실행 | mock 통과 | strict 대상 | strict 클린 |
|---|---|---|---|---|---|---|---|---|---|---|
| how-to | 76 | 9 | 0 | 41 | 17 | 9 | 67 | 66 | 67 | 60 |
| overview | 2 | 0 | 0 | 1 | 1 | 0 | 2 | 2 | 2 | 1 |
| quadnomicon | 26 | 1 | 20 | 3 | 2 | 0 | 5 | 5 | 5 | 3 |
| landing | 1 | 0 | 0 | 1 | 0 | 0 | 1 | 1 | 1 | 1 |

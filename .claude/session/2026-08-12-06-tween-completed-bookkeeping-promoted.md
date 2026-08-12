# 2026-08-12 세션 — Tween 자연완료 북키핑 확정, `tween-plan.md`를 `base/`로 승격

`research/tween-plan.md`에 마지막으로 남아있던 열린 질문 — 자연 완료
(Completed) 시 per-instance weak-keyed 저장소(3-상태 릴레이션 슬롯)에
남은 이전 Tween 참조를 정리해야 하는가(`research/pre-implementation-audit.md`
2-10번) — 를 사용자가 직접 결론냄.

## 결론: 정리 안 해도 됨

사용자 설명 그대로 요약:

- 이 정리를 하고 싶어지는 동기는 "인스턴스 초기 생성 시 프로퍼티가 유저가
  원치 않는 값(예: `Position`이 기본 `UDim2.new(0,0,0,0)`)일 수 있어, 거기서
  트윈이 시작되면 툭 튀어 오른다"는 문제다.
- 그런데 이건 이미 "3-상태 저장"의 **첫 세팅 분기**(`prev == nil` →
  애니메이션 없이 즉시 세팅)가 처리하는 문제고, 자연완료와는 무관하다.
- **자연완료 상태는 반대로 유저가 원한 목표값에 정확히 도달한 상태** —
  그 상태를 나타내는 북키핑을 안 지우고 남겨둬도, 다음 process 때 기존
  override 정책(`Cancel`/`Finish`)이 정확히 이 케이스를 위해 이미 정의돼
  있어 부작용이 없다.
- `Value`는 항상 lerp 가능한 프리미티브(number/UDim/Vector 등, 테이블
  aliasing 걱정이 있는 타입이 아님)라 참조를 계속 들고 있어도 메모리/정합성
  문제가 없다.
- 이 상태에서 Completed 이벤트를 구독해 슬롯을 되돌리는 별도 장치를
  추가하는 건 실질적 이득 없이 복잡도만 늘리는 오버엔지니어링.

## `base/`로 승격

이걸로 `research/tween-plan.md`에 남은 열린 설계 질문이 없어짐 — 사용자
제안대로 `base/tween-plan.md`로 승격(`git mv`).

**반영된 파일**:
- `base/tween-plan.md`(구 `research/tween-plan.md`) — 헤더/열린 질문
  절 갱신, "자연 완료(Completed) 시 per-instance 북키핑 — 정리 안 해도
  됨 (확정)" 절 신설.
- `research/pre-implementation-audit.md` 2-10번 — `[해소됨]` 표시 추가.
- `.claude/README.md` — `research/` 표에서 `tween-plan.md` 행 제거,
  `base/` 표에 추가. `archive/tween-special-bind-key-reversed.md` 행의
  경로도 `base/tween-plan.md`로 갱신.
- `.claude/question.md` — 트윈 요약 줄 경로를 `base/tween-plan.md`로 갱신.
- `CLAUDE.md` — "지금 할 일"/`research/` 목록에서 `tween-plan.md` 제거.
- 라이브 크로스레퍼런스(`research/tween-plan.md` → `base/tween-plan.md`)
  일괄 갱신: `base/architecture.md`(2곳), `base/attribute-plan.md`,
  `base/modifier-plan.md`(2곳), `base/bind-system-plan.md`(4곳),
  `research/pre-implementation-audit.md`, `research/operator-sugar-plan.md`,
  `research/documentation-content-map.md`,
  `archive/tween-special-bind-key-reversed.md`. **`session/` 안의 과거
  기록은 의도적으로 안 건드림** — 그 시점엔 실제로 `research/`였으므로
  원문 그대로 정확함.

이걸로 Tween 관련 설계는 전부 확정 — `ROADMAP.md` M11 착수 시 `base/
tween-plan.md`가 유일한 소스.

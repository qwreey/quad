# [역전됨] Tag/Attribute Handler는 "quad-base 모듈 로드 시점에 스스로 등록" — 등록 주체와 이름이 둘 다 틀렸음

**상태**: archive — 2026-08-14 열두 번째 세션(이 대화)에서 역전. 정본은
`base/dispatch-core-plan.md`의 "base가 소유하는 핸들러와 주입되는 엔진 op" 절.

## 뒤집힌 주장 (2026-08-14 열한 번째 세션, "네 번째, 최종 정정")

`TagHandler`/`AttributeKeyHandler`/`AttributeGroupHandler`가 **quad-base
자기 모듈 로드 시점**(top-level, require 시)에 `HANDLER_PRIORITY_FALLBACK`
우선순위로 **스스로** `Dispatch.addHandler`를 호출해 등록한다고 확정했었음
— `dispatch-core-plan.md`/`tag-plan.md`/`attribute-plan.md`/
`module-lifecycle-plan.md`/`architecture.md` 5개 파일에 반영됐었음.

## 왜 틀렸나 (사용자 정정, 2026-08-14 열두 번째 세션)

두 가지가 섞여 있었음:

1. **등록 주체가 틀림 — "모듈 로드 시점"은 이 프로젝트가 이미 명시적으로
   거부한 패턴.** `base/lifecycle-pattern.md` "rbvm에서 그대로 가져오면
   안 되는 것" 절이 "`InitNamespace`/`Registered`-가드/`NewLib` 3종 세트로
   라이브러리마다 하나하나 수동 init 하는 방식은 정확히 사용자가 피하고
   싶다고 한 패턴"이라고 이미 못박아뒀는데, "quad-base가 자기 모듈 로드
   시점에 스스로 등록"은 이름만 다를 뿐 같은 클래스의 top-level 부작용임.
   `base/module-lifecycle-plan.md`가 이미 확정해둔 일반 원칙("base
   유틸은 인터페이스만, 실제 등록/구현은 백엔드 팩토리가 `BaseModule`을
   뮤테이션하는 시점에 주입")과도 정면으로 어긋남 — 같은 문서
   124-154줄이 "이 결론이 Dispatch의 handler 레지스트리에도 그대로
   적용된다"고 이미 일반화해뒀던 걸 이 Tag/Attribute 결론만 예외로 뒀던
   셈.
2. **이름이 틀림 — "TagHandler 자신이 등록되는 주체"와 "TagHandler라는
   공유 알고리즘 구현"을 하나로 뭉갬.** `TagHandler`/`AttributeKeyHandler`/
   `AttributeGroupHandler`는 참조 카운트/이름 claim 알고리즘 그 자체를
   가리키는 이름이 맞고, 이건 엔진 지식을 요구하지 않는 **공유 코드**라서
   base에 위치하는 것뿐 — 이름 자체가 "자동으로 설치되는 안전망"이라는
   의미까지 담고 있지 않음.

## 정정된 모델

- `TagHandler`/`AttributeKeyHandler`/`AttributeGroupHandler` = 참조
  카운트/이름 claim **알고리즘 구현**(그대로 base 소유, 이름도 그대로).
- **실제로 `HANDLER_PRIORITY_FALLBACK`에 꽂히는 건 별도로 "Fallback"이
  이름에 들어간 엔티티** — `TagFallbackHandler`/
  `AttributeKeyFallbackHandler`/`AttributeGroupFallbackHandler`. 위
  알고리즘을 그대로 감싸 쓰되, "이게 기본 안전망으로 자동 설치되는
  대상"임을 이름으로 구분.
- **등록 주체는 quad-base 모듈 자체가 아니라 필요한 엔진(백엔드
  팩토리)** — quad-roblox 같은 백엔드의 팩토리 함수가 `BaseModule`을
  구성할 때, 자기 전용 Handler(Property/Event/OnChange/UICorner)들과
  **같이** 이 base 소유 Fallback Handler들도 등록해준다. 엔진 저자
  입장에선 "자동/공짜"(직접 코드를 안 짜도 됨)이지만, 메커니즘은 팩토리
  뮤테이션 시점의 정상 경로 — `module-lifecycle-plan.md`가 이미 확정해둔
  패턴을 그대로 따르는 것뿐, 새 예외가 아님.

## 영향 범위(정정 완료)

`base/dispatch-core-plan.md`(핸들러 계약 절, "base가 소유하는 핸들러와
주입되는 엔진 op" 절), `base/tag-plan.md`, `base/attribute-plan.md`,
`base/module-lifecycle-plan.md`, `base/architecture.md`(Tag.luau 파일
설명) — 전부 이 세션에 재반영. `CLAUDE.md`의 11번째 세션 서술(네 라운드
연속 정정 서사)은 **역사적 기록으로 그대로 둠**(그 세션 시점엔 이게
최선의 결론이었음) — 12번째 세션 요약이 이 재역전을 링크로 가리킴.

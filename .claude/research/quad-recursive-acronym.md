# `quad` 재귀 약어(recursive acronym) 브레인스토밍

GNU("GNU's Not Unix")/WINE("Wine Is Not an Emulator")류로 **`Quad`가 스스로를
가리키는 재귀 약어**를 만들어보자는 순수 카피 브레인스토밍. 설계 결정이
아니라 나중에 루트 `README.md` 헤딩 등에 한 줄로 얹을 캐치프레이즈
후보 모음이라 다른 `research/` 문서와 성격이 다름 — **상의 필요한 설계
질문 없음, 착수 게이팅 없음.** 채택 시점/장소는 미정(README.md 헤딩이
유력 후보).

형식: `Q-U-A-D` 4글자, `Q`는 "Quad" 자기 자신, 나머지 세 단어로 문장을
완성.

## 방향 1 — 자학/자기지시 개그 (기각 — 톤이 안 맞아서 안 내걸기로 함)

이 프로젝트의 세션 히스토리 자체(잦은 뒤집힘·감사·재정정)를 소재로 한
농담들. 재밌긴 한데 "우리는 맨날 뒤집혀요"로 읽혀서 배너로 내걸기엔
부적절하다고 판단, 기록만 남김:

- **Quad Usually Avoids [the] DOM** — DOMless 렌더러라는 정체성을 WINE
  톤 그대로 부정문에 담음.
- **Quad Unifies Attributes (via) Dispatch** — Store/State/Source가 전부
  같은 Dispatch 코어로 수렴한다는 아키텍처 요약.
- **Quad Undoes All (that v1) Did** — 처음부터 다시 짠다는 프로젝트
  배경과 맞물림. ⭐ 이 세션에서 제일 웃겼던 후보.
- **Quad Ultimately Avoids Destroy()** — `dispose()`가 `Slot`/`Instance`에만
  좁게 적용되고 나머지는 GC-native로 자동 정리된다는 설계 철학.
- **Quad Undoes And Documents** — 결정이 뒤집히면 항상 `archive/`에
  원문+역전 이유+diff로 남기는 지금 워크플로우 자체를 정의로 씀.
- **Quad Usually Audits, Daily** — `doc-check.py`+반복 감사 문화 패러디.

## 방향 2 — quad-v2의 매력(지연평가·재귀/커링·펑터·일급 클로저/팩토리)을
자랑스럽게 (채택 후보, 미확정)

사용자가 실제로 내걸고 싶다고 지목한 방향. Haskell 비교 세션
(`session/2026-08-13-02-haskell-comparison-dispatch-reentrant-bug.md`)에서
이미 `:Compute`/`:With` ≈ Functor/Applicative, `Merged`/`Overridden` ≈
Semigroup으로 대응 확인해둔 바 있어, 이 방향은 실제 설계와도 결이 맞음.

- **Quad Unwinds, Applies, Defers** — 동사 3박자. `Unwinds`=재귀(호출을
  풀어나감), `Applies`=커링(부분적용), `Defers`=지연평가. 리듬이 좋고
  외우기 쉬움. **1순위 추천.**
- **Quad Unwinds Anonymous Deferrals** — `Unwinds`=재귀, `Anonymous`=일급
  익명 클로저(quad의 커링 스타일 자체가 중첩 익명함수라 실제 코드
  관용구와 정직하게 맞물림), `Deferrals`=지연평가+팩토리. **quad
  실코드 스타일과 제일 잘 맞는 후보.**
- **Quad Unifies Applicatives, Deferred** — `Applicatives`가 펑터+커링을
  한 단어로 정확히 지칭, `Deferred`=지연평가. 제일 정밀하지만 캐주얼한
  배너보다는 학술적 각주 톤에 더 어울림.
- **Quad's Unapplied Arguments, Deferred** — `Unapplied Arguments`가
  커링을 교과서 용어 그대로 짚음, `Deferred`가 지연평가. 문장 자체는
  예쁘지만 "Quad's" 소유격 시작이라 GNU/WINE 원형(명사로 바로 시작)과는
  살짝 다름.

## 결론

아직 미확정 — 사용자가 방향 2 안에서 하나를 고르거나 조합을 더 다듬은
뒤 채택 위치(README.md 헤딩 등)를 정하면 반영. 이 문서 자체는 그 전까지
카피 후보 저장소로만 존재.

# 2026-09-07 (03) — 사용자 회신 3차(Q4~Q19) 반영, Gemini 4차 검증, 문항 서술 방식 지적

> 결정의 소스는 원장 `qa-request/post-implementation-review-round3.md` §5·§6, 새 원칙은
> `source-state-plan.md` "Compute 순수성" 절, 미룬 후보는 `research/deferred-hardening-plan.md`.

## 1. 대화형 회신

사용자가 §4 문항을 문서로 읽는 것이 *"기호가 많고, 압축서술이 너무 많아서 맥락을 모르겠음 … 문서를 보는걸론
효율이 안 나오네"*라 했다. 권고대로 닫을 것(Q4·Q8·Q10·Q11·Q13·Q15·Q16·Q17)은 바로 받았고, Q3·Q5·Q7·Q9·Q14·
Q18·Q19는 채팅에서 상황 → 무엇이 막히나 → 갈래의 뜻 순으로 평문 설명한 뒤 결정을 받았다. **교훈**: 원장 §4의
문항은 코드를 안 본 사람이 읽는 것이라 기호·약호 대신 한 문단 평문으로 쓴다(round3 §6 머리에 명문화).

## 2. 사용자가 설계를 준 것

- **Q12** — 리뷰의 갈래 셋 대신 사용자 설계: Animate가 이전 Tween과 값·옵션이 같으면 이전 Tween 객체를 그대로
  돌려주고, Property 핸들러가 같은 객체를 신원으로 접는다. `Dedup: boolean`(State도) 옵션, 기본 true.
- **Q9** — 좀비 Slot은 Instance와 동형: 상위가 quad 밖에서 죽으면 함께 죽은 것, 미리 뽑았어야 한다. 메시지와 UB만.
- **Q5** — UB로 두되 더 크게: *"compute 의 부작용은 readonly 이고 하류로 내리기만 한다"*를 원칙으로, 재진입
  게이트는 안 둔다. 메인 동의 — pull 모델에서 Compute 안 `:Set`은 epoch를 앞당겨 조용히 꼬인다. 값싼 가드는
  리서치.
- **Q18·Q7** — 급하지 않은 것은 리서치에 쌓아 두고 *"더 큰 문제를 찾아나가야"* — `research/deferred-hardening-plan.md`.

## 3. Gemini 4차

G-10~G-14 전부 실존(빈 문자열·nil 인자가 내부 VM 에러/엔진 예외로 닿는 남은 구멍) → `H-440`~`H-444`. 사용자
허락으로 파일을 `post-implementation-review-round4.md`로 개명.

## 4. 반영 중 잡은 것

- Modifier의 비문자열 키 에러가 `__index` 메타메소드에서 raise돼 태그 프레임이 없었다 → `__index`를 SURFACE로 태그.
- `setLength` State 팔의 도메인 검사는 `len:Set(-4)` 순간(설치 발화 recompute) 발화한다 — spec을 그 자리로.
- `Slot:List(nil, fn)`은 reconcile까지 안 가서 `List` 머리 게이트가 필요했다.
- 재정규화로 `dropped` 575 → 466(ReadOnly 109개가 `readProps`로 이동). 타입 검사 3.06s(마커 뒤 2.95s와 동급).
- relink 매니페스트에 옛 core dump(`quad-base/core.529483`) 항목이 남아 relink가 실패했다 — 항목 삭제(무시 파일).

## 5. 검증

`./scripts/test.sh` exit 0(스펙 49), doc-check ERROR 0.

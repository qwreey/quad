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

## 6. 회신 4차 (같은 날 밤)

Q6·Q20·Q21(round1)과 Q22·Q23(round3)을 닫았다(round3 §7). Q6은 "코드의 사실에 문서를 맞추고, 조합 기본 구현은
있는 게 맞으니 백로그" — 약속 철회와 백로그 등재를 같이. Q20은 사용자가 전제 자체를 바로잡았다: 파괴된 quad
Instance와 외부 Instance는 가를 수 없다(생성·Clone 직후 Parent nil — 전에 game 조상 검사를 도입했다 철회) →
Studio 실측 없이 메시지 하나가 둘을 말하게. Q21은 selene 폐기 + `luau` 0.734 핀(`mise install`이 이미 설치된 것을
그대로 씀). Q22는 Java `Object`의 비유로 "타입을 아는 유저가 캐스트" — 캐비엇만. Q23은 State 팔 하나. Q24는
`SlotItem`/`FieldOut`이 무엇을 하는지 먼저 설명해 달라 — 채팅에서 평문으로.

## 7. Q24 (같은 날 밤)

`SlotItem`/`FieldOut`이 무엇인지 평문으로 설명한 뒤 *"괜찮네. 확인했어"* — 넷 그대로 승인. 이어진 질문 *"FieldOut<T> 는
그럼 Peek 에도 사용되는걸까?"*가 구멍을 하나 드러냈다: `Peek`은 옛 `T | State<T> | None | nil`이라 저장된 Tween이 T로
보였다. 같은 "저장된 그대로" 값이므로 `FieldOut<T>?`로 통일하고, 별칭 정의를 quad-types로 올렸다(base `Modifier`와 생성
`<Class>Modifier` 둘 다 같은 타입을 쓰게). 이로써 리뷰 문항 Q1~Q24가 전부 닫혔다.

## 8. 회신 3차 묶음의 `/code-review` (같은 날 밤, round3 §8)

열 건. **`H-445`가 내 회귀**: Q15의 State 값 검사를 `contribution`(recompute 안 — 차단기 창)에 넣어, 사용자가 pcall로 잡으면
차단기가 영원히 켜진 채 남았다 — `checkPosition` 헤더가 "창에 들어가기 전에 거른다"고 적어 둔 규칙을 내가 어겼다. 검사를
Observer로 올렸다(nearest = `:Set` 줄). 둘은 문항(Q25 숏핸드 `Mapped`가 새 객체를 만들어 Q12 dedup이 두 키에서 불성립,
Q26 첫 스냅 뒤 슬롯에 dedup 정보 없음). 나머지 여섯은 게이트 구멍·주석·사본 정리. 리뷰가 평문으로 보고해 읽기 쉬웠다 —
인자에 "평문으로"를 넣은 효과.

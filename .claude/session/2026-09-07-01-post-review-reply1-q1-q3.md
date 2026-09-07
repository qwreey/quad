# 2026-09-07 (01) — 구현 뒤 리뷰 사용자 회신 1차(Q1~Q3) 반영, 라운드 번호 재시작

> 앞선 구간(7순회까지·문서 재편·Gemini 검증·구조 의견 여덟)은
> `session/2026-09-06-01-audit-sweep-and-m11-brief.md` 13절. 이 파일은 그 뒤 사용자가 루트
> `usernote-ignoreme.md`(커밋 안 함)로 준 회신 1차의 처리 원문. 결정의 소스는 원장
> `qa-request/post-implementation-review-round1.md` §15·§4.

## 1. 회신의 모양

사용자가 §4의 Q1~Q3(Q3는 ①~⑨ 항목별)에 답하고 마지막에 라운드 번호 지시를 붙였다. Q3에 대해 *"너무
많은게 묶여있어서 다른 에이전트로 explain 걸어야 보기 편했어 … 실제로 나뉘어지는 요소라 생각함"* —
품질 제안을 한 문항에 아홉 개 묶은 것이 읽기 비용을 만들었다는 지적. **앞으로 품질 제안은 항목마다
문항 하나**(원장 §15 Q3 행에 명문화).

## 2. Q1 — 결정이 아니라 사고, 실측을 붙였다

사용자 원문(요지): 처음부터 `Slot<T>`를 만들 생각은 없었고(항상 Instance, 잘못된 값은 런타임 에러),
Insert가 any일 수는 없으니 `Instance`를 넣은 건 이해한다. 바인드 자리엔 `Slot<any>`면 될지도, 아니
그냥 `State<Instance | Slot<Instance>>` 하나로 끝나지 않나. 더 나아가 *"'입력받는 곳'에 대해서는 마커
필드와 내부 구조 T 하나만 보존하는 마커 타입을 써도 되지 않나 … 구조적으로 확장된 타입은 잘 받기
때문에 … 진짜 State<T>의 method 같은건 유저가 쓰는 부분에 있어서 들어갈 뿐"*, *"어떻게 봐? 생각 더
필요한듯"*.

메인 판단: 두 생각은 같은 문제다 — 전체형 `State<T>`가 불변이라 `State<Instance>`는
`State<Instance | Slot<Instance>>` 자리에 못 들어간다(`H-353`이 `PV73`을 11팔로 늘린 이유). 마커 타입은
그 불변을 푸는 후보라, 답하기 전에 **최소 스파이크로 사실을 확정**했다 —
`luau-test/done/34-type-state-marker-covariance.luau`(새·옛 솔버 동일): 읽기 전용 마커 필드는 T에
공변, 메소드 붙은 실제 State 모양이 폭 서브타이핑으로 들어감, 다른 T·읽기쓰기 필드는 거부, 제네릭
소비자가 T를 복원. 즉 사용자 방향은 타입 이론상 성립한다. 남은 것은 **생성 D 규모에서 재는 것**
(gen-d의 `State<X>`/`Slot<X>` 팔을 마커로 바꿔 팔 수·한도 플래그·`spec.shorthandtypes` 양·음성 확인)이고,
그건 quad-types 표면 변경(값 타입에 마커 필드 둘)이라 결정 뒤 별도 단위. `typing-limits.md` 8.11에
실측만 적고 Q1은 열어 뒀다 — "발견≠결정" 규약대로 마커를 코드에 넣지 않았다.

## 3. Q2·Q3 — 결정의 반영

- **Q2 (a)** *"이건 그냥 하면 될것같음. 권고대로 둘 다 넣는거 동의"* → `NewChild`에 `Observer`/`EffectHandle`
  합류, strict 양성 `spec.componenttypes` `_observerChild`, gen-d 8.9 게이트 수확 대상에 둘 추가.
- **Q3** 항목별: ② `NotInstalled.luau`(세 사본 → 한 팩토리, *"raw*에서도 했던 행위"*), ③
  `Dispatch.setEmpty`(*"setEmpty 같은걸 넣어도 큰 문제는 없어보이겠다"* — 이름은 사용자 단어 그대로;
  quad-types `Dispatch` 필드 추가, `registerEmptySlot` 제거, quad-base 10곳 + quad-roblox 2곳), ④
  `Reflection.luau` `memberSet`(*"공통으로 두는건 아주 싸긴 해서 … 딱히 부작용도 없을듯"*; `game` 읽기는
  호출자 클로저에 남겨 getfenv 심 seam 유지), ⑤ `None.luau` `addProcessedHandler`, ⑥ `assertMutable`, ⑦
  gen-d가 `reserved`/`Callback`을 런타임 소스에서 읽고 `SHORTHAND` 키 집합은 `TABLE`과 대조 게이트.
  ①⑧⑨는 보류 — 사용자: *"당장은 더 치명적인 문제들이 있는지 확인해보자. 물론 보는 김에 최적화 할
  대상을 쌓아둬도 좋아"* → ROADMAP 백로그에 **최적화 후보 목록** 신설(①의 `rawOrder(newOrder)` 아이디어도
  *"리서치 목록에만"* 거기).

## 4. 라운드 번호

*"post 리뷰들도 라운드 분리하고 싶은데, round1 부터 다시 시작해서 라운드좀 붙여줄래? gemini 쪽은
round2 로 하면 될듯"* → `post-implementation-review.md` → `-round1.md`, Gemini →
`-round2.md`(참조 16파일 치환). 해석: 구현 뒤 리뷰는 번호를 1부터 새로 세고, 다음 리뷰 묶음부터
round3 새 파일(문항 표 §4는 round1이 소스로 남는다). 이 해석은 메인 것 — 사용자 사후 확인 대상.

## 5. 검증

`./scripts/test.sh` exit 0(스펙 49, gen-d check 통과 — `Reflection.luau`의 옵션 인자 좁히기 TypeError
한 번 고침), doc-check ERROR 0.

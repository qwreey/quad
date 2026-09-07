# 2026-09-04 (06) — M8 §0 확정 + 단위 ①: `:Wait`·`PreRef`·`PostRef`

> 원문 로그. 정본은 `base/ref-plan.md`("API 모양" 절의 `:Wait` 항목, "`Ref`의
> retract" 절 의사코드 순서, "`PostRef`" 절 보장 범위), 규약은
> `archive/v2-initial-implementation/m8-implementation-round18-brief.md`(§0 회신 블록), 발견은
> `-round18.md`.

## 1. §0 회신

사용자 원문은 brief §0 회신 블록에 그대로. 요지: Q1~Q5 (a). **Q6는 문항의
전제를 사용자가 정정** — *"'먼저다' 는 아니긴 함. Claim 을 건다던가, 어딘가 이미
Parent 가 셋팅 되든 우린 상관 안 함. 우리가 정의할 수 있는건 단지 자식이 다
붙은 다음이지"* → `PostRef`의 보장은 "자기 서브트리 완성"뿐, 부모 부착 여부는
어느 쪽도 보장하지 않음(정본 "`PostRef`" 절·ROADMAP M8 정정). **Q4는 지시**
(*"다른 내가 못 본 동작 변이가 있는지만 보고, 괜찮다면 택해줘"*)대로 훑었다 —
같은 v 재진입만 고쳐지고(dedup), 다른 v'로의 재진입은 순서와 무관하게 기존
UB, 콜백 error 중단은 no-pcall 계약상 실질 차이 없음 → (a) 채택, 정본 의사코드
`relate:SetWeak`를 `v:Set(inst)` 앞으로. **Q5**: *"항상 기다리면 돼. 그럴 땐
Option/Monad 같은 값을 제공하면 된다고 생각함 … 유저가 간단히 만들어 주입
가능한 타입"* → `Wait`는 채워져 있어도 다음 `:Set`까지, "값 없음"의 구분은
사용자가 `Just`/`Nothing`류를 `T`로 주입(quad가 개념을 도입하는 건 필요 시
사용자 결정) — 정본 "API 모양" 절에 등재.

## 2. 단위 ①

- `Ref.luau` `:Wait(thread?)` — 대기자는 이미 M2가 `:Set`의 thread 키 분기로
  받아 두었던 자리(`spec.ref` 9절이 흉내 내던 등록을 실물로). 태깅 `H-231`.
- `PreRef.luau`/`PostRef.luau` — 같은 템플릿(브랜드·마커·`_fired`만), 헤더에 각자의
  fire 시점(PostRef는 Q6 정정 반영).
- quad-types: `Wait`, `PreRef<T>`/`PostRef<T>`(교집합 마커 nominal), `Quad` 필드.
  새 export type이라 relink만으론 안 보이고 `pesde install`이 필요했다.
- spec: `spec.ref` 12~14절, `spec.preref` 3절. 3절을 짜다 정본 "Modifier 필드
  어디든" 옛 문장이 `modifier-plan` 4절과 어긋난 걸 봤다 → `H-316` 한정 각주.

## 3. 끝 절차

감사 1라운드 8건(옛 "부모에 붙기 전" 서술 5곳 — lifecycle-hooks-plan 두 곳·
documentation-content-map·README 두 행, `Modifier 필드` 잔여 2곳, round12
포인터 닫힘) 반영. `/code-review medium` 2건 — `Ref<T>` self 반환 메소드를
`<Self>` 제네릭으로(`H-317`, 소형 실측 뒤 반영; 확인 항목으로 §4에), `:Wait()`
`isyieldable` 가드(`H-318`). doc-check ERROR 0, test.sh 39 파일 통과.

## 4. 단위 ② — 핸들러 넷 + drive pre-pass

체크리스트(dispatch-core-plan "Handler 작성 체크리스트") 1~8 재독 후 착수.
배치: `Dispatch/Ref.luau`(pre-pass·`postRefList`·센티널·`Processed*` 핸들러 —
`Ref.luau`가 Dispatch를 require하므로 순환 회피, M7 `Dispatch/Modifier.luau`
선례) / `Ref.luau`(`RefLeafHandler` + 가드 둘, `H-278`). `spec.refhandlers` — Q4
재진입 케이스가 dedup으로 통과함을 실물로 확인. Studio: rojo serve가 죽어
있어(sourcemap 워처만) 재기동 → 플러그인 autoReconnect가 잠시 뒤 잡힘 → 8/8
(`audit/m8-unit2-studio-2026-09-04.md`). `H-320`.

감사 1라운드가 **정본과의 순서 모순 둘**을 잡았다 — PostRef fire를 배치
종료·recompute 뒤에 뒀는데 정본(`H-17` 두 곳·bind-system (c))은 배치 닫기
**앞**(게이트 켜진 채, recompute 하나가 catch-up)이고, pre-pass의 소진/fire
순서도 정본과 반대로 써 놓고 "재드라이브 안전"이라는 근거 없는 재량을 붙였다.
둘 다 정본대로 되돌림(갈래 ① — 문서가 답을 가진 것). spec에 게이트 켜짐 단언·
`State<PostRef>` 가드·`Processed*` retract no-op 추가, ROADMAP M8에 단위 ③
`[ ]` 신설(체크박스 100%가 M8 완료로 읽히던 문제).
리뷰 7건 — 첫째가 무거웠다: pre-pass를 게이트 `On()` 앞에 둬서(정본 ⓪→(a)
위반) PreRef 콜백이 부기를 건드리면 recompute가 죽는 걸 리뷰가 실측으로
잡았다 → 게이트 뒤로. `_fired` 시점은 정본대로 유지(기각 기록), 가드 문구
숫자 키 분기·nop 본문 공용화·브랜드 조회 축소·PreRef/PostRef 공용 팩토리·
미사용 인자 반영. Studio 재실측(순서 정정 뒤) 3/3.

## 5. 단위 ③ 스파이크 — `H-321`

실물 D + quad-types로 `<Class>Elem`에 `Ref<Frame?>`를 직접 넣어 봤다: 형제
클래스 `PreRef`·`State<Ref>`·오타는 거부되는데 **plain `Ref<TextLabel?>`와
`Ref<nil>`이 통과**(8.9절 — `<Self>` 제네릭이어도). 반공변 팬텀 필드
`read __quadRefAccepts: (T) -> ()` + 클래스별 마커 `{ read __quadRefAccepts:
(Frame) -> () }`는 4/4 거부·양성 통과·2.6s. 소형 재현(`luau-test/32`)은 직접
멤버 케이스를 잡아버려 실물을 대표하지 못했다(헤더에 기록). 새 메커니즘이라
Q3 회신대로 §4 문항으로 올리고 멈춤.

## 6. `H-321` 회신 + 단위 ③ — M8 완료

사용자 질문 *"이미 Set(Frame?) 이 들어있어서 … 오류 나지 않아? __quadRef.. 랑
같은거 아냐?"* → 실측으로 답: `{ read Set: (self: any, v: Frame?) -> any }` 단일
타입에도 `Ref<TextLabel?>`가 통과(제네릭 메소드 반공변 미검사) + 유니언에선
`State.Set` 이름 충돌 — 팬텀 필드는 그 검사를 솔버가 실제로 하는 이름으로 옮긴
것. 사용자: *"이해함. non-lazy type 으로 T 비교자를 넣어 굽는구나. 권고대로
진행해도 될것 같아"* → 단위 ③: quad-types `__quadRefAccepts`, `Ref.luau` `Void`
필드, 생성기 `<Class>RefMarker`(+ `State<…>`), `spec.reftypes`, 실물 음성 4/4.
`H-322`. **M8 완료.**
끝 절차: 감사 4건(types.luau의 "kept out now"·onchange-plan 정본 공식·8.9
헤더·brief §1) + 리뷰 6건 중 5(빈 슬롯 등록·센티널 생성자 공용화, 팬텀 필드
메타테이블 상주, `Init` 별칭, spec 헬퍼 + `{ r, r }` 케이스) 반영, one-shot 가드
공용화는 보류. 리뷰가 되짚은 후보 다섯(`H-170` 죽은 스레드 resume·`H-103`·
in-place 변형·`<Self>`·캐스트 관용구)은 전부 확정 계약이라 비조치.

## 7. `H-317` 수용

사용자: *"나도 자주 쓰는 패턴이라 괜찮아. <Self>(Self)->Self 라면 OK, 다른 타입
부작용을 심각한게 있는게 아니라면 택해도 좋아. 실측 해보고 나서"* → strict
스크래치로 부작용 실측: 무주석 체이닝 추론·콜백 인자 추론·`Epoch`/`Effect` dep
자리·`PreRef` 마커 보존 전부 성립, 음성 정상. round18 열린 문항·확인 항목 0.


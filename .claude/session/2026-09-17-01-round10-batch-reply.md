# 2026-09-17-01 — round10 배치 회신: `Q48`~`Q58` 열하나 대화형 해소

> 입력: `qa-request/post-implementation-review-round10.md` §4·§7·§8·§9의 사용자 문항 열하나. 사용자 지시: *"다음 배치 파일에 대한 인터랙티브 해결 작업을 수행해보자. 문제에 대해서 서술해주면 내가 답을 이어나갈게"*. 문항마다 평문 서술 → 사용자 결정 → 반영·게이트·커밋 한 사이클(커밋 열한 개, `720bf60..1e3e468`). 결정 원문은 각 `base/` 문서의 같은 날 항목이 소스이고, 여기는 흐름과 논거만.

## 결정 목록(순서대로)

1. **Q48 (a)** — 정적 자식·숏핸드 관리 자식도 Slot과 **같은** `elementOwner` 레지스트리에. 사용자: *"처음부터 막으려고 했던 표면인데, 안 막혀있는 부분 … elementOwner 는 공유적으로 둘 다 대칭으로 들어간다 보는데, 두 곳에 놓을 이유가 있나 모르겠음 … 이 변경은 괜찮아 (멀쩡한 소비자에는 큰 차이가 안 나)"*. `q.Bookkeeping.claimOwnerAt`/`releaseOwner` 공개. `claim-plan.md` 16번.
2. **Q50 (a)** — `_recompute` 재진입 가드. 사용자: *"순수 flag 로 막는게 가능하고 … 유저의 흔하게 날 수 있는 실수라 … 순환이나 yield 를 권장하는 확장된 방향은 가고싶지 않고 … 단순 마법 없이 flag 셋으로 만족"*. 구현 조정 둘(메인, 사용자에게 보고): 플래그를 불린이 아니라 **세대 스탬프**로(pcall 없이 일시적 검증 raise가 노드를 영구히 죽이지 않게 — `spec.operator` 6 실제 파손이 계기), `spec.state` 6의 옛 "다음 Get이 재시도" 계약을 "새 세대에서 재시도"로 좁힘. 부수: `spec.lengthoffset` 10의 H-240 원 재현이 이제 이 에러(길이 Compute가 자기 owner 부기를 건드림 = 중첩 재계산의 자기 읽기). `state-epoch-plan.md` 끝 절.
3. **Q51 (a)** — `_pending` 하강을 cleanup 뒤·fn 직전으로. 사용자: *"진짜 소비된게 맞아서 순서의 문제라 a가 맞는것 같아"*.
4. **Q52 (a)** — 마운트 walk 중 조상 CRUD·`:List` 설치는 `_materializing` 가드로 즉시 error. 사용자: *"compute 든 slot 이든 순수성 제약을 크게 풀어줄 이유가 없어서 … 던져도 될것 같아. 정상 사용에서 문제가 생기지 않는지만 봐줘"* → `spec.slot` 32가 정상 사용 셋(자기 자식 Slot 구성·마운트된 형제 CRUD·마운트 뒤 재조정/CRUD) 확인.
5. **Q55 (b)** — Time을 신호 진입에서 한 번 읽어 캐시. 사용자가 흐름도를 요청해 확인(*"확인했어"*). 의미 변화 하나: 신호 없이 Time만 바꾸면 다음 신호부터; leading 게이트의 던지는 신호는 통과 전에 던져 집합에 보류.
6. **Q56 (b)** — UB 문서화(`H-184` 범위를 `_assertBindable`로 좁힘). 사용자: *"에러로 인해 자료가 깨지는건 일반적이고, 그에 비해 에러를 내는 조건이 어려워서 UB에 가까운것"*. 메인이 원장의 (c) 권고를 철회(던지는 위치만 옮길 뿐 반쪽은 같다).
7. **Q49 (a)** — `nativeFindChild(inst, key, className?)`. 사용자: *"엔진별 요소들을 너무 많이 알아야하나 싶었는데 그건 아니기도 하고 … 이름만 보던 함수에 className 넣고 검사 한번 한다라면 난 동의"*. 원장의 "(b)에 가깝다" 논거 철회(base는 `_className`을 이미 들고 있었다). mock에 `IsA`(계층 없는 동등) 추가.
8. **Q57 — 사용자 제안(갈래 밖)** — `_consumeCleanup`이 `self._dying`을 cleanup의 `dying: boolean` 인자로 넘기고 `OnDestroyed`가 `if dying`. 사용자: *"_dying 이 true 로 새워지는건 오직 onDestroying 콜백 뿐이고, 내부적으로 있는 값을 외부에 노출해주는것일 뿐"*; 공개 `Dying` 필드 대안은 사용자가 기각(*"값이 설정되는 순간 순간에 진실성이고, 생명주기 계약 자체는 외부에서 접근하는데 있어 도움이 안 되는것"*). 메인 검증: 소진 자리 넷 중 Destroying 콜백만 `_dying` 참.
9. **Q58 (가) 안 좁힘·(나) 오프셋** — 사용자: *"단순히 '우리가 가졌나? 부기를 깨지 않아 지울 수 있냐?'를 보고 지워줄 뿐 … 계약 자체를 '부기를 깨지 않는 조건을 성립하고 안전히 제거'에 가깝게"* / *"handler dispatch 는 결정론적으로 해석되지 않기 때문에 각각 오프셋 되어 슬롯을 가지는게 이롭게 보임"*. `Event`·`OnChange` = NORMAL − 1. `claim-plan.md` 18번.
10. **Q53 (a)** — Tween 체인만 실제 retractor(철거 때 Cancel + 슬롯 비움). 사용자 실기기 사실: *"파괴된 인스턴스에 대한 tween 은 삭제되고, 코너는 갑자기 사라져"*; 사용자 질문 "Finish/Cancel은 새 Tween의 설정이 정하나?" → 맞음(`v.Override`), 그래서 철거엔 Cancel뿐. G-7 보강 같이 닫힘. `tween-plan.md` 끝 절.
11. **Q54 — 구절 추가** — 사용자: *"다른 쪽에서도 에러를 다듬어서 나는 경우를 여럿 설명해 해결했었는데, 여기도 똑같은 이야기"*.

부수: 사용자 에디터 실측 타입 에러 하나(`Slot/init.luau` `seen[occupant] == "held"` — unrelated types) → `{ [any]: boolean | "held" }` 주석(`28b709e`).

## 게이트

매 커밋 test.sh exit 0(스펙 61), doc-check ERROR 0, `sync-docs.py`. 스펙 신설: `spec.handlers` 12·13, `spec.shorthand` 8·9, `spec.state` 14(+6 갱신), `spec.lengthoffset` 10 재작성, `spec.effect` 끝 절 둘, `spec.slot` 32, `spec.debounce` 9 후반(+7c 갱신), `spec.hooks` 5, `spec.claim` 11. CHANGELOG `[Unreleased]`: Added 둘(cleanup `dying`, `Bookkeeping.claimOwnerAt/releaseOwner`), Changed BREAKING 둘(정적 자식 단일 마운트, Compute 재진입) + `nativeFindChild` 셋째 인자(프로바이더 BREAKING) + 우선순위 오프셋, Fixed 다섯.

## 메인이 결정 범위 안에서 조정하고 사용자에게 보고한 것

- Q50 세대 스탬프(위 2번) — 사용자가 되돌리길 원하면 불린으로 환원 가능(그 경우 `spec.operator` 6·`spec.state` 6이 바뀐다).
- Q55 leading 게이트의 던지는 신호가 통과 전에 던진다(스펙 7c 기대값 갱신) — 흐름도에 "idle이면 Off 그대로"로 적었고 사용자가 확인한 범위 안.

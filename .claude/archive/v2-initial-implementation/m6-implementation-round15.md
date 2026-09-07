# M6 병렬 탐사 구현 — 15라운드 발견 원장 (fork)

> **이 파일이 무엇인가**: **[2026-09-02 신설]** M6(Slot — mock 축) 병렬 탐사
> fork가 실제 코드를 옮기고 돌리다 나온 발견 전부. 규약은
> `m6-implementation-round15-brief.md`. 번호는 **`H6-1`부터**(접두로 메인
> `H-nnn`·M10 `H10-nnn`과 구분, ID 영구).
>
> **갈래 표기**(브리프 §2): **①** 자율 수정(코드+이 원장 같은 커밋) / **②**
> 사용자 결정 필요 — 원장에 문항+권고, 의존 작업 보류(`-- TODO(H6-n)` 마커),
> 막히면 이 fork 채팅에서 사용자 회신 대기 / **③** 대량 무효화 → 즉시 중단.
>
> **상태의 소스는 이 파일 자신** — 요약 표의 상태 열이 최신.

## 요약 표

| 번호 | 갈래 | 심각도 | 한 줄 | 상태 |
|---|---|---|---|---|
| `H6-1` | ① | 🟡 | (슬라이스 2, `H-232` (a) 예고분) `Bookkeeping.getBookkeeping`이 Slot ownerKey를 못 다뤘다 — 무조건 `module.bindLifetime(ownerKey, bk)`를 부르는데 Slot은 claim 불가라 mock `isMockInstance` 가드(실물은 `H-290`)로 죽는다. 헤더가 "M6에서 `SlotBrand` 분기"라 예고해둔 몫 | ✅ 반영 — `getBookkeeping`이 `SlotBrand:is`면 `slot._bk`(강, lazy)를 쓰고 물리 inst만 weak Relate+bindLifetime. bk 테이블 리터럴은 `newBk()`로 추출 |
| `H6-2` | ① | 🟡 | (슬라이스 2) Slot이 `recompute`를 직접 부르는데(정본 materialize/rawRemove 꼬리) **Dispatch 공개 테이블이 `recompute`를 재노출 안 함** — 5개만(setLength/setOffsetSource/getOffsetAt/getBlocker/getBookkeeping). `H-277` 분리 때 recompute는 `module._bookkeeping`에만 남음 | ✅ 반영 — Bookkeeping 헤더가 *"Slot must reach [it] WITHOUT going through Dispatch, {Slot,Dispatch}→Bookkeeping"*라 명시한 그대로 **Slot이 `module._bookkeeping`을 직접 캡처**해 여섯 op(recompute 포함) 사용. Dispatch 표는 안 건드림(M3 무영향) |
| `H6-3` | ① | 🔴 | (슬라이스 2, GC 계약) `Slot_mt`를 파일 스코프에 두면 `Slot.Init(module)`이 매 인스턴스마다 그 테이블에 `module` 캡처 메소드를 재대입해 **마지막 quad 모듈을 전역으로 붙잡는다** — `spec.init` 2번(`H-181` New() 인스턴스 GC)이 즉시 깨졌다 | ✅ 반영 — `Slot_mt`를 `Init` 안으로 이동(인스턴스별 메타테이블). 반응형 모듈이 `Init` 안에서 임플을 만드는 `H-174` 패턴과 같은 이유 |
| `H6-4` | ① | 🟢 | (슬라이스 2 관측) **마운트 전 `Slot.Length`는 0이다** — `rawAdd`의 미실체화 얼리리턴이 부기·`recompute`를 안 타므로 `Slot{a,b}` 직후 `.Length:Get()`은 0, 마운트돼야 2가 된다. 정본의 "마운트된 요소 개수" 정의와 일관되나 CRUD-후-즉시-읽기 사용자에겐 놀라울 수 있음 | 🟢 기록만 — 결함 아님(설계대로), spec은 마운트 후로 단언. 문서화 후보 |
| `H6-5` | 🟢 | — | (슬라이스 3·4 관측) 정본 의사코드가 대부분 **수정 없이 조립됐다** — **무수정 확인**: attach 3형제(materialize/mount/attachSlot 재귀, Length=기여도 합, 언마운트 재귀+포탈), reconcile/settle(추가/갱신/재사용/제거/필터/dup-key error), wrap/unwrap, `:Single`+`Add(state)`, Detach 재사용, 상호배타 가드, **`:List` Slot 언마운트→재마운트 상태 보존+캐치업 1회(H-163)**. **정본 축약 이식(무수정 아님)**: `rawMove`는 정본에 의사코드가 없어 규약대로 짰고 H6-6를 냈다. **간접 검증만**: `rawReplace`/`rawDetach`는 spec 직접 단언 없이 reconcile 경유로만 밟힘 | 🟢 기록만 — slot-plan.md 정본 검증됨(mock 축, 위 갈래대로). 실기기·잔여 공개 CRUD·`KeyGone` 파괴 분기는 §4 밖 참고 |
| `H6-6` | ① | 🔴 | (슬라이스 4, advisor 지적으로 재현) `rawMove`가 `_elements`·`bk.indexOfElement`만 순열하고 **`bk.sourceList`/`lengthList`/`observers`를 안 옮겼다** — 정본 raw* 규약 1번("넷 다 같은 순열")을 어겨, 리오더 후 `recompute`가 **옛 점유자의 Offset Source에** offset을 쓴다(State 요소 리오더 시 자리가 어긋남). plain-element인 test 10은 sourceList가 전부 None이라 이 결함을 못 봄 | ✅ 반영 — 래퍼 Slot(=비-None sourceList) 리오더 테스트(spec 14)로 재현 확인 후, `rotateInPlace`(nil 구멍 있는 `observers`도 안전한 인덱스 대입 회전)로 세 배열을 `_elements`와 같은 순열로 이동 + 캐시 무효화 + recompute. `nativeMove` 미호출은 mock/Roblox no-op이라 무해(§4에 백엔드 주의로 기록) |
| `H6-7` | ① | 🟡 | **[2026-09-03 통합 `/code-review`]** `SlotHandler.isHandlable`이 `isSlot(v)`만 보고 **`type(k) == "number"` 가드(`H-52`, Tag/Attribute 핸들러엔 있음)가 없었다** — 이름 키에 놓인 Slot이 HIGH 매치 → claim·bindLifetime 커밋 뒤 `Bookkeeping.checkPosition`이 내부 에러로 터지며 소유권·생명주기 바인드가 고아로 남음 | ✅ 반영 — 가드 추가, spec.slot 16절(매치 실패로 떨어지고 `canBound(s) == true` — 고아 없음) |
| `H6-8` | ① | 🟡 | **[통합 `/code-review`]** `:List` reconcile이 keyFn의 nil 반환을 검사하지 않아 `seen[key] = true`에서 Luau 원시 에러("table index is nil") | ✅ 반영 — 도메인 에러(`Slot:List — keyFn returned nil for item #i`). **blame 실측 하나**: reconcile은 마운트/emission 깊이에서 돌아 `errorBeforeNearest`가 raise 자리로 폴백 → 옆의 중복 키 raise와 함께 `errorBefore`(최외곽, `H10-2` 규칙)로 통일, spec이 사용자 줄 blame 단언 |
| — | 🟢 | — | (통합 `/code-review` 정리 후보 — 사용자 판단) `rawUnmount`/`rawDetach`/`rawRemove`의 동일 7줄 꼬리 + recompute 게이트 4곳 복붙 — slot-plan이 "raw 삼형제"로 **의도적 분리**를 문서화한 자리라 헬퍼 추출은 정본 갱신을 동반하는 설계 변경(conventions 2026-08-27: 새 헬퍼는 사용자 결정) → 아침 검토 목록 6번 | ✅ **[2026-09-03 사용자 확정 — 공용화 승인]** *"코드 스타일/유지보수성 문제라, 적절히 함수로 빼어내 관리가 된다면 … 개발 문서와 주석만 충분하고 흐름을 인간이 읽기 좋다면, 난 찬성"* — **[같은 날 반영]** `vacate`(꼬리)·`maybeRecompute`(게이트)·`unbindObserverAt`(머리 첫 줄) 추출, slot-plan "raw 3형제" 절 동기 |
| `H6-9` | ② | 🟢 | **[2026-09-03 M6 잔여 마감]** `Splice`의 물리 op 형태 — 정본 native* 절은 *"`Splice`도 `nativeExtract(…, removed, newElements)` 한 호출로 표현된다(리플로우 2회와 그 사이 창 제거)"*인데, 구현 `rawSplice`는 Blocker 합침으로 **recompute 1회**는 지키되 **물리 op은 요소별**(`rawUnmount` 역순 + `rawAdd`)이다. 한 호출로 만들려면 새 요소 중 중첩 Slot의 리프를 먼저 실체화만 하고(mount 없이) 리프를 모아 실은 뒤 마운트 플래그만 세우는 walk(= `mountSlotTree`를 플래그/물리로 쪼개는 새 헬퍼)가 필요 — 새 메커니즘이라 ② | ✅ **[2026-09-03 사용자 확정 — (b)]** *"사실, b가 정확한 구현이긴 해. 그리고 그걸 위해 collectLeaves 를 만들었던거 아녔어?"* — 마운트/언마운트를 플래그 walk(`markMountedTree`/`teardownTree`)와 물리 op 하나로 분리, `rawSplice`가 `deferPhysical`로 부기만 세운 뒤 리프를 모아 `nativeExtract(target, offset, removed, new)` 한 번(삽입만이면 `nativeInsert`). 부수로 일반 마운트/언마운트도 서브트리당 한 호출. `spec.slot` 19 스파이 단언, Studio 11/11(`audit/m6-remainder-studio-2026-09-03.md` 2절) |
| `H6-10` | ① | 🟡 | **[M6 잔여 마감]** Slot 공개 표면이 `H-238` 미태깅(fork는 `dispose`만) — `H10-7`이 Tag/Attribute에서 닫은 것과 같은 결. `slot:Move(0, 1)` 같은 인자 검증 에러가 사용자 줄이 아니라 `Slot.luau`를 blame | ✅ 생성자 `Slot`·공개 메소드 전부 `setFuncLevel`(전부 테이블 저장 함수라 스파이크 27 인라이닝 규칙 충족), `spec.slot` 17이 blame 단언 |
| `H6-11` | ① | 🟢 | **[M6 잔여 마감]** `spec.slot` 12의 `theFrame._destroyed` 단언이 **vacuous** — mock 프록시엔 그 필드가 없어(`data.destroyed`는 내부) 항상 `nil`이라 "파괴 안 됨"이 검증된 적이 없었다 | ✅ `mock.isDestroyed(inst)` 술어 신설, 12와 새 절 전부 그걸로 단언(실제로 파괴/생존이 갈리는 걸 확인) |
| `H6-12` | ② | 🟡 | **[M6 잔여 마감 — 손 트레이싱, 통합 리뷰가 재현으로 확정]** `Owned = false` Slot(`Add(state)`의 래퍼 포함)이 **살아서 나갈 때 안쪽 요소의 소유권을 안 놓는다** — 파괴 walk(`destroySlotTree` → `unmountSlotTree`)뿐 아니라 **공개 `Extract`/`ExtractAll`/`Splice`로 State 요소를 빼낼 때도** 같다(`rawUnmount(래퍼)` → `unmountSlotTree`는 래퍼 자신의 요소를 반납 안 함). 리뷰 재현: `st = Source(g); s:Add(st); s:Extract(1)`은 `st`를 돌려주지만 `elementOwner[g]`가 버려진 래퍼로 남아 **다음 `s:Add(st)`가 "already mounted"**, `dispose(g)`도 거부 — 래퍼가 GC되면 통과라 비결정(정본 *"요소를 살려서 내보내는 경로는 소유권 반납을 GC에 맡기면 안 됨"* 위반). `:List` 안의 교체/제거는 `releaseElement → rawUnmount`로 반납하므로 그쪽은 멀쩡 | ✅ **[2026-09-03 사용자 확정 — (b), 좁은 처방]** *"우리가 래핑해 가지는 구현은 State -> Slot 구현 뿐이라서 … 래퍼라서 문제 되는 부분인지라, 그 부분만 좁게 해결하는게 맞아보여"* — `_wrapped ~= nil`인 슈가 래퍼가 요소로서 떠날 때(`leaveAsElement`: `rawUnmount`/비파괴 `rawReplace`/`rawSplice`)와 파괴 walk의 `_owned == false` 분기에서만 안쪽 요소 `releaseOwner`(`releaseSugarWrapper`). 재클레임 자리 없음 — 슈가 래퍼는 재마운트되지 않는다. 포탈·사용자 `Owned = false` 리스트는 그대로. `spec.slot` 18이 재-Add·`dispose`·`Remove` 뒤 재클레임 단언, Studio 실측 |
| `H6-13` | ① | 🟢 | **[M6 잔여 마감]** `nativeMove`의 `toOffset` 의미가 미정의였다(정본은 시그니처 주석 "범위 이동(사이가 밀림)"뿐) — fork의 `rawMove`가 물리 op을 아예 안 불러 드러나지 않았고, "이 fork 슬라이스 밖" 절이 확인 몫으로 넘긴 것 | ✅ "이동 **후** 블록 첫 리프의 절대 offset"으로 명확화(slot-plan native* 절 각주), `rawMove`/`rawSwap`이 `collectLeaves`로 리프 배열을 만들어 호출(규약 5·6 실현), `spec.slot` 17이 인자(offset·리프 배열)를 스파이로 단언 |
| `H6-14` | ① | 🟢 | **[M6 잔여 마감]** ROADMAP M6 마지막 체크박스·slot-plan 경계 절·architecture 소스 트리가 말하는 `quad-roblox/Handlers/Slot.luau`("실제 Parent 조작")는 2026-08-21 `native*` 층 확정으로 **`EngineOps.luau`의 native* 여섯이 그 자체**가 됐다 — 별도 파일이 맡을 몫이 없다(M5 단위 ①이 실제로 그렇게 짰고 architecture EngineOps 줄이 이미 그렇게 서술) | ✅ 세 문서 정정(한때 표기 각주), ROADMAP 체크박스 `[x]` |
| `H6-15` | ① | 🟢 | **[M6 잔여 마감]** round12 §6 `H-286` ②(unbind가 leaf dedup relate를 못 비워 포탈 재마운트에서 재바인드 스킵) — M6 몫으로 유일하게 열려 있던 것 | ✅ **기각** — Slot 포탈 경로는 leaf dedup relate를 지나지 않는다(`_baseObserver`/`_listObserver`/`_detachCleanup`/`bk.observers` 전부 `bindLifetime` 직접), leaf 핸들러 retractor는 stand-down 때 relate를 비운다(`Observer.luau`). `spec.slot` 15가 포탈 재마운트+캐치업 실측. round12 §6에 기각 기록 |
| `H6-16` | ② | 🟢 | **[M6 잔여 마감]** quad-types `Detach`/`KeyGone` 타입 — `None`은 `H-300` 마커 필드로 좁혔는데 둘은 런타임 마커가 없어 `{}`(빈 테이블 타입)으로 자리표시. `updateFn`이 `KeyGone`을 `item` 자리로 받는 유니온(`Item | KeyGone`)이 실질 무의미 | ✅ **[2026-09-03 사용자 확정 — (a)]** *"마커 필드 두는거 동의(이미 그렇게 행해 왔으며 문제가 없었음)"* — `__quadDetach`/`__quadKeyGone` 마커 + quad-types `{ read __quadDetach: true }`형. **[통합 리뷰 보정]** 신원 비교(`item == KeyGone`)로는 안 좁혀지고 truthiness 좁힘만 — 사용자 `Item` 쪽 캐스트가 남을 수 있음을 타입 주석에 명시 |
| `H6-19` | ① | 🔴 | **[통합 `/code-review medium` — 확정 4건 묶음]** ⑴ `rawSplice`가 배치 Blocker를 켠 채 도는 동안 raise가 나면 게이트가 **영구히 켜진 채** 남아 그 Slot의 Length/Offset이 동결 — 도달 경로는 파괴된 Slot을 새 요소로 넘기는 것(선행 패스가 `_destroyed`를 안 봤다) ⑵ 선행 패스가 **래퍼**를 검사해 State 요소엔 무력(같은 State 두 번 / 값이 딴 데 마운트된 State가 통과 → reconcile 깊이에서 raise, 반쪽 상태) ⑶ 언마운트된 중첩 Slot에 CRUD 후 재마운트하면 옛 마운트의 `bk.N`/lengthList가 남아 Length 부풀림·형제 offset 오류(`Extract`가 첫 공개 경로 — 메커니즘은 diff 이전) ⑷ `Slot{bad}`가 생성자의 `self:Add` 프레임을 blame(태깅된 Add가 더 가까움) | ✅ ⑴⑵ `wrapElement`가 파괴된 Slot을 거부 + `prepareElements`가 **raw 값**으로 중복·소유권(State면 현재 값) 검사, `Add`도 같은 패스 ⑶ `unmountSlotTree`가 미실체화 불변식 복원(위치 부기 넷+캐시 리셋, `bk`·`indexOfElement`·`recomputeBlocker`는 유지) ⑷ 생성자가 `rawAdd` 직접 호출. `spec.slot` 22, slot-plan 에러 조건 절 각주. native* 자체가 던지는 경우의 게이트 잔류는 백엔드 결함 = UB(예외 안전성 계약 "감싸지 않는다") |
| `H6-20` | ② | 🟡 | **[통합 `/code-review medium`]** `nativeSwap`의 물리 계약이 **리프 수가 다른 두 블록**에선 성립 불가 — 정본은 "사이 고정, offset은 교환 전후 같다"인데 `[a(1), c(1), inner(2)]`의 `Swap(1,3)`은 올바른 물리 배치가 `i1,i2,c,a`라 가운데 `c`가 밀려야 하고, op엔 그걸 옮길 정보가 없다. 폴백 "`nativeSwap` = `nativeMove` 2회"는 크기가 다르면 다른 결과. Roblox/mock은 no-op이라 spec 17이 통과할 뿐(부기 쪽 `invalidateFrom`+recompute는 옳다) | ✅ **[2026-09-03 사용자 확정 — (a)]** *"계약 문구 제정의 동의"* — slot-plan native* 절의 시그니처 주석·"`nativeSwap`이 따로 있는 이유" 항목·`H6-13` 각주를 "두 블록을 맞바꾸고 사이 요소는 크기 차만큼 밀린다, offset 인자는 교환 전 값"으로 정정. 코드 무변경 |
| `H6-21` | ① | 🟡 | **[단위 끝 탐사자 — 재현]** `:List` reconcile은 `updateFn` 반환값에 선행 검증이 없다 — 반환 State의 현재 값이 딴 데 마운트돼 있으면(또는 `updateFn` 자체가 던지면) 배치 Blocker가 켜진 안에서 raise → 게이트 영구 잔류 + `_elements` 반쪽, 이후 `data:Set`이 조용히 무효(재현 스크립트 2종). 공개 CRUD의 `H6-19` ⑵ 처방을 사이클 전체로 넓히려면 `updateFn` 2회 호출이나 `pcall`이 필요 | ✅ **문서화로 닫음** — `architecture.md` "예외 안전성 계약 — 감싸지 않는다"(사용자: *"에러가 난 이후 데이터의 무결이 깨져도 별 책임 안 진다"*)가 적용되는 또 하나의 자리로 slot-plan 선행 패스 절에 명시. 코드 무변경(사용자가 계약을 바꾸면 그때 ②) |
| `H6-22` | ① | 🟡 | **[단위 끝 탐사자]** `quad-types` 새 `export type` 5개가 소비자 require 경로(`luau_packages/quad_types.luau` — pesde 생성 재export 심, gitignore)에 없어 `QuadTypes.Slot`이 "Unknown type" — `relink.sh`는 `.pesde/` 사본만 갱신하고 심은 안 건드린다 | ✅ `pesde install` 재실행으로 심 재생성(36 export), `project-setup-plan.md`에 규칙 등재 |
| `H6-23` | ① | 🟢 | **[회신 반영 중 손 트레이싱]** `rawReplace`의 미마운트(실체화됨) 분기가 비파괴 교체(`Extract(index, new)`)에서 옛 중첩 Slot을 **아무 정리 없이** 버렸다 — 그 서브트리의 `_baseObserver`·length observer가 물리 target에 묶인 채 `_physicalTarget`도 그대로 | ✅ 그 분기에서 `leaveAsElement(old, true)`(논리 teardown + 슈가 반납) — 마운트 분기의 `unmountSlotTree` 호출도 같은 헬퍼로 |
| `H6-24` | ① | 🔴 | **[회신 반영 `/code-review medium` — 확정 3건 묶음]** 선행 검증이 **raw 값** 단위로 dedup해 **점유자**(State의 현재 값) 단위 aliasing을 못 봤다 — ⑴ 한 Splice에 같은 Instance를 든 State 둘(또는 raw+State) → 래퍼의 claim이 배치 게이트 안(마운트 시점)에서 raise → 게이트 영구 잔류 ⑵ 마운트 전 `Add(State(g))` 둘 → `materializeSlotTree` 순회 중 같은 누수 ⑶ 미실체화 `Extract(i, new)`(`rawReplace` 미마운트 분기)가 `_physicalTarget == nil`이면 슈가 래퍼 반납을 건너뜀(이전에 마운트됐던 래퍼의 claim이 남음 — `H6-12` 처방의 구멍) | ✅ `prepareElements(self, …)`가 점유자(`occupantOf` — 래퍼면 `_wrapped:Get()`)로 dedup하고 `self._elements`의 기존 점유자까지 seen에 넣음(마운트 전 래퍼는 아직 claim이 없어 elementOwner만으론 못 봄) / 미실체화 분기도 `_wrapped`면 반납. `spec.slot` 23 |
| — | 🟢 | — | **[회신 반영 리뷰 효율 후보 — 기록만]** `rawMove`가 `#leavesOf(els[to])`로 서브트리를 평탄화해 리프 수를 얻는다(`Length:Get()`이 같은 값) — **채택 안 함**: reconcile 배치 안(Blocker on)에선 중첩 래퍼의 `Length`가 recompute 지연으로 낡을 수 있어 리프 수를 구조에서 세는 쪽이 정의상 옳다 / `rawSplice`의 위치별 `reindexFrom`은 위 효율 행과 같은 항목 | 🟢 실측 원칙 |
| — | 🟢 | — | **[통합 `/code-review medium` 정리·효율 후보 — 기록만]** `rawSplice`가 k×`rawUnmount` + m×`rawAdd`로 꼬리 시프트를 (k+m)번 반복(O((k+m)·n)), `table.insert(removed, 1, …)`/`ExtractAll`의 앞삽입 O(k²), `rawMove`의 `#leavesOf(els[toIndex])`가 크기만 읽으려고 서브트리를 평탄화 | 🟢 실측 원칙(관측된 병목 없음) — `H6-9`가 열리면(단일 물리 op walk) 같은 자리에서 구간 splice로 함께 다룬다 |
| `H6-17` | ① | 🟢 | **[M6 잔여 마감 — 툴링]** `.relink-manifest`(gitignore)에 삭제된 fork 워크트리 경로가 34행 남아 `test.sh`가 "스킵 때문에 트리가 최신이 아니다"로 exit 1 | ✅ 그 행 제거. **워크트리 제거 관례에 "매니페스트의 그 경로 행 제거"가 딸려야 한다** — 아침 검토 5번(관례 등재 위치)의 연장, 등재는 사용자 판단 |
| `H6-18` | ① | 🟢 | **[M6 잔여 마감 — 타입 실측]** quad-types `Slot<T>` — `updateFn` 타입을 별도 alias(`SlotUpdateFn<Item, T, UD>`)로 빼면 `Slot<T>` ↔ `SlotElement<T>` 재귀 그룹 안의 "Recursive type being used with different parameters"로 거부 | ✅ 메소드 시그니처에 인라인, typing-limits §1 "정확한 경계" 각주 |

## §4 배치 문항 (회신 대기)

**[2026-09-03 M6 잔여 마감]** 넷이 올라갔고 **같은 날 전부 회신·반영됐다**
(사용자: `H6-9` (b) / `H6-12` (b) 좁은 처방 / `H6-16` (a) / `H6-20` (a) —
결정 원문·근거는 요약 표의 각 행과 `session/2026-09-03-02-m6-remainder.md`
"회신 반영" 절). **열린 문항 0.**

## 이 fork 슬라이스 밖 (통합 시 메인/후속 몫)

**[2026-09-03 M6 잔여 마감 — 상태]** 아래 여섯이 **전부 닫혔다**(마지막
실기기 검증은 같은 날 Studio 세션이 살아 있어 바로 실측 —
`audit/m6-remainder-studio-2026-09-03.md`, 11/11 PASS).

- ✅ **공개 CRUD 잔여** — `Move`/`Swap`/`Extract`/`Splice`/`Replace` +
  `collectLeaves` + `rawSwap`/`rawSplice` 구현(`Slot.luau`), `spec.slot` 17~19·21.
  (원문: `raw*` 절반(`rawReplace`/`rawMove`/`rawDetach`)은 `:List` reconcile용으로
  fork가 구현, `rawMove`는 spec 14로 직접 검증.) `Splice`의 물리 op 형태는 `H6-9`.
- ✅ **`nativeMove`/`nativeSwap` 백엔드 계약** — `rawMove`/`rawSwap`이
  `collectLeaves`로 리프 배열을 만들어 부른다(규약 5·6), `toOffset` 의미
  명확화는 `H6-13`. (원문: fork의 `rawMove`는 물리 op을 아예 안 불렀다 —
  mock/Roblox는 no-op이라 무해.)
- ✅ **`KeyGone`의 파괴 분기** — `spec.slot` 20이 세 갈래(`nil` 파괴 / `Detach`
  홀드→재마운트 / 새 값 error)와 `Owned = false`의 언마운트-only를 단언.
- ✅ **실기기 검증** — `audit/m6-remainder-studio-2026-09-03.md`: 공개 CRUD
  다섯·중첩 Move의 실물 회귀 + Deferred 축(owner `Destroy()` 뒤
  `_detachCleanup`이 **한 틱 뒤** 홀드 요소를 정리 — 계약대로, `H-291` 일반론의
  한 사례) 11/11 PASS. (원문: Deferred 시그널 배달이 `_detachCleanup`/leaf 사망
  타이밍에 주는 영향, userdata 동일성 — mock은 동기라 못 보는 축.)
- ✅ **quad-roblox `Handlers/Slot.luau`** — 파일이 있을 몫이 없다(`H6-14`:
  백엔드 절반은 `EngineOps.luau`의 native* 여섯 그 자체).
- ✅ **round12 §6 `H-286` ②(unbind-relate)** — 기각(`H6-15`).

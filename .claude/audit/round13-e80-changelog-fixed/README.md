# E80 — CHANGELOG `[Unreleased]` Fixed 불릿(+동작이 바뀐 Changed 불릿) 재현·문구 대조 (2026-09-27)

HEAD `f547c3c8`(시작 시 `a83d3c7f` — 그 사이 `CHANGELOG.md`·`quad-base/src`·`quad-roblox/src` 변경 없음). 대상은 `CHANGELOG.md`
`[Unreleased]`의 **Fixed 45줄**(84~129행)과, E26/E68이 안 본 **동작이 바뀐 Changed 아홉 줄**(31·32·34·36·44·62·69·70·71행 — Tag nil·
`Time = 0` 스냅·Claim 소유 게이트·`OwnsElements = false` 해제·Event/OnChange 우선순위·교차 인스턴스·Effect 반환 검사·AddPlugin
dedup·버전 패턴). E26이 옮기는 법을 실측한 BREAKING 줄(38·40·42·48·54 등)과 E68이 존재만 대조한 이름 변경 줄은 다시 보지 않았다.
레포 파일은 이 폴더 말고 건드리지 않았다.

방법: 불릿마다 "그 버그를 드러냈을 가장 작은 mock 프로그램"을 E70 하네스(mock 백엔드 + 실 quad-roblox 프로바이더 + `D`,
`quad-roblox/luau_packages` 한 벌 — `typing-limits.md` 8.34)로 짜서 **HEAD**에서 돌리고(고친 동작이 지금도 있는가), 같은 프로브를
`git archive 3.2.0` 트리에서 **대조 실행**했다(그 버그가 게시본에 실제로 있었는가 — 프로브가 버그를 구별하는가). 3.2.0 대조에선
`q.Backend`/`q.Bookkeeping`을 3.2.0 표면(`q` 최상위·`q.Dispatch`)에 잇고, `updateFn(ctx)`·`OwnsElements`는 옛 위치 인자·`Owned`로
감싸는 어댑터만 넣었다(`run320.sh`). 에러 문구가 나온 자리는 `QuadNNNN`을 뽑아 `docs/reference/errors/*.md`의 `### QuadNNNN` 절과
문구 머리를 대조했고(`check-ids.py` — 61개 전부 절 있음·머리 일치), strict 주장(129행)은 `scripts/test.sh` 79행 플래그 셋 그대로
신 솔버로 HEAD·3.2.0 양쪽을 돌렸다.

재실행: 레포 루트에서 `./.claude/audit/round13-e80-changelog-fixed/run.sh`(HEAD), 이어서
`./.claude/audit/round13-e80-changelog-fixed/run320.sh <스크래치 경로>`(3.2.0 대조 — 경로는 지워도 되는 빈 곳), 그리고 같은 폴더에서
`python3 compare.py`.

## 파일

| 파일 | 뭐 하는가 |
|---|---|
| `harness.luau`·`engine-globals.luau` | E70 사본(변경 없음) — mock + quad-roblox 프로바이더 + 가상 `task` 시계 |
| `lib.luau` | 라벨 붙은 `check`·에러 첫 줄/`QuadNNNN` 추출(`err`)·절 단위 `section`(3.2.0에서 한 절이 죽어도 다음 절이 돈다) |
| `probes/a-effect.luau` | Effect/Observer/Ref/훅 — 84·85·97·99·106·113·116행, Changed 69행 |
| `probes/b-slot.luau` | Slot — 88·95·114·117·122·127·128·115행, Changed 36행 |
| `probes/c-claim.luau` | Claim — 92·93·119·125행, Changed 34행 |
| `probes/d-dispatch.luau` | Dispatch·핸들러·모듈 — 89·91·96·98·100~105·126행, Changed 31·44·62·70행 |
| `probes/e-tween.luau` | Tween/Property — 87·111·112·124행, Changed 32행 |
| `probes/f-debounce.luau` | Debounce/Throttle — 90·107·118행 |
| `probes/g-sugar.luau` | Modifier/Operator/Blocker — 94·108·109·120·121·123행 |
| `probes/h-version.luau` | Changed 71행(`VERSION_PATTERN`) |
| `strict/Quad.luau`·`strict/f45.luau`·`run-strict.sh` | 129행(Debounce `Time`/`MaxTime`·Operator 반환 타입)과 Changed 46행(옵션 변수) strict 확인 |
| `run.sh` | HEAD 실행 → `out/<프로브>.txt`, `out/strict-f45.txt`, `out/ids.txt` |
| `run320.sh` | 3.2.0 트리 조립·어댑터·같은 프로브 → `out/320/*.txt`(strict 포함) |
| `check-ids.py` → `out/ids.txt` | 출력에 나온 `QuadNNNN` ↔ 에러 레퍼런스 절 대조 |
| `compare.py` → `out/compare.tsv` | 라벨별 HEAD/3.2.0 결과 맞대기(`fixed` 106 · `same` 38 — `same`은 대조군·비구별 항목, 아래 표에서 따로 판정) |

## 불릿별 표

행 번호는 `CHANGELOG.md` 절대 줄. 도입 커밋은 그 줄을 처음 넣은 커밋(`git log -S`)이고, 코드 커밋이 다르면 괄호에 적었다.
"3.2.0"은 대조 실행에서 버그가 재현됐는지. 판정은 정확 / 문구 부정확 / 재현 불가 / 코드에 없음.

| 행 | 불릿 요약 | 도입 커밋 | 재현 결과 (HEAD / 3.2.0) | 문구 판정 |
|---|---|---|---|---|
| 84 | 던져 죽은 Effect·굳은 Observer를 Unsubscribe로 놓음 | `6e0b5346` | 해제·GC 수거·자기 해제 PASS / 3.2.0은 옛 문구 그대로로 거부 | 정확 |
| 85 | fn 도중 실행 자격 상실 → 반환 cleanup 즉시 소진 | `6e0b5346` | yield+파괴 dying=true·자기 해제 PASS / 3.2.0 누수(cl 1→1) | 정확 |
| 87 | 철거 직전 GC 창에서 Tween 미취소 | `3348a68d` | PASS / **3.2.0도 PASS(비구별)** — 원장 `H-547` code-review 정정이 "Cancel 안 됨은 구성 불가"라 적음 | 문구 부정확(발견 1) |
| 88 | 파괴된 quad Instance가 GC까지 claim된 것으로 읽힘 | `3348a68d` | `Quad0241` PASS / 3.2.0엔 claim 게이트 자체가 없음 | 문구 부정확(발견 2) |
| 89 | 정적 자식 자리에 부모·조상 → `Quad0220` | `3348a68d` | PASS / 3.2.0 mock은 에러 없음(엔진 순환 에러 자리) | 대체로 정확(발견 7) |
| 90 | Trailing=false가 MaxTime을 읽음 + 핸들 Flush blame | `3348a68d` | 둘 다 PASS / **앞 절반은 3.2.0도 PASS**(안 읽음), Flush blame은 3.2.0 `Debounce.luau` | 문구 부정확(발견 3) |
| 91 | `claimOwnerAt`/`releaseOwner` nil 게이트 | `3348a68d` | `Quad0157~0162` PASS / 3.2.0엔 op 자체가 없음 | 문구 부정확(발견 2) |
| 92 | Claim 실패가 루트·형제를 claim된 채 남김 | `69591cdd`(`2f8dad26`) | 네 갈래 잔여 0·재시도 PASS / 3.2.0 재시도가 `nativeClaim: … already claimed` | 정확 |
| 93 | Claim `[0]`/`[-1]`/`[1.5]` → `Quad0031` | `d1cc1d43` | PASS / 3.2.0 `Dispatch.drive: …`·잔여 | 정확 |
| 94 | Modifier 초기 필드 `__…` → `Quad0062` | `d1cc1d43` | PASS / 3.2.0 무에러 | 정확 |
| 95 | `:List` data가 배열 아님 → `Quad0143`, KeyGone 반환 `Quad0146` | `1f8cdc48` | PASS / 3.2.0 목록 통째로 비움(len 0) | 정확 |
| 96 | State 순환 사슬 → `Quad0070` | `1f8cdc48` | PASS / 3.2.0 `Brand.luau` stack overflow | 정확 |
| 97 | Deferred — 파괴 뒤 같은 프레임 재바인드 | `1f8cdc48` | PASS / 3.2.0 fn 영구 정지 | 정확 |
| 98 | 비브랜드 `is*` 헬퍼가 drive를 죽임 | `1b850b66` | PASS(+`isNonEmptyList` 캐비엇 그대로) / 3.2.0 `got Mobile` | 정확 |
| 99 | Deferred — 파괴 직후 `:Subscribe()` 되살림 | `f3c832ed` | PASS / 3.2.0 fn 정지 | 정확 |
| 100 | PreRef/PostRef 오용 주어가 백엔드 따라 `Ref:` | `200a0d49` | PASS / **3.2.0도 PASS**(quad-roblox에서 주어 정확) | 문구 부정확(발견 2) |
| 101 | `tostring(store)` 숫자 키 → 던짐 | `540e00a7` | PASS / 3.2.0 `attempt to compare` | 정확 |
| 102 | Context/Provider 오배치 힌트 | `e187865a` | "provider" 힌트 사라짐 PASS / 3.2.0 옛 힌트 | 정확, 단 새 힌트 방향(발견 5) |
| 103 | 문자 키 Slot/Ref → `Quad0141`/`Quad0137` | `1b850b66` | PASS / 3.2.0 provider 힌트 | 정확 |
| 104 | process index 구멍·nil 키·NaN priority·매퍼 이름·dedup·getHandler nil | `1b850b66`(`a8e4afad`) | 전부 PASS / 3.2.0 전부 재현 | 대체로 정확(발견 8) |
| 105 | `RunInit(nil/5)` → `Quad0208` | `1b850b66` | PASS / 3.2.0 내부 줄 | 정확 |
| 106 | Ref Wait 대기자가 던진 뒤 되꽂기 | `1b850b66` | PASS / 3.2.0 영영 nil | 정확 |
| 107 | 창 끝 통과 중 Cancel이 창을 다시 엶 | `1b850b66` | PASS / 3.2.0 다음 leading 보류 | 정확 |
| 108 | `state:Apply(modifier)` → `Quad0191` | `69591cdd` | 비팩토리와 같은 ID PASS / 3.2.0 무에러 | 정확 |
| 109 | Clamp min>max/NaN `Quad0124`, `Indexed(State)` `Quad0126` | `d1cc1d43` | PASS / 3.2.0 `math.clamp`·무에러 | 정확 |
| 110 | 프로바이더 계약 문서에 bindLifetime의 canBound 거부 명시 | `2f8dad26` | 같은 구간 `cb71e799`가 bindLifetime을 base로 옮겨 그 문서 문장이 없음 | 코드에 없음(발견 4) |
| 111 | 프로퍼티 체인 철거가 진행 중 Tween 취소, 같은 목표 재생 | `1e3e4680`(`9bb8a833`) | PASS / 3.2.0 cancels 0·재생 안 됨 | 정확 |
| 112 | 미claim 거부 문구 꼬리 구절 | `1e3e4680` | PASS / 3.2.0엔 그 거부 자체가 없음 | 문구 부정확(발견 2) |
| 113 | OnDestroyed를 State 자리에서 뺐다 되꽂기 | `f5b3291e` | 한 번만 PASS / 3.2.0 빼면 돌고 통틀어 두 번 | 정확 |
| 114 | 중첩 updateFn이 조상 CRUD → `Quad0167` | `e5a90c77` | PASS / 3.2.0 `bindLifetime: value is already bound` | 정확 |
| 115 | process 양의 정수 아닌 숫자 키 → no handler matched | `27b8306f` | 자식은 `Quad0076` PASS, **Slot 값은 `Quad0141`** / 3.2.0 Slot만 영구 already mounted | 문구 부정확(발견 6) |
| 116 | cleanup 안 Set → 한 사이클 | `6a2596ca` | PASS / 3.2.0 `fn1 cl fn99 cl fn99` | 정확 |
| 117 | State에 담은 원소 검사가 삽입 뒤 → 유령 원소 | `94d8f768` | PASS / 3.2.0 elems 2(유령) | 정확 |
| 118 | Debounce Time State 잘못 → 게이트 굳음; 신호 때 한 번 읽음 | `94d8f768`(`b5d17da7`) | PASS / 3.2.0 타이머 안에서 던지고 다음 신호까지 멈춤, 미개방 게이트 Flush가 던짐 | 정확 |
| 119 | Claim 키 부재·클래스 불일치 `Quad0032`, `nativeFindChild` 셋째 인자 | `94d8f768`(`a5721b84`) | PASS(className 전달 확인) / 3.2.0 Relate 리프·클래스 불일치 무에러 | 정확 |
| 120 | Modifier 초기 필드 함수 안내 `Quad0063` | `94d8f768` | PASS / 3.2.0 옛 안내 | 정확 |
| 121 | Operator nil 값 State 인자 → `Quad0120`(BREAKING) | `42a8bae9`(`a69c11fd`) | 아홉 연산 PASS / 3.2.0 일곱은 무에러·Clamp/Shl 내부 에러 | 정확 |
| 122 | 다른 인스턴스 Slot을 원소·dispose → `Quad0106` | `720bf607` | PASS / 3.2.0 무에러 | 정확하나 절 위치(발견 2) |
| 123 | Blocker `__apply` 비State → `Quad0018` | `a69c11fd` | PASS / 3.2.0 `attempt to index number` | 정확 |
| 124 | Animate State에 Tween/State → blame 사용자 줄 | `df5ce89f` | PASS / 3.2.0 `Animate.luau` | 정확 |
| 125 | debug Claim 두 실수 print | `720bf607` | 두 줄 PASS / 3.2.0 무출력 | 정확, 절 위치(발견 9) |
| 126 | 인자 모양 입구 검사 | `94d8f768` | 여덟 입구 PASS / 3.2.0 전부 내부 줄·무에러 | 정확 |
| 127 | 검증 실패 CRUD가 수동 모드 표시 | `94d8f768` | PASS / 3.2.0 `:List` 거부 | 정확 |
| 128 | Splice/Replace 되넣기 문구·keyFn NaN·Tag 자기 참조 | `94d8f768` | `Quad0170`·`Quad0144`·`Quad0201` PASS / 3.2.0 옛 문구·`table index is NaN`·stack overflow | 정확 |
| 129 | strict 조용히 꺼진 자리 둘 | `2bde166f` | HEAD TypeError 4(기대 그대로) / 3.2.0 0 | 정확 |
| 31 (C) | Tag 인자 nil = 없음 | `102a3935` | PASS(구멍·`Contains(nil)`은 여전히 에러) / 3.2.0 에러 | 정확 |
| 32 (C) | Info 없는 `Time = 0` → 스냅 | `1f33a22f` | PASS / 3.2.0 엔진 트윈 | 대체로 정확(발견 7) |
| 34 (C) | Claim 이미 소유 인스턴스 → `Quad0029` | `0ab941a8` | PASS / 3.2.0 루트·형제 claim 잔여 | 정확 |
| 36 (C) | `OwnsElements = false` dispose/Remove → 원소 해제 | `06b21647` | PASS / 3.2.0 원소 갇힘 | 정확 |
| 44 (C) | Event/OnChange 우선순위 NORMAL−1, tie 두 줄 사라짐 | `55be9b01` | −1/−1·tie 0(대조 tie 포착 1) / 3.2.0 0/0·tie 2 | 정확 |
| 62 (C) | 교차 인스턴스 배치 → `Quad0106` | `b338f030` | 네 자리 PASS·의존성 간선은 그대로 / 3.2.0 무에러 | 정확 |
| 69 (C) | Effect fn 반환 검사 `Quad0086` | `00fcfe99` | PASS·blame 사용자 줄 / 3.2.0 무에러 | 정확 |
| 70 (C) | AddPlugin identity dedup | `04e8bad0` | PASS / 3.2.0 두 번 돔 | 정확 |
| 71 (C) | `VERSION_PATTERN` `3.2^.0^` | `04e8bad0` | 3.7.0 통과·4.0.0 `Quad0228` / 3.2.0 정확 일치 | 문구 부정확(발견 3과 별개 — 발견 10) |

## 발견

1. **(문구 부정확, 중) 87행 "철거 직전 GC 타이밍에 따라 Tween이 취소되지 않던 것"은 게시본 사용자가 겪을 수 없는 증상이다.** 이 줄은
   `3348a68d`(원장 `H-547`)의 반영인데, 그 원장 항목 자신이 code-review 정정으로 "'Cancel 안 됨'은 구성 불가, plain 꼬리 직전 분기 3이
   취소를 끝낸 뒤라"라고 적었다. 실제로 GC 창을 넣은 프로브(`e-tween` F3)는 HEAD와 3.2.0 **둘 다** 취소가 된다 — 3.2.0에서 취소가 안
   된 것은 창과 무관하게 "철거가 아예 취소하지 않던 것"이고 그건 111행이 이미 말한다. `H-547`의 진짜 증상(철거 뒤 첫 Tween의
   스냅/애니메이션이 이력에 갈림)은 뒤이은 Q65(`9bb8a833`)가 "기록은 지우지 않는다"로 규칙을 정하면서 사라졌다. 그래서 87행은 같은
   미게시 구간에서 생기고 닫힌 중간 상태를 적은 줄이다. 갈래: (가) 87행을 지우고 111행 하나로 둔다, (나) 87행의 뒤 문장("첫 Tween이
   스냅하는가는 … 기준")만 111행에 합친다 — 111행에 이미 같은 기준 문장이 있으므로 사실상 (가)와 같다.

2. **(문구 부정확, 중) Fixed에 "이번 미게시 구간에 새로 생긴 기능의 중간 버그"를 고친 줄이 다섯 있다 — 게시본(3.2.0) 사용자에게는 고쳐진
   것이 아니다.** Keep a Changelog의 Fixed는 직전 릴리즈 대비 고쳐진 결함인데, 3.2.0 대조에서 아래 다섯은 그 버그의 전제가 되는 기능이
   3.2.0에 없거나(없는 op·없는 거부) 3.2.0에서 이미 옳았다.
   - 88행(파괴된 Instance가 GC까지 claim된 것) — claim 게이트 자체가 Changed 38행 BREAKING("`Slot`이 … claim되지 않은 인스턴스를 더는 원소로
     받지 않습니다")으로 이번에 생겼다. 3.2.0은 파괴된 인스턴스도 받았다(UB). 38행의 거부 문구가 이미 "and so does a destroyed
     one"을 포함하니 38행에 한 구절로 흡수하면 된다.
   - 91행(`claimOwnerAt`/`releaseOwner` nil 게이트) — 두 op는 Added 18행에서 이번에 공개됐다(3.2.0 대조는 `attempt to call a nil value`).
   - 100행(PreRef/PostRef 주어) — 3.2.0 + quad-roblox에서 `PreRef:`/`PostRef:`로 이미 정확했다(`out/320/d-dispatch.txt` F16). 원장 `H-681`의
     "quad-roblox 설치에선 … `Ref: …`"는 `1b850b66`(`H-567`)이 넣은 가드가 만든 상태였다.
   - 112행(미claim 문구 꼬리 구절) — 그 거부 문구 둘이 38행 BREAKING으로 이번에 생겼다(3.2.0은 무에러).
   - 122행(다른 인스턴스 Slot 거부) — 동작 자체는 3.2.0 대비 새 거부가 맞지만, 괄호의 "(`State`는 이미 거부됐고 …)"가 가리키는 것은
     62행 Changed(`b338f030`)의 미게시 가드다. 게시본 사용자 눈에는 62행과 한 변경이라 Changed 62행에 합치는 편이 정확하다.
   갈래: (가) 다섯을 각자의 Added/Changed 줄에 흡수, (나) 그대로 두되 Fixed 머리에 "이번 구간 안의 수정 포함" 같은 안내 — (나)는 이
   파일의 다른 곳에 선례가 없다. 원장 `H-665`·`H-690`의 "사용자에게 보이는 동작 변경이면 Fixed 한 줄" 관행이 이 다섯을 만든 경로로 보인다.

3. **(문구 부정확, 낮음) 90행 앞 절반("`Trailing = false`인 `Debounce`가 쓰지도 않는 `MaxTime`을 신호마다 읽어 …")은 3.2.0에 없던 버그다.**
   3.2.0 대조에서 같은 모양(Leading=true·Trailing=false·`MaxTime`에 `Compute`/잘못된 State)은 계산 0회·무에러였다(`out/320/f-debounce.txt`
   F6 두 줄 PASS). 신호 진입에서 `MaxTime`을 읽는 경로는 같은 구간의 Q55(`b5d17da7`, 118행)가 넣었고 `H-542`가 좁혔다. 뒤 절반(게이트
   핸들 `Flush`의 blame)은 3.2.0에서 `Debounce.luau:169`를 가리켜 실제 수정이다. 갈래: 앞 절반을 지우고 뒤 절반만 남기거나, 앞 절반을
   118행의 "`MaxTime`도 같은 자리에서 읽어" 문장 옆 괄호("`Trailing = false`면 읽지 않음")로 옮긴다.

4. **(코드에 없음, 중) 110행 "프로바이더 계약 문서: `bindLifetime`이 `canBound`가 거짓인 값을 거부해야 한다는 것과 … `_assertBindable`/
   `_catchUp`/`_bindDestroying` 셋이 … 규약의 일부라는 것을 명시했습니다"는 HEAD 문서에 없는 내용을 약속한다.** 이 줄(`2f8dad26`, 09-17)
   다음 날 `cb71e799`가 그 넷을 quad-base로 옮겼고(54행 BREAKING — "백엔드는 hold op 넷만"), 지금 `docs/reference/extend/01-backend-provider-contract.md`
   40·125행은 반대로 "`bindLifetime`/… 는 이 표에 없습니다 — quad-base가 조립"이라 적는다. 밑줄 훅 셋은 `docs/reference/` 어디에도
   안 나온다(`grep` 0 — Quadnomicon 06의 내부 소스 발췌에만). 이 줄을 읽고 자기 백엔드에 `bindLifetime` 거부를 넣으면 54행이 경고한
   "base의 게이트를 덮어쓴 채" 모양이 된다. 갈래: 줄을 지운다(54행이 대체) — 남길 이유가 없어 보인다.

5. **(수정 안의 결함 후보, 낮음) 102행이 약속한 Context/Provider의 새 힌트 "숫자 키 자리에 두라"는 그대로 따르면 또 에러다.** 문자 키의
   `Context`/`Provider`는 이제 `Quad0076 … — a quad value at a string key: it belongs in a numeric (array) slot`인데, 그 말대로 숫자 키에
   두면 `Quad0076 … — this quad value has no handler at an array position`이다(`out/d-dispatch.txt` F18 셋째 줄). 둘 다 Declaration의
   어느 자리에도 놓이지 않는 값이라, 같은 성격인 `Store`만 받는 "is not a value for any key" 꼬리(`quad-base/src/Dispatch/init.luau` 203)와
   어긋난다. 레퍼런스 `errors/02-dispatch-bookkeeping.md` Quad0076 "고치려면"도 `Store`만 예외로 적는다. 갈래: (가) Context/Provider도
   Store 쪽 꼬리 부류로 — 문구 변경이라 코드 한 줄이지만 새 이름·메커니즘은 없다, (나) 동작은 두고 102행과 Quad0076 "고치려면"에
   "Context/Provider는 Declaration에 놓는 값이 아니다"를 적는다. 3.2.0의 "프로바이더 초기화" 힌트보다는 여전히 낫다.

6. **(문구 부정확, 낮음) 115행 "`InstanceChild`·Slot 핸들러가 그런 키에 아예 매치되지 않아 `Dispatch: no handler matched key …`로"는
   Instance 자식에만 맞다.** `q.Dispatch.process(inst, 0 또는 1.5, slot, 1)`은 `Quad0141 Slot: must be an array item, not the value of a
   number key`다 — `SlotDynamicPathGuard`(`quad-base/src/Slot/Handler.luau` 55~61, FALLBACK)가 받는다. 아무것도 안 남긴다는 뒷말은 맞다
   (그 Slot을 곧바로 다른 자리에 놓을 수 있음). 또 "전에는 소유권 자리가 먼저 잡힌 뒤 … 영영 already mounted"는 3.2.0에서 **Slot에만**
   재현됐다 — 정적 자식의 소유권 부기는 40행 BREAKING으로 이번에 생겼으므로 Instance 자식은 3.2.0에서 내부 파일 줄 에러
   (`Dispatch.setOffsetSource: position must be a positive integer`)였을 뿐 갇히지 않았다. 갈래: "(Slot 값은 `Slot: must be an array item …`)"
   괄호 하나, 그리고 "그 값이"를 "그 Slot이"로.

7. **(문구 부정확, 낮음) 두 줄이 조건을 "없으면/있으면"으로 적지만 실제 판정은 "0·거짓이 아니면"이다.** 32행(Changed) "`DelayTime`/
   `RepeatCount`/`Reverses`도 없는 … 그 셋 중 하나라도 있으면 전과 같습니다" — `DelayTime = 0`·`RepeatCount = 0`·`Reverses = false`를
   명시해도 스냅한다(`out/e-tween.txt` C26 끝 세 줄, `quad-roblox/src/Handlers/Property.luau` 275~278). 레퍼런스 `roblox/06-tween-animate.md`
   85행은 "(또는 0·거짓)"으로 이미 정확하다. 89행의 "자리 부기가 먼저 잡힌 채"도 3.2.0 기준으로는 없던 부기(40행 BREAKING)라, 게시본 사용자가
   겪은 것은 "엔진의 순환 에러"뿐이다. 갈래: 32행에 "(0·거짓 제외)" 한 구절, 89행은 "자리 부기가 먼저 잡힌 채"를 뺀다.

8. **(문구 부정확, 낮음) 104행 끝 "`inst`나 `key`에 `nil`을 넘기면 다른 파일을 가리키는 VM 에러 대신"은 `inst`에만 맞다.** 3.2.0에서
   `getHandler(nil, k)`는 `Property.luau:119: attempt to index nil`(VM 에러)였지만 `getHandler(inst, nil)`은 **에러 없이** 돌아왔다
   (`out/320/d-dispatch.txt`). HEAD는 둘 다 `Quad0072`/`Quad0074`로 사용자 줄. 갈래: "`inst`가 `nil`이면 VM 에러, `key`가 `nil`이면 조용히
   통과하던 것 대신".

9. **(절 위치, 낮음) 125행("`q.debug`가 켜져 있으면 `Claim`이 두 가지 실수를 알려 줍니다")은 결함 수정이 아니라 새 진단이다** — 3.2.0은
   아무것도 출력하지 않았고 동작은 그대로라고 줄 자신이 말한다. Keep a Changelog로는 Added. 같은 결로 119행 끝의 **BREAKING(프로바이더
   작성자)** `nativeFindChild` 셋째 인자, 121행의 **BREAKING** Operator 에러화가 Fixed 안에 있다 — 표시가 달려 있어 독자가 놓치진
   않지만 Changed(BREAKING)로 옮기는 편이 형식에 맞다. E26이 둘의 옮기는 법은 이미 확인했다.

10. **(문구 부정확, 중) 71행(Changed) "`3.2^.0^` — 3.2.0 이상, 메이저 3"은 이 줄이 실릴 릴리즈에서 틀린 값이 된다.** `scripts/check-version.py`
    (12·173행)는 bump 때 `VERSION_PATTERN`을 새 버전 하한 `M.m^.p^`로 다시 쓰므로, 이 절이 3.3.0으로 게시되면 `quad_roblox` 3.3.0이 요구하는
    것은 `3.3^.0^`(3.3.0 이상)이다 — `[Unreleased]`에 BREAKING이 여럿이라 `quad_roblox` HEAD가 `quad_base` 3.2.0과 실제로 맞지도 않는다
    (`q.Backend`가 없음). 그리고 "설치 시점 검사"는 pesde 설치가 아니라 `quad:UseProvider(QuadRoblox)` 런타임 검사(`Quad0228`,
    `quad-roblox/src/init.luau` 227)다 — `quad_base`는 `quad-roblox/pesde.toml`에서 dev 의존성이라 설치 해석에는 들어가지도 않는다.
    갈래: "요구 버전이 정확히 일치에서 **자기 버전을 하한으로 한 같은 메이저**로 풀렸습니다(예: 3.3.0은 `3.3^.0^`) … `UseProvider` 때의 버전
    검사에서"로. 패턴의 판정 자체(3.3.0·3.9.1 통과, 3.1.9·4.0.0·`3.3.0-rc.2` 거부, 프리릴리즈 패턴은 그 빌드만)는 `h-version`에서 맞았다.

## 확인만 한 것

- 위 표의 "정확" 줄은 전부 HEAD에서 고친 동작이 그대로 있고(프로브 PASS), 3.2.0 대조에서 적힌 옛 증상이 실제로 났다 — 옛 문구가
  적힌 줄은 3.2.0 출력과 글자까지 일치했다(84행 `cannot change subscription from inside fn or cleanup`, 92행 `nativeClaim: Instance is already
  claimed by quad`, 114행 `bindLifetime: value is already bound`, 101행 `attempt to compare string < number`, 96행 stack overflow, 98행
  `got Mobile` 등).
- 에러 ID: 프로브가 부딪힌 `QuadNNNN` 61개 전부 `docs/reference/errors/`에 절이 있고 문구 머리가 실행 결과와 같다(`out/ids.txt`).
  기능 서술도 레퍼런스와 맞다 — 118행 ↔ `sugar/03-debounce-throttle.md` 101~102행, 111행 ↔ `roblox/06-tween-animate.md` 255~257행, 36행 ↔
  `core/06-slot.md` 407행, 84행 ↔ `core/05-observer-effect.md` 108·232·292행과 `errors/04` Quad0113 "굳은 뒤 밖에서 불러도" 문장,
  114행 ↔ `core/06-slot.md` 380~383행, 98행 ↔ `core/11-predicates.md` 60행.
- 129행 strict: HEAD에서 `Time = "x"`·`MaxTime = "y"`·Throttle `Time = "z"`·`Operator.Sum` 결과의 `string` 대입 넷이 TypeError, State<number>·
  숫자·변수에 담은 옵션은 클린. 3.2.0에선 넷 다 무진단(옵션 변수만 `DebounceOptions` 불일치 — 46행 Changed의 옛 모양).
- 44행: 3.2.0에서 quad-roblox 설치 시 tie 줄이 정확히 둘(`ties=2`), HEAD 0. 인터셉트가 실제로 잡는지는 같은 모듈에 동률 둘을 등록해
  한 줄 잡히는 것으로 대조했다.
- 118행의 "다음 신호까지 멈춤"은 3.2.0에서 Throttle 창 안에 `Time` State를 잘못된 값으로 바꾸면 창 끝 재개방이 **타이머 콜백 안에서**
  던지고(`[task error] … Debounce.luau:71`) 다음 유효 신호에 풀리는 모양으로 재현됐다. HEAD는 타이머 안에서 던지지 않고, 잘못된 값은
  다음 `:Set` 줄에서 `Quad0039`로 난다.
- 84행 부수 관찰: 굳은 `Observer`의 재구독 거부 문구가 "from inside its own fn"(`Quad0113`)이라 콜백 밖에서 부른 사람에겐 어색하지만,
  레퍼런스 절이 그 경우를 명시하므로 발견으로 올리지 않았다. `Quad0039`가 음수에 "(got number)"라고만 하는 것도 이 대상 밖이라 기록만.
- 문구 규칙: 대상 줄 전부 `H-nnn`·`.claude/` 경로 없음(소비자 언어). 104·115·91행의 "핸들러 작성자용:" 머리는 대상 독자 표시로 적절.

## 미완

- 97·99행(Deferred 시그널)은 mock에서 `onDestroying`을 큐에 쌓는 셔임으로만 재현했다 — 실기기 Deferred 모드 실측은 하지 않았다(E79가
  같은 셔임 축을 다뤘다).
- 89행의 3.2.0 옛 증상("엔진의 순환 에러")은 mock이 부모 순환을 검사하지 않아 재현 불가 — 3.2.0 mock에선 에러 없이 순환이 생겼다.
  실기기에서 엔진 문구를 확인하지 않았다.
- 111행의 "숏핸드 `UICorner = …`를 `nil`로 내려 관리 자식을 파괴할 때" 경로는 관리 자식이 생기는 것까지만 보고, 그 자식 위에서 도는
  Tween의 취소는 `retractFrom` 경로로만 확인했다.
- 111행 끝 캐비엇("값 종류가 바뀌는 교체가 Tween 도중이면 `Override = "Finish"`가 옛 목표로 스냅하지 않고 중간값에서 이어간다")은
  mock Tween이 보간하지 않아 판정하지 못했다(실행 흔적만 `out/e-tween.txt`).
- 123행 `q.Blocker()`의 `__apply` 비State 경로는 `b:__apply(5)` 직접 호출로만 쳤다 — 소비자 코드가 이 경로에 닿는 자연스러운 모양은 찾지
  않았다.
- 문서 쪽은 에러 ID 절과 위에 적은 기능 절만 대조했다. how-to·시작하기 트랙에서 이 줄들을 언급하는 곳은 보지 않았다.

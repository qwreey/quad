# E75 그룹 C — `docs/reference/errors/03-slot.md` "고치려면" 실측

케이스 `cases/C.luau`(80 케이스, `R.done` 80), 출력 `out/C.txt`(exit 0). 하네스는 E75 공용(`harness.luau`, mock + 실 quad-roblox 프로바이더). 판정은 **현재 페이지 문구 기준**.

## (i) id별 표

| id | 페이지:줄 | 판정 | blame | 한 줄 메모 |
|---|---|---|---|---|
| Quad0140 | 03-slot.md:10 | 정확 | 사용자 C.luau:14 | 새 Slot으로 마운트 |
| Quad0141 | 03-slot.md:18 | 정확 | 사용자 C.luau:19/22/25 | 문자 키·State·`process(k=0)` 세 갈래 모두 배열부로 옮기면 됨 |
| Quad0142 | 03-slot.md:26 | 정확 | 사용자 C.luau:33/45(`data:Set` 줄) | 문자열·Store 값 둘 다; 평범한 배열로 `Set` |
| Quad0143 | 03-slot.md:34 | 정확 | 사용자 C.luau:57 | 딕셔너리 → 배열 |
| Quad0144 | 03-slot.md:42 | 정확 | 사용자 C.luau:67 | |
| Quad0145 | 03-slot.md:50 | 정확 | 사용자 C.luau:79 | smoke 재사용 |
| Quad0146 | 03-slot.md:58 | 정확 | 사용자 C.luau:91/99 | nil 갈래·Detach 갈래 둘 다 |
| Quad0147 | 03-slot.md:66 | 정확 | 사용자 C.luau:113 | Detach 보관 뒤 재등장 시 같은 원소 재부착 확인 |
| Quad0148 | 03-slot.md:74 | 정확(메모) | 사용자 C.luau:128 | data가 평범한 배열이면 "그 data State"가 없다 — 아래 발견 5 |
| Quad0149 | 03-slot.md:82 | 정확 | 사용자 C.luau:139/142 | `Slot({})`·Add 뒤 둘 다 |
| Quad0150 | 03-slot.md:90 | 정확 | 사용자 C.luau:151 | |
| Quad0151 | 03-slot.md:98 | 정확 | 사용자 C.luau:154 | Store(브랜드) 값으로 트리거 |
| Quad0152 | 03-slot.md:106 | 정확 | 사용자 C.luau:157/160 | 함수·생략 두 갈래 |
| Quad0153 | 03-slot.md:114 | 정확 | 사용자 C.luau:163 | |
| Quad0154 | 03-slot.md:122 | 정확 | 사용자 C.luau:170/173 | 함수·생략(항등) 두 갈래 |
| Quad0155 | 03-slot.md:130 | 정확 | 사용자 C.luau:176 | |
| Quad0156 | 03-slot.md:138 | 불충분 | 사용자 C.luau:183/193/208 | "언제"가 적은 두 변형(같은 원소 두 키·자기 Slot 반환)엔 처방이 안 맞음 — 발견 1 |
| Quad0157 | 03-slot.md:146 | 정확 | 사용자 C.luau:215 | |
| Quad0158 | 03-slot.md:154 | 정확 | 사용자 C.luau:218 | |
| Quad0159 | 03-slot.md:162 | 정확 | 사용자 C.luau:221 | |
| Quad0160 | 03-slot.md:170 | 정확(Bookkeeping 경로) | 사용자 C.luau:224/232 | 공개 경로(정적 자식 두 번)도 이 id — 그쪽은 0172 b와 같은 공백 |
| Quad0161 | 03-slot.md:178 | 정확 | 사용자 C.luau:235 | |
| Quad0162 | 03-slot.md:186 | 정확 | 사용자 C.luau:238 | |
| Quad0163 | 03-slot.md:194 | 정확 | 사용자 C.luau:241 | |
| Quad0164 | 03-slot.md:202 | 미도달 | — | 공개 API로 못 닿음 — 발견 6 |
| Quad0165 | 03-slot.md:211 | 정확 | 사용자 C.luau:276 | 호스트 dispose는 Slot을 파괴로 표시하지 않음(부수 관측, 발견 7) |
| Quad0166 | 03-slot.md:219 | 정확 | 사용자 C.luau:281/289 | State 갈래·새 Slot 갈래 둘 다 |
| Quad0167 | 03-slot.md:227 | 불충분 | 사용자 C.luau:304/307/324/342 | 괄호 속 "Observer에서"가 마운트 중 발화하는 Observer면 같은 에러; `D.Frame { outer }` 형태는 호스트를 못 받아 `q.dispose` 처방을 따를 수 없음 — 발견 2 |
| Quad0168 | 03-slot.md:235 | 정확 | 사용자 C.luau:357 | |
| Quad0236 | 03-slot.md:243 | 정확 | 사용자 C.luau:360/363 | Remove·Add(n+2) |
| Quad0169 | 03-slot.md:251 | 정확 | 사용자 C.luau:368 | |
| Quad0170 | 03-slot.md:259 | 정확 | 사용자 C.luau:373/379 | Add로 옮기기 → Move; Replace(i, Get(i))는 호출 자체가 무의미 |
| Quad0171 | 03-slot.md:267 | 정확 | 사용자 C.luau:384 | |
| Quad0172 | 03-slot.md:275 | 불충분 | 사용자 C.luau:389/396/404 | 다른 Slot·State 자리는 됨; **리터럴 정적 자식**은 빼는 공개 경로가 없음 — 발견 3 |
| Quad0173 | 03-slot.md:283 | 정확 | 사용자 C.luau:413 | 의도 자체가 불법(순환) |
| Quad0174 | 03-slot.md:291 | 정확 | 사용자 C.luau:418/421 | 초과·생략 둘 다 |
| Quad0175 | 03-slot.md:299 | 정확 | 사용자 C.luau:426 | `Get(5)`는 nil 확인 |
| Quad0176 | 03-slot.md:307 | 정확 | 사용자 C.luau:431 | |
| Quad0177 | 03-slot.md:315 | 정확 | 사용자 C.luau:434 | |
| Quad0178 | 03-slot.md:323 | 정확 | 사용자 C.luau:439 | |
| Quad0179 | 03-slot.md:331 | 불충분 | 사용자 C.luau:445~511 | 수동 Slot·`:List` 키 삭제·State 자리·숏핸드 갈래는 정확; "owner Slot 자체를 파괴" 갈래는 owner Slot이 자리에 앉아 있으면 같은 0179; 리터럴 정적 자식 갈래 없음 — 발견 4 |
| Quad0180 | 03-slot.md:339 | 정확 | 사용자 C.luau:521/524 | State를 dispose하려던 경우는 페이지 밖(메모) |
| Quad0238 | 03-slot.md:347 | 정확 | 사용자 C.luau:529/532 | Ref·Observer를 원소의 props에 붙이면 동작 확인(ref.Value, observer 발화) |
| Quad0239 | 03-slot.md:355 | 정확 | 사용자 C.luau:540/543 | `Add(None)`·`Replace(i, nil)` → Remove/Extract |
| Quad0240 | 03-slot.md:363 | 정확 | 사용자 C.luau:546 | |
| Quad0241 | 03-slot.md:371 | 정확 | 사용자 C.luau:549/552/560 | Declaration·Claim 두 갈래, 파괴된 Instance |
| Quad0242 | 03-slot.md:379 | 정확 | 사용자 C.luau:563 | |

(blame 줄 번호는 `out/C.txt`의 트리거 메시지 접두 그대로. 모든 도달 id의 blame이 케이스 파일(사용자 코드)에 떨어졌다 — 내부 파일 blame 0건.)

## (ii) 발견

**발견 1 — Quad0156 (03-slot.md:142~143): "언제"가 적은 두 변형에 "고치려면"이 안 맞는다.** 페이지 "언제"(142줄)는 "`updateFn`이 같은 원소를 두 키에 돌려주거나 자기 Slot을 돌려준 경우도 … 이 문구가 납니다"라고 적는데, "고치려면"(143줄)은 "그 값을 먼저 옛 자리에서 빼세요(`Extract`, 데이터 키 삭제 등)" 하나뿐이다. 같은 원소를 두 키에 돌려준 경우 옛 자리는 같은 `:List` Slot의 앞 키라서, 처방대로 `Extract`하면 `:List`를 건 Slot의 수동 CRUD라 `Quad0166 Slot: manual CRUD is not allowed after :List/:Single`로 바뀐다(C.luau:191 케이스, 픽스 줄 200의 출력 `FIX=err … C.luau:200: Quad0166 …`). 데이터 키 삭제도 두 키가 다 필요하니 맞지 않다 — 실제 고침은 "키마다 새 원소를 만들어 돌려주세요"다. 자기 Slot을 돌려준 경우(C.luau:206)는 순환이라 뺄 옛 자리가 없고 처방이 적용될 곳이 없다. 문구 대안: "고치려면"에 "`updateFn`이 키마다 다른 원소를 돌려주게 하세요(같은 원소를 두 키에·자기 Slot을 돌려주면 안 됩니다)" 갈래 한 줄 추가.

**발견 2 — Quad0167 (03-slot.md:231): 괄호 속 "Observer에서"와 복구 처방 둘 다 따를 수 없는 경우가 있다.** (가) "마운트가 끝난 뒤(`Observer`에서) 하세요"를 문자 그대로, `updateFn` 안에서 어떤 State를 `Set`하고 그 State의 Observer가 조상 Slot에 `Add`하게 바꾸면 Observer가 마운트 중에 동기로 발화해 같은 Quad0167이 난다(C.luau:306, 픽스 줄 311 `FIX=err … Quad0167 …`). 메시지 자체가 "(or an Observer that fires during the mount)"라고 말하므로 모순은 아니지만, 괄호가 "Observer로 옮기면 된다"로 읽힌다. 실제로 된 것은 `D.Frame` 반환 뒤에 바로 `outer:Add`한 형태(C.luau:303, 정확). 문구 대안: "마운트가 끝난 뒤에(`D.Frame`/`drive`가 반환한 다음, 또는 그 뒤에 발화하는 Observer에서)". (나) 두 번째 문장 "이미 이 에러가 났다면 … 호스트 Instance를 `q.dispose`하세요"는 `q.Dispatch.drive(F, { outer })` 형태에선 `F`가 손에 있어 동작한다(C.luau:317, dispose 뒤 새 Slot 정상). 그러나 가장 흔한 `D.Frame({ outer })` 형태에서 마운트가 던지면 `D.Frame`이 호스트를 반환하지 못해 사용자는 dispose할 호스트를 얻을 길이 없다(C.luau:336 — 내부 필드 `outer._physicalTarget`로만 호스트가 존재함을 확인, 공개 경로 없음; 출력 `host via public API unavailable`). 사용자 문항 후보: 그 형태에서 무엇을 하라고 적을지(갈래: 그 Slot을 버리라고만 적기 / 호스트는 GC에 맡겨진다고 적기 / 그대로).

**발견 3 — Quad0172 (03-slot.md:278~279) 및 Quad0160 공개 경로: 리터럴 정적 자식은 "옛 자리에서 빼는" 공개 경로가 없다.** "언제"(278줄)가 "정적 자식"을 명시하고 "고치려면"은 "Quad0156과 같습니다 — 먼저 옛 자리에서 빼세요"다. 다른 Slot 원소(C.luau:388, `Extract` 뒤 정상)와 State 자리(C.luau:403, `Set(nil)` 뒤 정상)는 맞다. 하지만 `D.Frame({ el })`로 놓은 리터럴 정적 자식은 사용자가 할 수 있는 유일한 "빼기"인 `el.Parent = nil`로는 부기가 풀리지 않아 같은 Quad0172가 난다(C.luau:395, 픽스 줄 400 `FIX=err … Quad0172 …`). 정적 자식을 두 번째 정적 자리에 놓는 경우(C.luau:231)는 Quad0160(주어 `Bookkeeping.claimOwnerAt` — Q90 ① 기추적)으로 나고 역시 같은 처방이 가리키는 길이 없다. Q58(정적 자식 dispose 거부) 설계와 일관된 "정적 자식은 못 옮긴다"일 수 있으니, 문구 대안은 "리터럴 정적 자식은 자리에서 뺄 수 없습니다 — 옮길 값은 처음부터 `State` 자리(`Set(nil)`로 비움)나 Slot에 두세요" 한 줄. 사용자 문항 후보(설계 의도 확인).

**발견 4 — Quad0179 (03-slot.md:335): "owner Slot 자체를 파괴" 갈래가 흔한 경우에 같은 에러로 돌아오고, 리터럴 정적 자식 갈래가 없다.** `:List`가 `q.Detach`로 보관한 원소는 수동 CRUD도 데이터 키 삭제도 안 되므로 페이지는 "(또는 owner `Slot` 자체를 파괴)"를 준다. 그러나 owner Slot이 `D.Frame({ s })` 숫자 키 자리에 앉아 있으면 `q.dispose(s)`가 그 Slot 자신에 대해 같은 Quad0179를 낸다(C.luau:462, 출력 `FIX=intent-fail dispose(owner Slot) ok=false Quad0179 …`). 되는 길은 둘: owner Slot을 State 자리에 두고 `Set(nil)` 뒤 `q.dispose(s)`(C.luau:490, 보관 원소 파괴 확인), 또는 호스트 인스턴스를 `q.dispose`(C.luau:476, 보관 원소도 같이 죽음 — core/06 `q.Detach` 절이 적은 동작과 일치). 페이지는 연쇄(먼저 owner Slot을 자리에서 빼거나 호스트를 파괴)를 말하지 않는다. 또 리터럴 정적 자식 `D.Frame({ el })`을 dispose하려는 경우(C.luau:507)는 Q58 설계상 거부인데 "고치려면"에 해당 갈래가 없다(발견 3과 같은 결). 나머지 갈래 — `Extract`/`Remove` 뒤 dispose(C.luau:444/447), 데이터 키 삭제 뒤(450), State `Set(nil)` 뒤(504), 숏핸드 키 `nil` 뒤(510) — 는 전부 에러 없이 의도대로 동작. 부수: `Remove`는 이미 원소를 파괴하므로 그 뒤 `dispose`는 불필요하지만 에러 없이 통과한다(C.luau:447). 문구 대안: "owner Slot 자체를 파괴(그 Slot이 자리에 앉아 있으면 먼저 그 자리에서 빼거나, 호스트 Instance를 `q.dispose`)" + 정적 자식 한 줄.

**발견 5(경미) — Quad0148 (03-slot.md:79).** "그 `:List`가 참조하는 `data` State를 바꾸세요"는 data가 State일 때만 성립한다. 처음에 평범한 배열로 설치했으면 바꿀 State가 없고 재설치도 금지라, 실제 길은 "`data`를 State로 설치하는 새 Slot"뿐이다. Quad0166(223줄)은 "새 Slot을 만드세요" 갈래를 같이 주는데 0148은 안 준다. 판정은 정확(State로 바꾸면 동작, C.luau:125)으로 두고 문구 대안만: "(처음에 배열로 설치했다면 State를 data로 하는 새 Slot을 만드세요)".

**발견 6 — Quad0164 미도달.** Slot을 `_destroyed`로 만드는 곳은 `destroySlotTree`(quad-base/src/Slot/Tree.luau:221)뿐이고, 그 입구는 `q.dispose(slot)`와 소유 부모의 Remove/Replace/KeyGone 파괴다. 부모 Slot의 원소인 Slot을 파괴하려면 먼저 소유를 풀어야 해 `q.dispose`가 Quad0179로 막히고, 부모 Slot 자체를 파괴하면 부모가 먼저 Quad0140/0165로 막힌다. 호스트 인스턴스를 마운트 walk 도중 `q.dispose`해도(C.luau:246 — 중첩 `:List`의 `updateFn`에서 dispose, 261 — 마운트 중 발화 Observer에서) Slot은 호스트 수명에 GC로 묶여 있어 `_destroyed`가 서지 않고 walk가 정상 완료된다(`TRIG=noerr`). 페이지 서술("공개 경로에서는 … 직접 볼 일은 드뭅니다")과 일치 — 사실상 방어 코드.

**발견 7(부수, 페이지 무관) — 호스트 dispose는 Slot을 파괴로 표시하지 않는다.** `D.Frame({ s })` 뒤 `q.dispose(f)`를 해도 `s:Add(...)`는 에러 없이 통과한다(E75 스크래치 프로브 — 케이스 파일엔 트리거를 `q.dispose(s)`로 바꿔 넣음, C.luau:275). Quad0165 "언제"는 "파괴된 Slot"만 말하므로 페이지와 모순은 아니다. core/06 "죽은 Slot과 마운트 규칙"이 호스트 죽음과 Slot 파괴의 관계를 어떻게 적는지는 이번 범위 밖(미확인).

**Quad0180 메모.** `q.dispose(q.Source(1))`(C.luau:523)처럼 State를 정리하려던 사용자에게 페이지는 "Slot이거나 isInst 값을 넘기세요"만 준다 — 의도 자체가 dispose의 범위 밖이라 정확으로 둔다(State/Observer 해제 안내는 다른 페이지 몫).

**E28 기추적과의 관계.** E28이 적은 0141(숫자 키 갈래)·0149(빈 `Slot({})`)·0168(`index < 1`)·0169/0242 구분·0179 꼬리는 현재 페이지 문구에 전부 반영돼 있다(고쳐짐). 0160 주어 문제는 Q90 ①로 기추적.

## (iii) 페이지 개수

| 페이지 | 섹션 | 시도 | 정확 | 불충분 | 틀림 | 미도달 |
|---|---|---|---|---|---|---|
| 03-slot.md | 47 | 47 | 42 | 4 (0156·0167·0172·0179) | 0 | 1 (0164) |

## (iv) 미완

- 없음(47절 전부 시도). 다만 실기기(Roblox 엔진) 확인은 하지 않았다 — 전부 mock. 특히 발견 2(나)의 "`D.Frame` 마운트가 던진 뒤 호스트가 어떻게 되는가"와 발견 3의 `el.Parent = nil`은 엔진에서도 부기 쪽 결론이 같을 것으로 보이나 실측 아님.
- 발견 7의 core/06 대조는 범위 밖이라 안 했다.

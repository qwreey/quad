# finder-core-sonnet — 2026-10-12 코어 변경 리뷰 (읽기 전용, 사본 실행)

사본: review/core-s (HEAD), review/base-s (26932869), 프로브는 core-s/quad-base/test/probe*.luau 와 core-s/quad-roblox/test/probe_prop.luau.
실행: `cd core-s/quad-base && mise exec -- luau test/probeN.luau`. spec.slot·spec.dispatch*·spec.tweenproperty 사본에서 통과, quad-base/types luau-analyze 클린.

## 발견 (심각도 순)

### 1. [실측, 회귀] 도착하던 부분 트리에서 창 도중 빠져나간 Slot이 `_materializing = true`인 채 영구히 남는다
raiseTree가 도착 중인 트리의 모든 Slot에 플래그를 올리고 내리는 쪽은 markMountedTree가 `_elements`를 다시 훑는 것뿐이다. 그 사이(nativeInsert가 동기로 낸 신호의 콜백)에서 State 값이 바뀌어 도착 트리 안의 `:Single`/`:List` 재조정이 돌면, 재조정은 raw 층이라 assertNotMounting을 안 거치고 원소를 빼 낸다. 빠진 Slot(OwnsElements=false라 살아 있는 것)은 `_elements`에서 사라졌으므로 markMountedTree가 닿지 않아 플래그가 안 내려간다. 결과: 사용자가 들고 있는 살아 있는 Slot에 `U:Add(...)`가 Quad0167("mid-operation")로 영구 거부되고, `U:WhenIdle(fn)`은 영영 안 돌고 S.pending에 쌓인다(재마운트하면 풀린다). 사전 커밋(26932869)엔 raiseTree가 없어 없던 증상. 위치 quad-base/src/Slot/Tree.luau raiseTree/markMountedTree(약 85-100행), Raw.luau rawSplice 420-433행 같은 뿌리. 재현: core-s/quad-base/test/probe9.luau (drive/Add 두 경로 모두 "U flag: true", U:Add → Quad0167, WhenIdle ran now: false). 한 줄 제안: 끝에서 raiseTree가 올린 Slot 목록을 따로 기억해 그것들을 내리거나, 재조정이 빼 낸 Slot의 플래그를 leave 경로에서 같이 내리기(어느 쪽이든 새 메커니즘이라 사용자 결정).

### 2. [실측, 기존 + 가드 설계 전제 반증] 조상 Slot은 자식의 평범한 원소 연산 중에 플래그가 없고 그 Length가 낡아 있어, 조상 CRUD가 물리 순서를 어긋나게 한다
brief/audit는 "평범한 원소 연산은 조상 자리를 잡지 않는다"로 조상에 플래그를 안 세웠다. 그러나 자식(manual이든 `:List`든)의 nativeInsert/nativeRemove 도중 신호 콜백이 조상 P에 인덱스가 자식 뒤인 `P:Add(x, 2)`를 하면, P는 플래그가 없어 허용되고, P가 쓰는 자식의 Length는 아직 갱신 전(setLength가 호출 뒤)이라 오프셋이 한 칸 틀린다. 결과: 장부 순서와 화면 순서가 어긋난다. inner:Add(y) + 콜백에서 P:Add(pz,2) → 장부 x,r,y,pz,tail / 화면 x,r,pz,y,tail. inner:Remove도 장부 x,pz,tail / 화면 x,tail,pz. `:List` 재조정(State 변경)에서도 같다(probe2 P4). 사전 커밋도 동일하게 어긋나므로 이번 변경이 만든 회귀는 아니지만, WhenIdle이 "우회 도구"로 제시된 자리에서 조상 쪽 WhenIdle은 플래그가 없어 즉시 돌아 같은 낡은 상태를 읽는다(probe7: P:WhenIdle 안에서 `P.Length` = 6, 실제 비운 뒤엔 2). 증상 확정, 처방은 사용자 결정(조상 사슬에 플래그를 올리는 비용/범위). 재현: probe2.luau(P4 구간), probe3.luau(두 변형, base-s에서도 DIVERGED), probe7.luau. 화면 순서는 probe_h.luau의 오프셋 시뮬레이터(nativeInsert/Extract/Remove 래핑)로 계산한 것 — 실제 Roblox LayoutOrder 충돌 양상은 [추정].

### 3. [실측] `fn`이 던지면 대기 중이던 다른 실행 가능 요청이 무관한 연산이 올 때까지 잠복한다
settle은 요청을 목록에서 빼고 나서 `item.fn(slot)`을 부르는데 pcall이 없어, 첫 fn이 던지면 바로 뒤의 이미 실행 가능한 f2가 그 호출 안에 남는다. f2는 나중에 어디서든(다른 Slot) 아무 연산이 settle을 부를 때야 돈다 — 그 사이 f2의 Slot 상태는 계속 바뀔 수 있다. 무-pcall 계약 안(던진 뒤 상태는 계약이 아님)이지만 "영영/뒤늦게"의 모양이 비직관이라 기록. Init.luau settle 284-302행. 재현: probe1.luau P1("after remove ran=f1", 무관한 Slot Add 뒤 "f1,f2").

### 4. [실측, 낮음] 플래그가 영구히 올라간 Slot(위 1번 또는 엔진 호출이 던진 뒤)에 걸린 요청이 모듈 전역 S.pending에 영영 쌓이고, 쌓인 만큼 모듈 안의 모든 Slot 연산이 느려진다
settle은 연산마다 목록 전체를 건너뛰며 훑는다. 1001건 대기 상태에서 무관한 Slot에 Add 2000회가 0.067s, 기준(대기 없음) 0.0066s로 약 10배. 호스트 Instance를 Destroy해도 요청(Slot·클로저 강참조)이 풀리지 않는다. 재현: probe8.luau.

### 5. [실측, 낮음] "꼬리까지 끝난 뒤에 돈다"는 보증은 Length/Offset 구독자가 다른 Slot 연산을 하면 깨진다
Add의 setLength 구독 통지 안에서 다른 Slot에 `other:Add`를 하면 그 연산의 settle이 첫 Slot의 대기 요청을 이미 플래그가 내려간 상태라 판단하고 그 자리(첫 연산이 끝나기 전)에서 돌린다(probe6: obs len=3 → FN ran 이 첫 Add 반환 이전). 이번 실행들에서 결과 장부/화면은 일치(probe10 네 변형은 이 경로를 못 탔고 정상 끝에서 돔) — 일관성 파괴는 못 보았고 설계 문장("tail included")과 다르다는 것만 확정.

### 6. [릴리즈 도구, 낮음~중간] 4.0.0 경계 릴리즈에서 publish.py가 새 번호의 quad_error/type_version_check를 기본으로는 게시 안 한다
`check-version.py bump 4.0.0`은 3.x인 두 패키지를 4.0.0으로 올리지만(새 번호), `rides_lockstep`은 4.0.0 미만만 참이라 `publish.py`는 4.0.0 릴리즈에서 둘을 "게시 안 함(--with)"으로 두고 exit 0으로 끝난다. quad_base 4.0.0이 `quad_error ^`로 4.0.0을 요구하므로 `--with quad-error,type-version-check`를 잊으면 소비자 설치가 깨진다. 설계된 동작(문서: 4.0.0부터는 --with)이나 경계 한 번이 함정. 위치 scripts/publish.py selected()/rides_lockstep(), 읽기만으로 확인 [추정, 게시 안 돌림].
같은 계열: `bump 4.0.0-rc.1` 뒤 `bump 4.0.0`(최종)은 두 패키지가 이미 core (4,0,0)이라 lockstep으로 안 올리고 "NOT bumped"만 찍고 exit 0 — 두 패키지는 4.0.0-rc.1에 남는다(check는 통과). 방침상 메이저 프리릴리즈는 안 쓰므로 낮음. 실측: rel/ 사본 bump 4.0.0-rc.1 후 매니페스트 확인.
그 외: `bump-package`가 하향/같은 버전(4.1.0→4.0.0, 4.0.0→4.1.0 재실행)을 exit 0으로 받는다(기존 동작, 새 건 아님).

## 확인했지만 문제없던 것
- Property 차등(사본 old/new, probe_prop.luau 아홉 시나리오: plain→plain, tween→plain, tween→tween Cancel, Finish, zero-time, plain→zero, Dedup/Dedup=false, 첫 세팅 Tween, 목표값과 같은 plain): 콜백 순서·최종 값·트윈 수 전부 동일. 유일한 차이는 Finish 경로에서 OnChange 리스너가 보는 "재생 중 트윈 수"가 0→1(Finish 스냅 쓰기가 settle 앞으로 옮겨졌기 때문, 설계 의도, 엔진에선 쓰기가 비동기라 무해 [추정]).
- debug 구멍 검사(probe5.luau): `{a,nil,c}`·희소 `[1],[3]`·`{nil,b}`·4개 채운 뒤 t[2]=nil은 List/Slot 모두 Quad0269/0270으로 잡음. 거짓 양성 없음: 정상 배열, `{a,b,nil}`, 빈 표, `table.create(5)` 뒤 1,2만, `table.create(5,x)` 뒤 remove로 끝 빼기, 끝에서 t[4]=nil, 빈 `table.create(3)`. State로 나중에 구멍 생기면 Set 시점에 던짐. debug off면 둘 다 통과(문서대로). 비-debug 경로에도 count/highest 증가가 붙지만 이미 도는 루프라 무시할 비용.
- WhenIdle 중첩/상호 호출: fn이 연산→콜백이 다시 WhenIdle(probe1 P2: 체인이 순서대로 돌고 장부/화면 일치), 두 Slot 서로의 콜백(probe2 P3b: 플래그된 쪽 직접 Add는 Quad0167, WhenIdle은 끝에서 돔, 장부=화면), Clear/ExtractAll/Splice/Remove에서 원소마다 요청(probe7: 각 한 번씩, 순서 맞음, 최종 일치).
- 플래그 대조표 결론(읽기+프로브): 올림 자리 — materializeSlotTree(끝에서 내림), raiseChain/restoreChain, raiseTree(markMountedTree가 내림, 1번 예외), rawAdd/rawRemove/rawUnmount/rawReplace/rawSplice 각 창(`was` 저장·복원), destroySlotTree(정상 경로는 안 내리지만 `_destroyed`=true로 idle 취급; OwnsElements=false 경로는 끝에서 무조건 false로 내림). settle 호출 자리 — 공개 CRUD 일곱(Add/Remove/Replace/Extract/Splice/Clear/ExtractAll), List 설치(마운트된 경우), 재조정 Observer 끝, Handler 마운트 끝, dispose 끝. 대기 요청이 생길 수 있는데 settle 없는 진입점: Move/Swap(nativeMove/Swap에 플래그 없음, Roblox에선 no-op이라 무해), Handler의 unmount 소멸자(플래그 없음 — 논리 반쪽 먼저라 요청이 즉시 돔). 그 외 못 찾음.
- unmountSlotTree의 "논리 반쪽 먼저" 변경: 오프셋/잎 목록을 teardown 전에 잡아 nativeExtract에 넘기므로 순서 문제 없음.
- 타입: `{ read __apply: any }` 확대는 Blocker/Debounce의 `__apply: (self: any, state: any) -> any`(quad-types 282/315행)와 충돌 없음, 파일 전체 luau-analyze 클린. WhenIdle 시그니처는 구현과 일치하며 setFuncLevel에 등록됨. 다만 `{ __apply = 5 }`도 타입은 통과하고 런타임 Quad0191로 잡힘(넓히기의 결과, 의도).
- check-version: `bump 3.3.0`/`4.0.0`/`3.3.0-rc.1`/`4.0.0-rc.1` 사본 실행 후 pesde install 전 check가 exit 1(STALE LOCK) — 게이트 작동. 락 손으로 맞춘 뒤 check exit 0. 3.x에서 bump-package quad-error는 exit 1로 거부. 4.0.0 뒤 bump 4.2.0은 독립 둘을 "NOT bumped"로 안내.

## 못 본 것
- 실제 Roblox 엔진의 Immediate 신호/LayoutOrder 거동(Studio 불가, mock만). 2번의 화면 어긋남은 오프셋 시뮬레이터 기준.
- publish.py 실행(네트워크·게시 금지라 읽기만), `pesde install` 후 lock 갱신 흐름.
- Move/Swap의 nativeMove/nativeSwap 안에서 신호가 나는 경우(mock은 no-op).
- 5번 Length 구독자 경로에서 fn이 큰 변경을 할 때의 장기 일관성(네 변형은 정상 끝에서 돌아 이 경로를 못 탐).

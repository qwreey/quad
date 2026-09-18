# 2026-09-18-01 — round11 원장 §4 Q59~Q69 대화형 회신

원장: `.claude/qa-request/post-implementation-review-round11.md` §4. 전날 체크포인트(`session/2026-09-17-02-round11-defect-hunt.md`) 뒤 사용자가 문항 열하나를 읽고 와서 하나씩 회신. 이 파일은 결정의 논거 원문. 결과 반영은 원장 각 문항의 닫힘 문단이 소스.

## Q59 — 이름 문제가 아니라 경계 문제였다

메인이 (a) 밑줄 이름 유지 / (b) 밑줄 없는 이름으로 BREAKING을 띄우자 사용자가 문항 자체를 다시 봤다. 원문:

> 그런데 해당 부분은 우리가 _ 붙은건 언제든지 변경될 수 있다 말하는데, 저건 아니지 않아? 이미 settled behavior 인거로 알고있음. bindLifetime 자체가 공개 표면이라면 _assertBindable 는 비공개 표면일 이유는 없고(단순 읽기+fast throw만 내므로 — 내부 계약으로 사용중인것 맞지만, 외부자가 안다고 부작용은 없음) 그런데 _catchUp 의 경우는 외부자가 아는건 문제가 됨. 하지만 내 시각은 조금 더 크게 들어가, bindLifetime 자체가 base 가 아는 경계랑 각 백엔드가 아는 경계가 섞여있다는 점이 문제가 돼. 이 구조상에서는 base 에 사소한 변경만 와도 백엔드 전부 코드 개편이 불가피함. inst == nil 과 value == nil 검사도, isInst 로 봐지는 isMockInstance 검사도 양쪽 같게 유지되는 모양으로 나오고, isObserver 상태에서 isGlobal 확인 경로는 base 에서 아는 경로이고, gchold 를 보는 sameInst 는 반대임. 아래쪽 isObserver 보고 catchup 먹는곳과 isEffect 보는 bindDestroying 거는 부분은 또 base, 여러 맥락이 섞여 한줄 한줄 크리티컬한 구역이 나왔고, 하는 일이 크다고 볼 수 있으며 중복돼. 어떻게 생각함?

메인이 quad-roblox와 mock의 `bindLifetime`을 줄 단위로 대조해 표로 냈다 — base 지식(nil 게이트, 거부 메시지 세 팔, `_assertBindable` 선행, `_catchUp`/`_bindDestroying`, `isBoundAlive`의 `.Subscribed` 팔)과 백엔드 지식(inst claim 여부, gchold/gcconn 부기, `sameInst` 대조)이 섞여 있고 두 백엔드가 40줄을 글자까지 복제. 제안: 넷은 base가 조립, 백엔드는 인스턴스 쪽 op 넷만 주입(임시 이름 attach/detach/isAttached/isAttachedTo; `isAttachedTo`는 `H-395` 메시지 팔 하나용이라 합칠 수도 있다고 덧붙임).

사용자: *"그게 맞겠네. 굳이 합칠 이유는 안 보여서, 네가 권한 4개가 난 괜찮아보인다 생각함. 이름은 나도 괜찮아보인다 생각하긴 하는데, 이것도 sonnet 여럿/둘정도 굴려서 봤던 잘 통했던 객관적 의견 얻기 방법을 써볼만한 표면인것 같아. 메인과 내가 가지는 객관성 결여를 해결해보고 작업 시작해볼래?"*

sonnet 둘을 서로 다른 각도(기존 `Backend` 어휘·코퍼스 내부 용어와의 일관성 / 다른 엔진에 이식하는 외부 프로바이더 작성자)로 띄웠고 둘 다 독립적으로 `holdLifetime`/`releaseLifetime`/`isHeld`/`isHeldBy`를 냈다. 근거: `hold`는 기존 명사 `gchold`의 동사라 새 단어가 아니고 `release`는 `Bookkeeping.releaseOwner`와 같은 결(claim/hold/release 사다리); `detach`는 공개 센티널 `q.Detach`("떼되 살려둔다")와 op 2("생존 보장을 거둔다")의 뜻이 반대라 강한 충돌, `attach`도 `attachSlot`·물리 attach와 겹침; `Lifetime` 접미는 `bindLifetime` 옆 같은 절이라 유지. 브리프 원문은 세션 scratchpad `r11/naming/brief.md`.

반영 뒤 발견 하나: 에러 궤적이 한 경우 바뀐다 — 미claim inst에 이미 묶인 값을 넣으면 전엔 백엔드의 "not claimed"가 먼저였고 지금은 base의 "already bound"가 먼저(백엔드 게이트가 `holdLifetime` 안으로 들어갔으므로). 둘 다 프로그램 오류라 정상 프로그램은 무관, `lifecycle-pattern.md` (1-2)에 기록. mock 스펙(`spec.lifetime` 7 "not a mock instance")은 그대로 통과 — 그 게이트도 `holdLifetime` 안이고 접두는 `bindLifetime:` 유지.

## Q60 — (a) 캐비엇, 그리고 "선행 검증 계약"의 출처

사용자: *"권고대로. 해결하려면 retract 가 받은 hint(new) 에 대해 마운트 가능성을 봐야한다는건데, retract 는 자신을 철거하는데 있어 기준을 정의할 뿐 미정의 행동에 대한 처리를 하는 방향으로 정의된 적이 없어서, 케비엇 한 줄이 맞는것 같음. 특히 이미 시끄럽게 에러를 낸다면 상관이 없고, '거부된 연산은 아무것도 안 건드린다' 는 어디서 나온 말인지 모르겠음. 내가 정의했던 기억은 없고, 내가 정의했던 부분은 에러가 시끄러워야한다는 정도 레이어와 가능한 경우 fail fast 일 뿐으로 기억해. 해당 선행 검증 계약은 구현중/테스트 중 생긴것으로 느껴져"*

메인이 추적한 출처: 그 문구는 문항을 쓸 때 메인이 만든 의역. 실제 규칙은 `slot-plan.md` CRUD 목록의 "검증은 실제 mutate 전에 전부 먼저 통과"이고, 그 기원은 구현 전 손 트레이싱 6라운드(`H-30`/`H-31`)의 에이전트 발견 — 존재 이유는 배치 Blocker 창 안에서 던지면 Slot이 동결되는 것(`H6-19`). 원자성 원칙이 아니라 동결 회피 장치였고, 정적 자리엔 그 창이 없다. 사용자 감각이 맞았다. 원장 Q60 닫힘 문단에 기록.

## Q61 — 파괴 경로만 풀고, Extract는 쥔 채

메인이 코드에서 "이 Slot은 `_elements`를 든 채 살아남으므로 Remove 뒤 Add하면 원소째 옮겨진다 — (가)는 그걸 깬다"며 (나)로 권고를 바꿔 띄웠다. 사용자: *"잠만. 이건 이미 단일 경로에서는 release owner 를 굴렸던 기억이 있음. 다만 recursive 하게 가는 경로인가보네? 다만 이건 Slot 을 dispose 하기 전 경로에는 안 사라지는게 맞는데, dispose 자체는 recursive 하게 돌아서 release 가 되는게 맞다고 보는데, 정확한 경로는 셋 다 아니지 않음?"*

경로 확인 결과 사용자가 맞았다. "원소째 옮기기"는 `Extract`/비소유 부모의 `Remove`(`rawUnmount` → `leaveAsElement`)이고 `destroySlotTree`를 타지 않는다. `q.dispose(slot)`과 소유하는 부모의 `Remove`/`Clear`만 `destroySlotTree`로 와서 `_owned == false` 분기에 걸리며, 거기서 요소 전부의 소유권을 놓고 비우면 Extract 동작은 건드리지 않는다. 그러니 (가)를 "파괴 경로에만"으로 정확히 읽으면 그게 답이었고, 메인의 "깨진다"는 두 경로를 합쳐 본 오독. 부수로 :List 조정 클로저 상태를 재마운트 때 처음부터 돌리기 위해 `_listActivated`를 내린다(기존 플래그).

## Q62 — (c) UB, Q42의 재확인

사용자: *"동의. 권고대로. 리컬션을 막는 비용 대비 이득 trade-off 가 불균형이라 나도 막을 이유를 못 느꼈어"*. 반영 중 slot-plan에 round8 Q42(2026-09-08)로 같은 결정이 이미 있음을 확인 — 이번은 `H-545` 뒤의 비대칭 재확인이고 사용자 문서(core/06)에만 캐비엇이 빠져 있었다.

## Q63 — (b), 해제는 fn을 안 부른다

사용자: *"이것도 권고대로 가면 될것 같아. 그런데 unsub 가 다시 fn/cleanup 을 부르진 않지? 그 모양인지 먼저 보고싶어"* → 메인이 `Unsubscribe`/`WeakUnsubscribe`/`_consumeCleanup`/`rawRerun` 본문으로 답(fn 호출 없음, 죽은 핸들의 cleanup은 이미 nil). 부수 모양(fn 안 자기 해제 뒤 반환 cleanup)은 Q68 (b)를 "실행 불가면 즉시 소진"으로 넓혀 같이 닫기로 제안 → 사용자 *"확인. 그렇다면 그 경로로 가도 될것 같아"*.

**교훈**(메인): 원장 문항이 "이름"으로 좁혀져 있었다 — 발견자(탐사 E′)가 증상(밑줄 훅이 계약에 노출)만 보고 갈래를 이름 층위로 냈고 메인도 그대로 띄웠다. 사용자가 "왜 백엔드가 그 훅을 알아야 하는가"를 물어 구조로 올라갔다. 다음 문항들도 갈래가 증상 층위에 갇혀 있지 않은지 한 번 더 보고 띄울 것.

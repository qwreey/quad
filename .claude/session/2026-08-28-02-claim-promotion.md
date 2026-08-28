# 2026-08-28 (02) — `Claim` 갈래 확정, `research/`에서 `base/claim-plan.md`로 승격

> 이 파일은 **원문 기록**이다(시행착오 포함). 지금 유효한 설계는 `base/claim-plan.md`.
> 앞 세션 `session/2026-08-28-01-handtrace-round10-resolution.md`가 만든 research
> 문서(옛 `existing-mount-plan`) §5 갈래 여덟을 사용자와 대화형으로 닫은 기록.

## 경위

10라운드 후속 2까지 커밋(`f020f3f`)한 뒤 사용자가 *"`research/existing-mount-plan.md`
관해서 다뤄보자. 우선 5. 미결을 보자"*로 이어갔다. 사용자가 항목 1~5를 먼저 적어
보냈고("내가 적어둔걸 볼래?"), 에이전트가 사실 셋을 확인한 뒤 의견과 함께 답이
없던 §5-7·§5-8을 되물었다. 사용자가 둘을 답해 전량 확정.

## 사용자 원문 (1차 메시지)

> 1. 의 권고 b는 문제가 생겨. 루트에 대해서 {} 안의 타입체크와 타입 자동완성이
> 전혀 안 먹음. 내 생각에는 D.Frame 의 함수의 부분들을 type FrameParam = {}
> 형태로 빼서 공유되는 타입 부분으로 D.Mapper.Frame 도 구성되고, 리턴부분만
> 다르게 될것 같아. Claim 자체는 타입을 받는건 말이 안되어보임. New 와는 완전
> 다른 계열이라서: New 는 후행 입력에 대한 타입을 선언시키는 D 계열이지만,
> Claim 은 공유 부분이고 말한것 처럼 엔진 요소를 알 수 없어. a 가 가장 정확한
> 구현으로 보임.
> 2. 나는 처음에 A 를 생각했어. 권고 그대로 가줘.
> 3. 그런데 호출 순서가 달라진다는 문제가 있긴함. D.Mapper 의 프레임이 전부
> 구워지는 도중에 생기고 각각 claim 매핑 되기 전에 New 가 호출됨. 새로 붙임
> 자체는 한 배열에 섞이는게 문제는 없어보여. 그 경우에서도 순차 마운트 Add 는
> 작동할것이거든. 대신 Add 가 위치를 진짜 실어서 보내지 않으면 맨 뒤에
> 놓인다는게 문제일 뿐.
> 4. 는 디버깅 도구 만들 때 고려해야할 점으로 옮겨져야해. 부분 부분 디버깅
> 가능성을 아직 다 논한게 없어서 지금 그림으로 보면 작은 그림을 먼저
> 그리는거라서, 미결상황으로, 위치 이동이 필요함
> 5. 표면 이름은 Claim 이 가장 마음에 들어. D.Mapper 가 이미 있는걸 매핑해서
> 내가 가진다는 의미적으로 가장 맞고.
> 승격은 지금도 가능해보임. 간단한 레이어라서.

## 에이전트가 확인한 사실과 되물은 것

- `D.Frame = New<<Frame>> "Frame" :: (({ ...타입명시 }) -> Frame)` — props 타입이
  캐스트 안 인라인이고 `D` 전체가 생성기 산출물(`base/bind-system-plan.md`) →
  `type FrameParam` 공유는 생성기 한 줄. `InstanceChildHandler`는 `v.Parent = inst`이고
  `H-154` 문단이 이미 "같은 값, 엔진 no-op"을 전제 → §5-8 근거. `nativeInsert`는
  Roblox가 offset을 무시(`architecture.md`) → §5-3의 위치 문제는 web 프로바이더 요구사항.
- 제안 둘(사용자 거부 없음, 결정은 아님으로 표시): 센티널을 `D.Mapper.Root`에
  두기 / `Claim<T>(inst: T, desc: MapperDescriptor<T>): T` **추론**(타입 인자 없음은
  사용자 결정).
- **§5-7 문항을 다시 세움** — "여러 quad 인스턴스"가 아니라 **한 quad·여러
  스크립트**(같은 `quad` 모듈 require)가 흔한 경우라 이중 claim error가 그 사례를
  막는 게 진짜 문제. 갈래 (α) `Claim`은 전체 소유만, 루트 `.Parent =`는 밖에서
  (`H-146` 복원, 새 메커니즘 0) [권고] / (β) 다중 claim·부분 소유(web에서 offset이
  남의 자식을 못 봄) / (γ) 별도 표면(`H-146` 인용문이 반대한 것).

## 사용자 원문 (2차 메시지) — §5-7·§5-8

> 5-8 확인완료. 5-7 에서는 정확히는 두번 Claim 불가하다는 의미. 필요하다면
> Slot 을 안에 만들고 리턴하는 중간 모듈을 만들어야함. 밖에서 .Parent 설정하는건
> 괜찮아. 루트도 quad 소유이긴 한데, .Parent 를 밖에서 설정하는건 괜찮음.
> 정확히는 ScreenGUI 가 이미 존재해도 똑같음.

읽기: (α) 채택. `Claim`은 같은 `inst`에 1회, 소유는 전체. 루트의 `Parent`는
**만든 방법과 무관하게**(`New`든 `Claim`한 기존 `ScreenGui`든) 부기 밖이라 밖에서
대입 허용 — `H-146`의 예외가 좁혀서(그리고 `Claim`한 루트까지 넓혀서) 복원됐다.
PlayerGui 직하 Slot을 여러 스크립트가 공유하려면 `Claim` 한 번 + Slot 반환 중간 모듈.

## 반영

`git mv research/existing-mount-plan.md base/claim-plan.md` 후 전면 재작성(§7 결정
기록, §8 안 만들기로 한 것, §9 구현 체크리스트·문서화 대상). 포인터 갱신:
`bind-system-plan.md` `H-146` 배너("폐기" → "좁혀서 복원") / `slot-plan.md` 두 곳 /
`architecture.md` 주입 op 목록에 `nativeFindChild`(조합 폴백 예외) / `ROADMAP.md`
M2 배너·M5 두 체크박스 / `question.md` 최우선 절 비움 + `archive/question-resolved.md`
절 / `debug-tooling-plan.md` "열린 질문"에 검사 범위 이관 / `documentation-content-map.md`
§4 21번 / `README.md` 행 이동 / `CLAUDE.md`·`todos.md`·`project-context.md` /
`-round10-followup.md` 후속 3 절. 코퍼스의 옛 경로는 새 경로로 일괄 치환(히스토리
문서 포함 — 파일 참조가 깨지지 않게).

## 옛 §5 원문 (승격 직전 커밋 `f020f3f`의 `research/existing-mount-plan.md` §5 — 갈래 a/b/c 선택지 전문)


1. **루트 디스크립터의 이름** — 루트는 `Claim`이 `inst`를 직접 받으니 매칭 키가
   필요 없다. 사용자: *"최상위는 이름을 뭐로 둬야할지 아직 모르겠음. 비워두는걸
   D.Mapper.Frame{} 으로 제공하는건 더 나빠보이는데. 아니면 테이블로써
   MapperRoot = {} Mapper.Frame (MapperRoot) {} 모양이 되어도 될것같음."*
   갈래: (a) 센티널 `MapperRoot`(`M.Frame(MapperRoot) {…}`) / (b) 루트는
   `Claim(inst, { … })`처럼 클래스 없는 맨 테이블(클래스는 `inst`가 이미 안다)
   / (c) 이름을 받되 무시. **권고 (b)** — 루트 클래스를 두 번 말하지 않고,
   `M.<Class>`는 "찾아야 하는 자식"에만 쓰여 뜻이 하나가 된다. 단 타입(`D`
   생성기가 만든 props 타입)을 잃으므로 `Claim<<"Frame">>(inst, {…})`처럼
   타입 인자로 보완 — `New<<X>>`와 같은 관용구.
2. **물리 순서 계약** — 디스크립터 배열 순서와 기존 트리의 실제 순서가 다를 때.
   Roblox는 물리 순서가 의미 없어 무관, web은 DOM 순서라 `nativeInsert` 위치가
   어긋난다. 갈래: (a) 디스크립터 순서가 정본이고 일치는 사용자 책임(UB,
   debug 검사) / (b) claim 시 quad가 `nativeMove`로 실제 순서를 디스크립터에
   맞춘다. **권고 (a)** — "이미 있는 걸 그대로"의 취지, Roblox에선 비용 0.
3. **`New`로 만든 자식을 claim된 부모에 넣는 것** — 위 §4 첫 항목. 정적 자식이니
   `InstanceChildHandler`가 `Parent =`를 하면 되고 새 결정은 없어 보이나,
   "매핑(이미 있음)"과 "생성(새로 붙임)"이 한 배열에 섞이는 것이 계약상
   괜찮은지 확인 문항.
4. **debug 검사의 범위** — 이름 중복 / 부재 / 클래스 불일치 / 미매핑 부기
   대상 자식 / 같은 quad의 이중 claim 중 어디까지. 권고: 전부(debug에선 싸다).
5. **표면 이름** — `Claim`/`Mount`/`Adopt`, `D.Mapper`/`D.Existing`.
   `Mount(root, parent)`를 `H-146`에서 기각한 사유("부기 없는 대상에 quad 객체
   주입")는 여기 반대로 적용된다 — claim은 부기를 *세우는* 행위. 권고 `Claim`.
6. **마일스톤** — M5 이후(`nativeFindChild`가 프로바이더 표면). `ROADMAP.md`
   백로그에 포인터만. **[2026-08-28 `/code-review`, `H-161`]** 단 `H-146` 루트
   예외를 폐기한 지금 **M5에 승인된 루트 부착 경로가 없다** — (a) `Claim`을 M5
   스코프로 당김 / (b) `Claim` 전까지 M5 한정 임시 예외 / (c) 루트 컨테이너용
   얇은 표면. **사용자 확정 (a)**(*"M5 스코프로 올라가도 될것으로 보임"*) — 헤더와
   `ROADMAP.md` M5 체크박스에 반영. §5-7(다중 스크립트)은 여전히 미결.
7. **[2026-08-28 `/code-review`, `H-161`] 여러 스크립트/여러 quad가 같은 루트
   컨테이너를 쓰는 경우** — 위 "이중 claim error / 다중 quad UB / 부기 대상 자식
   전부 매핑"을 그대로 두면 `Shop.client.luau`와 `Inventory.client.luau`가 각각
   `Claim(PlayerGui, …)`하는 **가장 흔한 사례가 막힌다**. 이건 "전부 매핑" 계약이
   **루트 컨테이너**(부기 대상이 아닌 `PlayerGui`·`CoreGui`류 — 자식 순서가
   의미 없고 quad가 그 형제들을 관리하지 않는다)에는 안 맞는다는 신호다. 갈래:
   (a) `Claim`은 **부기를 갖는 노드**에만, 루트 컨테이너엔 "quad가 만든 자식
   하나를 붙이는" 별개 표면(부기 없음, 여러 스크립트 공존, 이름은 §5-5와 같이) /
   (b) `Claim`에 "이 노드의 다른 자식은 관리하지 않는다"(부분 매핑) 모드 — 단
   web처럼 물리 순서가 의미 있는 엔진에선 위험 / (c) 다중 claim을 허용하되 각
   claim이 자기가 매핑한 자식만 소유(UB 대신 정의) — 부기 충돌 없음이 조건.
   **권고 없음** — (a)는 `H-146`에서 기각한 `Mount(root, parent)`의 재개방과
   경계가 얇고, (b)(c)는 계약을 약화시킨다. 사용자 판단.
8. **매핑된 정적 자식의 `Parent` 대입** — §2는 "부기만, `.Parent =`는 안 한다"인데
   `InstanceChildHandler`는 `v.Parent = inst`가 계약(`dispatch-core-plan.md`
   `H-134`). 같은 핸들러를 쓰면 이미 거기 있는 자식에 같은 값을 재대입(엔진
   no-op)하는 것뿐이라 별도 핸들러가 필요 없어 보인다 — 확인 문항(권고: 같은
   핸들러, 재대입 감수).


## 승격 뒤 `/code-review high` (2026-08-28)

감사 6라운드 수렴 뒤 돌린 리뷰가 10건을 냈다. 서술·라벨·stale 여섯은 반영, **새
메커니즘이 필요한 넷**(gcconn/gchold 셋업 자리 / 이중 claim 레지스트리 / `PlayerGui`
own-all vs `ResetOnSpawn` / 공유 `Param` 배열 파트)은 `base/claim-plan.md` §10과
`question.md`에 문항으로 — 사용자 결정 대기. 리뷰가 제안한 이름(`nativeAdopt`,
`FrameParam<C>`)은 전부 가칭.

## 사용자 원문 (3차 메시지) — `/code-review` 문항 넷의 답

> A. 이건 nativeClaim 을 만들고 gchold/gcconn 경로를 여기에 전부 두면 되지 않을까
> 생각중. B. 정확히는, claim 은 slot 이랑 무관하지 않아? 이중 claim 자체가 무슨
> 상황이야. C. 는 애초에 PlayerGui 자체를 Own 한다는게 좀 잘못되었어. 공동 소유
> 가능 객체인데 그러는거지. ScreenGui/SurfaceGui 등으로 생각해야지. D. 내가 생각한게
> 원소를 파라미터로 받는거였어. 거기에 Instance 또는 Instance|MapperDescriptor 가
> 오는거지

읽기와 반영은 `base/claim-plan.md` §7-9~12. 에이전트 읽기 하나 — A의 "전부"를 `New`
②단계도 `nativeClaim`을 부르는 것으로 옮겼다(`bind-system-plan.md` 의사코드 주석,
`lifecycle-pattern.md` (0) 머리). B는 리뷰 문항의 전제(`elementOwner` 충돌)가 틀렸다는
답이라 레지스트리 없이 셋업 유무로 판정. C로 §6의 `Claim(PlayerGui, …)` 예시가
폐기되고 중간 모듈 패턴의 루트가 `ScreenGui`로 바뀌었다.

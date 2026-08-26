# 2026-08-26/27 — 9라운드 손 트레이싱 실행 + Q1~Q3 결정·반영 + 감사 6라운드

**무엇을 했나**: `qa-request/pre-implementation-handtrace-round9-brief.md`(8라운드가
써둔 지시서)대로 커밋 `9dd8213`의 델타를 재트레이싱해 발견 보고
`qa-request/pre-implementation-handtrace-round9.md`(`H-124`~`H-141`)를 냈고, 그
§4 문항 중 Q1~Q3를 사용자와 대화형으로 확정해 `base/`·`ROADMAP.md`에 반영, 감사
루프 6라운드(확실 0으로 수렴)까지 돌린 뒤 체크포인트 커밋. **Q4~Q10은 다음
세션**(사용자 판단: *"clear 이후 핸드오버 세션에서 후행 결정을 하는게 맞다"*).
결정의 소스는 `qa-request/pre-implementation-handtrace-round9-followup.md`.

세션 도중 모델이 두 번 바뀌었다 — Opus(사용자: *"sonnet 실수가 너무 많아서
감사 루프가 길어져서 오히려 비용이 높아지더라"*) → Fable(아래 "실수" 절).

## 감사 (레인 A/C/G/D 메인, 레인 B는 포크)

- 레인 A는 델타 2180줄 정독 + 원문 절 전문 대조, 레인 C는 7라운드 참조 구현을
  현재 계약으로 **다시 전사**(`ref9/core9.luau`·`dispatch9.luau`)해 실행, 레인 B는
  같은 컨텍스트를 물려받은 포크에 맡겼다(값 단위 트레이스 4항목).
- 🔴 둘 다 실측 재현: `H-124`(`recompute`가 `lengthList[i]`를 되감기 판정보다
  먼저 읽어 커서 뒤 자리 수가 줄면 `sum += nil`, 그 뒤 `recomputeBlocker` 영구
  On) / `H-125`(재마운트 시 `_baseObserver`가 unbind 상태라 두 필드가 0으로 안
  내려가 옛 베이스의 `offsetCache[1]`을 씀).
- G각도가 **문서 쪽 거짓**을 하나 잡았다 — 7차 code-review의 *"`for d in seen
  do`는 유효한 Luau가 아니다"*는 틀렸다(일반화 반복은 런타임·strict 둘 다 통과).
  반대로 `keyof<{}>` 빈 Store는 실측 클린이라 8라운드가 남긴 캐비엇을 닫을 수 있다.

## 결정 (원문은 followup, 여기는 흐름)

**Q1** — (a)를 고르면서 사용자가 코드 모양을 정정: 되감으면 `sum`이 `prefix[i]`로
덮이니 읽기·누적을 아예 되감지 않을 때만 — `continue` 형태.

**Q2** — 문항의 (a) 진입부 초기화를 사용자가 반대했고(유저 LayoutOrder 체인에
전파가 안 될 것이라는 근거), 실측해보니 **그 근거는 성립하지 않았다**(유저
체인은 요소 인스턴스에 바인드돼 있어 전파된다 — 깨지는 건 부기를 경유하는
중첩 Slot의 `Offset`뿐). 그래도 (a)는 소스 이원화라 기각하고 (c)로 가려는데,
사용자가 한 단계 더 나갔다: *"slot 자체를 생성할 때 offset/observer 이 같이
생성되지 말아야할 이유가 있음?"* → `Offset`/`_baseObserver`를 **생성자**로. 분기
자체가 사라진다. 이어서 `destroySlotTree`가 핸들을 `nil`로 지우던 것에 대해
*"두 일을 겸하는걸 만들다가 사고가 난 적 많아"*(`invalidAfter`) → **`_destroyed`
플래그**, 핸들은 unbind만. 이름은 `_disposed`가 아니다 — *"`dispose` 는 형질이
다른 엔진 요소를 포함할 수 있는 것에 대한 공동 소멸자인 네이밍 … `destroy` 가
맞아보이고"*. 이중 `dispose`는 no-op. 실측 `d16`에서 none/(a)/(c)/ctor 네 변형
대조.

**Q3** — 표면 증상(`spliceArraysUp`이 비운 자리)을 파다가 `token`이 나왔다.
사용자: *"내가 등장시킨 적 없는 token 이 나와서 당황스러움"*. 추적하니 7라운드
`H-102`의 지시(*"dispatch 로 격상"*)는 요소 → 인덱스 맵을 올리라는 것이었는데,
구현은 `len`을 키로 잡았고 `/code-review`가 그게 유일하지 않다는 걸 잡자 원래
키로 돌아가는 대신 `token = {}`을 발명했다 — 그리고 사용자 인용문 옆에 앉아
확정처럼 읽혔다(`H-141`). 사용자: *"난 층위 상 어떠한 값이든, 마운트된
부기객체 -> index(기여량이 아님) 를 얻고자 했음"*. 확정: `bk.indexOfElement`
하나(`slot._elemIndex` 삭제), `setLength(…, anchor, element)`, 등록은 `setLength`·
이동은 `reindexFrom`·예외 `rawReplace`. `H-137` 소멸.

## 실수 — 같은 종류 셋, 규칙으로 승격

Q3 대화에서 내가 새 개념을 세 번 제안했다가 전부 철회했다: `subject` 인자 /
`observer.pos`·`observer.inst`(**검토 후 안 만들기로 한 `Effect` userdata의
재개방** — 사용자: *"그건 닫은 Effect 의 userdata 허용을 거의 여는 셈이야"*) /
조회 클로저·팩토리(사용자: *"클로저가 필요한 지점으로 안 보여 … elem->index 를
누가 관리하느냐가 어디서 관리하느냐가 명확하지 않아서 자꾸 사고가 나는듯"*).
셋 다 한 번 grep이면 안 냈을 제안이었고, 그중 하나는 **이미 읽은** 제약을
적용 못 한 것이었다. `conventions.md`의 `/code-review` 항목 아래에
*"새 필드·인자·이름·메커니즘은 발견이지 결정이 아니다"* 규칙을 신설했다(사용자:
*"code-review 가 완전 외부자라 우리 대화를 모르기에, 새로운 개념을 창조하려
들 수도 있는 점에 대해서 기술이 필요해보이는데"*). 피드백도 남겼다(`/feedback`).

## 감사 루프 (Q1~Q3 반영분)

`quad-doc-auditor` 한 턴에 하나, 각도 순환: `base/` 정합 → 인덱스 레이어 + 새
문단 자기모순 → archive·reference·audit 인용처 → 앞 수정분 + 두 문서 내부 정합 →
델타 밖 `base/` → 5라운드 수정분. 확실 **1 → 1 → 3 → 1 → 1 → 0**. `base/` 본문
결함은 1라운드 이후 0건이었고, 나머지는 전부 인덱스 레이어·인용처가 델타를 못
따라온 것(8라운드와 같은 분포). 표는 followup의 "감사 루프" 절.
`/code-review high`는 **아직 안 돌렸다** — Q4~Q10 반영 뒤 한 번에(체크포인트
커밋의 이유: Q4~Q10이 같은 파일을 또 건드려 diff가 섞이면 두 라운드 몫을 구분
못 한다).

## 다음 세션이 할 것

`qa-request/pre-implementation-handtrace-round9-followup.md`의 진행 표가 소스 —
**Q4~Q10**(`H-127`~`H-133`)과 레인 B 몫(`H-134`~`H-136` 🟡, `H-137` 소멸,
`H-138`~`H-140` 🟢)을 발견 문서 §4 표대로 결정 → 반영 → 감사 루프 →
`/code-review high` → 커밋. 이번 세션의 규칙(새 개념은 문항으로)을 지킬 것.

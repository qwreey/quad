# 2026-08-12 열여섯 번째 세션 — 코퍼스 전체 감사, Attribute retract 전면 재설계, Slot 소유권 일반화

## 배경

사용자가 "문서 전체에서 가정이 틀렸는데 다른 문서에서는 이미 정정된
사실이 있음에도 잘못된 추론이 그대로 남아있는 곳이 있는지" 감사를 요청.
이전 세션들(특히 2026-08-12 열한~열다섯 번째, retract-always-fires
정정과 그 파생 GC 이슈 시리즈)에서 큰 변경이 여러 차례 있었기 때문 —
"정정됨" 표시만 붙고 원 문장이 그대로 방치되는 패턴이 반복된다는 CLAUDE.md
자기 경고가 이번에도 실제로 맞아떨어짐.

## 1부 — 코퍼스 전체 감사 (7개 에이전트 병렬)

`base/` 14개 파일 + `research/`/`question.md`/`README.md`를 7개
서브에이전트로 나눠 정독·대조. 발견해서 그 자리에서 고친 것:

- **`bind-system-plan.md`**: "Tag는 retract가 무조건 전체 삭제"라던
  옛 서술 2곳이 세션11 정정(참조 카운트 기반) 이후에도 안 고쳐진 채
  남아있었음 — 수정.
- **`attribute-plan.md`**: "retract 불필요" 헤더가 바로 아래 정정된 코드
  주석과 모순 — 수정(이후 2부에서 이 절 전체가 다시 크게 재작성됨).
- **`slot-plan.md`**: `slotOwner:GetWeak/SetWeak` 호출이 `Relate` 공식
  API(항상 3-인자)와 인자 개수가 안 맞는 실제 버그 — sentinel key 추가로
  수정. "재마운트는 즉시 throw" 절이 나중에 확정된 "같은 위치 재-emit은
  no-op" 예외를 반영 안 함 — 교차참조 추가. `rawRemove`가 element
  기준/index 기준 두 가지로 같은 파일에 리터럴로 존재 — M6 미확정임을
  명시하는 주석 추가(결정 자체는 안 내림).
- **Tween 승격(research→base) 반영 누락**: `tween-plan.md` 상태 필드가
  여전히 "research", `architecture.md` 2곳("Tween은 여전히 research/에
  있음"), `ui-shorthand-plan.md`의 폐기된 "Tween 핸들러" 용어 — 전부 수정.
- **`question.md`/`CLAUDE.md`의 "지금 할 일" 1번**: `pre-implementation-audit.md`
  우선순위1 중 열려있는 게 "1개(1-3)뿐"이라던 요약이 실제로는 4개(1-3/
  1-4/1-10/1-11, 원문에 `[해소됨]` 마커 없음)였음 — 개수/목록만 정정,
  실제 해소는 사용자가 "나중으로 연기" 선택.

## 2부 — Attribute retract 전면 재설계 (사용자 주도 다단계 정정)

diff를 직접 보던 사용자가 "AttributeHandler가 retract 없는 게 말이 되나"
질문에서 시작해 여러 라운드에 걸쳐 최종 설계에 도달:

1. **1차**: 그룹 자신의 `(inst,index)` 슬롯도 process/retract 코드가
   없다는 gap 발견 — `AttributeGroupHandler.process`/`.retract` 스케치.
2. **2차 (사용자 catch)**: `retract`의 `v` 타입을 안 보고 `v:NameMap()`을
   호출하는 게 버그 — `TagHandler.retract`의 `isTag(newv)` 가드 선례와
   대조해 확인. `Ref`/`Slot`/`AttributeKey`의 기존 retract는 전부
   identity/nil 비교뿐이라 애초에 이 문제가 없었음(내용을 봐야 하는 건
   Tag/Attribute뿐).
3. **3차 (사용자 catch)**: `AttributeKeyHandler.retract`가 `v==nil`이면
   `SetAttribute(name,nil)`을 직접 부르는 게 깜빡임(`a→nil→b`) 위험 —
   "일반 프로퍼티와 동일하게 취급"이라는 기존 원칙대로 retract를 완전
   no-op으로, 지우는 건 오직 `process(inst,k,nil)`(None/nil 명시)로만
   통일.
4. **4차 (사용자 결정, 가장 큰 정정)**: 그룹이 "사라진 이름"을 자동으로
   `SetAttribute(nil)` 해주는 것 자체를 기각 — **Attribute는 오직
   명시적 `None`/`nil`로만 지워진다.** 그룹 바인딩이 통째로 사라져도
   (컴포넌트 언마운트 등) 자동 청소 없음. 이유: diff로 조용히 빠지는
   이름과 통째 소멸을 다르게 취급하면 오히려 모호해지고, Attribute는
   이미 "겹치면 error"로 소유 코드가 명확히 갈리는 설계라 프레임워크가
   대신 판단할 근거가 불투명함. `Ref`의 "Destroy 무관, 정리는 Effect로"
   철학과 통일. 이 결정으로 기존 "Tag와 동일하게 확실히 청소" 초안(line
   308-313)이 뒤집힘.
5. **5차**: (4차와 별개 문제) 값을 안 지워도 사라진 이름의 *구독*은
   끊어야 함 — 안 그러면 그룹이 더 이상 안 쓰는 Source를 향한 StoreBind
   구독이 인스턴스가 살아있는 동안 계속 살아남아 리소스 누수. `retract`가
   `Dispatch.retractUnder`만 부르고(`process`는 안 부름 — retract 안에서
   process 호출은 UB, 아래 참고) 구독만 끊는 걸로 확정 — `SetAttribute`는
   여기서도 절대 안 일어남.

**부수적으로 확정된 일반 규칙 2개**(`bind-system-plan.md`에 추가):
- retract의 `v`는 타입 보장 안 됨 — 내용을 보려면 `isX(v)` 가드 필수.
- retract 안에서 `Dispatch.process` 호출은 UB(`retractUnder`의 체인
  추적이 꼬임) — retract는 구조적 팝/자원 해제만, 새 등록 트리거 금지.
  `Dispatch.retractUnder`를 (다른 키에 대해) retract 안에서 부르는 건
  문제없음.

**백로그**: 그래도 자동 unset이 필요해지면 `Animate`와 같은 모양의
`:Apply` opt-in 유틸(이전 이름 집합과 비교해 사라진 이름을 `None`으로
채워주는 콤비네이터)을 나중에 추가 가능 — `research/operator-sugar-plan.md`에
"Attribute 그룹 명시적 unset 유틸" 절로 신설, 착수 안 함.

## 3부 — Slot 소유권 일반화, bindLifetime 스코프 정정

같은 흐름에서 Slot도 감사:

- **소유권 레지스트리 이중화 gap(사용자 발견)**: top-level Dispatch
  마운트(`slotOwner`)와 nested `Add`(문서에만 있고 코드 없던 "전역
  weak-set")가 서로 다른 레지스트리라, 한쪽으로 먼저 마운트한 걸 다른
  쪽이 못 보고 이중 마운트를 허용하는 실제 gap이 있었음. `slotOwner`를
  `elementOwner`(Slot이든 plain Instance든 공용)로 승격, `claimOwner`/
  `releaseOwner`를 top-level(`SlotHandler`)과 nested(`rawAdd`/`rawRemove`/
  `rawExtract`)가 동일하게 호출하도록 통합.
- **bindLifetime 스코프 정정(사용자 판단)**: `attachSlot`이 재귀 모든
  레벨에서 `bindLifetime`을 부르던 것을 **top-level에서만**으로 축소 —
  nested Slot은 담는 outer의 `_elements`(plain strong array)로 이미
  transitively 살아있어서 별도 anchor가 불필요, State의 노드 연결처럼
  말단만 실제 엔진 생명주기에 건다는 원칙과 일치. `destroySlotTree`의
  자기-unbind도 대칭으로 제거, top-level 파괴 지점(`SlotHandler.retract`)
  에서만 짝 맞춤.
- **GC 안전성 확인**: `slot._mountedInst = physicalTarget`은
  `relate-plan.md`가 이미 안전하다고 확정한 "값이 자기 키를 다시
  참조하는" 단일-Relate 자기참조 패턴(`Ref.Value=inst`와 동일 부류)이라
  안전 — `relate-plan.md`에 확인 사례로 추가.

## 4부 — `and`/`or` 삼항 관용구 전면 금지

사용자가 성능(진짜 short-circuit이라 매 단계 truthiness 테스트, `if-then-else`는
단일 분기)과 안전성(가운데 값 falsy 시 새는 구조적 결함) 둘 다 근거로
"쓸 수 있는 곳은 전부 `if-then-else`"를 요청 — 기존에 "가운데 값이
항상-truthy면 예외적으로 and/or 허용"이라던 예외 조항을 폐기하고, 코드로
실존하던 6곳(`bind-system-plan.md`/`slot-plan.md`/`tag-plan.md`)을 전부
`if-then-else`로 교체. `architecture.md`/`bind-system-plan.md`의 규칙
설명도 같이 강화. 단순 2항 `A or B` fallback(`props.Modifier or None`류)은
애초에 이 문제가 없어 그대로 유지.

## 반영 완료 확인

`base/attribute-plan.md`(221줄 변경), `base/slot-plan.md`(147줄),
`base/bind-system-plan.md`(67줄), `base/architecture.md`(22줄),
`base/tag-plan.md`(24줄), `base/relate-plan.md`, `base/tween-plan.md`,
`base/ui-shorthand-plan.md`, `research/operator-sugar-plan.md`,
`.claude/question.md`, 루트 `CLAUDE.md` 전부 이 세션 안에서 갱신 완료.
열린 설계 질문 없음 — Attribute/Slot 소유권 메커니즘 둘 다 최종 확정.

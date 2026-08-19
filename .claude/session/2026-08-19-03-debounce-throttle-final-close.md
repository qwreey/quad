# 2026-08-19 — `Debounce`/`Throttle` 마지막 판단 대기 4개 닫음, `base/`로 승격

**요청**: `research/debounce-throttle-plan.md` 12절에 남아있던 판단 대기
항목(이름/의미론/제어 핸들/`Time = 0`) 중 사용자가 이미 답을 준 이름(Q1)을
빼고 나머지를 리뷰. "지금은 다른 에이전트들이 있어서 읽기만 해달라"는
조건으로 시작 — 다른 에이전트들이 끝난 뒤 반영·핸드오버까지 진행.

## 1. 리뷰 준비 — 문서 재확인, 새 질문 발견

문서를 다시 읽는 과정에서 12절에 없던 새 항목이 나옴 — **`Time`/`MaxTime`을
`State`로 받을 수 있는가**(5-2절은 당시 "plain 값만"으로 확정돼 있었음).
사용자가 먼저 판단을 제시: *"1. 이름 -> Debounce Throttle 유지를 하는게
나도 맞다고 봄. 관용 표현과 다르다는 경고로 넣기로 문서화 계획만 되도록
해줘 + debounce-throttle 에 시간은 state 로 받을 수 있을지는 확인 필요한
부분으로 보임."*

## 2. Time as State

사용자: *"Throttle 과 Debounce 는 state 중간이나 말단에 들어가서 emit 을
제어하는거라, tween 과 완전 다름. 그리고 한번 바인딩 된다면 다시 Time
같은걸 바꿀 수 없게되어버림. (…) 필요 시마다 get 해서 쓰긴 하는거야."*
즉 구독이 아니라 **`setTimeout` 호출 시점에만 폴링**하자는 제안 — 검토
결과 5-2절이 인용하던 `tween-plan.md`의 "옵션에 두 번째 반응 경로를
안 만든다" 근거와 안 부딪힘(폴링은 새 무효화 채널이 아님). 후속 확인:
*"이미 스캐쥴 한건 반영 안함. Animate 슈거랑 비슷함. 오직 setTimeout
수행할 때 읽음. MaxTime 같은 다른것도 number|state<number> 주는거
가능해보임."* → `Time`/`MaxTime` 둘 다 `number | State<number>` 허용,
이미 스케줄된 타이머엔 미반영·다음 창부터 적용으로 확정.

## 3. Q2 — 의미론, (B) value-hold 철회

사용자: *"Get 을 지연된 값으로 만들어낸다 하면, 이전에 Compute 안 했던걸
다시 컴퓨팅 하기 어려움. 리프 바인딩이라 가정하면 그냥 Blocker 동작이랑
동일하는게 맞다고 생각하는데. (…) value-hold 라는걸 해야하는 순간부터,
Get을 명시적으로 호출하고 들고 있어준다는게 되지 않느냐는것. (…) 이전에
Get하지 않았다면 아주 이전 값일 가능성이 있는데. 이는 어떻게 제어하는가?"*

검토 결과 지적이 정확함을 확인 — (B)의 "held value" 계약은 직전 커밋에서
`invalid = true`로 세팅된 채 아무도 안 읽다가 새 창이 열리는 경로에서
조용히 깨지고, 이걸 고치려면 창이 열리는 순간 upstream을 강제로 pull해야
해서 laziness와 정면 충돌(Throttle의 주 용례인 "비싼 연산 게이팅"에서
치명적). **(A) emit-gate로 확정, (B) 철회.** 부수로 Q7(blocker-plan.md
명확화)도 (A)를 택하면서 자동 소멸.

## 4. Q4 — 제어 핸들, 세 라운드 만에 수렴

1차 제안(에이전트): 게이트가 반환하는 State 자체에 `:Flush()`/`:Cancel()`을
직접 붙임. 사용자 반박: *"State 가 확장되거나 해야함. 상태 따라 debounce
에 대한 메서드를 실행할 수 있거나 없고. 타입이 나뉘거나 함. 차라리
Debounce() 할 때, 디바운싱을 진짜 하는건 state 따로이지만, Flush Cancel
은 한 핸들에서 수행 가능하고(마치 On/Off 처럼) 그게 전파 되는건 어떻게
봄?"* — State 서브타입 분기 문제를 정확히 짚음.

2차 제안: `base/ref-plan.md`의 `Ref`(채워지길 기다리는 빈 박스) 패턴을
재사용 — 옵션 필드로 `Handle = Ref()`를 받아 게이트 생성 시 채움. 사용자
동의, 이어서 대칭 확장 질문: *"Debounce{} 결과에 :Flush 하면 있는 전체가
플러싱되고, 하나만 하고 싶으면 Handler 를 넣어 쓰게 하면 되고,
정확해보임."* → 개별은 `Ref` 아웃파라미터, 전체는 팩토리 자신의
`:Flush()`/`:Cancel()`(모든 인스턴스에 브로드캐스트)로 최종 확정.

`:Apply()`를 계속 쓰는 이유도 확인: *"왜 Apply 일 이유가 있어? (…) 내부적으로
Blocker 로 동작하기 때문임?"* — 두 근거 다 유효(① `Operator` 관용구가
이미 "factory(self) + `:Apply`"로 확정, ② 내부적으로 `Blocker`와 같은
gated state를 공유) 확인 후 동의.

전체 브로드캐스트의 구현 함정(weak 레지스트리 필요, GC 방해 방지) 지적에
사용자 동의: *"1. 은 동의, weak 로 전부 가지고 있으면 돼."* `Cancel`도
`Flush`와 대칭 포함 확정: *"Cancel도 대칭으로 포함해줘."*

## 5. Q8 — `Time = 0`

사용자: *"Q8 은 금지할 이유가 없어보이긴 함. 그냥 defer 될 수 있다고만
알리면 별 문제 없음."* → 허용, "defer될 수 있음"만 문서화, 별도 이름/에러
없음.

## 6. 부수 발견 — 순수 슈가로 귀결

사용자: *"이건 어쩌다 보니 사실상 슈거가 되었고, setTimeout 만 나중에
진짜 quad-base 에 추가적으로 들어가는 부분이 될듯. 표면 상 아주 나중에
구현되어도 괜찮아 보이는데, 지금 구현 상 base 승격에 문제 없어보임."*
제어 핸들까지 확정되면서 새로 필요한 quad-base 코어 표면이 주입 op
2개(`setTimeout`/`clearTimeout`)뿐임이 드러남 — 게이트는 `Blocker`가 이미
확정한 gated state 위, 핸들은 이미 확정된 `Ref` 위에 전부 얹힘. 옛
13절의 "순수 슈가가 아니라 실제 기능 갭이라 우선순위를 위로 둔다"는
서술을 뒤집고, `Operator.*`와 같은 급의 후순위로 재평가.

## 7. 반영

*"다른 에이전트들 다 끝났어, 이제 반영해줘. 세션 기록도 남기고 핸드오버
준비해줘. 끝나면 커밋하면 돼."*

`base/debounce-throttle-plan.md`(구 `research/debounce-throttle-plan.md`,
`research/`에서 승격 — 4차 리뷰 배너, 4/5-2/5-3/5-4/7/9-1/12/13절 갱신,
`DebounceHandle`/`Timeout` 등 타입 확장, 의사코드에 `readTime`/weak
레지스트리/`Flush`·`Cancel` 반영), `ROADMAP.md`(백로그 항목 경로+서술
갱신), `.claude/todos.md`(4번 항목), `.claude/question.md`(3번 항목
전체 제거 — 전량 해소), `.claude/README.md`(research→base 테이블 이동),
`base/source-state-plan.md`/`base/blocker-plan.md`(경로 참조 갱신)에
반영. `archive/`·`session/`의 과거 경로 참조는 히스토리 문서라 그대로
둠(`doc-check.py`가 파일명 기준 폴백 매칭이라 깨지지 않음).

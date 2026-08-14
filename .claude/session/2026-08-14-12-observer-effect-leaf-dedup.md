# 2026-08-14 열두 번째 세션 — Observer/Effect Leaf에 `Ref`와 같은 identical-value dedup 추가(성능 최적화)

## 배경

이전 대화에서 State<Ref>/State<Effect>/State<Observer>가 전부 설계상
지원되는지(읽기만으로 판단) 확인한 뒤, 사용자가 이어서 "state<Observer>의
`state`가 emit됐는데 내부 Observer 객체 자체는 안 바뀐 경우, unbind/bind가
안 일어나고 process/retract가 nop인지"를 물었다.

## 1차 조사 — Dispatch 계층엔 값 동일성 비교가 없음

`base/dispatch-core-plan.md`의 "Dispatch 체인" 절(`Dispatch.process`의
(A) 분기)을 추적한 결과: 핸들러 **타입**이 같으면 `v`가 이전 값과 같은
객체든 아니든 무조건 `slot.retractor(v)`→`h.process(inst,k,v,index)`가
다시 불림 — Dispatch 자신은 값 동일성을 전혀 비교하지 않고, 값 단위
dedup은 필요한 핸들러가 직접 `Relate`로 구현해야 하는 몫(`RefLeafHandler`가
`old ~= v`를 `Relate`로 체크하는 게 그 예, `base/ref-plan.md` "`Ref`의
retract" 절). `Dispatch/Leaf.luau`가 매치하는 Observer/Effect 쪽엔 이
dedup이 문서 어디에도 없다는 걸 확인하고 사용자에게 "확정된 설계는 아님,
잠재적 갭"으로 보고했다.

## 2차 — "메인에서 작업해도 됨, 문제 되는 부분 찾아 고쳐" 지시 후 재조사

사용자가 다른 에이전트는 쉬고 있으니 메인 브랜치에서 직접 작업해도
된다며 이 갭을 고치라고 지시. 처음엔 곧바로 `RefLeafHandler`와 같은
dedup을 추가하려 했으나, 그 전에 `base/lifecycle-pattern.md`의
`bindLifetime`/`unbindLifetime` **실제 구현 스케치**를 다시 추적해보니
애초에 "버그"가 아니었음이 드러났다:

- `bindLifetime`/`unbindLifetime`은 `Relate` weak 테이블에 대한 필드
  쓰기 몇 개뿐 — 실제 Roblox 커넥션(`gcconn`)은 **Instance 생성 시점에
  단 한 번만** 만들어져 모든 `bindLifetime` 호출이 공유(위 문서 "(0)"
  절). 같은 값에 unbind 직후 바로 rebind해도 커넥션을 만들거나 끊지
  않음 — 저렴하고 안전.
- `Ref`가 dedup이 **꼭 필요했던** 이유는 `RefLeafHandler.process`가
  `v:Set(inst)`를 호출해서 — 이건 사용자가 등록한 `:Callback()`을
  스퓨리어스하게 재통지하는 **관측 가능한 부작용**. Observer/Effect의
  Leaf 바인딩(`bindLifetime`만 호출)엔 이런 부작용이 없음 — `fn` 재실행은
  leaf 바인딩이 아니라 Observer/Effect 자기 내부 구독이 따로 트리거함.

이 재조사를 근거로 처음엔 `base/dispatch-core-plan.md`에 "Observer/Effect
Leaf는 이 dedup이 불필요 — 확인 후 기각"이라는 노트를 추가하고, 사용자에게
"버그가 아니었다"고 보고했다(이 시점까지는 커밋 전).

## 3차 — 사용자 반론: 성능상 `==` 비교가 항상 더 쌈, 그래도 넣는다

사용자가 correctness 문제가 아니라는 판단엔 동의하면서도, **성능
관점에서 `==` 비교(바이트코드 1개 + 분기)가 매번 여러 `Relate` weak
테이블 읽기/쓰기(해싱 비용)를 도는 것보다 항상 더 싸다**고 지적 — 이득이
공짜에 가까운데 안 넣을 이유가 없다는 판단으로, `RefLeafHandler`와 같은
패턴을 그냥 넣기로 확정.

## 최종 반영

- `base/dispatch-core-plan.md` "핸들러 내부 상태 저장" 절(4번) — "불필요,
  확인 후 기각" 노트를 "채택함(correctness 아니라 순수 성능 최적화)"으로
  교체, 근거(gcconn 공유로 안전함 + `==` 비교가 항상 더 쌈) 둘 다 명시.
- `base/source-state-plan.md`에 새 절 **"Observer/Effect Leaf dedup"**
  신설(위 "bindLifetime이 이 게이트의 두 번째 진입점이다" 절 바로 뒤,
  "PA님 코드와의 교차검증" 절 앞) — `RefLeafHandler`와 완전히 같은 모양의
  pseudocode(`old ~= v` 체크, retractor 안에서만 `relate` 정리하는
  기존 주의사항까지 그대로 재사용).
- `doc-check.py` ERROR 0 유지 확인(중간에 절 제목이 줄바꿈에 걸쳐
  인용되면서 생긴 WARN 1건은 그 자리에서 한 줄로 재정렬해 해소).

## 교훈

- **"문제로 보인다"와 "실제로 문제다"는 구현 스케치를 끝까지 추적해야
  갈린다** — `bindLifetime`/`unbindLifetime`의 실제 비용(weak table 쓰기
  몇 개, 커넥션 재생성 없음)을 확인하기 전까진 이게 실제 버그인지 판단할
  근거가 없었음. 처음 보고("잠재적 갭")는 근거 없이 과하게 신중했고, 재조사
  후 "버그 아님"도 성능 관점을 놓쳐 성급했음 — 두 번 다 사용자가 다음
  질문으로 바로잡음.
- **"correctness엔 불필요"와 "넣을 가치가 없다"는 다른 결론** — 안전하다고
  최적화까지 자동으로 기각되는 건 아님, 비용 대비 이득을 따로 판단해야 함.

## 4차 — `/code-review` 실행, 확정 findings 10건 + 추가 발견 1건

사용자가 `/code-review`(effort: high)를 실행 — 이 코퍼스는 소스코드가
없는 설계 문서 저장소라 "버그"는 자기모순/dead pseudocode/깨진 절
참조로 정의됨. 결과 10건을 `ReportFindings`로 렌더한 뒤, 같은
task-id가 한 번 더(다른 표본의 finder 조합으로) notify하며 1건을
추가로 찾아냄(`effect-plan.md`/`ref-plan.md`/`source-state-plan.md`의
"동적 경로 가드"가 볼드 텍스트일 뿐 실제 마크다운 헤딩이 아닌데 6곳이
절 제목처럼 인용 — `doc-check.py`로 직접 재확인해 사전에 존재하던
WARN임을 검증, "이번 diff가 새로 만들었다"는 리뷰의 프레이밍만 부정확
했음). 사용자가 "전부 고쳐줘"로 확정.

## 5차 — 고치던 중 사용자 개입: Tag/Attribute 자기등록 모델 자체가 틀림

findings #5(`dispatch-core-plan.md:402`)/#6(`:560`)을 고치려던 참에
사용자가 끼어들어 "tag, attribute를 base가 스스로 등록한다는 사실이
아닌거 알지?"라고 지적 — 이건 열한 번째 세션이 네 라운드 정정 끝에
확정했던 "`TagHandler`/`AttributeKeyHandler`/`AttributeGroupHandler`가
quad-base 모듈 로드 시점에 스스로 등록"이라는 결론 그 자체였다.

사용자가 정정한 모델: (1) `TagHandler` 등 그 이름들은 참조 카운트/이름
claim **알고리즘 구현**일 뿐 — 공유 코드라 base에 위치하는 것뿐,
스스로 등록되는 주체가 아님. (2) `HANDLER_PRIORITY_FALLBACK`에 실제로
꽂히는 건 이를 감싸는 **별도 이름의 엔티티**(`TagFallbackHandler` 등)여야
함 — 이름 자체로 "자동 안전망"임을 구분. (3) 등록 주체는 quad-base
모듈이 아니라 **필요한 엔진(백엔드 팩토리)** — `BaseModule` 뮤테이션
시점에 자기 전용 Handler들과 같이 등록. 사후 검증 결과 이건
`base/lifecycle-pattern.md`가 이미 명시적으로 거부해둔 `InitNamespace`류
top-level 부작용 패턴과 정확히 같은 클래스의 실수였고,
`base/module-lifecycle-plan.md`가 이미 일반화해둔 "base는 인터페이스만,
등록/구현은 팩토리 뮤테이션 시점"이라는 원칙을 이 Tag/Attribute
결론만 예외로 뒀던 것이었다.

**반영**: `archive/tag-attribute-load-time-registration-reversed.md`
신설(뒤집힌 원문+근거), `base/dispatch-core-plan.md`("base가 소유하는
핸들러와 주입되는 엔진 op" 절 전면 재작성 + `addHandler` 절 수정),
`base/tag-plan.md`, `base/attribute-plan.md`, `base/architecture.md`
(Tag.luau 파일 설명), `base/module-lifecycle-plan.md` 전부 새 이름
(`TagFallbackHandler`/`AttributeKeyFallbackHandler`/
`AttributeGroupFallbackHandler`)과 새 등록 주체 서술로 갱신.
`CLAUDE.md`의 11번째 세션 서술은 **역사적 기록으로 그대로 둠**(그
세션 시점엔 최선의 결론이었음) — 이 재역전만 짧게 링크로 남김.

## 최종 반영 (code-review findings 11건 전부)

1. `source-state-plan.md` `ObserverEffectLeafHandler.isHandlable`에
   `type(k) == "number"` 체크 추가(FALLBACK 가드가 죽은 코드였던 것 수정).
2. `source-state-plan.md`의 `bindLifetime` pseudocode `canExecute`→
   `canBound`로 정정.
3. `README.md` source-state-plan.md 행의 "canExecute 하나로 통합" 서술을
   `canBound`/`canExecute` 분리 모델로 갱신.
4. `lifecycle-pattern.md` 445줄 "bindLifetime + canExecute"에 `canBound`
   추가.
5-6. `dispatch-core-plan.md`의 Tag/Attribute 등록 모델 전면 재작성(위
   5차 참고, 원래 findings의 "stale 문장"/"미설명 배너" 둘 다 이걸로 해소).
7. `ref-plan.md:585`/`source-state-plan.md:910`의 존재하지 않는
   `"HANDLER_PRIORITY_FALLBACK"` 절 인용을 실제 헤딩 제목("base가
   소유하는 핸들러와 주입되는 엔진 op")으로 정정.
8. `question.md`/`CLAUDE.md`/`HUMAN_TODO.md`의 "결정 대기 절이 비어
   있음" 서술을 "헤딩째로 삭제됨"으로 정정(헤딩 자체가 이미 없었음).
9. `CLAUDE.md`의 Debounce/Throttle "열린 질문 4개"를 개수 언급 없이
   `question.md`/`debounce-throttle-plan.md` §12로 위임(실제는 6개 —
   "개수는 소스 하나만" 원칙 적용).
10. `CLAUDE.md`의 11번째 세션 기록을 ~103줄에서 ~13줄로 압축(전문은
    이미 `session/2026-08-14-11-...md`에 보존돼 있어 손실 없음).
11. `effect-plan.md`/`ref-plan.md`/`source-state-plan.md`의 볼드
    "동적 경로 가드" 3곳을 전부 실제 `###` 헤딩으로 승격 — 6곳의 절
    인용이 전부 자연히 해소됨.

`doc-check.py` ERROR 0 / WARN 93→85 유지 확인(마지막에 새 archive
파일을 README 색인에 추가하지 않아 ERROR 1건 잠깐 발생 — 바로 수정).

## 교훈

- **문서가 "네 라운드 정정 끝에 확정"했다고 자기 서술해도 그게 진짜
  맞다는 보장은 아님** — 같은 결론이 그 코퍼스 안의 다른 확정 원칙
  (`module-lifecycle-plan.md`의 팩토리 뮤테이션 패턴)과 충돌하는지는
  "여러 번 검토했다"는 사실과 별개로 매번 다시 확인해야 함.
- **사용자가 "아닌 거 알지?"로 끼어들면 그 자리에서 멈추고 확인부터** —
  이미 진행 중이던 수정 계획(findings #5/#6)을 그대로 밀어붙였으면 틀린
  전제 위에 새 "정정"을 또 쌓을 뻔했음.

## 6차 — 같은 실수의 다른 잔존 여부 전수 확인

사용자가 "다른 부분도 이런 실수 나온 거 있는지 봐줘"라고 요청 —
"모듈 로드 시점/require 시점에 스스로 등록·실행"류 top-level 부작용
주장을 코퍼스 전체에서 grep. 두 개는 오탐으로 확인(`bind-system-plan.md`
133줄은 그냥 정적 lookup 테이블 채우기라 부작용 없음, `research/
debug-tooling-plan.md`362줄은 React DevTools 비교 서술이라 quad 자신의
설계가 아님). `dispatch-core-plan.md`의 일반 Handler 등록 절(492-516줄,
`NoneHandler`/`StoreBind`/`Leaf`)은 이미 "BaseModule 테이블에 딸린
state"로 정확히 서술돼 있어 문제 없음 확인.

**진짜 갭 발견**: `ROADMAP.md` M10 체크리스트가 여전히 `TagHandler`/
`AttributeKeyHandler`/`AttributeGroupHandler` 자체를
`HANDLER_PRIORITY_FALLBACK`으로 등록한다고 서술 중이었고, 새로 분리된
`TagFallbackHandler`/`AttributeKeyFallbackHandler`/
`AttributeGroupFallbackHandler` 파일 자체가 체크리스트에 아예 없었음
— 이대로면 구현자가 이 세 파일을 만들 필요를 몰랐을 것. M10 배너에
정정 노트 추가, 세 알고리즘 항목에서 "스스로 등록 안 함" 문구로
정정, 새 Fallback 파일 셋을 체크리스트 항목으로 추가.
`base/architecture.md`의 AttributeKey.luau/Attribute.luau 파일 트리
설명에도 같은 Fallback 언급 보강(Tag.luau는 5차에서 이미 반영됨).
`doc-check.py` ERROR 0 유지.

## 7차 — 두 번째 `/code-review high`, 5차 정정의 잔존 흔적 3건 + 별개 버그 1건

사용자가 `/code-review high`를 재실행 — 5차의 Tag/Attribute 정정이
프로즈만 고치고 실제 pseudocode/다른 서술은 놓친 곳들을 정확히 잡아냄:

1. `tag-plan.md:155` — `TagHandler.priority = HANDLER_PRIORITY_FALLBACK`
   pseudocode가 100줄 아래 프로즈 정정과 모순(실제 코드로 복붙될
   블록이라 가장 심각). `TagHandler`는 `.priority` 없음으로 수정,
   "패키지 배치" 절에 `TagFallbackHandler = { priority = ...,
   isHandlable = TagHandler.isHandlable, process = TagHandler.process }`
   래퍼 pseudocode 신설.
2. `dispatch-core-plan.md:612` — opt-in 가로채기 예시가 "`TagHandler`
   자신(FALLBACK)"이라고 서술, 몇 줄 위 재정정 블록과 모순 — 실제
   FALLBACK에 있는 건 `TagFallbackHandler`로 정정.
3. `ref-plan.md:257` — `RefLeafHandler.isHandlable`이 `and not
   isPostRef(v)`를 빠뜨림(PostRef 도입 9차 세션 때 이 자리가 안
   갱신됨) — 같은 파일 783줄의 최종 공식과 불일치했던 걸 발견, 이번
   세션과 무관한 **별개의 사전 존재 버그**였음(Tag/Attribute 정정과
   무관). 정정.
4. `architecture.md:170` — `Leaf.luau` 파일 트리가 `v=Ref/Observer/
   PreRef/PostRef`만 나열하고 `Effect`가 빠져 있었음(이번 세션 1~3차가
   만든 `ObserverEffectLeafHandler`와 불일치) — `Effect` 추가 + 결합
   핸들러 언급 보강.

전부 직접 재확인 후 반영(finder가 인용한 줄 번호/문맥을 실제로 열어
확인). `doc-check.py` ERROR 0 유지.

**교훈**: 프로즈만 고치고 pseudocode 블록을 안 고치는 게 이 세션에서
반복된 패턴(5차의 근본 원인과 같은 클래스) — "핸들러 계약을 코드
블록으로 정의하는 절"은 그 코드 블록 자체를 grep 대상에 넣어야
한다는 게 이번에 다시 확인됨.

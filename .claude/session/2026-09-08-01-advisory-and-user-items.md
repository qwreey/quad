# 2026-09-08-01 — Gemini 코드 품질 자문 처리 + 남은 사용자 몫 일괄 회신 (새벽~아침, 대화형)

원장: `qa-request/post-implementation-review-round3.md` §12. 커밋 넷: `66281ab`(Attr) · `55ca091`(quad-error 가변인자 + 메시지 규약) · `24320db`(`__tostring`) · `7e80ace`(Q26·Q27) + 이 문서 커밋.

## 1. 입력

사용자가 Gemini 세션에서 받은 코드 품질·아키텍처 자문을 무시 파일 `qa-request/code-quality-and-architecture-advisory-ignoreme.md`로 반입했다(커밋 안 됨). §1에 사용자 본인의 회신 원문(2026-09-08 00:27), §2 기각 넷(Luau `x is Type` — 없는 문법 / `Slot:List` reconcile 전역 스크래치 — 재진입 오염 / ErrUtil 자동 태깅 — 층위 결합 / 퍼징 하네스 — 범위 이탈), §3 권고 셋(`__tostring` / `setFuncLevel(level, ...fns)` / 메시지 포맷 헬퍼). 사용자: *"기각 된 것 이외 남은 실질 조언은 아주 작은것들 뿐이라서, 사용자 몫을 검토하며 같이 처리하면될것 같아."* 남은 사용자 몫은 `question.md` 2절: round3 Q25·Q26·Q27, 구조 재편 8절 `Attr`, 10-4 정적 굽기, flatten 슈거 일곱.

## 2. 메인의 1차 정리(질문 여섯)와 사용자 회신

메인이 각 항목에 의견과 기본값을 붙여 한 덩어리로 물었다. 회신 요지:

- **`__tostring`**: 하되, 메인이 낸 "브랜드가 있으면 `__tostring`" 규칙은 거부 — *"__tostring 이 거기까지 넓어지는건 조금 애매한듯. 예를 들어 Epoch 도 Brand 라서요. 나열된 목록 자체는 괜찮은것 같은데 … Brand 가 있는 함수일 수도 있고, metatable 자체가 없는 뭔가일 수도 있고, Brand 가 가지는 대상은 다양함."* → 목록으로 고정(값 프리미티브 열넷 + Tween), `AttrKey`(plain 브랜드) 제외.
- **`setFuncLevel` 가변인자**: *"이전 시그니처 남길 이유 없는듯. 다른 프로젝트에서 안 쓰고 있고 지금이 최적의 시기."* 메인 논거 하나 추가 — 배열 리터럴의 nil 구멍을 루프가 조용히 건너뛰던 `H-410` list drift의 남은 구멍이 `select("#")`로 닫힌다(`H-475`).
- **메시지 포맷 헬퍼**: 기각 — *"grep 해보기에 핼퍼 자체가 나빠보임. 난 에러에 대해 정적으로 stacktrace 없이도 문제를 볼 수 있어야하는데 (특히 Fallback 같은게 들어오면 더 그럼) 핼퍼가 있으면 에러 포멧 부분이 전부 쪼개짐. 그냥 프로젝트 컨벤션 상 어느정도 일정한 에러 형식을 정해두고 각자 포멧하는게 나을지도 … 필요한 부분만 손질하는게 좋아보이는데"*. 메인도 동의(축소안 (a)조차 리터럴을 쪼갠다). → `architecture.md`에 "메시지 모양" 규약(`주어: 이유 (got X)`), 159곳 실측 중 어긋난 열 곳 손질(`H-477`).
- **Q25**: 문항의 틀을 다시 봄 — *"크게 보면 숏핸드 핸들러 문제는 아닌거 같기도. 그냥 이전 Tween == 지금 Tween 인가 보는게 없으면 사실 Source<Tween> 에서 같은걸 emit 해도 일반 Frame 에서도 Dedup 안 되는거 아님? 근데 그 경우도 사실 이걸 Dedup 으로 봐야할지, 재 실행으로 봐야할지 애매해보임. Animate 에 슈거로 간단히 들어갈 레이어가 어쩜 아니였을지도? 더 큰 그림으로 봐야하나 고민중."* → 열림. 메인 분석은 §12(사실관계: 일반 Frame에선 Q12의 객체 신원 비교로 접힌다 — 안 접히는 건 `Mapped`가 새 객체를 만드는 숏핸드 두 키뿐; 해석: Tween은 불변 값이라 같은 값 재도착은 멱등이 자연스럽고 재실행은 새 값으로 표현된다 → 신원 dedup은 Tween 값의 멱등성이고 소비 자리가 맞다; 위로 올리려면 State에 distinct-until-changed가 새로 필요).
- **Q27**: 등록 op 기각 — *"따로 Brand 를 담은걸 두고 require 도 못하는게, 하위 모듈들이 안 deps 로 가지고 런타임에 주입 받는 구조상 module.is... 로 받는게 아닌 이상 불가능하고, 따라서 브랜드 추가자가 필요한건 맞음. 그런데 나는 저런 핼퍼를 만들 이유는 못 느끼는중. 그냥 Brand 를 가져야하는것도 맞고 … isXXX를 최상위에 넣는게 관행인데, 각 프로바이더/플러그인 상 그냥 필드로 넣는게 맞는 계약같아서, Dispatch.addBrandProbe 같은게 필요한지는 의문임. 필요하다 해도 Dispatch 에 오는게 맞는지 모르겠음."* → 메인 구현 선택(새 표면 0): 진단 `brandNameOf`가 모듈의 `is*` 함수 필드를 스캔해 base 목록보다 먼저 시도(`pcall` — 브랜드 아닌 `isX` 헬퍼가 진단을 가리지 않게), `BRAND_PROBES`의 `"isTween"` 삭제.
- **Q26**: 별도 언급 없음 → 메인 권고 (a)의 축소판. 코드 대조에서 둘째 증상이 Q33 (a)로 이미 사라진 것을 확인(`H-476`) — None이 nil 쓰기 경로를 타 슬롯이 `true`로 내려간다.
- **`Attr`**: *"Attr 로 두는건 동의. 다만 동일하게 AttrKey 와 setAttr getAttr 로 두는게 맞아보임. 이로써 quad 의 Attr 은 기본적으로 엔진과 무관하다는게 표면적으로 드러나고, 그 구현이 실제로 Attribute 로 바인드 된다는게 명확해져서 괜찮은 것 같음."* → 엔진 op까지(`setAttr`; `getAttribute` op는 없음).
- **10-4**: *"정적 굽기는 지금 안 한다 동의. 이건 해야할 일이 아닌듯 하고, 백로깅이 아닌 리서치 대상으로 둬야할듯. 정보 추합부터 되어야하는 부분이라서 …"* → 리서치 상태로, `question.md`에서 제거.
- **flatten 일곱**: *"내일 다뤄볼 예정"* + 새 축(named ref/modifier는 핸들러를 안 타는 값이라 `Split`이 받으면 "이 자체로 drive된다"는 오독 위험 — named만 받는 좁은 슈거일 수도) → 플랜 2절 꼬리에 메모.

## 3. 반영 순서와 방법

1. **`Attr` 축약** — 한 파이썬 스크립트로 코드·타입·gen-d·spec·라이브 문서(base/research/reference/qa-request/README/question/todos/conventions/project-context/ROADMAP/HUMAN_TODO/CLAUDE) 일괄 치환. 토큰 맵을 긴 것부터(`AttributeKeyFallbackHandler` → … → `AttributeKey` → … → 맨 끝 단어 경계 `Attribute`), **"옛 `…`" 인용 구간은 정규식으로 잘라 치환에서 제외**(2026-09-07 자기모순 16곳 사고의 재발 방지). `git mv Attribute Attr`. 제외: `session/`·`archive/`·`session-summary.md`·`audit/`·`luau-test/`(spike 23만 실 패키지를 require하므로 포함). 사고 하나: `research/source-layout-plan.md` 8절 자체가 옛 이름을 서술하는 절이라 치환 뒤 "`Attr` → `Attr` 축약"이 됐다 — 절을 통째로 다시 썼다(옛 이름은 `옛 \`Attribute\``). 메시지 하나(`Attributes or plain tables`)를 `Attr values`로. 남은 `Attribute`는 Roblox 어휘(`SetAttribute`)·파일명·README 이력 문장뿐. `mise exec -- pesde install` 뒤 test.sh exit 0.
2. **quad-error** — `ns.setFuncLevel(level, ...)`: level 비-number·인자 nil/비함수는 `error(…, 2)`. 호출부 45곳은 정규식 두 벌(루프형 → 한 호출, 단일형 인자 교환), Slot·Modifier의 긴 목록은 여러 줄로. gen-d 템플릿 두 줄 + `emit`/`check`. `spec.errorutil` V절(둘 태깅·nil 구멍·옛 순서·0개).
3. **메시지 손질** — 정본 모양은 우세한 기존 형태 그대로 명문화. spec 단언은 부분 문자열이라 대부분 통과, 모양을 단언한 넷(`spec.leaf`·`spec.refhandlers`·`spec.tween`)만 갱신. base 인용 여섯(effect-plan 의사코드·attribute-plan·architecture 트리·deferred-hardening·source-state-plan·slot-plan 의사코드).
4. **`__tostring`** — 각 Impl 메타테이블에 직접(메타메서드는 `__index`로 상속되지 않아 `GateImpl`은 자기 것). Observer/Effect는 `Subscribed[self]`/`WeakSubscribed[self]` 레지스트리로 강·약·없음 셋 — 처음엔 `self.Subscribed` 플래그를 썼는데 drive 경로에서 기대와 달라 spec을 명시적 `Subscribe/WeakSubscribe`로 바꾸고 레지스트리 기준으로 정리. State는 `_cacheCurrCount == _cacheTargetCount`일 때만 값. `spec.tostring` 신설(스펙 50).
5. **Q26·Q27** — Property 첫 스냅 `{ Value, Source }`, 취소·Finish는 `prev.Tween` 있을 때만(스냅 기록은 취소할 것도 되돌릴 목표도 없다 — 외부 쓰기 뒤 Finish가 옛 값을 다시 박지 않게); `brandNameOf` 스캔. spec 둘.
6. 문서: round3 §4 행 셋·§12, question.md 2절, question-resolved, source-layout-plan 8·9·10-4, flatten 플랜, todos 00, README, 이 파일, session-summary.

## 4. 교훈

- 기계 치환은 "옛 이름을 서술하는 절" 자체를 망가뜨린다 — 인용 보호만으로는 부족하고, 이름 변경을 다루는 절(8절)은 치환 뒤 반드시 다시 읽을 것.
- 문항을 닫기 전에 그 문항이 든 증상이 **다른 결정으로 이미 사라졌는지** 코드로 대조할 것(Q26 둘째 증상은 Q33이 지웠다).
- 외부 자문의 "채택 권고"도 발견≠결정 — 권고 3은 사용자가 근거(정적 가독성)로 뒤집었고, 권고 1의 적용 범위도 메인이 넓힌 만큼 사용자가 좁혔다.

## 5. 후속(같은 날 아침) — Q25는 값 비교 모델로 닫힘

메인이 §2의 Q25 분석(신원 dedup은 Tween 값의 멱등성, 소비 자리가 맞다 / 위로 올리는 건 새 메커니즘)을 보고한 뒤, 사용자가 자기 뜻을 정확히 짚었다: *"정확히 내가 말 한 부분은 Animate 보다 위 계층인, 처리자인 프로퍼티 핸들러(소비자) 계층이긴 했음. 슈거보다 위 계층. Source/State 아니고. 신원 가지고는 한계가 보여서, Value 만 보는게 맞다고 봄 — Time/Style 등은 Animate 가 변경되어도 무시하던것 처럼, 비교 대상이 아니라 봄. 2. Dedup 필드가 Tween 에 있는것 맞고, dedup 메커니즘을 tween 하나에만 두는것도 동의함."* 즉 메인이 Q12 인용(*"이전 Tween 을 그대로 리턴"*)을 **객체 신원**으로 읽고 구현했던 것이 어긋남의 뿌리였다 — 사용자의 모델은 처음부터 소비자 층의 **값 비교**였고, 그러면 숏핸드의 `Mapped` 새 객체 문제는 캐시 없이 사라진다. 메인이 짚은 부수 조건 하나: `Animate{ Dedup = false }`가 "새 객체를 만든다"로 구현돼 있어 값 비교 아래선 접혀 버리므로 스위치가 Tween 값에 실려야 한다 → 사용자 동의(`Tween.Dedup` 필드, 메커니즘 하나). 반영(`H-478`): `Tween.validateFields`에 `Dedup` boolean, types `TweenOptions`/`TweenData`에 `Dedup: boolean?`, `Animate`는 `FIELDS`에 `Dedup`을 넣어 전달만(`sameTween`·`previous` 삭제), Property 핸들러 `v.Dedup ~= false and prev.Value == v.Value`, 슬롯 `{ Value }`/`{ Tween, Value }`(`Source` 삭제). plain 슬롯 `true`는 값을 기억하지 않아 거기 오는 Tween은 항상 재생(핫패스 할당 회피 — 메인 판단, 문서에 명시). spec: `spec.tweenproperty` 7·8절 재작성(직접 `Dispatch.process`를 StoreBind와 같은 인덱스에 넣으면 StoreBind가 밀려나는 것을 밟아 별도 인스턴스로), `spec.shorthand` 7절(UDim 심에 `__eq` — 엔진의 값 동등을 흉내), `spec.animate` 5절, `spec.tween` 7절. test.sh exit 0(스펙 50).


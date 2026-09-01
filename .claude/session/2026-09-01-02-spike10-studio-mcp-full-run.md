# 2026-09-01-02 — 스파이크 `10` 현행 모델 재작성 + Studio MCP 첫 완주

## 지시

M4 종결 직후, 다음 수순 권고("스파이크 `10` 재작성+실측 → 그 결과를 전제로
M5 규약 문항지")에 사용자: *"권고대로 하고싶어"* — compact 후 이 세션이
이행. 실행 전제(별도 계정 `qwreey_selene` 컨테이너 + MCP 프록시)는 직전
세션에 이미 충족(`HUMAN_TODO.md` 1번 해소).

## 한 일

1. **A 섹션 재작성** — 폐기 모델(2-인자 `canExecute`, `bindLifetime`의
   `.Subscribed` 세팅)을 걷어내고 `base/lifecycle-pattern.md`의
   (0) `nativeClaim` / (1) `isBoundAlive`+4함수 / (3) `canBound` vs
   `canExecute` 스케치를 최소 이식. 요구 명세는
   `audit/gcconn-trick-verification.md`의 "아직 확인 안 된 것" 절 전량.
2. **Studio MCP `execute_luau`(Edit)로 실측** — GC 대기(canary 헬퍼) 때문에
   4청크로 분할(execute_luau 타임아웃 회피, 각 do 블록 자기완결). 모든 GC
   대기가 2~3 epoch(1초 미만)에 끝나 분할이 과보수였을 수도 있지만 실패
   비용이 없었다. **전 항목 PASS** — 결과 전문은
   `audit/spike10-full-run-2026-09-01.md`(이하 그 파일이 소스, 여기선 요지만).
3. **파일 `done/` 이동 + 상태 문서 갱신**(STATUS 배너·행·개수 / README 행 /
   gcconn 문서 완주 배너 / `base/attribute-plan.md` 조건화 배너).

## 굵은 발견 둘

- **무claim inst의 userdata는 workspace 트리에 살아있어도 1 GC 사이클에
  수거된다** — `nativeClaim`이 서는 전제("강참조를 안 들면 재조회 시 다른
  userdata", `lifecycle-pattern.md` (0))가 처음으로 실증됐다. claim된
  쪽(X1)은 강참조 없이 GC를 견디고 재조회가 rawequal.
- **Attribute의 Instance 참조는 `InstanceHandle` 언랩 경유** — 구판 B 단언
  (`GetAttribute == 원본`)이 깨지면서 발견. `typeof == "InstanceHandle"`,
  `:Get()`이 원본과 rawequal, Destroy 후에도 핸들 잔존(죽은 Instance 반환).

## 사용자가 세션 중 정체를 설명 (원문 발췌)

실측 중간에 사용자가 개입해 InstanceHandle의 배경을 제공:

> *"InstanceHandle 은 우리가 Quad 작업 도중에 나온 것으로(릴리즈 시점 고려)
> ObjectValue나 Attr 등에서 Instance를 읽을 때 반환되는 값이야. … 해당
> Attr/ObjectValue는 서버에서 설정해도 클라이언트로 복제돼. 그런데
> 클라이언트는 Ref 대상 객체가 아직 서버에서 받지 못하였을 수 있어(특히
> StreamingEnabled 상태에서 더 잘 나타나 …). 그것을 해결하기 위해
> InstanceHandle를 제공해. 내가 찾아보았는데, 아직 문서화 조차 하지도
> 않았어 - 이런 일 흔해. Roblox는 문서화 안 하고 릴리즈로 움직이거든."*

> *":Get() 은 단순 얻기인데, nil 일 수도 있어. :Wait() 도 존재하는데, 이는
> 해당 객체가 나에게 들어와 실체화 되기 까지 기다려줘."*

> *"Instance:SetAttribute(name, value) : now accepts an Instance or an
> InstanceHandle. An Instance is wrapped for you. Passing nil deletes the
> attribute."* (발표 글: devforum.roblox.com/t/studio-beta-reference-instances-directly-with-attributes/4753441)

`InstanceHandle.new(inst)` 생성과 remote 전송 용법
(`remote:FireClient(player, InstanceHandle.new(workspace.Boss))` →
클라이언트 `handle:Wait()`)도 같은 설명에 포함 — `.new` 존재·
`SetAttribute(핸들)` 수용·nil 삭제는 이어서 실측으로도 확인했다.

**관측 불일치 하나(단정 안 함)**: 사용자 설명은 ObjectValue 읽기도 핸들
반환이라 했는데, 이번 Edit 모드 실측은 `.Value`가 Instance를 직접 줬고
핸들 대입은 거부됐다("Instance expected, got InstanceHandle"). 실체화
여부·롤아웃 단계 의존일 가능성만 남기고 관측 그대로 기록
(audit 파일의 "이번 실측이 안 본 것").

## 교훈/절차 메모

- **Studio 전용 스파이크의 "이 환경에서 못 돌림" 전제가 사라졌다** — MCP
  `execute_luau`로 에이전트가 직접 완주 가능(첫 사례). GC 대기는 청크
  분할이면 충분. `not-run/` 폴더의 의미가 그만큼 좁아짐(STATUS에 반영).
- 구판 단언이 깨진 것을 "스파이크 실패"가 아니라 **발견**으로 처리 —
  정밀 조사(타입/멤버/왕복/Destroy 거동) 후 단언을 실측 모양으로 갱신하고
  갱신본을 재실행해 5/5 통과 확인. M4의 `H-287` 교훈(판정 근거를 정확히)과
  같은 결.

## 후반부 — 감사 루프 · 운용 지침 신설 · M5 문항지

- **사용자 운용 지침 신설(세션 중)**: *"너 컨텍스트상, 비용상 그냥 opus 로
  내려 돌리는게 나음 그런건 서브에이전트 굴리고 기다리다 결과 보고 받는게
  맞는듯"* — 메인(fable)은 판단이 드는 일만, 가벼운·기계적 일은 opus
  서브에이전트로. `conventions.md` 언어/모델 관례 절에 명문화 + 메모리
  보완. 곧바로 적용해 M5 스코프 자료 수집을 opus 읽기 에이전트로 위임
  (감사자와 병행 — 감사자 sonnet 고정 규약은 그대로).
- **감사 1라운드(diff 정합성)**: 확실 3(README `audit/` 색인 stale /
  `dispatch-core-plan.md`의 Instance weak-key "미확인·M3 실측 대상" 서술 /
  `HUMAN_TODO.md` 5번 미마감) + 의심 2(gcconn 문서 지침 절 로컬 마커,
  "사용자가 직접" 문구 둘) — 전부 반영. 사용자 판단 1(Attribute
  `InstanceHandle` 발견의 등록 위치)은 M5 문항지 §0 Q6으로 올려 해소 경로
  확보. 자체 발견 둘도 같이 교정(ROADMAP M5 게이트 문구 stale /
  `lifecycle-pattern.md` "스텁 4종"에 `onDestroying` 동반 명시).
- **감사 2라운드(교정분+인덱스)**: 확실 2 — gcconn 문서의 "아직 확인 안
  된 것" 절 본문이 배너 없이 현재형 미해소 서술로 남은 것(→ 절 머리 배너
  추가), ROADMAP M0 "재검증 대기" 절의 `10` 체크박스 미갱신(→ `[x]` +
  닫힘 각주). 사용자 판단 1 — conventions의 모델 위임 기준 모호(haiku/
  sonnet 크기 축 vs 신설 opus 위임 축의 관계) — 사용자 회신 대기로 보고.
- **감사 3라운드(신선 산문+수렴)**: 확실 2 — 이 세션 파일이 2라운드 이후
  기록을 안 담아 summary와 어긋난 것(→ 이 절이 그 교정), `luau-test/
  README.md`의 "사용자 손이 필요한 건 Studio 전용뿐" 문장이 표의 배너와
  자기모순(→ 정정). 의심 채택 2(폴더 표 "누가 처리" 열, gcconn 문서 제목).
- **감사 4라운드(3라운드 교정분 좁은 검증)**: 교정 대상 자체는 전부 정확
  반영 확인. 새 발견은 **이 기록의 메타 결함 둘** — `not-run/` 행의 "뜻"
  열이 "처리" 열 정정과 모순(→ CLI 한정 서술로 정정), 라운드별 발견 수
  집계가 기준 혼합 + 두 파일 이중 서술(→ 개수 서술을 걷어내고 **이 절이
  라운드 기록의 유일한 소스**, summary는 개수 없이 가리키기만). **루프
  종결 판단**: 4라운드째 발견이 코퍼스가 아니라 감사 기록 자신의 메타로
  좁혀졌으므로 유한 절차 규약(각도 소진 시 잔여 보고 후 종결)대로 여기서
  닫는다 — 잔여 없음(마지막 교정은 doc-check ERROR 0으로 게이트).
- **M5 규약 문항지 신설** — `qa-request/m5-implementation-round14-brief.md`
  (§0 회신 대기). opus 스코프 보고가 낸 불일치들이 §0 문항이 됐다:
  `quad_base` 의존의 base 두 문서 모순(Q3 — architecture "quad-types에만"
  vs project-setup-plan `quad_base = workspace`), `EngineOps` M5/M10 분할
  (Q4), typed Modifier 생성자 방치 제안(Q5), 실기기 절차 확장(Q1), 단위
  다섯 절단(Q2), `InstanceHandle` 등록 위치(Q6). 머리말 3층·README 색인
  갱신, 발견 번호는 `H-290`부터 예약.

## 다음

M5 brief §0 여섯 문항의 사용자 회신 → 확정 시 `m5-implementation-round14.md`
신설 후 단위 ① 착수.

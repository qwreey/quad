# 2026-10-19-01 — opus 독립 리뷰 패스, Declaration 4절 3~5번 닫힘

## 1. 2026-10-18 — round15에 opus 한 패스 (사용자 요청)

사용자: *"opus 로 한 패스만 돌아보자. 목적은 거의 gemini 모델 시점으로만 보았는데, opus 시점에선 어떤지 보고자 함과 동시에 어느정도 의견이 수렴되는지 보고싶음(모델별 의견 수렴?)"*. opus 하나를 두 단계로 — 1단계는 round15 원장을 열지 않은 독립 리뷰(20건), 2단계는 같은 에이전트에 원장을 보여 대조. 결과는 `qa-request/code-quality-review-round15.md` §6(`H-927`~`H-939`, 수렴 표). 요지: "새 공개 표면은 열지 않는다"는 판단은 세 모델 계열이 수렴, 갈린 것은 찾는 쪽(opus는 파일 안 국소 중복·틀린 주석 — 대부분 sonnet 리뷰어가 못 본 파일; round15는 코퍼스 횡단 세기·피드백 대조). 메인이 파일:줄 아홉 자리 직접 확인, 전부 맞음.

## 2. 2026-10-19 — flatten·Spread는 미루고 3.4.0 막는 것부터

사용자: *"spread 는 아직 add 나 crud 정의도 완전히 끝난 상태가 아니란점이 걸려. 그걸 완결하고 가는게 이롭겠다 … 그러나 flatten 슈거와 spread 는 순수 추가이고. 지금 가장 급한건 3.4.0 를 막는 것과 타입함수들의 세세한 다듬기"*. 메인 정리: 남은 판정은 층 셋(원천 → 표면 모양 → 이름), 위가 정해지면 아래는 대부분 "내보내지 않음"으로 준다.

## 3. 사용자 회신 — 결정

결정 본문은 `research/declaration-surface-plan.md` 5절 끝 문단(2026-10-19)이 소스. 원문 요지:
- 원천: *"아에 덤프를 걷어내는건 아니고, 클래스맵, 기타 policy, hidden 같은걸 살려내기 위해서만 쓰고, 체커에 따라 다른 일부 요소들은 그냥 문서화로 두고 인정"* — 근거는 `p: Part`도 체커마다 달라지는 것이라 원래 사용자가 인지할 부분.
- 클래스 맵: 사용자 이해 확인 질문(*"상속 관계도를 타입에 두는 경우 크기 한도가 생기기에 그 부분을 타입 함수로 처리하도록 돕겠다는것"*) — 메인 답은 회신 본문(31은 생성 D가 클래스마다 타입을 써 넣던 크기에서 왔고, 타입 함수 꼴은 체커의 클래스를 그 자리에서 읽어 맵은 가리키기만 함). Elem/Mapper 만들 수 있는 클래스만, Modifier/Spread 추상 포함 — 동의.
- `Out` 커리 동의(*"OnChange Class Prop (Fn) … Out Class Prop (Source) 모양의 유사 짝"*), Q127·Q122 확인.
- `OnChangeFn`·`OutFn`·`OnEventFn` 비노출 — 이름이 fn 자리 타입인지 함수 자체 타입인지 모호. `typeof`에서 타입 함수가 깨지지 않는지 보고 싶다 → 2차 실측 M1.
- MapperRoot: *"Source() 와 Source<T> … 프리미티브의 경우 Ctor/Type 짝으로 내보내는데 MapperRoot 도 어찌보면 프리미티브이고(싱글턴인) … None 을 … 내보내고 있다면 똑같이"* — 메인 확인: 이미 값·타입 짝(quad-types). 메인 직전 권고("타입 이름 비노출")는 현황 확인 없이 낸 것이라 틀렸다.
- 이름 정리·H-929·Q188 등은 "좀 이따". 재야 할 것은 재자 → 2차 실측(M1 typeof, M2 ReadOnly 읽기 표면, M3 Modifier `As`/`Into`/`Overridden`/숏핸드, M4 클래스 맵 확장) opus 서브에이전트로 착수.

## 4. 2차 실측 M1~M4 결과 (opus 서브에이전트)

본문은 `audit/decl-typefn-probe-2026-10-16/REPORT.md` 끝 절(그대로 저장). 요지: M1 `typeof` 서명 꺼내기 됨(놓침 하나 — 다른 클래스로 부분 적용한 함수 대입); M2 ReadOnly 포함 읽기 표면 됨, 체커엔 읽기 전용 표시가 전혀 없어 쓰기 표면 제외는 덤프 데이터(`DenyWrite`); M3 Modifier As·Into·숏핸드는 vsc에선 킷 꼴 전부 서지만 sync에선 추상 클래스 As 트리 + Into 자리가 too complex(타입 함수 결과에 이름 정체성이 없어 구조 비교 — 추정); M4 맵 자체는 싸나 한 바운드에 361~417 이름은 sync 한도를 넘음(위치·클래스 크기 효과), 분야별 84는 깨끗, 비GUI에서 Policy 문제 셋(전역 이름 Deny가 `Part.Shape`를 지움, Hidden 규칙이 `Position` 등을 지움, `GuiObject.Transparency`가 새 덤프에서 Deprecated로 흘러감). 시스템 업데이트 예약으로 사용자가 "중간에 끝나면 잠시 멈춰줘" — Studio 싱크·후속 실측은 하지 않고 멈춤. Instance As 트리 실측이 3 GiB 상한에서 `bad_alloc`으로 남긴 코어 덤프 둘(각 3 GiB, gitignore 대상)은 메인이 지웠다.

## 5. M3 후속 — Into 자리 too complex의 갈래

사용자 *"실측 띄워줘"*. opus 서브에이전트가 (다) 하강 목록 좁히기·(라) 얇은 Into를 쟀다(본문 `audit/decl-typefn-probe-2026-10-16/REPORT.md` 끝 절): (다)는 GuiObject 하강 2~3개까지만 sync 깨끗(4개면 호출 자리, 5개 이상 전부 무너짐 — 노드 수 문턱), (라)는 효과 없음(메소드 반환 Modifier 사본끼리 비교가 원인, 태그만은 깨끗). 메인이 킷 꼴을 다시 보니 Into 자리 넷은 하강한 값을 놓기만 하고, 런타임은 놓는 자리에서 태그를 안 본다 — 메인 추가 실측: 전체형 `Modifier<GuiObject>?` prop도 sync에서 무너짐(사본 비교는 Into 고유가 아님), **마커 prop(C와 조상 태그만)을 As 없이 놓는 꼴은 세 모드 모두 깨끗·NEG 전부**(전체형이 놓치던 Frame·ScreenGui Modifier까지 거부). 이 방향(놓기만 하는 Modifier prop은 마커 — quad-types "입력 자리 = 마커" 규칙 그대로)과 이름은 사용자 결정 대기. 메인 실수 하나: `pkill -f`가 자기 셸을 맞혀 명령이 exit 144로 끊김(메모리 `feedback-pgrep-self-match`가 이미 경고한 것 — 피해 없음).

## 6. 2026-10-20 — 마커 결정, 킷 규모 시험

사용자: M3 추천 (가) 동의(`ModifierInto<C>`가 마커, 옛 Rust식 인터페이스는 물러남), M4 (가) 동의(GUI 중심 맵 유지), *"그냥 입력 받는 부는 전부 Into 를 마커 필드로써 될 수 있는걸로 두고 많은 부분이 해결될 것으로 보이긴함. 시도해보자"*. 결정은 `research/declaration-surface-plan.md` 5절 끝 문단(2026-10-20), `base/modifier-plan.md` 11절 Into 자리에 3.4.0 변경 배너. 시험: opus 서브에이전트가 변환 스크립트 시제품으로 두 킷 전체를 새 표면 사본(스크래치)으로 바꿔 sync·vsc·pin 타입 검사 — 기준선(변환 전) 대비, 입력 Modifier에 메소드가 필요한 자리 수, 기계 변환 실패 목록.
같은 날: devplorer 상향 보고 프롬프트를 사용자에게 써 줌(devplorer `.claude/feedback/devui.md`를 출발점으로 층 다섯 — quad 코어·quad-roblox/타입·devui 빈칸·devui 상향 후보·문서 공백; 출력 `devplorer/.claude/feedback/quad-upstream-2026-10-20.md`), 사용자가 넣어 둠.

## 7. 2026-10-20 — devplorer 상향 보고서 판정

devplorer가 `quad-upstream-2026-10-20.md`를 냈다(사용자: 핵심 셋 — quad 코어로 못 한 것 없음, 가장 큰 덩어리는 "있는데 못 찾음", 진짜 결핍은 devui의 막힘 셋 U2·U3·U7). 메인이 원문을 다 읽고 `feedback/devplorer-2026-10-20.md`에 판정: devui 결핍·상향 후보를 장치별 묶음 여섯(가 포인터 아래 맨 위 판정 — 10-16 코드 리뷰 5·6·8과 같은 장치, 메인이 `Window/Manager.luau` 126행·`Interaction.luau` 105~108행으로 확인; 나 입력 상자; 다 팝업; 라 목록 가상화; 마 창 채우기; 바 위젯 prop·Style)으로, 문서 공백은 devui README·위젯 주석에서 quad 스킬로 가는 링크 한 처방으로. 묶음은 전부 사용자 결정, 문서 줄과 U17(PlotLines X 모양) 원인 조사는 메인 자율.

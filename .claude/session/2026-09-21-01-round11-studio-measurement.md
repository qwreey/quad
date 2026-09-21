# 2026-09-21-01 — round11 실측 라운드(Studio 샌드박스, sonnet) + 반영 묶음

사용자 지시: *"작은 실측을 하나씩 sonnet 으로 굴리며, 코드를 바꾸진 말고 우선 내 의견을 기록해나가보자"* — 여섯 항목을 하나씩 재고 결과마다 의견을 받아 `audit/round11-studio-2026-09-21/REPORT.md`에 원문으로 적었다. 라운드 끝에 사용자 *"다른 내가 답해줘야하는 부분이 없다면 천천히 시작해도 돼"*로 문서·생성기 묶음을 반영(감사 한 라운드 5건 정정).

## 환경 사건 — Studio 실행 스레드의 capability 제한

MCP `execute_luau` 스레드가 9월 16일 이후 제한 capability 스레드가 되어(빠진 것: `ScriptGlobals`·`LoadUnownedAsset`·`AssetRequire` 등 15개) rojo가 넣은 일반 ModuleScript를 `require`할 수 없었다. 사용자는 Beta Features에서 끌 항목이 없었고 명령줄에서 quad 폴더를 샌드박스+capability로 설정했으나 그 집합의 `ScriptGlobals`가 스레드에 없어 여전히 거부. 메인이 스레드의 capability를 전수 열거(스크래치 샌드박스 폴더에 하나씩 대입)해 `CapabilityControl`이 있음을 확인하고 두 폴더를 `ScriptGlobals` 없는 집합으로 다시 설정 — quad는 `_G`/`shared`/`getfenv`를 src에서 안 쓰므로 정상. 이후 로드 관용구는 REPORT.md 2번 절.

## 결과 여섯(REPORT.md가 소스)

1 소문자 별칭 시그널은 죽은 시그널 → Deprecated 허용목록(사용자: 의도는 처음부터 "자주 쓰이던 것만", `Draggable` 제외) / 2 물리 순서는 설계 그대로 / 3 Q62 네 입구 — `Extract`로 회복, `Splice` 삽입은 Q40 동결, **문서의 "`Remove`로 회복"은 틀림**(host·조상 파괴), `nativeExtract` 가드는 순환 UB 하나뿐이라 보류(사용자) / 4 B″-8 창은 실기기 도달 불가(Q9 좀비 UB) / 5 강하게 쥔 Tween은 대상 Instance를 붙잡지 않음 — 처방 불필요(사용자: 간접적으로 알고 있었고 실측으로 확정) / 6 GS 07 `SelectedObject` 예제는 서술대로, 파괴 때 비우는 건 엔진이 아니라 cleanup.

## 반영 묶음(`6b0adf3c`, 감사 `948800e8`)

생성기 `DEPRECATED_NAME_KEEP` + 표면 JSON 44항목 제거 + D 재생성(타입 BREAKING), roblox/02 레거시 절, core/06 순환 회복 안내·좀비 UB, slot-plan·round8/round11 원장 정정 마커, GS 07 캐비엇 둘, CHANGELOG, todos/HUMAN_TODO 10~13 닫음, ROADMAP tweenSlots 메모 닫음.

**교훈**: 사용자 문서의 "회복 방법" 문장은 실기기 실측 전엔 mock에서만 참일 수 있다 — `Remove`가 Roblox에선 `Destroy`라는 백엔드 차이를 문서가 안 탔다.

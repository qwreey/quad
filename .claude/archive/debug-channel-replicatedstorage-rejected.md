# [기각됨] quad-debug 채널을 `ReplicatedStorage`에 자동 생성하는 방식

**기각 일시**: 2026-08-06 세션. **현재 유효한 설계**: `research/
debug-tooling-plan.md` "데이터 채널" 절 — Bindable을 quad 모듈 자신의
Instance 트리 안(quad가 이미 설치돼 있는 위치 그대로)에 두고
`CollectionService` 태그로 노출, 플러그인은 `GetTagged(tag)`로 찾음
(`GetDescendants()` 전체 순회 불필요). 이 파일은 더 이상 능동적으로 참고할
필요 없음(구현에 안 씀) — 사유를 짧게 보존해둔 것.

## 무엇을 검토했었나

quad-debug-roblox가 초기화 시 `ReplicatedStorage` 밑에 잘 알려진 이름으로
Bindable을 만들어 노출하는 방식.

## 기각 이유

개발자가 의도하지 않은 Instance를 게임 트리에 주입하는, 부작용이 큰 행위라
기각(사용자 정정). `ReplicatedStorage`는 개발자 자신의 게임 트리이지
quad가 마음대로 채워도 되는 공간이 아님 — quad 모듈 자신의 Instance 트리
안에 두면 이 문제 자체가 없고, `CollectionService` 태그를 쓰면 플러그인이
quad가 어디 설치됐는지 몰라도 바로 찾을 수 있어 `ReplicatedStorage`에 둬야
할 이유도 애초에 없었음.

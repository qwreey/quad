# M5 단위 ⑤ — 첫 실물 렌더 실측 (2026-09-02)

ROADMAP M5 마지막 체크박스("실제 Roblox에서 첫 `Frame{...}` 렌더 확인")의
실측 기록. 판정 관례는 스파이크 `10`(PASS/FAIL 계수 + 최종 마커,
`audit/spike10-full-run-2026-09-01.md`) 준용.

## 반입 경로 — rojo 라이브 싱크 (이 날 확립, 청크 업로더 폐기)

- 처음엔 소스를 `execute_luau`로 밀어넣는 청크 업로더(19청크)로 갔으나
  **사용자 지시로 rojo 정본 경로로 전환·업로더 폐기**("우회는 하지
  말도록 하자").
- 구성: 개발 머신에서 `mise exec -- rojo serve --address 0.0.0.0 --port
  34872`(기존 `default.project.json` — `ReplicatedStorage/quad-base·
  quad-roblox` 매핑, relink 덕에 `luau_packages`가 실복사라 트리
  자기충족) + Studio 쪽 공식 Rojo 플러그인. **사용자가 1회 Connect +
  `autoReconnect` 켬 + 변경 확인(패치 컨펌) 끔** — 이후 파일 저장이
  실시간 반영되고, Studio 재시작 시에도 serve가 떠 있으면 자동 재연결
  (플러그인 소스 `App:tryAutoReconnect()` — sonnet 리서치로 확인).
  Studio 프로세스 자체가 죽으면 재기동은 사람 몫(사용자 확인 —
  "스튜디오가 터지면 재시작으로 플레이스 들어가기까지 자동으로 다시 안
  되는지라").
- 네트워크 실측: Studio 컨테이너 → 개발 머신 `http://172.17.7.5:34872`
  도달 OK(HttpService, HttpEnabled는 place에 저장돼 이미 켜져 있었음).
  serve API는 msgpack 전용(참고 — 플러그인 우회 경로를 기각한 근거 중
  하나).
- **require 캐시 주의(사용자 지적)**: Studio에서 `require`는 캐시되므로
  같은 ModuleScript를 다시 require하면 rojo가 Source를 갱신해도 옛
  모듈이 돌아온다. 단일 모듈이면 `require(ms:Clone())` 관용구지만 quad는
  다중 모듈(내부 상대 require)이라 **패키지 폴더째 클론해 임시 폴더에
  앉힌 뒤 클론의 `src`를 require** — 클론 안에서 상대 require가
  자기충족이고, 실행마다 신선한 quad 인스턴스가 나온다(아래 스크립트).

## 실측 스크립트와 결과 (Edit 모드, execute_luau)

`ReplicatedStorage`의 quad-base(모듈 39)/quad-roblox(모듈 76 — `.pesde`
사본 포함)를 `ServerStorage.QuadTestRun`으로 클론 →
`QuadRoblox(require(qb.src).New())` → 세 시나리오(**⚠️ [같은 날 후속 —
탐사자 지적] 이 직접 호출형은 이 실측 시점의 표면이고, 같은 날 `H-305`
(d′)로 `Quad.New():UseProvider(QuadRoblox)`로 재성형됐다 — 지금 재현은
그 표면으로 할 것(직접 호출은 identity 락·확장 병합을 우회, unsupported).
재성형 후 재실측(멱등/외부 프로바이더 거부/아래 3종 전부 PASS)은
`session/2026-09-02-04-h305-useprovider.md`가 기록**):

| 시나리오 | 단언 | 결과 |
|---|---|---|
| 정적 렌더 | `D.TextLabel` 자식이 `D.Frame`에 마운트 + Text/Size/Position/BackgroundColor3 프로퍼티 적용 | PASS (`childMounted=true`) |
| 반응형 프로퍼티 | `Source(UDim2)` → `Size` 바인딩, `:Set`으로 300→150 폭 변경이 실프로퍼티에 도달 | PASS (`{0,300}→{0,150}`) |
| 반응형 자식 교체 | `Source(inst)` 자식 첫 마운트 → `:Set(b)`에 새 자식 마운트 + 옛 자식 강등(`.Parent == nil`)·파괴 아님(생존) | PASS (`firstMount/swapped/oldDemoted/oldAlive` 전부 true) |

루트 셋을 `ScreenGui`에 담아 `StarterGui` 부착(루트 `.Parent =`는 밖에서
허용 — H-148 복원 그대로) — **뷰포트 스크린캡처로 시각 확인**(다크
프레임 + "quad first render" 라벨 + 반응형 프레임 렌더됨).

최종 마커: 3/3 PASS, FAIL 0.

## 잔여·부수

- 옛 청크 업로드 잔여물 `ServerStorage.QuadPkg`는 이 실측 전에 정리함.
- `H-25` 확인분(quad-types `Quad` 갱신·`H-305` 문항)은 발견 원장
  `qa-request/m5-implementation-round14.md`가 소스 — 여기 반복하지 않음.

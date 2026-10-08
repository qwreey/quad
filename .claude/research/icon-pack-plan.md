# 아이콘 팩 계획 — Material Symbols 아틀라스 + quad로 다시 짜는 IconPack 플러그인 (2026-10-08)

> **[2026-10-08 신설 — 사용자 요청, 착수 아님]** 사용자(2026-10-08): material 킷 글리프 아이콘이 잘리는 것을 보고, 옛 `qwreey/qwreey.roblox.plugins` `IconPack.Plugin`의 Material 아이콘을 쓰되 그 플러그인을 quad + material 킷으로 다시 짜고 아이콘 자원도 새로 만들어 올리자는 구상 — *"이것도 quad에서 제공하는 요소가 되고싶어 … quad 레포에 있는건 애매하긴 한듯. 어떻게 보니? 다만 문서에서는 연결해주고 싶어"*. 이 문서는 조사 사실(sonnet 조사, 출처는 각 줄)과 메인 제안, 사용자가 정할 것을 담는다. 위치·이름이 정해지면 이 문서는 그 레포로 옮긴다.

## 1. 지금 있는 것 — 옛 플러그인

옛 플러그인(`qwreey/qwreey.roblox.plugins` master, `IconPack.Plugin/` — 마지막 커밋 2021-04-04)은 `res/IconDump.lua`에 `IconDump[스타일][그룹][이름] = 에셋 URL` 표를 두고, 스타일은 `baseline` 하나, 아이콘 1482개(그룹 17)에 **이미지 id 1482개를 아이콘마다 따로** 쓴다. 독 위젯은 열 때 1482개 모두 `ImageButton` + `ImageLabel`을 만들고 각자 자기 URL을 로드한다(`Main.server.lua` 1101~1250행, `PreloadAsync`는 주석 처리) — 사용자가 짚은 "미리보기 로드가 엄청 걸린다"가 코드로 확인된다. outlined·rounded·sharp·fill 변형은 없다. 레포 라이선스는 MIT(2021 qwreey75)이고 Google 아이콘의 Apache 2.0 고지는 코드에 없다. id 대역(6022668875~6035229858)이 사용자 본인 업로드인지 Roblox 라이브러리의 Material Icons(README가 `roblox.com/library/6045494621` 링크)를 덤프한 것인지는 판정하지 못했다.

## 2. 원천 — Material Symbols

Google의 현행 세트는 Material Symbols다(구 Material Icons는 2022년에 갱신이 멈춤 — `google/material-design-icons` README). 라이선스 Apache 2.0(배포물에 LICENSE·NOTICE 고지 필요). 스타일 셋(Outlined·Rounded·Sharp) × 가변 축(FILL 0/1, wght 100~700, GRAD, opsz 20~48). 아이콘 수는 Google Fonts 메타데이터 기준 Symbols 3927개(구 Icons 2160). SVG는 npm `@material-symbols/svg-400`(Apache-2.0, 0.47.6 확인)에서 jsDelivr로 바로 받을 수 있다 — `/{outlined|rounded|sharp}/<이름>.svg`와 `<이름>-fill.svg`, 스타일당 7854개(3927 × fill 둘), 합계 23565개·13 MB, 각 파일은 48×48 viewBox의 path 하나(단색 — Roblox에선 `ImageColor3` 틴트). 이 컨테이너에서 **resvg 0.48.1 정적 바이너리**(GitHub 릴리즈, 4.6 MB)가 시스템 설치 없이 돌고 SVG → PNG 렌더가 확인됐다.

## 3. 업로드 — 사용자 기억 대조

사용자 기억은 *"Open Cloud(creative api)로 올리면 플레이스/경험에 귀속돼 다른 곳에서 못 쓴다"*였는데, 문서 근거로는 다르다(추정 — 실측 아님): Open Cloud Assets API(`POST apis.roblox.com/assets/v1/assets`)의 소유자(creator)는 **사용자 또는 그룹**이고, 경험에 묶이는 것은 에셋이 아니라 **API 키의 선택적 범위 제한**("Restrict by Experience")이다. 이미지·데칼은 기본이 Open Use(Roblox creator-docs `projects/assets/privacy.md`: *"By default, Images, Decals, and Meshes are created as Open Use"*) — 단 계정·그룹에 Asset Privacy를 켜 두면 새 에셋이 Restricted가 되어 허가한 크리에이터·게임만 쓴다. **올리기 전에 그 계정의 Asset Privacy 설정을 확인**해야 한다. 걸리는 점 둘: (1) Open Cloud 업로드는 **데칼 id**를 돌려주고 이미지 id로 바꾸는 공식 API가 없다(DevForum 기능 요청) — Studio에서 `InsertService:LoadAsset(decalId)`로 `Decal.Texture`를 읽어 resolve하는 스크립트가 현실적이다(이 킷의 시트들을 사용자가 손으로 resolve한 것과 같은 일 — 메모리 `feedback-roblox-image-asset-id`); (2) 이미지 업로드 속도·일일 상한의 공식 수치는 찾지 못했다 — 429와 `x-ratelimit-*` 헤더로 물러나며 재시도하는 스크립트면 되고, 시트 방식이면 장수가 수십~백여 장이라 예전처럼 1482장을 몇 주에 걸쳐 손으로 올릴 일은 없다. 모더레이션 대기는 업로드 operation의 `moderationResult`로 본다.

## 4. 아틀라스 규모

이 킷에서 실측한 대로 칸을 붙이면 축소 렌더에서 이웃 칸이 섞여 티끌이 생기므로 여백을 넉넉히 둔다(`feedback/consumer-kits-studio-qa-2026-10-07.md` 5차). 1024×1024 한 장 기준(wght 400·GRAD 0·opsz 24 고정 가정):

| 칸(아이콘 / 피치) | 한 장 | 한 조합(3927개) | 스타일 셋 × fill 둘 |
|---|---|---|---|
| 48 / 64 | 256 | 16장 | 96장 |
| 64 / 80 | 144 | 28장 | 168장 |
| 96 / 128 | 64 | 62장 | 372장 |

UI 아이콘은 보통 18~24 px로 그려지므로 48/64면 2~3배 여유다(메인 의견). 메타데이터에 `popularity`가 있어 인기 상위만 먼저 굽는 선택도 있다.

## 5. 메인 제안 — 어디에, 어떤 모양으로

**quad 레포 밖**에 둔다. quad는 "있는 그대로 제공"하는 라이브러리이고, 아이콘 세트는 특정 디자인 시스템의 자원이라 성격이 다르다(같은 이유로 material 킷도 게시 때 분리 — 사용자에게 같은 날 제안). 구성은 둘:

- **아이콘 자원 패키지**(가칭): 생성기(SVG 받기 → resvg 렌더 → 여백 넣은 1024 아틀라스 합성 — 이 킷의 `assets/gen-*.py`처럼 결정적 생성), 업로드 스크립트(Open Cloud + 429 백오프 + 데칼 → 이미지 id resolve 단계), 그리고 런타임 색인 모듈 `name → { Image, ImageRectOffset, ImageRectSize }`(스타일·fill별). 아이콘 하나 그리는 데 `ImageLabel` 하나, 미리보기도 같은 시트를 잘라 쓰므로 시트 몇 장만 로드된다.
- **플러그인**: quad + material 킷으로 다시 짠다. 사용자 지시대로 옛 독 합치기 등은 버리고 정규 진입점 하나(Studio 플러그인 샌드박스·격리 때문에 옛 구조를 되살리는 의미가 없음 — 사용자). 목록은 가상화(보이는 줄만)로.
- material 킷은 아이콘 prop이 그 색인 항목을 받게 해 자원 패키지를 **선택적으로** 쓴다(지금의 텍스트 글리프는 기본 폴백으로 남김).
- quad 문서는 "쓸 수 있는 자원" 페이지에서 킷·아이콘 팩·플러그인으로 링크한다(사용자: *"문서에서는 연결해주고 싶어"*; material 킷도 "킷·사용처" 목록에서 별도 문서로 — 사용자 고민 중).

## 6. 사용자가 정할 것

1. 레포 위치와 이름(자원 패키지·플러그인·material 킷 분리 시점) — 메인 권고: 자원 패키지와 플러그인은 처음부터 quad 밖, material 킷은 이름이 정해져 게시할 때 분리.
2. 범위 — 스타일 셋 전부 × fill 둘(48/64 칸이면 96장)인지, Outlined 하나부터인지, 인기 상위만인지.
3. 칸 크기(48/64 권고).
4. 업로드 계정(사용자 개인 / 그룹)과 Asset Privacy 설정 확인 — 다른 경험에서 쓰려면 Open Use여야 함.
5. 옛 1482개 id의 처분(쓰지 않고 새 아틀라스로 대체하는 쪽이 메인 의견 — 소유·잘림·스타일 부재 때문).

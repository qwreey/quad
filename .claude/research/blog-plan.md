# 공개 사이트 블로그 — `starlight-blog` 검토

> **[2026-09-14 신설 — 조사만, 착수 아님]** 사용자 제안. 공개 로드맵 페이지를 만드는 대신
> 블로그를 두고, "무엇을 내려 하는지"를 사용자 자신의 입장으로 적어 나가자는 구상.
> 옛 로드맵·changelog 구상(`archive/surveys/2026-09-11-roadmap-changelog-docs-plan.md`, 같은 날 archive)의 **후행 로드맵** 쪽을
> 이 문서가 대신한다. 그 문서의 CHANGELOG 쪽은 사이트에 이미 안정화됐다(`starlight-changelogs`).

## 1. 왜 로드맵이 아니라 블로그인가 (사용자 논거)

사용자(2026-09-14): *"틀이 잡힌 로드맵은 이미 마일스톤 단위에서 끝났고, 뭔가 더 틀 잡아서
수행할만한게 없는 시점에 왔기 때문에 그게 더 나아보여."* 그리고 *"뭘 내려 하는지 등을 내 입장으로
같이 적어 나가는게 나아보임."*

정리하면 셋이다.

- M0~M11이 끝난 뒤 남은 일은 백로그(`ROADMAP.md`)의 느슨한 후보들이라, 체크박스식 공개 로드맵으로
  세우면 약속처럼 읽히고 곧 낡는다.
- 블로그 글은 **쓴 날짜가 박힌 입장**이라 낡아도 거짓이 되지 않는다 — "그때 이렇게 생각했다"로 남는다.
- 설계 이유·방향 전환을 사용자 목소리로 풀 자리가 생긴다(Quadnomicon은 설계 해설, 블로그는 소식·의도).

## 2. 플러그인 사실 (조사 시점 2026-09-14)

출처: `HiDeoo/starlight-blog@main`의 `packages/starlight-blog/package.json`과 `docs/src/content/docs/`.

- **버전·호환**: `starlight-blog` 0.29.0, peer `@astrojs/starlight >=0.41.0`. 우리 사이트는 `^0.42.0`, astro `^7.3.2`라
  peer 조건은 맞는다(실제 설치·빌드는 안 해 봄 — 2026-09-14 `npm ci` 사고가 있었으니 설치할 땐 `--legacy-peer-deps` 없이).
- **기능**: 헤더의 블로그 링크, 페이지네이션 글 목록, 전역·글별 저자, 태그, 커버 이미지, 블로그 전용 사이드바(최근 글·
  추천 글·태그), RSS, 구조화 데이터, 여러 인스턴스.
- **설치 모양**: `astro.config.mjs`의 Starlight `plugins`에 `starlightBlog({...})`, 그리고 `src/content.config.ts`의
  `docs` 컬렉션 스키마를 `docsSchema({ extend: (context) => blogSchema(context) })`로 확장. 글은 `src/content/docs/blog/`의
  `.md`/`.mdx`.
- **frontmatter**: `title`·`date` 필수. 선택은 `lastUpdated`, `tags`, `excerpt`, `authors`, `featured`(사이드바 상단 고정),
  `draft`, `cover`, `metrics`.
- **설정**: `title`(로케일별 객체 가능), `postCount`(기본 5), `recentPostCount`(기본 10), `authors`, `prevNextLinksOrder`,
  `prefix`(기본 `blog`), `navigation`(`header-start`/`header-end`/`none`, 기본 `header-end`), `metrics`, `rss`·`structuredData`
  (Astro `site`가 있으면 기본 켜짐 — 우리는 `site`가 설정돼 있어 둘 다 켜진다).
- **다국어**: Starlight i18n을 그대로 따른다. 로케일 디렉터리마다 `blog/`를 두고 같은 파일 이름으로 번역을 잇고,
  번역이 없으면 Starlight 폴백. 블로그 제목은 `title` 객체로 번역.

## 3. 우리 사이트에 붙일 때 걸리는 자리

1. **`starlight-sidebar-topics`와의 관계.** 지금 사이드바는 토픽 넷(Docs/Reference/Quadnomicon/Changelog)이고, 어느 토픽에도
   안 속한 페이지는 `exclude`에 적어야 한다(랜딩이 그 예). 블로그 페이지는 자기 사이드바를 따로 그리므로 **블로그 경로를 토픽으로
   세울지(다섯째 토픽), `exclude`로 뺄지**를 실측으로 정해야 한다. 두 플러그인이 같은 사이드바 자리를 서로 덮을 수 있다 —
   설치 전 `quad-site-tester`로 확인할 항목.
2. **헤더 링크 위치.** `navigation` 기본값 `header-end`는 테마 전환기 앞에 링크를 단다. 사용자가 손질 중인 탑바 스타일
   (`src/styles/starlight-*.css`)과 겹치니 위치는 사용자 판단.
3. **로케일.** 한국어가 `root` 로케일이라 한국어 글은 `src/content/docs/blog/`, 영어는 `src/content/docs/en/blog/`. `en/` 번역은
   잠정 유보 중이라(todos 00번 2026-09-09 저녁) 처음엔 한국어만 쓰고 영어는 폴백에 맡기는 게 자연스럽다.
4. **원본 위치와 동기화.** 사이트의 `src/content/docs/`는 `sync-docs.py`가 `docs/<track>/`에서 만드는 생성물이다(`TRACKS`
   목록). 블로그 글도 원본을 `docs/blog/`에 두고 트랙을 하나 더할지, 사이트 폴더에 직접 둘지 정해야 한다 — 원본 `docs/`는
   GitHub에서도 읽히는 것이 원칙이라 전자가 기존 규약과 맞다. 그 경우 `date`·`tags` 같은 블로그 frontmatter를 `sync-docs.py`가
   그대로 통과시키는지 확인이 필요하다.
5. **스키마 확장 겹침.** `content.config.ts`의 `docs` 컬렉션은 지금 `docsSchema()` 그대로라 `extend`를 처음 넣는 것이고, 다른
   플러그인(quiz·changelogs)은 별도 컬렉션이라 겹치지 않는다.
6. **`starlight-md-txt`와의 관계.** 블로그 글에도 `.md.txt` 사본이 생기는지(에이전트가 읽는 경로) — 해도 무해하지만 확인 항목.

## 4. 정해야 할 것 (사용자)

1. 블로그를 둘지 자체 — 이 문서는 "둔다면"의 조사다.
2. 첫 글감 — 예: 3.x 공개 소감과 BREAKING 허용 주간의 뜻, v1 사용자에게 하는 말, 앞으로 볼 것(spring·fastscroll·quad-debug)에
   대한 지금의 생각.
3. 사이드바 토픽으로 세울지, 헤더 링크만 둘지(3절 1·2).
4. 원본을 `docs/blog/`에 둘지(3절 4).
5. 저자 표기 — 전역 저자 한 명(사용자)으로 둘지.
6. RSS를 켜 둘지(기본 켜짐).

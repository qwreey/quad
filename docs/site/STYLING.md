# 사이트 스타일 손보기 — 사람이 관리하는 CSS의 진입점 (2026-09-14)

사용자 지정 CSS는 `astro.config.mjs`의 `customCss` 목록에 파일을 하나씩 더해 관리한다(`src/styles/user-theme.css`·`starlight-sidebar-topics-tweak.css`가 그 예). 이 문서는 "Starlight 요소를 어떻게 골라잡나"만 다룬다.

## 왜 `astro-xxxx` 클래스를 잡을 필요가 없나

- **Starlight의 CSS는 전부 cascade layer 안에 있다** (`@layer starlight.base / reset / core / content / components …` — 빌드 산출 `dist/_astro/*.css`에서 확인). layer 밖의 규칙은 specificity와 무관하게 layer 안 규칙을 이긴다. `customCss`로 넣는 파일은 layer 밖이므로 **어떤 선택자를 쓰든 Starlight 기본값을 덮는다.** `!important`가 필요 없다.
- **Starlight는 `scopedStyleStrategy: "where"`로 컴포넌트 스타일을 스코프한다**(`node_modules/@astrojs/starlight/dist/index.js`). 즉 `.astro-hkc32dio` 같은 해시 클래스는 `:where()`로 감싸여 specificity 0이다. 우리가 그 해시를 흉내 낼 이유가 없다.
- `vite.css.modules.generateScopedName`은 **CSS Modules(`*.module.css`)에만** 적용된다. Starlight 컴포넌트의 `<style>` 스코프 해시(컴포넌트 소스의 해시)에는 영향이 없고, 미리 구워진 CSS도 마찬가지다. 해시는 컴포넌트 소스가 같으면 빌드마다 같지만 Starlight 업그레이드 때 바뀌므로 잡지 않는다.

그래서 남는 일은 **안정된 훅으로 요소를 고르는 것**뿐이다.

## 안정된 훅 (빌드 HTML에서 해시를 벗기고 본 것)

| 자리 | 선택자 |
|---|---|
| 헤더 | `header.header`, `.site-title`, `.version-badge`(우리 컴포넌트), `site-search button` |
| 왼쪽 사이드바 전체 | `nav.sidebar`, `sl-sidebar-pane#starlight__sidebar`(`.sidebar-pane`), `.sidebar-content`, `sl-sidebar-state-persist` |
| 토픽 바(플러그인) | `.starlight-sidebar-topics`, `.starlight-sidebar-topics-current`, `-icon`, `-badge` |
| 사이드바 그룹 | `.sidebar-content details`, `summary`, `.group-label`, `.caret` |
| 사이드바 항목 | `ul.top-level > li > a.large`(최상위 항목), 그룹 안은 `details > ul > li > a`, 현재 페이지는 `a[aria-current="page"]` |
| 오른쪽 목차 | `.right-sidebar-panel`, `starlight-toc`, `#starlight__on-this-page`, `mobile-starlight-toc`, `#starlight__mobile-toc` |
| 본문 | `.sl-markdown-content`, `.sl-heading-wrapper`, `.sl-anchor-link`, `.expressive-code`, `.sl-badge`, `.starlight-aside` |
| 이전/다음 | `.pagination-links`, `.sl-link-button` |
| 퀴즈(플러그인) | `.sl-quiz-source`, `.sl-quiz-title`, `.sl-quiz-progress-*`, `.sl-quiz-results-*` |
| 유틸 | `.sl-flex`, `.sl-hidden`, `md:sl-hidden`, `lg:sl-block`, `.print:hidden`, `.not-content` |

찾는 법: 브라우저 DevTools에서 요소를 고르고 **`astro-`로 시작하지 않는 클래스·`id`·`aria-*`·커스텀 엘리먼트 이름**(`starlight-menu-button`, `site-search`, `sl-quiz-…`)을 잡는다. 대부분 있다. 없으면 부모의 안정된 훅 + 구조(`> ul > li > a`)로 내려간다 — 구조는 Starlight 마이너 버전 안에서는 거의 안 바뀐다.

## 그래도 훅이 없는 요소면 — 컴포넌트 오버라이드(하나만)

전부 붙일 필요는 없다. 그 요소가 든 **컴포넌트 하나**를 얇게 감싸 클래스를 하나 얹는다(`astro.config.mjs`의 `components:`에 이미 `SiteTitle`을 이렇게 바꿔 두었다). 예 — 사이드바에 우리 클래스를 얹고 싶을 때:

```astro
---
// src/components/Sidebar.astro
import Default from '@astrojs/starlight/components/Sidebar.astro';
---
<div class="qd-sidebar"><Default {...Astro.props}><slot /></Default></div>
```

```js
// astro.config.mjs → starlight({ components: { Sidebar: './src/components/Sidebar.astro' } })
```

오버라이드 가능한 컴포넌트 목록은 Starlight 문서 "Overrides Reference"(Header·Sidebar·PageFrame·TableOfContents·Pagination·ContentPanel·MarkdownContent 등 스무 개 남짓). 이미 다른 플러그인이 같은 컴포넌트를 바꾸고 있으면(지금은 sidebar-topics가 `Sidebar`, sidebar-swipe가 `MobileMenuToggle`) 그 플러그인의 컴포넌트를 감싸야 한다 — 그 경우는 플러그인이 제공하는 클래스(`.starlight-sidebar-topics`)를 쓰는 편이 낫다.

## 확인

`npm run build` 뒤 `grep -o "내-클래스" dist/_astro/*.css`로 규칙이 그대로 실렸는지 본다(사용자 테마 색 `#c7001e`가 그대로 나오는 것을 2026-09-14에 확인). dev 서버가 도는 중엔 build를 돌리지 말 것(`dev.sh` 머리 주석).

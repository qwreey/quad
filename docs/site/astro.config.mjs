// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import mermaid from 'astro-mermaid';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
// [2026-09-13 사용자] 플러그인 여섯 + 다이어그램 확대(HUMAN_TODO 도식 항목 관련 사용자 후속 요청) — 각 훅 자리에 결정 배너를 남긴다.
import starlightQuiz from 'starlight-quiz';
import starlightMdTxt from 'starlight-md-txt';
import starlightContextualMenu from 'starlight-contextual-menu';
import starlightSidebarSwipe from 'starlight-sidebar-swipe';
import starlightChangelogs, { makeChangelogsSidebarLinks } from 'starlight-changelogs';
import starlightSidebarTopicsPlugin from 'starlight-sidebar-topics';
import starlightImageZoom from 'starlight-image-zoom';

// [2026-09-11] 현재 버전 — 메인 패키지 quad-base/pesde.toml을 **설정 파일이 읽어 상수로 박는다**(vite define).
// 컴포넌트가 import.meta.url로 읽으면 build에서는 번들 위치(dist/.prerender)가 기준이라 경로가 깨진다(사용자 실측: ENOENT …/docs/site/quad-base/pesde.toml).
const manifestPath = fileURLToPath(new URL('../../quad-base/pesde.toml', import.meta.url));
const versionMatch = readFileSync(manifestPath, 'utf8').match(/^version\s*=\s*"([^"]+)"/m);
if (!versionMatch) throw new Error(`astro.config: no version in ${manifestPath}`);
const QUAD_VERSION = versionMatch[1];

// https://astro.build/config
export default defineConfig({
	// [2026-09-10] Cloudflare Pages(Wrangler 직접 업로드)로 배포 — 루트 base. 커스텀 도메인 quad.qwreey.moe(사용자 결정 2026-09-10) — sitemap·canonical의 절대 URL만 여기서 나온다. 프리뷰 URL(*.quad-docs.pages.dev)은 그대로 열린다(DEPLOY.md).
	site: process.env.DOCS_SITE ?? 'https://quad.qwreey.moe',
	base: '/',
	// [2026-09-10 사용자] 로컬 dev 서버를 샌드박스 밖 프록시 호스트로 볼 때 vite가 Host 헤더로 막는다(allowedHosts).
	// DOCS_ALLOWED_HOSTS: 쉼표 목록(추가 호스트) 또는 `all`(아무 호스트나). 기본은 quad.selene.yaeji.moe 하나.
	vite: {
		define: { __QUAD_VERSION__: JSON.stringify(QUAD_VERSION) },
		server: {
			allowedHosts:
				process.env.DOCS_ALLOWED_HOSTS === 'all'
					? true
					: ['quad.selene.yaeji.moe', ...(process.env.DOCS_ALLOWED_HOSTS ?? '').split(',').map((h) => h.trim()).filter(Boolean)],
		},
	},
	// [2026-09-10 사용자] 박스 문자 아스키아트가 브라우저·폰트마다 깨진다(CJK 폭) → ```mermaid 블록을 클라이언트에서 렌더(GitHub도 mermaid를 그린다). starlight보다 앞에 둬야 remark 단계에서 코드 블록을 가로챈다.
	integrations: [
		mermaid({ autoTheme: true }),
		starlight({
			title: 'Quad',
			logo: { src: './src/assets/quad-logo.svg', replacesTitle: true, alt: 'quad' },
			favicon: '/favicon.svg',
			description: 'DOMless Reactive UI Framework for Roblox & Luau',
			// [2026-09-10 사용자 버그 리포트] 한국어를 root 로케일로 — 로고·홈 링크가 `/ko`(없는 페이지, 404)가 아니라 `/`로 간다.
			// 한국어 문서는 `/<track>/…`, 영어는 `/en/…`. 옛 `/ko/…` URL은 public/_redirects가 301로 보낸다.
			defaultLocale: 'root',
			customCss: [
				'./src/styles/custom.css',
				'./src/styles/theme-images.css',
			],
			locales: {
				root: {
					label: '한국어',
					lang: 'ko',
				},
				en: {
					label: 'English',
					lang: 'en',
				},
			},
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/qwreey/quad' }],
			// [2026-09-11 사용자] 헤더 로고 옆 현재 버전 배지(quad-base/pesde.toml을 빌드 시 읽음 — src/version.ts) → pesde 패키지 페이지 링크
			components: { SiteTitle: './src/components/SiteTitle.astro' },
			// [2026-09-13 코디네이터 지시] mermaid 다이어그램 클릭 확대(스크립트는 public/scripts/mermaid-zoom.js —
			// astro-mermaid가 그리는 인라인 svg는 빌드 타임 rehype 변환(starlight-image-zoom)이 못 잡아서 별도로 둔다).
			head: [{ tag: 'script', attrs: { src: '/scripts/mermaid-zoom.js', defer: true } }],
			tableOfContents: {
				minHeadingLevel: 2,
				maxHeadingLevel: 4,
			},
			// [2026-09-10] Starlight 0.39+ — autogenerate 그룹은 `items: [{ autogenerate }]` 형태, 그룹의 `badge`는 유지된다(항목 badge만 지원)
			// [2026-09-10 사용자] 그룹은 기본 접힘(`collapsed`) — 현재 페이지가 든 그룹(과 그 상위)만 Starlight가 펼친다(각 토픽의 `items` 안에서도 그대로 적용)
			// [2026-09-13 사용자] 사이드바가 너무 많고 복잡하다는 판단 — starlight-sidebar-topics로 트랙을 토픽 여섯으로 갈랐다.
			// 이 플러그인은 최상위 `sidebar`가 설정돼 있으면 config:setup에서 즉시 throw하므로, 옛 `sidebar: [...]` 배열은
			// 지우고 각 그룹을 그대로 토픽의 `items`로 옮겼다(라벨·collapsed·badge 전부 그대로 유지). 랜딩(index.mdx)은
			// 어느 토픽에도 없는 페이지라 plugins 배열 아래 `starlightSidebarTopicsPlugin`의 두 번째 인자 `exclude`로 뺐다.
			plugins: [
				starlightSidebarTopicsPlugin(
					[
						{
							label: 'Getting Started (시작하기)',
							link: '/getting-started/00-installation/',
							items: [{ autogenerate: { directory: 'getting-started' } }],
						},
						// [2026-09-10 사용자] 순서: 시작하기가 맨 앞, 왜 Quad인가는 그 뒤(비교 문서) — 토픽 순서도 같게(2026-09-13)
						{
							label: 'Overview (왜 Quad인가)',
							link: '/overview/01-why-quad/',
							items: [{ autogenerate: { directory: 'overview' } }],
						},
						{
							label: 'How-To Guides (실전 가이드)',
							link: '/how-to/01-component-conventions/',
							items: [{ autogenerate: { directory: 'how-to' } }],
						},
						{
							label: 'Reference (레퍼런스)',
							link: '/reference/00-index/',
							items: [
								{ label: '색인', slug: 'reference/00-index' },
								// [2026-09-11 사용자] 슈거는 quad-base 안의 물건이라 Core 아래 하위 그룹으로(Blocker도 Gate 위의 순수 슈거라 이쪽)
								{
									label: 'Core (quad-base)',
									collapsed: true,
									items: [
										{ autogenerate: { directory: 'reference/core' } },
										{ label: 'Sugar (순수 슈거)', collapsed: true, items: [{ autogenerate: { directory: 'reference/sugar' } }] },
									],
								},
								{ label: 'Roblox (quad-roblox)', collapsed: true, badge: { text: 'Roblox', variant: 'note' }, items: [{ autogenerate: { directory: 'reference/roblox' } }] },
								{ label: 'Extend (확장 계약)', collapsed: true, badge: { text: 'Advanced', variant: 'caution' }, items: [{ autogenerate: { directory: 'reference/extend' } }] },
							],
						},
						{
							label: 'The Quadnomicon (심층 아키텍처)',
							link: '/quadnomicon/01-revision-and-epochmap/',
							badge: { text: 'Deep Dive', variant: 'caution' },
							items: [{ autogenerate: { directory: 'quadnomicon' } }],
						},
						// [2026-09-13 파일럿] starlight-changelogs 버전별 페이지(/changelog-versions/…)를 기존 전문 미러
						// `/changelog/`(sync-docs.py가 CHANGELOG.md를 그대로 싣는 페이지) 옆에 나란히 둔다 — 대체할지
						// 병존시킬지는 사용자 결정 대기(보고 5번 참고). base는 기존 `/changelog/`와의 경로 충돌을 피해
						// 'changelog-versions'로 잡았다.
						{
							id: 'changelog',
							label: 'Changelog (변경 이력)',
							link: '/changelog-versions/',
							items: [
								...makeChangelogsSidebarLinks([
									{ type: 'latest', base: 'changelog-versions', label: '최신 버전' },
									{ type: 'recent', base: 'changelog-versions', count: 5 },
									{ type: 'all', base: 'changelog-versions', label: '전체 버전' },
								]),
								{ label: '전문 미러 (기존, /changelog/)', link: '/changelog/' },
							],
						},
					],
					{
						// index.mdx(한국어 root)·en/index.mdx — 랜딩은 토픽 밖(사용자 지시)
						exclude: ['index', 'en/index'],
						// starlight-changelogs가 동적으로 만드는 /changelog-versions/version/…·/compare/…는 docs 컬렉션
						// 페이지가 아니라 sidebar-topics가 자동으로 못 찾는다 — 'changelog' 토픽에 수동으로 묶는다.
						// picomatch가 매칭하는 id는 맨 앞에 슬래시가 붙는다(ensureLeadingSlash) — 패턴에도 슬래시가 있어야 매칭된다.
						// en 로케일 페이지는 id 앞에 `en/`이 그대로 붙어 나오므로(로케일별 topics 자동 처리 없음) 패턴을 둘 다 둔다.
						topics: { changelog: ['/changelog-versions/**', '/en/changelog-versions/**'] },
					},
				),
				starlightQuiz(),
				// [2026-09-13 사용자] 각 페이지 원문을 `<slug>.md.txt`로 노출 — AI 에이전트가 읽는 용도(파일럿 결과는 보고 2번)
				starlightMdTxt({ format: '.md.txt' }),
				// [2026-09-13 사용자] 본문 복사 + AI 프로바이더에 물어보기. copy/view 버튼은 `<path>/index.md`를 하드코딩해서 fetch하므로
				// `injectMarkdownRoutes`(기본 true, starlight-markdown 경유)를 켠 채로 둔다 — starlight-md-txt의 `.md.txt`와
				// 형식이 달라 라우트가 겹치지 않는다.
				starlightContextualMenu({ actions: ['copy', 'chatgpt', 'claude'] }),
				// [2026-09-13 사용자] 모바일 사이드바 스와이프 — 옵션 없이 켜기만 하면 됨
				starlightSidebarSwipe(),
				starlightChangelogs(),
				// [2026-09-13 코디네이터 추가] 다이어그램 확대 — docs/assets SVG(<img class="light-only/dark-only">)를 zoom 대상으로
				// 자동으로 잡는다(rehype가 markdown의 <img>/<picture>를 감싼다). astro-mermaid 인라인 <svg>는 이 플러그인의
				// 대상이 아니다(빌드 타임 rehype 변환이라 클라이언트에서 그려지는 svg를 못 봄) — 그 처리는 별도 스크립트로(아래 참고).
				starlightImageZoom(),
			],
		}),
	],
});

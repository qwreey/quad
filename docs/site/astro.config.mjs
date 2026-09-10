// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	// [2026-09-10] Cloudflare Pages(Wrangler 직접 업로드)로 배포 — 루트 base. 커스텀 도메인 quad.qwreey.moe(사용자 결정 2026-09-10) — sitemap·canonical의 절대 URL만 여기서 나온다. 프리뷰 URL(*.quad-docs.pages.dev)은 그대로 열린다(DEPLOY.md).
	site: process.env.DOCS_SITE ?? 'https://quad.qwreey.moe',
	base: '/',
	// [2026-09-10 사용자] 로컬 dev 서버를 샌드박스 밖 프록시 호스트로 볼 때 vite가 Host 헤더로 막는다(allowedHosts).
	// DOCS_ALLOWED_HOSTS: 쉼표 목록(추가 호스트) 또는 `all`(아무 호스트나). 기본은 quad.selene.yaeji.moe 하나.
	vite: {
		server: {
			allowedHosts:
				process.env.DOCS_ALLOWED_HOSTS === 'all'
					? true
					: ['quad.selene.yaeji.moe', ...(process.env.DOCS_ALLOWED_HOSTS ?? '').split(',').map((h) => h.trim()).filter(Boolean)],
		},
	},
	integrations: [
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
			tableOfContents: {
				minHeadingLevel: 2,
				maxHeadingLevel: 4,
			},
			// [2026-09-10] Starlight 0.39+ — autogenerate 그룹은 `items: [{ autogenerate }]` 형태, 그룹의 `badge`는 유지된다(항목 badge만 지원)
			// [2026-09-10 사용자] 그룹은 기본 접힘(`collapsed`) — 현재 페이지가 든 그룹(과 그 상위)만 Starlight가 펼친다
			sidebar: [
				// [2026-09-10 사용자] 순서: 시작하기가 맨 앞, "왜 Quad인가"는 그 뒤(비교 문서 — 먼저 밝힐 필요 없음), Quadnomicon은 레퍼런스 아래
				{ label: 'Getting Started (시작하기)', collapsed: true, items: [{ autogenerate: { directory: 'getting-started' } }] },
				{ label: 'Overview (왜 Quad인가)', collapsed: true, items: [{ autogenerate: { directory: 'overview' } }] },
				{ label: 'How-To Guides (실전 가이드)', collapsed: true, items: [{ autogenerate: { directory: 'how-to' } }] },
				{
					label: 'Reference (레퍼런스)',
					collapsed: true,
					items: [
						{ label: '색인', slug: 'reference/00-index' },
						{ label: 'Core (quad-base)', collapsed: true, items: [{ autogenerate: { directory: 'reference/core' } }] },
						{ label: 'Sugar (슈거·오퍼레이터)', collapsed: true, items: [{ autogenerate: { directory: 'reference/sugar' } }] },
						{ label: 'Roblox (quad-roblox)', collapsed: true, badge: { text: 'Roblox', variant: 'note' }, items: [{ autogenerate: { directory: 'reference/roblox' } }] },
						{ label: 'Extend (확장 계약)', collapsed: true, badge: { text: 'Advanced', variant: 'caution' }, items: [{ autogenerate: { directory: 'reference/extend' } }] },
					],
				},
				{
					label: 'The Quadnomicon (심층 아키텍처)',
					collapsed: true,
					badge: { text: 'Deep Dive', variant: 'caution' },
					items: [{ autogenerate: { directory: 'quadnomicon' } }],
				},
			],
		}),
	],
});

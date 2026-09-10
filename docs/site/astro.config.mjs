// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	// [2026-09-10] Cloudflare Pages(Wrangler 직접 업로드)로 배포 — 루트 base. 커스텀 도메인 quad.qwreey.moe(사용자 결정 2026-09-10) — sitemap·canonical의 절대 URL만 여기서 나온다. 프리뷰 URL(*.quad-docs.pages.dev)은 그대로 열린다(DEPLOY.md).
	site: process.env.DOCS_SITE ?? 'https://quad.qwreey.moe',
	base: '/',
	integrations: [
		starlight({
			title: 'Quad',
			logo: { src: './src/assets/quad-logo.svg', replacesTitle: true, alt: 'quad' },
			favicon: '/favicon.svg',
			description: 'DOMless Reactive UI Framework for Roblox & Luau',
			defaultLocale: 'ko',
			locales: {
				ko: {
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
			sidebar: [
				{ label: 'Overview (왜 Quad인가)', items: [{ autogenerate: { directory: 'overview' } }] },
				{ label: 'Getting Started (시작하기)', items: [{ autogenerate: { directory: 'getting-started' } }] },
				{ label: 'How-To Guides (실전 가이드)', items: [{ autogenerate: { directory: 'how-to' } }] },
				{
					label: 'The Quadnomicon (심층 아키텍처)',
					badge: { text: 'Deep Dive', variant: 'caution' },
					items: [{ autogenerate: { directory: 'quadnomicon' } }],
				},
				{
					label: 'Reference (레퍼런스)',
					items: [
						{ label: '색인', slug: 'reference/00-index' },
						{ label: 'Core (quad-base)', items: [{ autogenerate: { directory: 'reference/core' } }] },
						{ label: 'Sugar (슈거·오퍼레이터)', items: [{ autogenerate: { directory: 'reference/sugar' } }] },
						{ label: 'Roblox (quad-roblox)', badge: { text: 'Roblox', variant: 'note' }, items: [{ autogenerate: { directory: 'reference/roblox' } }] },
						{ label: 'Extend (확장 계약)', badge: { text: 'Advanced', variant: 'caution' }, items: [{ autogenerate: { directory: 'reference/extend' } }] },
					],
				},
			],
		}),
	],
});

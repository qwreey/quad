// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	// [2026-09-10] Cloudflare Pages(Wrangler 직접 업로드)로 배포 — 루트 base. site는 커스텀 도메인이 정해지면 바꿀 것(DEPLOY.md).
	site: process.env.DOCS_SITE ?? 'https://quad-docs.pages.dev',
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
			social: {
				github: 'https://github.com/qwreey/quad',
			},
			tableOfContents: {
				minHeadingLevel: 2,
				maxHeadingLevel: 4,
			},
			sidebar: [
				{
					label: 'Overview (왜 Quad인가)',
					autogenerate: { directory: 'overview' },
				},
				{
					label: 'Getting Started (시작하기)',
					autogenerate: { directory: 'getting-started' },
				},
				{
					label: 'How-To Guides (실전 가이드)',
					autogenerate: { directory: 'how-to' },
				},
				{
					label: 'The Quadnomicon (심층 아키텍처)',
					badge: { text: 'Deep Dive', variant: 'caution' },
					autogenerate: { directory: 'quadnomicon' },
				},
				{
					label: 'Reference (레퍼런스)',
					items: [
						{ label: '색인', link: '/ko/reference/00-index/' },
						{ label: 'Core (quad-base)', autogenerate: { directory: 'reference/core' } },
						{ label: 'Sugar (슈거·오퍼레이터)', autogenerate: { directory: 'reference/sugar' } },
						{ label: 'Roblox (quad-roblox)', badge: { text: 'Roblox', variant: 'note' }, autogenerate: { directory: 'reference/roblox' } },
						{ label: 'Extend (확장 계약)', badge: { text: 'Advanced', variant: 'caution' }, autogenerate: { directory: 'reference/extend' } },
					],
				},
			],
		}),
	],
});

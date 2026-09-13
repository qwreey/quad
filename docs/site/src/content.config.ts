import { defineCollection } from 'astro:content';
import { docsLoader, i18nLoader } from '@astrojs/starlight/loaders';
import { docsSchema, i18nSchema } from '@astrojs/starlight/schema';
import { changelogsLoader } from 'starlight-changelogs/loader';

export const collections = {
	docs: defineCollection({ loader: docsLoader(), schema: docsSchema() }),
	i18n: defineCollection({ loader: i18nLoader(), schema: i18nSchema() }),
	// [2026-09-13 사용자] starlight-changelogs — 루트 CHANGELOG.md(Keep a Changelog 형식)를 버전별 페이지로.
	// base를 'changelog'가 아닌 'changelog-versions'로 둔 것은 기존 sync-docs.py가 만드는 전문 미러 페이지 `/changelog/`와의
	// 경로 충돌을 피하기 위한 파일럿 배치 — 대체/병존 여부는 사용자 결정 대기(브리프 보고 참고).
	changelogs: defineCollection({
		loader: changelogsLoader([
			{
				provider: 'keep-a-changelog',
				base: 'changelog-versions',
				changelog: '../../CHANGELOG.md',
				title: 'Changelog (변경 이력)',
			},
		]),
	}),
};

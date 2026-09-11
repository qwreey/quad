// [2026-09-11 사용자] 문서에 "현재 버전"을 보여준다 — 소스는 `quad-base/pesde.toml`(메인 패키지).
// 다섯 패키지의 버전은 `scripts/check-version.py`가 lockstep으로 묶어 두므로 quad_base 하나만 읽으면 된다.
// 값은 astro.config.mjs가 빌드 시작 때 파일을 읽어 vite define으로 박는다(여기서 fs로 읽으면 build 번들 위치 기준이라 깨진다 — 사용자 실측).
declare const __QUAD_VERSION__: string;

export const QUAD_VERSION: string = __QUAD_VERSION__;
export const PESDE_PACKAGE = 'qwreey/quad_base';
export const PESDE_URL = `https://pesde.dev/packages/${PESDE_PACKAGE}`;

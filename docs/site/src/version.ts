// [2026-09-11 사용자] 문서에 "현재 버전"을 보여준다 — 소스는 `quad-base/pesde.toml`(메인 패키지).
// 다섯 패키지의 버전은 `scripts/check-version.py`가 lockstep으로 묶어 두므로 quad_base 하나만 읽으면 된다.
// 빌드 시점(SSG)에 읽는다 — 레지스트리를 조회하지 않으니 오프라인 빌드도 되고, bump 뒤 배포하면 자동으로 따라온다.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const manifestPath = fileURLToPath(new URL('../../../quad-base/pesde.toml', import.meta.url));
const manifest = readFileSync(manifestPath, 'utf8');
const m = manifest.match(/^version\s*=\s*"([^"]+)"/m);
if (!m) throw new Error(`version.ts: no version in ${manifestPath}`);

export const QUAD_VERSION: string = m[1];
export const PESDE_PACKAGE = 'qwreey/quad_base';
export const PESDE_URL = `https://pesde.dev/packages/${PESDE_PACKAGE}`;

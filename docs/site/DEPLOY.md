# 문서 사이트 배포 — Cloudflare Pages (Wrangler 직접 업로드)

CI는 두지 않는다(사용자 결정 2026-09-10). 로컬에서 `npm run deploy` 한 번이 sync → build → 업로드다.

## 1회 준비(사람 몫 — 샌드박스 밖에서)

```sh
cd docs/site
npm install                                   # wrangler는 devDependency
npx wrangler login                            # 브라우저로 Cloudflare 계정 인증(토큰은 ~/.wrangler에 저장)
npx wrangler pages project create quad-docs --production-branch main
```

- 프로젝트 이름 `quad-docs`는 `wrangler.toml`의 `name`·`deploy.sh`의 `--project-name`과 같아야 한다. 바꾸려면 셋을 같이.
- **커스텀 도메인 `quad.qwreey.moe`**(사용자 결정 2026-09-10). `astro.config.mjs`의 `site`는 이미 이 도메인이다(sitemap·canonical의 절대 URL에만 쓰인다 — `quad-docs.pages.dev`로 열어도 페이지는 그대로 뜬다; 환경변수 `DOCS_SITE`로 덮어쓸 수 있다). 붙이는 순서:
  1. 위 `project create` 뒤 **첫 `npm run deploy`를 먼저** — 도메인은 프로젝트에 붙는 것이라 production 배포가 하나는 있어야 검증·연결이 된다.
  2. `qwreey.moe`가 같은 Cloudflare 계정의 zone이면: 대시보드 → Workers & Pages → quad-docs → Custom domains → Set up a custom domain → `quad.qwreey.moe`. Cloudflare가 `quad` CNAME → `quad-docs.pages.dev`(proxied)를 그 zone에 자동으로 넣고 인증서를 발급한다(몇 분).
     zone이 다른 곳(외부 DNS)이면: 그 DNS에 `quad CNAME quad-docs.pages.dev`를 먼저 넣고 같은 화면에서 도메인을 추가한다(검증이 CNAME 조회로 된다).
  3. CLI로만 하고 싶으면 wrangler엔 도메인 명령이 없다 — API `POST /accounts/<account_id>/pages/projects/quad-docs/domains` body `{"name":"quad.qwreey.moe"}`(토큰에 Pages 편집 권한), DNS 레코드는 별도.
- 비대화형(토큰) 인증이 필요하면 `CLOUDFLARE_API_TOKEN`·`CLOUDFLARE_ACCOUNT_ID` 환경변수로 대신할 수 있다(Pages 편집 권한 토큰).

## 매번

```sh
cd docs/site
npm run deploy            # production(main)
npm run deploy:preview    # 현재 브랜치 이름의 프리뷰 URL — <branch>.quad-docs.pages.dev
```

`deploy.sh`는 `python3 sync-docs.py`(docs/ 정본 → `src/content/docs/ko/`, frontmatter 없으면 실패) → `astro build`(`dist/`) → `wrangler pages deploy dist` 순서다. 업로드 한도는 파일 20,000개·파일당 25 MiB(지금 105페이지).

## 로고

`src/assets/quad-logo.svg`(가로 로고, 헤더 타이틀 대체)와 `public/favicon.svg`(Q 하나)는 루트의 사용자 원본(Inkscape, git 무시)을 편집기 메타데이터만 벗겨 넣은 것이다. 원본을 다시 따면 같은 정리(주석·`sodipodi`/`inkscape` 속성·id 제거, `style` → `fill`)를 거쳐 교체한다.

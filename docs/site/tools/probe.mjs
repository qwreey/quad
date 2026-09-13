#!/usr/bin/env node
// quad 사이트 실측 프로브 — CDP로 연결한 headless Chrome에서 단계를 순서대로
// 실행하고 결과를 stdout에 JSON 한 덩어리로 찍는다.
//
// 전제: docs/site/tools/browser.sh up 으로 컨테이너를 띄우고
// QUAD_CDP_URL(예: http://172.17.7.2:9222)을 export 해둘 것.
//
// 사용 예:
//   QUAD_CDP_URL=http://172.17.7.2:9222 node tools/probe.mjs \
//     --url https://quad.selene.yaeji.moe/getting-started/03-flowing-values/ \
//     --mobile --wait 800 \
//     --swipe 5,400,300,400,20 --wait 500 \
//     --screenshot /tmp/shot.png --full \
//     --html "#starlight__sidebar" --console
//
// 옵션(순서대로 실행됨, 여러 번 반복 가능):
//   --url U                페이지 이동
//   --viewport WxH         뷰포트 크기 (기본 1280x800)
//   --mobile               390x844 + touch + dsf 2 + 모바일 UA로 뷰포트 설정
//   --dark                 prefers-color-scheme: dark 에뮬레이트 + <html data-theme="dark">
//   --wait MS              지정 ms 대기
//   --click SEL            셀렉터 클릭 (마우스)
//   --tap SEL              셀렉터 탭 (touch)
//   --swipe x1,y1,x2,y2[,steps]  터치스크린으로 (x1,y1)→(x2,y2) 스와이프
//   --eval JS              페이지 컨텍스트에서 JS 평가, 결과를 JSON으로 기록
//   --html SEL             셀렉터의 outerHTML 기록 (4000자 넘으면 앞부분만)
//   --screenshot PATH      스크린샷 저장 (--full 이 앞/뒤에 있으면 전체 페이지)
//   --console              지금까지 쌓인 페이지 콘솔/에러 로그를 기록
//
// 출력: { steps: [...], screenshots: [...] } 형태의 JSON 하나.

import puppeteer from "puppeteer-core";

const MOBILE_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";

function parseArgs(argv) {
  const steps = [];
  let full = false;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const take = () => argv[++i];
    switch (a) {
      case "--url":
        steps.push({ op: "url", value: take() });
        break;
      case "--viewport":
        steps.push({ op: "viewport", value: take() });
        break;
      case "--mobile":
        steps.push({ op: "mobile" });
        break;
      case "--dark":
        steps.push({ op: "dark" });
        break;
      case "--wait":
        steps.push({ op: "wait", value: Number(take()) });
        break;
      case "--click":
        steps.push({ op: "click", value: take() });
        break;
      case "--tap":
        steps.push({ op: "tap", value: take() });
        break;
      case "--swipe":
        steps.push({ op: "swipe", value: take() });
        break;
      case "--eval":
        steps.push({ op: "eval", value: take() });
        break;
      case "--html":
        steps.push({ op: "html", value: take() });
        break;
      case "--screenshot":
        steps.push({ op: "screenshot", value: take(), full });
        break;
      case "--full":
        full = true;
        break;
      case "--console":
        steps.push({ op: "console" });
        break;
      default:
        throw new Error(`알 수 없는 옵션: ${a}`);
    }
  }
  return steps;
}

async function main() {
  const cdpUrl = process.env.QUAD_CDP_URL;
  if (!cdpUrl) {
    console.error("QUAD_CDP_URL 환경변수가 없습니다 (예: http://172.17.7.2:9222)");
    process.exit(1);
  }
  const steps = parseArgs(process.argv.slice(2));

  const browser = await puppeteer.connect({ browserURL: cdpUrl });
  const page = await browser.newPage();

  const consoleLog = [];
  page.on("console", (msg) => {
    consoleLog.push({ type: msg.type(), text: msg.text() });
  });
  page.on("pageerror", (err) => {
    consoleLog.push({ type: "pageerror", text: String(err) });
  });
  page.on("requestfailed", (req) => {
    consoleLog.push({
      type: "requestfailed",
      text: `${req.method()} ${req.url()} — ${req.failure()?.errorText ?? "?"}`,
    });
  });

  const results = [];
  const screenshots = [];

  // 기본 뷰포트.
  await page.setViewport({ width: 1280, height: 800 });

  for (const step of steps) {
    try {
      switch (step.op) {
        case "url": {
          // networkidle2를 쓰면 astro dev 서버의 HMR 웹소켓이 계속 열려 있어
          // 영원히 idle이 안 되고 타임아웃난다(실측) — domcontentloaded로.
          await page.goto(step.value, { waitUntil: "domcontentloaded", timeout: 30000 });
          results.push({ op: "url", value: step.value, status: "ok" });
          break;
        }
        case "viewport": {
          const [w, h] = step.value.split("x").map(Number);
          await page.setViewport({ width: w, height: h });
          results.push({ op: "viewport", value: step.value, status: "ok" });
          break;
        }
        case "mobile": {
          await page.setViewport({
            width: 390,
            height: 844,
            isMobile: true,
            hasTouch: true,
            deviceScaleFactor: 2,
          });
          await page.setUserAgent(MOBILE_UA);
          results.push({ op: "mobile", status: "ok" });
          break;
        }
        case "dark": {
          await page.emulateMediaFeatures([
            { name: "prefers-color-scheme", value: "dark" },
          ]);
          await page.evaluate(() => {
            document.documentElement.setAttribute("data-theme", "dark");
          });
          results.push({ op: "dark", status: "ok" });
          break;
        }
        case "wait": {
          await new Promise((r) => setTimeout(r, step.value));
          results.push({ op: "wait", value: step.value, status: "ok" });
          break;
        }
        case "click": {
          await page.waitForSelector(step.value, { timeout: 5000 });
          await page.click(step.value);
          results.push({ op: "click", value: step.value, status: "ok" });
          break;
        }
        case "tap": {
          await page.waitForSelector(step.value, { timeout: 5000 });
          await page.tap(step.value);
          results.push({ op: "tap", value: step.value, status: "ok" });
          break;
        }
        case "swipe": {
          const parts = step.value.split(",").map(Number);
          const [x1, y1, x2, y2, stepsN] = parts;
          const n = stepsN || 10;
          const touch = page.touchscreen;
          // puppeteer-core의 Touchscreen은 touchStart/Move/End를 직접 노출하지
          // 않는 버전이 있어 CDP Input 도메인을 직접 사용한다.
          const client = await page.target().createCDPSession();
          await client.send("Input.dispatchTouchEvent", {
            type: "touchStart",
            touchPoints: [{ x: x1, y: y1 }],
          });
          for (let i = 1; i <= n; i++) {
            const x = x1 + ((x2 - x1) * i) / n;
            const y = y1 + ((y2 - y1) * i) / n;
            await client.send("Input.dispatchTouchEvent", {
              type: "touchMove",
              touchPoints: [{ x, y }],
            });
            await new Promise((r) => setTimeout(r, 16));
          }
          await client.send("Input.dispatchTouchEvent", {
            type: "touchEnd",
            touchPoints: [],
          });
          await client.detach();
          results.push({ op: "swipe", value: step.value, status: "ok" });
          break;
        }
        case "eval": {
          const value = await page.evaluate(step.value);
          results.push({ op: "eval", code: step.value, result: value });
          break;
        }
        case "html": {
          const html = await page.evaluate((sel) => {
            const el = document.querySelector(sel);
            return el ? el.outerHTML : null;
          }, step.value);
          const truncated =
            html && html.length > 4000 ? html.slice(0, 4000) + "...(truncated)" : html;
          results.push({ op: "html", selector: step.value, html: truncated, found: html !== null });
          break;
        }
        case "screenshot": {
          await page.screenshot({ path: step.value, fullPage: !!step.full });
          screenshots.push(step.value);
          results.push({ op: "screenshot", path: step.value, full: !!step.full, status: "ok" });
          break;
        }
        case "console": {
          results.push({ op: "console", log: consoleLog.slice() });
          break;
        }
      }
    } catch (err) {
      results.push({ op: step.op, value: step.value, status: "error", error: String(err) });
    }
  }

  await browser.disconnect();

  console.log(JSON.stringify({ steps: results, screenshots }, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

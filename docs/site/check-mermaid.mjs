// [2026-09-10] ```mermaid 블록 문법 검사 — 사이트는 클라이언트에서 그리므로 빌드가 문법 오류를 못 잡는다(사용자 리포트: "Syntax error in text").
// Node + jsdom 위에서 mermaid.parse()를 돌린다.  사용법: node check-mermaid.mjs [docs 루트]  (exit 1 = 오류 있음)
import { JSDOM } from 'jsdom';
import fs from 'node:fs';
import path from 'node:path';
const dom = new JSDOM('<!doctype html><html><body></body></html>', { pretendToBeVisual: true });
globalThis.window = dom.window; globalThis.document = dom.window.document;
globalThis.DOMParser = dom.window.DOMParser;
globalThis.Element = dom.window.Element; globalThis.SVGElement = dom.window.SVGElement;
const mermaid = (await import('mermaid')).default;
mermaid.initialize({ startOnLoad: false });
const root = process.argv[2] ?? path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const files = [];
(function walk(d) { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) { if (e.name !== 'site' && e.name !== 'node_modules') walk(p); } else if (p.endsWith('.md')) files.push(p); } })(root);
let bad = 0, total = 0;
for (const f of files) {
  const text = fs.readFileSync(f, 'utf8');
  const re = /^```mermaid[^\n]*\n([\s\S]*?)^```/gm; let m;
  while ((m = re.exec(text))) {
    total++;
    const line = text.slice(0, m.index).split('\n').length;
    try { await mermaid.parse(m[1]); }
    catch (e) { bad++; console.log(`${path.relative(root, f)}:${line}: ${String(e.message ?? e).split('\n').slice(0, 3).join(' | ')}`); }
  }
}
console.log(`check-mermaid: ${total - bad}/${total} blocks parse OK`);
process.exit(bad ? 1 : 0);

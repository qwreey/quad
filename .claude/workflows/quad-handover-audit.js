export const meta = {
  name: 'quad-handover-audit',
  description: '커밋 전 .claude/ 코퍼스 정합성을 quad-doc-auditor 병렬·다회 감사로 수렴시킴',
  whenToUse: '사용자가 "핸드오버 준비하고 커밋해" 류로 요청했을 때, 커밋 전에 자동으로 돌릴 것. 단일 감사 패스는 비결정적이라 놓치는 게 있을 수 있으므로, 라운드마다 독립된 감사를 병렬로 여러 번 돌리고, 새 발견이 없는 라운드가 연속으로 나올 때까지 반복해 수렴시킨다. 시간보다 정확성을 우선하는 사용자 요청에 따라 기본 워크플로 크기 가이드라인(15 에이전트 이하)을 의도적으로 초과할 수 있음.',
  phases: [
    { title: 'Audit', detail: 'quad-doc-auditor 서브에이전트를 라운드당 병렬로 여러 번' },
    { title: 'Fix', detail: '라운드에서 나온 새 발견을 파일별로 반영' },
  ],
}

// 실측 편의를 위해 조정 가능한 상수. 과거 세션의 수동 감사가 보통
// 4~6라운드 안에 수렴했음(예: 8→7→11→9→4→0, 9→2→3→2→0→0) — MAX_ROUNDS는
// 그보다 여유를 두되 무한루프는 막는 안전판.
const PASSES_PER_ROUND = 3
const DRY_ROUNDS_TO_CONVERGE = 2
const MAX_ROUNDS = 6

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string', description: '레포 루트 기준 상대 경로' },
          line: { type: 'number', description: '해당 줄 번호(모르면 0)' },
          issue: { type: 'string', description: '무슨 문장이 무엇과 모순/stale인지 한 문장' },
          fix: { type: 'string', description: '어떻게 고치면 되는지 한 문장' },
          confidence: { type: 'string', enum: ['확실', '의심'] },
        },
        required: ['file', 'issue', 'fix', 'confidence'],
      },
    },
  },
  required: ['findings'],
}

const AUDIT_PROMPT =
  '핸드오버 준비 감사 라운드다. 너의 정해진 절차대로 .claude/ 코퍼스를 ' +
  '처음부터 독립적으로 감사해라. 다른 병렬 패스가 이미 뭘 찾았는지는 ' +
  '모른다 — 그걸 의식하지 말고 빠짐없이 훑어라.'

function keyOf(f) {
  return `${f.file}:${f.line || 0}:${(f.issue || '').slice(0, 40)}`
}

function fixPrompt(file, items) {
  const lines = items
    .map((f) => `- (줄 ${f.line || '?'}, ${f.confidence}) ${f.issue} → 제안: ${f.fix}`)
    .join('\n')
  return (
    `아래는 quad-doc-auditor가 "${file}"에서 찾은 stale/모순 서술이다. ` +
    `이 파일을 읽고 CLAUDE.md의 관례(한국어 서술, 최소 수정, 뒤집힌 결정은 ` +
    `archive/로 이전+포인터, 날짜 없는 시한부 주장엔 날짜 붙이기)에 맞춰 직접 ` +
    `고쳐라. "의심"으로 표시된 항목은 실제로 문제인지 먼저 확인하고, 문제가 ` +
    `아니면 건드리지 말고 넘어가라(억지로 고치지 말 것).\n\n${lines}`
  )
}

const seen = new Set()
const roundLog = []
let dry = 0
let round = 0

while (dry < DRY_ROUNDS_TO_CONVERGE && round < MAX_ROUNDS) {
  round++
  phase('Audit')
  log(`라운드 ${round} — quad-doc-auditor 병렬 ${PASSES_PER_ROUND}회`)

  const passes = await parallel(
    Array.from({ length: PASSES_PER_ROUND }, (_, i) => () =>
      agent(AUDIT_PROMPT, {
        label: `audit-r${round}-${i}`,
        phase: 'Audit',
        agentType: 'quad-doc-auditor',
        schema: FINDINGS_SCHEMA,
      })
    )
  )

  const all = passes.filter(Boolean).flatMap((p) => p.findings || [])
  const fresh = all.filter((f) => !seen.has(keyOf(f)))

  if (!fresh.length) {
    dry++
    log(`라운드 ${round}: 새 발견 없음 (연속 dry ${dry}/${DRY_ROUNDS_TO_CONVERGE})`)
    roundLog.push({ round, fresh: 0, dry })
    continue
  }

  dry = 0
  fresh.forEach((f) => seen.add(keyOf(f)))
  log(`라운드 ${round}: 새 발견 ${fresh.length}건 — 파일별로 반영 시작`)

  const byFile = {}
  for (const f of fresh) {
    ;(byFile[f.file] ||= []).push(f)
  }

  phase('Fix')
  await parallel(
    Object.entries(byFile).map(([file, items]) => () =>
      agent(fixPrompt(file, items), {
        label: `fix:${file}`,
        phase: 'Fix',
        agentType: 'general-purpose',
      })
    )
  )

  roundLog.push({ round, fresh: fresh.length, files: Object.keys(byFile) })
}

const converged = dry >= DRY_ROUNDS_TO_CONVERGE
if (!converged) {
  log(`${MAX_ROUNDS}라운드 안에 수렴 못 함 — 남은 문제는 사람이 볼 것`)
}

return {
  converged,
  rounds: round,
  totalFindingsFixed: seen.size,
  roundLog,
}

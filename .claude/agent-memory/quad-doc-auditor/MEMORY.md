# Memory Index

- [Self-referential line/count claims break on commit](feedback_self_referential_counts.md) — a doc stating its own line count/entry count is wrong even at commit time; fix by deleting the number, not updating it.
- [Recurring failure pattern: second instance in same file survives the fix](feedback_recurring_failure_pattern.md) — when a claim flips, grep finds multiple files but check *within* each file too; a second mention in the same file often survives a banner fix.
- [quad corpus structure and audit scope](project_quad_corpus_structure.md) — layout of .claude/, what's always-loaded vs on-demand, what's in/out of audit scope.
- [My own agent-memory dir is itself an audit target](project_agent_memory_self_reference_risk.md) — quad-doc-auditor.md's claims about its own tool/memory behavior can go stale; check them too, and verify MEMORY.md indexes all files (parallel passes can race).
- [Definition freshness is unknown](project_agent_prompt_caching_bug_reproduced.md) — the text I receive sometimes lags disk and has matched no commit at all; three explanations were tried and two refuted, so report a mismatch as a concrete comparison, never as a mechanism claim.

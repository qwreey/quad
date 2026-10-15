# 이름 검토 2026-10-15 — 한 번만 짓는 Slot 설치(`Defer` → `Lazy`)

사용자 1안 `Defer`, 2안 `Lazy`를 sonnet(레포를 안 읽은 외부자, 채팅 보고)과 Gemini(`gemini.md`)에 같은 과제로 맡겼다. 둘 다 따로 `Lazy`를 추천 —
`Defer`는 Roblox `task.defer`·`SignalBehavior = Deferred`와 겹쳐 "다음 틱에 비동기로"로 읽히고(실제는 마운트 순회 안 동기), `slot:WhenIdle`·`Debounce`·`Throttle`의
시간 계열과 섞이며, `List`/`Single`(무엇을 담나)과 축이 다르다. `Lazy`는 Rust·Kotlin·C#의 "처음 필요할 때 한 번 계산하고 재사용"과 뜻이 같고, 시작하기 19장 "게으름"과 이어진다.
`Once`는 `RBXScriptSignal:Once`, `Factory`는 "부를 때마다 새로"와 겹쳐 탈락. 사용자: *"동의. 더 어울리는 단어같아."* → `slot:Lazy(fn)`.

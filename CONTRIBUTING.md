# 기여하기

이 저장소 자체를 고치고 테스트를 돌리는 법만 다룹니다. 사용자로서 `quad`를 쓰는
법은 [`docs/`](./docs/README.md)를, 그중 자기 프로젝트에서 헤드리스로 검증하는
법은 [`docs/how-to/06-headless-testing.md`](./docs/how-to/06-headless-testing.md)를
보세요.

## 테스트 돌리기

진입점은 **`./scripts/test.sh` 하나**입니다.

```bash
./scripts/test.sh; echo $?
```

- **판정은 종료 코드입니다.** 스크립트는 타입 검사 진단이 있어도 개별 테스트
  실행을 계속하므로, 출력에 찍힌 `ALL PASS` 줄 개수를 세면 안 됩니다. `0`이
  아니면 실패입니다.
- 스크립트는 먼저 `scripts/relink.sh`를 돌립니다. **`luau` CLI가 심볼릭 링크를
  못 타기 때문**입니다 — 이 저장소는 pesde 워크스페이스(`quad-base`/`quad-roblox`/
  `quad-types`/`quad-error`/`type-version-check`가 서로를 `workspace = "..."`로
  참조)라 pesde가 멤버 간 참조를 **디렉토리 심볼릭**으로 까는데, 그걸 실제
  복사로 바꿔놓지 않으면 스모크가 죽고, 더 나쁘게 `luau-analyze`는 모듈을
  `any`로 떨어뜨린 채 **조용히 통과**합니다("거짓 클린"). `relink.sh`를 직접
  돌려야 할 일은 거의 없지만, 워크스페이스 멤버 소스를 고친 뒤 스냅샷이 낡은
  것 같으면(`.relink-manifest`가 옛 경로를 기억) 그 파일을 지우고
  `pesde install` 후 다시 돌리세요.
- 그다음 타입 검사 두 그룹이 돕니다. 엔진 무관 그룹(`quad-base`/`quad-types`/
  `quad-error`, 두 번째 패스는 `type-version-check`까지)은 **Roblox 정의 없이**
  두 패스로 분석해서 엔진 전역이 새어 들어오면 그 자리에서 걸립니다 —
  `luau-analyze` 한 번, `luau-lsp analyze --flag:LuauSolverV2=true` 한 번입니다.
  둘 다 신 솔버이고, 차이는 솔버 종류가 아니라 Luau 빌드(luau-analyze 0.734 /
  luau-lsp 1.69.0 내장)와 설정입니다. `quad-roblox`만 Roblox 타입 정의를 얹고
  봅니다.
- 그다음 `quad-base/test/smoke.*.luau`, `quad-base/test/spec.*.luau`,
  `quad-roblox/test/spec.*.luau`를 하나씩 실행하고, 마지막으로 문서 커버리지와
  버전 정합성 게이트가 돕니다.

테스트 프레임워크는 쓰지 않습니다. 각 spec은 그냥 `assert`와 `print`로 된
평범한 Luau 스크립트이고, 실패하면 `assert`가 그 자리에서 던집니다.

```luau
print("=== 1. 무엇을 검증하는지 ===")
do
    -- ... assert들 ...
    print("PASS")
end
```

## 그 밖의 규약

커밋 전 게이트(`doc-check.py`), 문서 작성 규약, 세션·감사 절차 등 이 저장소의
나머지 작업 방식은 [`.claude/conventions.md`](./.claude/conventions.md)가
정본입니다.

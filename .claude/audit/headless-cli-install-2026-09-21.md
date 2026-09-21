# 헤드리스 CLI 설치 실측 — 2026-09-21

`docs-review-2026-09-14.md` 2-1(a) 채택에 따라 `how-to/06-headless-testing.md`를
다시 쓰기 전에, **이 저장소 밖의 평범한 사용자 프로젝트**가 pesde 레지스트리에서
`quad_base`를 내려받아 순정 `luau` CLI로 돌릴 때 실제로 무엇이 만들어지는지
추측 없이 측정했다. 스크래치 폴더(레포·git 밖)에서 진행 — 삭제하지 않았다.

## 1. 프로젝트 생성

`pesde init`은 대화형(입력을 아무리 흘려보내도 TTY 프롬프트에서 멈춤)이라
매니페스트를 손으로 썼다. **워크스페이스 루트 `pesde.toml`을 참고하니 `[package]`
테이블이 아니라 최상위에 `name`/`version`이 바로 온다** — 처음에 `[package]`로
감쌌다가 `missing field \`name\`` 에러를 냈다(이 레포에 설치된 pesde 소스 트리는
`Cargo.toml` 0.7.3이지만 바이너리는 `0.7.4+registry.0.2.3`이라 정확히 일치하진
않는다 — 실제 매니페스트 스키마는 이 레포 자신의 `pesde.toml`들로 확인).

```toml
name = "qwreey/headless_demo"
version = "0.1.0"
license = "MIT"

[indices]
default = "https://github.com/pesde-pkg/index"

[target]
environment = "luau"

[dependencies]
```

`[indices]`가 없으면 `pesde install`이 `index named \`default\` not found in
manifest`로 죽는다 — `pesde add`만으로는 안 생기므로 quad 자신의 `quad-base/quad-roblox`
`pesde.toml`을 보고 직접 채웠다.

## 2. 의존성 추가 — 레지스트리 실접속

```
$ mise exec -- pesde add qwreey/quad_base
added qwreey/quad_base@3.2.0 luau to dependencies

$ mise exec -- pesde install
qwreey/headless_demo luau: +4
++++
dependencies:
+ qwreey/quad_base 3.2.0 luau
done in 2.93s
```

레지스트리 접속이 실제로 됐다 — **폴백 없이 진짜 설치**. `quad_base`가
`quad_types`/`quad_error`를 끌고 왔고(+4 = quad_base 자신 + quad_types +
quad_error + type_version_check), 전부 `3.2.0`(quad_error/type_version_check는
범용 패키지라 자기 SemVer지만 지금 lockstep 시점엔 같은 번호로 같이 게시돼
있었다).

## 3. 생성된 레이아웃

```
headless-cli/
├── pesde.toml
├── pesde.lock
├── test/reactive.luau
└── luau_packages/
    ├── quad_base.luau              ← 얇은 링커 (텍스트 파일)
    └── .pesde/
        ├── qwreey+quad_base/3.2.0/quad_base/{src,pesde.toml,LICENSE,README.md}
        ├── qwreey+quad_types/3.2.0/quad_types/{src,pesde.toml,...}
        ├── qwreey+quad_error/3.2.0/quad_error/{src,pesde.toml,...}
        └── qwreey+type_version_check/3.2.0/type_version_check/{src,pesde.toml,...}
```

`luau_packages/quad_base.luau` 내용 전문:

```luau
local module = require("./.pesde/qwreey+quad_base/3.2.0/quad_base/src")
return module
```

## 4. 심볼릭 링크인가 — 아니다

**`find . -type l`가 이 프로젝트 트리에서 심볼릭 링크를 0개 반환했다.**
`luau_packages/quad_base.luau`는 `stat`상 `Links: 2`(하드 링크)인 평범한
텍스트 파일이지 심볼릭이 아니다. `.pesde/` 아래 실체 파일들도 마찬가지로
일반 파일(하드 링크)이다.

**이건 이 레포 자신의 `scripts/relink.sh`가 다루는 상황과 다르다.**
`relink.sh`의 주석이 명시하듯 그 스크립트가 되돌리는 건 **워크스페이스
멤버 간** 링크(`quad-base`가 `workspace = "qwreey/quad_types"`로 같은
워크스페이스의 다른 멤버를 참조할 때 pesde가 만드는 **디렉토리 심볼릭**)다.
지금 측정한 것처럼 **평범한 소비자 프로젝트가 레지스트리에 게시된 패키지를
설치할 때는애초에 심볼릭이 생기지 않는다** — `quad_base.luau` 링커도,
그 아래 `.pesde/` 실체도 전부 일반 파일이다. 그래서 소비자 입장에서는
`relink.sh`에 해당하는 절차가 아예 필요 없다.

(참고로 이 레포 자신의 `quad-base/luau_packages/`를 봐도 지금은 일반 파일뿐인데,
이건 `relink.sh`가 이미 돌아 심볼릭을 복사로 바꿔놓은 뒤의 상태라 그렇다 —
워크스페이스 설치 직후 최초 상태에서는 심볼릭이 생긴다는 것이
`relink.sh` 자신의 주석과 매니페스트 로직의 근거다. 이번 측정은 그 워크스페이스
케이스를 재현한 게 아니라 **순수 소비자 설치**만 측정했다.)

## 5. require 경로와 실행

`test/reactive.luau`에서:

```luau
local Quad = require("../luau_packages/quad_base")
```

이 경로가 그대로 풀렸다. §2 스니펫(Source/Compute assertion + Blocker)을
그대로 넣고:

```
$ mise exec -- luau test/reactive.luau
PASS
$ echo $?
0
```

추가 설정, relink, symlink 우회 없이 **`pesde install` → `require` → `luau`
CLI 실행**만으로 끝났다.

## 6. how-to에 반영한 결론

- how-to §2(반응형 그래프만)의 require 경로는 `require("../luau_packages/quad_base")`
  형태로 쓰고, "패키지 설치 위치는 여러분의 Rojo/pesde 프로젝트 구성에 따라
  다르다"는 캐비엇만 붙인다(경로 자체는 이번 실측으로 검증됨).
- **"CLI가 심볼릭 링크를 못 탄다"는 경고는 이 저장소 자신의 워크스페이스
  설치에만 해당한다** — 소비자 프로젝트 얘기가 아니므로 how-to에 넣지 않고
  `CONTRIBUTING.md`(이 레포의 `relink.sh` 절차)로 넘긴다.
- `pesde.lock`/`.pesde/` 캐시 구조 자체는 사용자가 몰라도 되는 구현 세부라
  how-to 본문엔 넣지 않았다(이 문서에만 남긴다).

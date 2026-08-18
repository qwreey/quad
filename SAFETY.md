- Git 레포지토리 접근은 원격별로 용도가 분리되어 있음(2026-08-18 기준,
  `qwreey-bot` 제한 계정 도입 후 갱신):
  - `origin` (`https://git.qwreey.moe/qwreey-bot/quad.git`) — **메인
    작업 공간.** 모델이 어디로 튈지 모르니 기본 작업은 GitHub이 아닌
    여기(비-GitHub 제한 계정)에서만 함. 자유롭게 push 가능.
  - `github` (`https://github.com/qwreey-bot/quad`) — `upstream`을 포크한,
    같은 `qwreey-bot` 계정 소유 레포. **사용자가 명시적으로 "싱크"를
    요청할 때만** push — 그 후 사용자가 GitHub 웹 GUI에서 이 포크 기준
    PR을 만들어 변경사항을 검토함. 기본 push 대상 아님, 사용자 요청 없이
    먼저 올리지 말 것.
  - `upstream` (`https://github.com/qwreey/quad`) — 원본 레포(모델
    계정 소유 아님). **pull/fetch 전용, 절대 push 금지** — 다른 경로로
    생긴 변경사항을 당겨오기 위해서만 존재.
- Code-docker 활용: 컨테이너 환경으로 한번 격리하여 사용할 수 있도록 유도. studio 환경은 메인 계정이 아닌 다른 계정을 사용하여야함
- **[2026-08-18 직접 점검 확인]** 모델이 안전하게 쓸 수 있는 유틸 — 아래
  둘 다 실제로 위험 옵션을 하나씩 시도해 authz/격리가 거부하는지 확인한
  결과(세션 로그에 전체 시도 목록 있음, 여기는 결론만).
  - **code-docker 컨테이너 자체**: 일반 로컬 작업(빌드/테스트/파일 조작)에
    자유롭게 사용 가능. non-privileged, `SYS_ADMIN`/`NET_ADMIN`/
    `SYS_MODULE`/`SYS_RAWIO` 등 위험 capability 없음, seccomp 필터
    활성화, PID 네임스페이스 격리(호스트/다른 컨테이너 프로세스 안 보임),
    `docker.sock` 등 호스트 제어 소켓 미장착, 루트 파일시스템은 overlay
    (호스트 바인드 아님). 호스트 자체도 Proxmox VM이라 컨테이너 탈출
    성공해도 물리 하이퍼바이저 직행은 아님. 남는 약점은 uid 0로 실행 +
    AppArmor `unconfined`뿐 — 알려진 흔한 탈출 경로는 다 막혀 있음.
  - **dind**(`DOCKER_HOST=tcp://dind:2375`, code-docker와 같은 호스트
    네임스페이스 공유): 컨테이너 빌드/실행 용도로 사용 가능, `dind-authz`
    플러그인이 위험 옵션을 화이트리스트 방식으로 차단함 — 직접 확인된
    거부 목록: `--privileged`, `--cap-add=SYS_ADMIN`/`ALL`, `--pid=host`/
    `--net=host`/`--ipc=host`, 호스트 임의 경로 마운트(`/`, `/etc`,
    `docker.sock`, `-v`/`--mount` 문법 둘 다 — **경로 순회(`../..`)로
    허용 prefix를 흉내내는 우회도 막힘**, 즉 문자열 prefix 매칭이 아니라
    정규화된 경로로 검사함), `--device` passthrough,
    `--security-opt seccomp=unconfined`/`apparmor=unconfined`. 허용되는
    건 현재 프로젝트 디렉토리(`./`) 바인드 마운트뿐(편의 기능으로 의도된
    것) — 이 범위를 벗어나는 새 시도를 할 땐 이 목록이 최신인지 다시
    확인할 것(authz 정책이 바뀌면 이 서술도 갱신 필요).

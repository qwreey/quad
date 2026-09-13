#!/usr/bin/env bash
# quad 사이트 실측용 headless Chrome 컨테이너 관리 스크립트.
#
# dind(도커 인 도커) 호스트에 CDP(Chrome DevTools Protocol) 포트가 열린
# headless Chrome 컨테이너를 띄우고/내리고/상태를 본다. Chrome DevTools의
# /json* 엔드포인트는 Host 헤더가 IP나 localhost가 아니면 거부하므로,
# 컨테이너 이름(dind) 대신 IP로 접속 URL을 구성해서 알려준다.
#
# 사용:
#   ./browser.sh up       컨테이너를 띄우고(이미 있으면 재사용) QUAD_CDP_URL을 출력
#   ./browser.sh down     컨테이너를 내리고 삭제
#   ./browser.sh status   현재 상태 + (떠 있으면) QUAD_CDP_URL 출력
#
# 환경변수:
#   DOCKER_HOST  기본 tcp://dind:2375 (이미 설정돼 있으면 그 값 사용)
#   IMAGE        기본 zenika/alpine-chrome:latest
#   NAME         컨테이너 이름, 기본 quad-chrome
#   PORT         호스트/컨테이너 공통 포트, 기본 9222

set -euo pipefail

export DOCKER_HOST="${DOCKER_HOST:-tcp://dind:2375}"
IMAGE="${IMAGE:-zenika/alpine-chrome:latest}"
NAME="${NAME:-quad-chrome}"
PORT="${PORT:-9222}"

dind_ip() {
  # DOCKER_HOST가 tcp://<host>:<port> 형태라고 가정하고 그 호스트명을 resolve.
  local host
  host="$(echo "$DOCKER_HOST" | sed -E 's#^tcp://([^:/]+).*#\1#')"
  if [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$host"
  else
    getent hosts "$host" | awk '{print $1; exit}'
  fi
}

print_cdp_url() {
  local ip
  ip="$(dind_ip)"
  if [[ -z "$ip" ]]; then
    echo "경고: dind IP를 resolve하지 못했습니다 (DOCKER_HOST=$DOCKER_HOST)" >&2
    return 1
  fi
  echo "QUAD_CDP_URL=http://${ip}:${PORT}"
}

cmd_up() {
  if docker ps --filter "name=^${NAME}\$" --format '{{.Names}}' | grep -q "^${NAME}\$"; then
    echo "이미 떠 있음: ${NAME}"
    print_cdp_url
    return 0
  fi
  if docker ps -a --filter "name=^${NAME}\$" --format '{{.Names}}' | grep -q "^${NAME}\$"; then
    echo "중지된 컨테이너 제거 후 재생성: ${NAME}"
    docker rm -f "${NAME}" >/dev/null
  fi
  # --disable-gpu 필수: 없으면 Page.captureScreenshot이 "Internal error"로
  # 실패한다(이 컨테이너 환경에서 실측 확인, 2026-09-14).
  docker run -d --name "${NAME}" -p "${PORT}:${PORT}" "${IMAGE}" \
    --no-sandbox \
    --remote-debugging-address=0.0.0.0 \
    --remote-debugging-port="${PORT}" \
    --disable-gpu \
    --disable-dev-shm-usage \
    --window-size=1280,800 \
    about:blank >/dev/null
  echo "기동: ${NAME} (image=${IMAGE})"
  # /json/version이 뜰 때까지 잠깐 대기.
  local ip
  ip="$(dind_ip)"
  for _ in $(seq 1 20); do
    if curl -s -o /dev/null -m 1 "http://${ip}:${PORT}/json/version"; then
      break
    fi
    sleep 0.5
  done
  print_cdp_url
}

cmd_down() {
  if docker ps -a --filter "name=^${NAME}\$" --format '{{.Names}}' | grep -q "^${NAME}\$"; then
    docker rm -f "${NAME}" >/dev/null
    echo "제거됨: ${NAME}"
  else
    echo "없음: ${NAME}"
  fi
}

cmd_status() {
  if docker ps --filter "name=^${NAME}\$" --format '{{.Names}}' | grep -q "^${NAME}\$"; then
    docker ps --filter "name=^${NAME}\$"
    print_cdp_url
  else
    echo "떠 있지 않음: ${NAME}"
  fi
}

case "${1:-}" in
  up) cmd_up ;;
  down) cmd_down ;;
  status) cmd_status ;;
  *)
    echo "usage: $0 {up|down|status}" >&2
    exit 1
    ;;
esac

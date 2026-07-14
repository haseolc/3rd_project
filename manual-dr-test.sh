#!/usr/bin/env bash
set -u

SEOUL_ALB="k8s-alb-v2-386360249.ap-northeast-2.elb.amazonaws.com"
OSAKA_ALB="osaka-dr-alb-171790249.ap-northeast-3.elb.amazonaws.com"

check_endpoint() {
  local name="$1"
  local endpoint="$2"

  code=$(curl -sS \
    --connect-timeout 3 \
    --max-time 5 \
    -o /dev/null \
    -w '%{http_code}' \
    "http://${endpoint}" 2>/dev/null || true)

  if [ "$code" = "200" ]; then
    echo "${name}: 정상 (HTTP 200)"
    return 0
  fi

  echo "${name}: 비정상 또는 접속 실패 (HTTP ${code:-000})"
  return 1
}

echo "===== DR 상태 확인 ====="

if check_endpoint "서울 Primary" "$SEOUL_ALB"; then
  echo "선택된 서비스 주소: http://${SEOUL_ALB}"
  echo "현재 상태: Primary 운영"
else
  echo "서울 장애 감지"
  if check_endpoint "오사카 DR" "$OSAKA_ALB"; then
    echo "선택된 서비스 주소: http://${OSAKA_ALB}"
    echo "현재 상태: 오사카 DR 전환"
  else
    echo "서울과 오사카 모두 비정상"
    exit 1
  fi
fi

# recommender.py
# 이상 탐지 결과 → 액션 추천 및 자동화 트리거 데이터 생성

def get_recommendation(metric_name: str, result: dict) -> dict:
    """
    메트릭 이름과 탐지 결과를 받아 추천 액션 딕셔너리 반환

    반환 형식:
    {
        "message": "디스코드 전송용 포맷팅 메시지",
        "action_code": "자동화 인프라 트리거용 코드 (예: SCALE_OUT, POD_RESTART, etc.)"
    }
    """
    z_score = abs(result["z_score"])

    # 기본값 설정 (이상 미초과 시)
    response = {
        "message": "ℹ️ 모니터링 지속 (임계값 미초과)",
        "action_code": "NO_ACTION"
    }

    # ----------------------------------------
    # CPU 이상 → Scale Out 자동화 연동
    # ----------------------------------------
    if metric_name == "CPU":
        if z_score >= 3.0:
            response["message"] = (
                "🔴 [긴급] CPU 과부하\n"
                "  → Scale Out 즉시 실행 권장\n"
                "  → 트래픽 분산 검토"
            )
            response["action_code"] = "SCALE_OUT"
        elif z_score >= 2.0:
            response["message"] = (
                "🟡 [경고] CPU 급증\n"
                "  → 원인 프로세스 확인 필요\n"
                "  → Scale Out 준비"
            )
            response["action_code"] = "PREPARE_SCALE_OUT"

    # ----------------------------------------
    # 메모리 이상 → Pod Restart 자동화 연동
    # ----------------------------------------
    elif metric_name == "메모리":
        if z_score >= 3.0:
            response["message"] = (
                "🔴 [긴급] 메모리 부족\n"
                "  → Pod Restart 즉시 실행 권장\n"
                "  → Scale Out 검토"
            )
            response["action_code"] = "POD_RESTART"
        elif z_score >= 2.0:
            response["message"] = (
                "🟡 [경고] 메모리 급증\n"
                "  → 메모리 누수 여부 확인\n"
                "  → Pod Restart 준비"
            )
            response["action_code"] = "PREPARE_POD_RESTART"

    # ----------------------------------------
    # 디스크 이상 → 스토리지 확장 / 정리
    # ----------------------------------------
    elif metric_name == "디스크":
        if z_score >= 3.0:
            response["message"] = (
                "🔴 [긴급] 디스크 사용량 급증\n"
                "  → 불필요한 로그/파일 즉시 정리\n"
                "  → 스토리지 확장 검토"
            )
            response["action_code"] = "CLEAN_DISK"
        elif z_score >= 2.0:
            response["message"] = (
                "🟡 [경고] 디스크 사용량 증가\n"
                "  → 디스크 사용 원인 파악\n"
                "  → 로그 로테이션 확인"
            )
            response["action_code"] = "LOG_ROTATION"

    # ----------------------------------------
    # Latency 이상 → 트래픽 제어
    # ----------------------------------------
    elif metric_name == "Latency":
        if z_score >= 3.0:
            response["message"] = (
                "🔴 [긴급] 응답 지연 심각\n"
                "  → 트래픽 분산 즉시 실행\n"
                "  → Rollback 검토"
            )
            response["action_code"] = "TRAFFIC_SHEDDING"
        elif z_score >= 2.0:
            response["message"] = (
                "🟡 [경고] 응답 지연 증가\n"
                "  → DB 쿼리 및 외부 API 응답 확인\n"
                "  → 캐시 히트율 점검"
            )
            response["action_code"] = "CHECK_EXTERNAL_API"

    # ----------------------------------------
    # ErrorRate 이상 → Rollback 검토
    # ----------------------------------------
    elif metric_name == "ErrorRate":
        if z_score >= 3.0:
            response["message"] = (
                "🔴 [긴급] 에러율 급증\n"
                "  → Rollback 즉시 검토\n"
                "  → 외부 의존성 (DB / API) 상태 확인"
            )
            response["action_code"] = "ROLLBACK"
        elif z_score >= 2.0:
            response["message"] = (
                "🟡 [경고] 에러율 증가\n"
                "  → 에러 로그 즉시 확인\n"
                "  → 최근 배포 이력 점검"
            )
            response["action_code"] = "CHECK_ERROR_LOG"

    # ----------------------------------------
    # TPS 이상 → Rate Limiting / Scale Out
    # ----------------------------------------
    elif metric_name == "TPS":
        if z_score >= 3.0:
            response["message"] = (
                "🔴 [긴급] TPS 급증\n"
                "  → Scale Out 즉시 실행\n"
                "  → Rate Limiting 적용 검토"
            )
            response["action_code"] = "APPLY_RATE_LIMITING"
        elif z_score >= 2.0:
            response["message"] = (
                "🟡 [경고] TPS 증가\n"
                "  → 트래픽 원인 확인\n"
                "  → Scale Out 준비"
            )
            response["action_code"] = "MONITOR_TRAFFIC"

    # ----------------------------------------
    # 비용 이상 → 유휴 리소스 정리 (FinOps)
    # ----------------------------------------
    elif metric_name == "비용":
        if z_score >= 3.0:
            response["message"] = (
                "🔴 [긴급] 비용 급증\n"
                "  → 유휴 인스턴스 즉시 점검\n"
                "  → 비용 높은 리전 변경 검토\n"
                "  → 스케줄 기반 자동 종료 설정 권장"
            )
            response["action_code"] = "CLEAN_UNUSED_RESOURCES"
        elif z_score >= 2.0:
            response["message"] = (
                "🟡 [경고] 비용 증가\n"
                "  → 리소스 사용량 확인\n"
                "  → 불필요한 인스턴스 식별\n"
                "  → 리소스 축소 검토"
            )
            response["action_code"] = "OPTIMIZE_RESOURCES"

    return response
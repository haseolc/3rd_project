# correlator.py
# 이벤트 상관 분석 (노션 문서 6번 기반)
# 복수 메트릭 동시 이상 발생 시 원인 추론

from datetime import datetime, timedelta
from collections import deque


class EventCorrelator:
    def __init__(self, window_seconds: int = 60):
        """
        window_seconds : 몇 초 이내에 발생한 이벤트를 묶어서 분석할지
                         TODO: 운영 환경 응답속도에 맞게 조정
                         예) 빠른 장애 전파 환경이면 30초, 느리면 120초
        """
        self.window_seconds = window_seconds
        self.events = deque()

    def add_event(self, metric_name: str, value: float, z_score: float):
        """
        이상 이벤트 기록
        """
        self.events.append({
            "timestamp":   datetime.utcnow(),
            "metric_name": metric_name,
            "value":       value,
            "z_score":     z_score
        })

    def analyze(self, current_metrics: dict) -> dict | None:
        """
        최근 window_seconds 이내 이벤트를 분석하여 상관 관계 탐지

        탐지 시나리오 (노션 문서 6번):
          1. CPU + Latency 동시 이상     → 서버 과부하 의심
          2. ErrorRate + Latency 동시 이상 → 장애 의심
          3. TPS + CPU 동시 이상         → 트래픽 급증 의심
          4. 메모리 + CPU 동시 이상      → 리소스 고갈 의심
        """
        now = datetime.utcnow()
        cutoff = now - timedelta(seconds=self.window_seconds)

        # window 밖 이벤트 제거
        while self.events and self.events[0]["timestamp"] < cutoff:
            self.events.popleft()

        # 최근 이상 메트릭 목록
        recent_anomalies = {e["metric_name"] for e in self.events}

        # ----------------------------------------
        # 시나리오 1: CPU + Latency 동시 이상
        # ----------------------------------------
        if {"CPU", "Latency"}.issubset(recent_anomalies):
            return {
                "type":    "OVERLOAD",
                "metrics": ["CPU", "Latency"],
                "message": (
                    "⚡ 서버 과부하 의심\n"
                    "• CPU 급증과 Latency 증가가 동시 발생\n"
                    "• 원인: 트래픽 급증 또는 무한 루프 프로세스\n"
                    "• 추천: Scale Out 또는 원인 프로세스 확인"
                )
            }

        # ----------------------------------------
        # 시나리오 2: ErrorRate + Latency 동시 이상
        # ----------------------------------------
        if {"ErrorRate", "Latency"}.issubset(recent_anomalies):
            return {
                "type":    "FAILURE",
                "metrics": ["ErrorRate", "Latency"],
                "message": (
                    "🔥 장애 발생 의심\n"
                    "• ErrorRate 증가와 Latency 증가가 동시 발생\n"
                    "• 원인: 외부 API 장애 또는 DB 연결 문제\n"
                    "• 추천: 외부 의존성 확인 및 Rollback 검토"
                )
            }

        # ----------------------------------------
        # 시나리오 3: TPS + CPU 동시 이상
        # ----------------------------------------
        if {"TPS", "CPU"}.issubset(recent_anomalies):
            return {
                "type":    "TRAFFIC_SPIKE",
                "metrics": ["TPS", "CPU"],
                "message": (
                    "📈 트래픽 급증 의심\n"
                    "• TPS 급증과 CPU 증가가 동시 발생\n"
                    "• 원인: 갑작스러운 사용자 유입\n"
                    "• 추천: 트래픽 분산 및 Scale Out"
                )
            }

        # ----------------------------------------
        # 시나리오 4: 메모리 + CPU 동시 이상
        # ----------------------------------------
        if {"메모리", "CPU"}.issubset(recent_anomalies):
            return {
                "type":    "RESOURCE_EXHAUSTION",
                "metrics": ["메모리", "CPU"],
                "message": (
                    "⚠️ 리소스 고갈 의심\n"
                    "• 메모리와 CPU 동시 이상 발생\n"
                    "• 원인: 메모리 누수 또는 대용량 배치 작업\n"
                    "• 추천: Pod Restart 및 메모리 누수 점검"
                )
            }

        # TODO: 추가 상관 시나리오는 팀 협의 후 작성
        # 예) 배포 직후 에러율 증가 감지 등

        return None

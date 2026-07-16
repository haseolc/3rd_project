# forecaster.py
# Prophet 기반 성능 예측 (시계열 예측)
# 노션 문서 5번 (성능 예측) 기반

from datetime import datetime
import pandas as pd
from prophet import Prophet


class PerformanceForecaster:
    def __init__(self, metric_name: str, periods: int = 10, min_samples: int = 30):
        """
        metric_name : 예측 대상 메트릭 이름 (로그 출력용)
        periods     : 몇 분 후까지 예측할지 (기본 10분)
                      TODO: 운영 환경에 맞게 조정
                      예) 빠른 대응이 필요하면 5, 여유있게 보려면 30
        min_samples : 예측에 필요한 최소 데이터 수
                      TODO: 데이터 수집 주기에 맞게 조정
                      예) 10초마다 수집하면 30개 = 5분치 데이터
        """
        self.metric_name = metric_name
        self.periods = periods
        self.min_samples = min_samples
        self.history = []  # (timestamp, value) 리스트

        # ----------------------------------------
        # Prophet 위험도 임계값
        # TODO: 실제 운영 메트릭 기준으로 조정 필요
        # ----------------------------------------
        self.thresholds = {
            "CPU":       {"warning": 70.0,  "critical": 85.0},   # CPU 사용률 (%)
            "메모리":     {"warning": 75.0,  "critical": 90.0},   # 메모리 사용률 (%)
            "Latency":   {"warning": 200.0, "critical": 500.0},  # 응답시간 (ms)
                                                                  # TODO: 서비스 SLA 기준으로 변경
            "ErrorRate": {"warning": 1.0,   "critical": 5.0},    # 에러율 (%)
            "TPS":       {"warning": 1000.0,"critical": 2000.0}, # TODO: 실제 서비스 TPS 한계치로 변경
        }

    def add_data(self, value: float) -> dict | None:
        """
        새로운 데이터를 추가하고 미래 값을 예측
        min_samples 이상 쌓이면 예측 시작
        """
        self.history.append({
            "ds": datetime.utcnow(),
            "y":  value
        })

        if len(self.history) < self.min_samples:
            return None  # 데이터 부족 → 예측 보류

        return self._forecast()

    def _forecast(self) -> dict | None:
        """
        Prophet으로 미래 값 예측
        """
        try:
            df = pd.DataFrame(self.history)

            # TODO: 계절성이 있는 메트릭이면 아래 파라미터 조정
            # 예) 주간 패턴 있으면 weekly_seasonality=True
            model = Prophet(
                daily_seasonality=False,
                weekly_seasonality=False,
                yearly_seasonality=False,
                changepoint_prior_scale=0.05  # 변화점 민감도
            )
            model.fit(df)

            # 미래 데이터프레임 생성 (10초 간격으로 periods분 예측)
            future = model.make_future_dataframe(
                periods=self.periods * 6,
                freq="10s"
            )
            forecast = model.predict(future)

            forecast_value = round(float(forecast["yhat"].iloc[-1]), 2)
            forecast_upper = round(float(forecast["yhat_upper"].iloc[-1]), 2)
            risk = self._evaluate_risk(forecast_value)

            return {
                "metric":          self.metric_name,
                "current_value":   self.history[-1]["y"],
                "forecast_value":  forecast_value,
                "forecast_upper":  forecast_upper,
                "periods_minutes": self.periods,
                "risk":            risk   # NORMAL / HIGH / CRITICAL
            }

        except Exception as e:
            print(f"❌ [{self.metric_name}] 예측 실패: {e}")
            return None

    def _evaluate_risk(self, forecast_value: float) -> str:
        """
        예측값을 임계값과 비교하여 위험도 반환
        """
        threshold = self.thresholds.get(self.metric_name)

        if threshold is None:
            return "UNKNOWN"

        if forecast_value >= threshold["critical"]:
            return "CRITICAL"
        elif forecast_value >= threshold["warning"]:
            return "HIGH"
        else:
            return "NORMAL"

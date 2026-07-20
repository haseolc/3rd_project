# detector.py
# Z-score 기반 실시간 이상 탐지 + Isolation Forest 기반 이상 탐지

import os
import joblib
from collections import deque
import numpy as np
from sklearn.ensemble import IsolationForest


# ============================================================
# 1단계: Z-score 기반 이상 탐지 (MVP)
# ============================================================
class RealTimeAnomalyDetector:
    def __init__(self, window_size=10, threshold=2):
        """
        window_size : 최근 몇 개 데이터를 기준으로 판단할지 (테스트용 10)
        threshold   : Z-score 임계값 (낮을수록 민감, 보통 2~3)
        """
        self.window = deque(maxlen=window_size)
        self.threshold = threshold

    def add_data(self, value):
        """
        새로운 데이터를 추가하고 이상 여부를 판단
        반환값: dict 또는 None (데이터 누적 중)
        """

        # 타입 검증
        if not isinstance(value, (int, float)) or np.isnan(value):
            raise ValueError(f"유효하지 않은 입력값: {value}")

        # 현재 값 추가 전에 통계 계산
        # (이상값이 평균을 오염시키지 않도록 먼저 계산)
        if len(self.window) >= self.window.maxlen:
            mean = np.mean(self.window)
            std = np.std(self.window)
        else:
            self.window.append(value)
            return None  # 데이터 부족 → 판단 보류

        # 현재 값 추가
        self.window.append(value)

        # Z-score 계산
        if std < 1e-10:
            z_score = 0.0  # 분산이 0이면 변화 없음
        else:
            z_score = (value - mean) / std

        status = "ANOMALY" if abs(z_score) > self.threshold else "NORMAL"

        return {
            "value":   value,
            "z_score": round(z_score, 4),
            "mean":    round(float(mean), 4),
            "std":     round(float(std), 4),
            "status":  status
        }


# ============================================================
# 2단계: Isolation Forest 기반 이상 탐지 (비지도 학습)
# 비정상 패턴 탐지에 강함 - Z-score 보완용
# ============================================================
class IsolationForestDetector:
    # 💡 min_samples 기본값을 50에서 10으로 축소 수정!
    def __init__(self, n_estimators=100, contamination=0.05, min_samples=10):
        """
        n_estimators  : 트리 개수 (많을수록 정확, 느림 / 기본 100)
        contamination : 이상 데이터 비율 예상치 (기본 5%)
        min_samples   : 모델 학습에 필요한 최소 데이터 수 (테스트용 10개로 변경)
        """
        self.model = IsolationForest(
            n_estimators=n_estimators,
            contamination=contamination,
            random_state=42
        )
        self.min_samples = min_samples
        self.buffer = []
        self.is_trained = False

    def add_data(self, value) -> dict | None:
        """
        새로운 데이터를 추가하고 이상 여부를 판단
        min_samples 이상 쌓이면 자동으로 모델 학습
        """
        if not isinstance(value, (int, float)) or np.isnan(value):
            raise ValueError(f"유효하지 않은 입력값: {value}")

        self.buffer.append(value)

        # 데이터가 충분히 쌓이면 모델 학습 (최초 1회)
        if not self.is_trained and len(self.buffer) >= self.min_samples:
            X = np.array(self.buffer).reshape(-1, 1)
            self.model.fit(X)
            self.is_trained = True
            print(f"✅ IsolationForest 학습 완료 ({len(self.buffer)}개 데이터)")

        if not self.is_trained:
            print(f"🌲 IsolationForest 학습 중... ({len(self.buffer)}/{self.min_samples})")
            return None

        # 예측 (-1: 이상, 1: 정상)
        X = np.array([[value]])
        prediction = self.model.predict(X)[0]
        score = round(float(self.model.score_samples(X)[0]), 4)

        status = "ANOMALY" if prediction == -1 else "NORMAL"

        return {
            "value":  value,
            "score":  score,   # 이상 점수 (낮을수록 이상)
            "status": status
        }

    def retrain(self):
        """
        새로운 데이터가 충분히 쌓이면 모델 재학습
        """
        if len(self.buffer) >= self.min_samples:
            X = np.array(self.buffer).reshape(-1, 1)
            self.model.fit(X)
            print(f"🔄 IsolationForest 재학습 완료 ({len(self.buffer)}개 데이터)")

    def save(self, path: str):
        """
        학습된 모델을 파일로 저장
        """
        os.makedirs(os.path.dirname(path), exist_ok=True)
        joblib.dump(self.model, path)
        print(f"✅ 모델 저장 완료: {path}")

    def load(self, path: str):
        """
        저장된 모델 불러오기
        """
        if not os.path.exists(path):
            print(f"⚠️ 저장된 모델 없음: {path} → 실시간 학습으로 대체")
            return
        self.model = joblib.load(path)
        self.is_trained = True
        print(f"✅ 모델 불러오기 완료: {path}")
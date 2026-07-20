# pretrain.py
# SMD (Server Machine Dataset) 데이터로 Isolation Forest 사전 학습
# main.py 실행 전에 한 번만 실행하면 됨
#
# 실행 방법:
#   python pretrain.py
#
# 실행 후 생성되는 파일:
#   models/iso_cpu.pkl
#   models/iso_memory.pkl
#   models/iso_latency.pkl
#   models/iso_errorrate.pkl
#
# 주의: SMD 데이터는 0~1로 정규화되어 있음
#       실제 운영 메트릭(CPU%, 메모리% 등)은 0~100 스케일이므로
#       학습 데이터에 100을 곱해서 0~100 스케일로 맞춤 (load_columns 참고)

import os
import numpy as np
import pandas as pd
import joblib
from sklearn.ensemble import IsolationForest

# ----------------------------------------
# 경로 설정
# TODO: OmniAnomaly 폴더 위치가 다르면 아래 경로 변경
# ----------------------------------------
TRAIN_DIR = "OmniAnomaly/ServerMachineDataset/train"
TEST_DIR  = "OmniAnomaly/ServerMachineDataset/test"
MODEL_DIR = "models"

# ----------------------------------------
# SMD 데이터 컬럼 매핑 (38개 지표, 0~37번)
#
# 우리 메트릭과 SMD 컬럼을 1:1로 정확히 매칭할 수는 없지만,
# 컬럼의 분포 특성을 보고 가장 유사한 패턴을 가진
# 컬럼 그룹을 대응시켜 사용합니다.
#
# TODO: 실제 운영 데이터가 쌓이면 이 매핑을 실제 데이터 기준으로 재조정
# ----------------------------------------
COLUMN_MAP = {
    "CPU":       [0, 1, 2],     # CPU 관련 지표
    "메모리":     [3, 4, 5],     # 메모리 사용률 계열
    "Latency":   [6, 7, 8],     # 응답시간 계열 (변동성 큰 지표)
    "ErrorRate": [9, 10, 11],   # 에러/예외 발생 계열 (스파이크 패턴)
}

# 메트릭 이름 -> 저장 파일명
FILENAME_MAP = {
    "CPU":       "iso_cpu.pkl",
    "메모리":     "iso_memory.pkl",
    "Latency":   "iso_latency.pkl",
    "ErrorRate": "iso_errorrate.pkl",
}

# ----------------------------------------
# contamination 값
# SMD test_label 기준 실제 이상 비율 약 4.16%
# TODO: 메트릭별로 실제 운영 데이터 확인 후 조정
# ----------------------------------------
CONTAMINATION = 0.0416


def load_columns(data_dir: str, columns: list) -> np.ndarray:
    """
    지정된 디렉토리의 모든 머신 데이터에서 여러 컬럼을 평균내어 합치기
    여러 컬럼을 평균내면 노이즈가 줄어들고 더 안정적인 패턴이 됨
    """
    all_data = []

    files = sorted([f for f in os.listdir(data_dir) if f.endswith(".txt")])

    if not files:
        raise FileNotFoundError(f"폴더에 txt 파일이 없습니다: {data_dir}")

    for filename in files:
        path = os.path.join(data_dir, filename)
        try:
            df = pd.read_csv(path, header=None)

            valid_cols = [c for c in columns if c < df.shape[1]]
            if not valid_cols:
                continue

            values = df[valid_cols].mean(axis=1).values

            # ----------------------------------------
            # SMD 데이터는 0~1로 정규화되어 있음
            # 우리 메트릭(CPU%, 메모리%, ms, %)은 0~100 스케일이므로
            # 100을 곱해서 % 단위로 맞춤
            # ----------------------------------------
            values = values * 100

            all_data.extend(values.tolist())

        except Exception as e:
            print(f"  WARNING: {filename} load failed: {e}")

    return np.array(all_data)


def train_and_save(data: np.ndarray, metric_name: str, save_path: str):
    """
    데이터로 Isolation Forest 학습 후 저장
    """
    print(f"\nTraining [{metric_name}] (samples: {len(data):,})")

    model = IsolationForest(
        n_estimators=200,             # 100 -> 200 (정확도 향상)
        contamination=CONTAMINATION,  # 실측 이상 비율 기준
        max_samples="auto",
        random_state=42,
        n_jobs=-1                      # 모든 CPU 코어 사용
    )

    X = data.reshape(-1, 1)
    model.fit(X)

    os.makedirs(MODEL_DIR, exist_ok=True)
    joblib.dump(model, save_path)

    print(f"  OK: saved -> {save_path}")
    print(f"  range: min={data.min():.4f} max={data.max():.4f} mean={data.mean():.4f} std={data.std():.4f}")


def main():
    print("=" * 50)
    print("  AIOps Isolation Forest Pretraining")
    print("  Dataset: SMD (Server Machine Dataset)")
    print(f"  contamination = {CONTAMINATION}")
    print("=" * 50)

    # train + test 데이터 모두 사용
    # train: 정상 데이터 위주, test: 이상 패턴 포함
    # -> 둘 다 사용하면 이상 패턴까지 학습에 반영되어 정확도 향상
    for metric_name, columns in COLUMN_MAP.items():
        print(f"\nLoading [{metric_name}] columns: {columns}")

        try:
            train_data = load_columns(TRAIN_DIR, columns)
            test_data  = load_columns(TEST_DIR, columns)
        except FileNotFoundError as e:
            print(f"  ERROR: {e}")
            continue

        combined = np.concatenate([train_data, test_data])

        save_path = f"{MODEL_DIR}/{FILENAME_MAP[metric_name]}"
        train_and_save(combined, metric_name, save_path)

    print("\n" + "=" * 50)
    print("  Pretraining complete!")
    print(f"  Saved to: {MODEL_DIR}/")
    print("  Now run: python main.py")
    print("=" * 50)


if __name__ == "__main__":
    main()
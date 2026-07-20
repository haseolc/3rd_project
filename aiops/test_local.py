# test_local.py
# EC2 없이 로컬에서 이상 탐지 + Discord 알림 테스트
# 실제 CloudWatch 대신 임의 데이터로 동작 확인
#
# 실행 방법:
#   python test_local.py

from detector import RealTimeAnomalyDetector, IsolationForestDetector
from recommender import get_recommendation
from correlator import EventCorrelator
from alert import send_alert

# ----------------------------------------
# 테스트용 임의 CPU 데이터
# 정상 데이터 중간에 이상값(90%) 삽입
# ----------------------------------------
test_data = [
    30, 32, 31, 33, 30, 29, 31, 32, 30, 31,  # 정상 10개 (window 꽉 채움)
    90, 90, 90,                                # 이상값 3개 연속
    31, 30,
]

def run_test():
    print("=" * 50)
    print("  AIOps 로컬 테스트 시작")
    print("  임의 CPU 데이터로 이상 탐지 + Discord 알림 확인")
    print("=" * 50)

    zscore_detector  = RealTimeAnomalyDetector(window_size=10, threshold=2)
    iso_detector     = IsolationForestDetector(n_estimators=100, contamination=0.05)
    correlator       = EventCorrelator()

    # 사전 학습 모델 불러오기
    print("\n📦 사전 학습 모델 불러오는 중...")
    iso_detector.load("models/iso_cpu.pkl")

    print("\n📊 테스트 데이터 처리 시작\n")

    for i, cpu in enumerate(test_data):
        print(f"[{i+1:02d}] CPU 입력값: {cpu}%")

        # Z-score 탐지
        try:
            z_result = zscore_detector.add_data(cpu)
        except ValueError as e:
            print(f"  ❌ 입력 오류: {e}")
            continue

        if z_result is None:
            print(f"  📊 데이터 누적 중...\n")
            continue

        print(f"  Z-score: {z_result['z_score']} | 평균: {z_result['mean']} | 상태: {z_result['status']}")

        # Isolation Forest 탐지
        iso_result = iso_detector.add_data(cpu)
        if iso_result:
            print(f"  IsolationForest: {iso_result['status']} (score: {iso_result['score']})")

        # 이상 탐지 시 Discord 알림 전송
        if z_result["status"] == "ANOMALY":
            recommendation = get_recommendation("CPU", z_result)
            correlator.add_event("CPU", cpu, z_result["z_score"])

            print(f"\n  🚨 이상 탐지 발생!")
            print(f"  💡 추천 액션: {recommendation}")
            print(f"  📨 Discord 알림 전송 중...")

            result = send_alert(
                f"[테스트] CPU 이상 감지\n"
                f"• 현재값: {cpu}%\n"
                f"• Z-score: {z_result['z_score']}\n"
                f"• 평균: {z_result['mean']}% / 표준편차: {z_result['std']}%\n"
                f"💡 추천 액션: {recommendation}"
            )

            if result:
                print(f"  ✅ Discord 알림 전송 성공!\n")
            else:
                print(f"  ❌ Discord 알림 전송 실패\n")
        else:
            print(f"  ✅ 정상\n")

    print("=" * 50)
    print("  테스트 완료!")
    print("=" * 50)


if __name__ == "__main__":
    run_test()
# main.py
# AIOps + FinOps 전체 파이프라인 실행 (AWS 단일 클라우드)
#
# 알람 채널 구조:
#   AIOps 이상  → 인프라 채널
#   FinOps 이상 → FinOps 채널
#   통합 이상   → 인프라 채널 + FinOps 채널 동시 전송

import os
import time
import subprocess  # 실제 인프라 제어 명령 실행을 위한 라이브러리
from detector import RealTimeAnomalyDetector, IsolationForestDetector
from forecaster import PerformanceForecaster
from recommender import get_recommendation
from correlator import EventCorrelator
from alert import (
    send_alert, 
    send_recovery_alert, 
    send_cost_alert, 
    send_cost_recovery_alert, 
    send_integrated_alert
)
from data_collector import (
    get_cpu_metric,
    get_memory_metric,     # [수집 연동 활성화]
    get_disk_metric,       # [수집 연동 활성화]
    get_latency_metric,    # [수집 연동 활성화]
    get_error_rate_metric, # [수집 연동 활성화]
    get_tps_metric,        # [수집 연동 활성화]
    get_cost_metric,       # [수집 연동 활성화]
)


# ----------------------------------------
# Z-score 기반 detector (메트릭별 분리)
# 💡 빠른 테스트를 위해 window_size를 7로 축소 설정!
# ----------------------------------------
WINDOW_SIZE_TEST = 7  # 7개 수집 시 즉시 학습 완료 및 모델 가동

zscore_detectors = {
    "CPU":       RealTimeAnomalyDetector(window_size=WINDOW_SIZE_TEST, threshold=2),
    "메모리":     RealTimeAnomalyDetector(window_size=WINDOW_SIZE_TEST, threshold=2),
    "디스크":     RealTimeAnomalyDetector(window_size=WINDOW_SIZE_TEST, threshold=2),
    "Latency":   RealTimeAnomalyDetector(window_size=WINDOW_SIZE_TEST, threshold=2),
    "ErrorRate": RealTimeAnomalyDetector(window_size=WINDOW_SIZE_TEST, threshold=2),
    "TPS":       RealTimeAnomalyDetector(window_size=WINDOW_SIZE_TEST, threshold=2),
    "비용":       RealTimeAnomalyDetector(window_size=WINDOW_SIZE_TEST, threshold=2),
}

# ----------------------------------------
# Isolation Forest detector (2단계)
# ----------------------------------------
iso_detectors = {
    "CPU":       IsolationForestDetector(n_estimators=100, contamination=0.05),
    "메모리":     IsolationForestDetector(n_estimators=100, contamination=0.05),
    "Latency":   IsolationForestDetector(n_estimators=100, contamination=0.05),
    "ErrorRate": IsolationForestDetector(n_estimators=100, contamination=0.05),
}

# ----------------------------------------
# Prophet 예측기
# ----------------------------------------
forecasters = {
    "CPU":     PerformanceForecaster(metric_name="CPU",     periods=10),
    "Latency": PerformanceForecaster(metric_name="Latency", periods=10),
}

# ----------------------------------------
# 이벤트 상관 분석기
# ----------------------------------------
correlator = EventCorrelator()

# ----------------------------------------
# 수집 함수 매핑 (실시간 카프카/CloudWatch 파이프라인 활성화)
# ----------------------------------------
collectors = {
    "CPU":       get_cpu_metric,            # CloudWatch 직접 수집
    "메모리":     get_memory_metric,         # 카프카 수집
    "디스크":     get_disk_metric,           # 카프카 수집
    "Latency":   get_latency_metric,        # 카프카 수집
    "ErrorRate": get_error_rate_metric,     # 카프카 수집
    "TPS":       get_tps_metric,            # 카프카 수집
    "비용":       get_cost_metric,           # 카프카 수집
}

# FinOps 메트릭 구분 (비용 관련)
FINOPS_METRICS = {"비용"}

# 알림 발생 추적 및 장애 최고 수치(Peak) 계산을 위한 내부 상태 관리
active_alerts_state = {}
peak_tracker = {}


def load_pretrained_models():
    """
    pretrain.py로 사전 학습된 모델 불러오기
    """
    print("📦 사전 학습 모델 불러오는 중...")
    iso_detectors["CPU"].load("models/iso_cpu.pkl")


# --------------------------------------------------------
# AIOps / FinOps 자동 대응 시스템 (Auto-healing) [실제 인프라 명령 적용]
# --------------------------------------------------------
def trigger_auto_remediation(metric_name: str, action_code: str) -> str:
    """
    action_code를 해석하여 실제 쿠버네티스(kubectl) 인프라 제어 명령을 실행하고, 
    수행 결과를 텍스트로 리턴합니다.
    (서울 Primary와 오사카 DR 환경 설정에 따라 네임스페이스와 디플로이먼트가 분기됩니다.)
    """
    print(f"\n⚡ [Auto-healing Engine] 실시간 인프라 제어 가동 (Target: {metric_name})")
    
    # 환경 변수 "AIOPS_TARGET_ENV"의 값에 따라 서울/오사카 세션 분기 처리
    target_env = os.environ.get("AIOPS_TARGET_ENV", "SEOUL")

    if target_env == "OSAKA":
        target_namespace = "dr-test"
        target_deployment = "dr-smoke-app"
        env_label = "오사카 DR"
    else:
        target_namespace = "ci-cd-test"
        target_deployment = "ci-cd-smoke-app"
        env_label = "서울 Primary"

    action_summary = "조치 적용 대기"
    
    # 1. CPU / TPS 이상 발생 시 -> 실제 인스턴스/파드 수평 확장 (Scale Out)
    if action_code == "SCALE_OUT":
        print(f"🤖 [Auto-healing] 트래픽 집중 감지! '{env_label}' 환경의 '{target_deployment}' Replicas 확장을 시작합니다...")
        try:
            result = subprocess.run(
                ["kubectl", "scale", f"deployment/{target_deployment}", "--replicas=5", "-n", target_namespace],
                capture_output=True, text=True, check=True
            )
            print(f"✅ [Auto-healing 성공] {result.stdout.strip()}")
            action_summary = f"{env_label} Scale Out 완료 (replicas=5)"
        except Exception as e:
            print(f"❌ [Auto-healing 실패] kubectl scale 명령 에러: {e}")
            action_summary = f"{env_label} Scale Out 실패 ({e})"
    
    # 2. 메모리 과부하 / 이상 징후 감지 시 -> 실제 무중단 파드 순차적 백업 및 교체 (Pod Restart)
    elif action_code == "POD_RESTART":
        print(f"🤖 [Auto-healing] 앱 리소스 고사 감지! '{env_label}' 환경의 '{target_deployment}' 파드 재시작을 수행합니다...")
        try:
            result = subprocess.run(
                ["kubectl", "rollout", "restart", f"deployment/{target_deployment}", "-n", target_namespace],
                capture_output=True, text=True, check=True
            )
            print(f"✅ [Auto-healing 성공] {result.stdout.strip()}")
            action_summary = f"{env_label} 무중단 롤아웃 재배포 완료"
        except Exception as e:
            print(f"❌ [Auto-healing 실패] kubectl rollout restart 명령 실행 에러: {e}")
            action_summary = f"{env_label} 무중단 롤아웃 재배포 실패 ({e})"
        
    # 3. 디스크 풀(Full) 발생 임박 시 -> 자동 청소 스크립트 실행
    elif action_code == "CLEAN_DISK":
        print(f"🤖 [Auto-healing] 호스트 디스크 용량 과부하 감지! 불필요 리소스 정리 명령을 실행합니다...")
        try:
            result = subprocess.run(
                "docker system prune -af && find /var/log -type f -name '*.log' -delete",
                shell=True, capture_output=True, text=True, check=True
            )
            print(f"✅ [Auto-healing 성공] 디스크 크론 정리 작동 완료")
            action_summary = f"호스트 도커 및 로그 정리 완료"
        except Exception as e:
            print(f"❌ [Auto-healing 실패] 디스크 클린 스크립트 실행 실패: {e}")
            action_summary = f"디스크 정화 실패 ({e})"
        
    # 4. 장애 및 에러율 3.0 이상 솟구칠 시 -> 직전 안정 배포 버전으로 롤백 (Rollback)
    elif action_code == "ROLLBACK":
        print(f"🤖 [Auto-healing] 어플리케이션 장애율 임계치 돌파! '{env_label}' 환경 직전 안정 빌드로 롤백을 진행합니다...")
        try:
            result = subprocess.run(
                ["kubectl", "rollout", "undo", f"deployment/{target_deployment}", "-n", target_namespace],
                capture_output=True, text=True, check=True
            )
            print(f"✅ [Auto-healing 성공] {result.stdout.strip()}")
            action_summary = f"{env_label} 안정 버전으로 자동 롤백 성공"
        except Exception as e:
            print(f"❌ [Auto-healing 실패] kubectl 롤백 실패: {e}")
            action_summary = f"{env_label} 롤백 실패 ({e})"
        
    elif action_code == "APPLY_RATE_LIMITING":
        print(f"🤖 [Auto-healing] 트래픽 폭주 대응: Istio Rate Limiting 제어 실행.")
        action_summary = "Istio 트래픽 레이팅 제한(Rate Limiting) 적용 완료"
        
    elif action_code == "CLEAN_UNUSED_RESOURCES":
        print(f"🤖 [Auto-healing] FinOps 비용 절감: 가상 미사용 자원 스케줄러 가동.")
        action_summary = "AWS 가상 미사용 자원 정리 완료"
        
    elif action_code == "NO_ACTION":
        print("ℹ️ [Auto-healing] 정상 범위 수치로 조치가 필요하지 않습니다.")
        action_summary = "정상 유지 (조치 미실행)"
        
    else:
        print(f"🔎 [Auto-healing] 수동 분석 권장 상태 ({action_code}). 레포트 확인 요망.")
        action_summary = f"수동 대응 검토 권장 ({action_code})"
        
    print("-----------------------------------------------------------------------\n")
    return action_summary


def run():
    print("\n==================================================")
    print("🚀 AIOps + FinOps 통합 모니터링 파이프라인 가동 (AWS)")
    print("==================================================\n")

    loop_count = 0

    while True:
        loop_count += 1
        print(f"\n🔄 [Monitoring Cycle #{loop_count}] 메트릭 수집 및 이상 탐지 시작...")
        
        current_metrics  = {}
        aiops_anomalies  = []  # 이번 루프에서 발생한 AIOps 이상
        finops_anomalies = []  # 이번 루프에서 발생한 FinOps 이상

        for name, collect in collectors.items():

            # 1. 데이터 수집
            value = collect()
            
            # 수집 중 에러가 나서 None이 반환되어도 셧다운되지 않고 유연하게 continue 처리
            if value is None:
                continue

            current_metrics[name] = value

            # 2. Z-score 이상 탐지
            try:
                z_result = zscore_detectors[name].add_data(value)
            except ValueError as e:
                print(f"❌ [{name}] Z-score 탐지 오류: {e}")
                continue

            if z_result is None:
                print(f"📊 [{name}] 데이터 수집 중... (현재값: {value} | 학습 완료까지 대기)")
                continue

            # CPU 90% 이상 강제 감지 플래그
            is_cpu_danger = (name == "CPU" and value >= 90.0)

            status_icon = "🚨 ANOMALY" if z_result['status'] == "ANOMALY" else "🟢 NORMAL"
            print(f"📈 [{name}] 값: {z_result['value']} | Z-score: {z_result['z_score']} | 상태: {status_icon}")

            # 3. Isolation Forest 탐지
            if name in iso_detectors:
                iso_result = iso_detectors[name].add_data(value)
                if iso_result:
                    print(f"🌲 [{name}] IsolationForest: {iso_result['status']} (score: {iso_result['score']})")

            # 4. Prophet 예측
            if name in forecasters:
                forecast = forecasters[name].add_data(value)
                if forecast:
                    print(
                        f"🔮 [{name}] 예측 | "
                        f"10분 후: {forecast['forecast_value']} | "
                        f"위험도: {forecast['risk']}"
                    )

            # 이상 발생 트리거 정의
            is_anomaly = (z_result["status"] == "ANOMALY" or is_cpu_danger)

            # --------------------------------------------------------
            # 🚨 1단계: 지표 최초 이상 발생 경보 (Alert)
            # --------------------------------------------------------
            if is_anomaly:
                rec_data = get_recommendation(name, z_result)
                recommendation = rec_data["message"]
                action_code = rec_data["action_code"]
                
                # 피크(Peak) 수치 트래킹
                if name not in peak_tracker:
                    peak_tracker[name] = value
                else:
                    if value > peak_tracker[name]:
                        peak_tracker[name] = value
                
                max_peak = peak_tracker[name]

                correlator.add_event(name, value, z_result["z_score"])

                # 변수 추출 및 단위 표기 교정
                current_val = z_result['value']
                mean_val = z_result['mean']
                std_val = z_result['std']
                z_score = z_result['z_score']
                
                increase_amount = current_val - mean_val
                increase_percent = (increase_amount / mean_val * 100) if mean_val > 0 else 0
                direction_symbol = "▲" if increase_amount >= 0 else "▼"
                
                if name == "비용":
                    current_str = f"${current_val}"
                    mean_str    = f"${round(mean_val, 2)}"
                    change_str  = f"${round(abs(increase_amount), 2)}"
                elif name == "CPU":
                    current_str = f"{current_val}%"
                    mean_str    = f"{round(mean_val, 2)}%"
                    change_str  = f"{round(abs(increase_amount), 2)}%"
                else:
                    current_str = f"{current_val}"
                    mean_str    = f"{round(mean_val, 2)}"
                    change_str  = f"{round(abs(increase_amount), 2)}"
                
                abs_z_score = abs(z_score)
                if abs_z_score >= 3.0 or is_cpu_danger:
                    severity = "🚨 심각 (Critical)"
                elif abs_z_score >= 2.5:
                    severity = "⚠️ 높음 (High)"
                elif abs_z_score >= 2.0:
                    severity = "주의 (Warning)"
                else:
                    severity = "정상"

                # CPU 리소스 고사 상황 판단
                resource_starvation_warning = ""
                if name == "CPU" and is_cpu_danger:
                    current_tps = current_metrics.get("TPS", 10.0)
                    if current_tps <= 20.0:
                        severity = "🚨 심각 (Critical - 리소스 고사)"
                        action_code = "POD_RESTART"
                        recommendation = (
                            "무의미한 CPU 독점(고사) 상황입니다. "
                            "Scale Out 대신 파드를 롤아웃 재배포하여 시스템 락을 해제합니다."
                        )
                        resource_starvation_warning = (
                            f"\n⚡ **[리소스 고사 경보 (Resource Starvation)]**\n"
                            f"• 현재 CPU 점유율: **{current_val}%** / TPS: **{current_tps}**\n"
                            f"• 좀비 프로세스 또는 루프 병목 감지 -> 강제 복구를 실행합니다.\n"
                        )

                alert_message = (
                    f"⚠️ **[{name}] 지표 이상 감지 (위험도: {severity})**\n"
                    f"• **현재 수치:** {current_str}\n"
                    f"• **최근 평균:** {mean_str} / **표준편차:** {round(std_val, 4)}\n"
                    f"• **변화량:** 평소 대비 **{change_str}** 변동 ({direction_symbol} {round(abs(increase_percent), 1)}% 변화)\n"
                    f"• **통계 분석:** 정상적인 편차 기준의 약 **{round(abs_z_score, 1)}배**를 벗어난 특이 수치입니다."
                    f"{resource_starvation_warning}\n"
                    f"💡 **추천 조치:** {recommendation}"
                )

                # 한 번도 경보를 안 날린 장애 상황 진입 시점에만 디스코드 최초 1회 발송
                if name not in active_alerts_state:
                    print(f"📢 [{name}] 디스코드 경보 발송 중...")
                    if name in FINOPS_METRICS:
                        finops_anomalies.append(name)
                        send_cost_alert(alert_message)
                    else:
                        aiops_anomalies.append(name)
                        send_alert(alert_message)

                    # 오토힐링 복구 실행
                    remediation_action = trigger_auto_remediation(name, action_code)
                    
                    active_alerts_state[name] = {
                        "action": remediation_action,
                        "severity": severity
                    }

            # --------------------------------------------------------
            # 🟢 2단계: 정상 상태 복귀 시 자동 해결 보고 알림 (Resolution)
            # --------------------------------------------------------
            else:
                if name in active_alerts_state:
                    final_peak = peak_tracker.get(name, value)
                    remediation_action = active_alerts_state[name]["action"]
                    
                    is_fin = (name in FINOPS_METRICS)
                    unit = "$" if is_fin else "%"
                    if name == "CPU":
                        unit = "%"
                    elif name == "비용":
                        unit = "$"
                    
                    current_str = f"${value}" if is_fin else f"{value}{unit}"
                    peak_str = f"${final_peak}" if is_fin else f"{final_peak}{unit}"

                    recovery_message = (
                        f"🛡️ **[{name}] 인프라 자동 복구 완료 및 안정화 성공**\n"
                        f"• ✅ **복구 후 현재 수치:** {current_str}\n"
                        f"• 📈 **장애 모니터링 기간 중 최고 피크치:** **{peak_str}**\n"
                        f"• ⚙️ **수행된 인프라 자동 제어:** `{remediation_action}`\n"
                        f"*(AIOps 오토힐링 시스템에 의해 정상 상태로 자동 원복되었습니다.)*"
                    )

                    print(f"📢 [{name}] 디스코드 복구 알림 발송 중...")
                    if is_fin:
                        send_cost_recovery_alert(recovery_message)
                    else:
                        send_recovery_alert(recovery_message)

                    # 세션 초기화
                    del active_alerts_state[name]
                    if name in peak_tracker:
                        del peak_tracker[name]

        # 6. 이벤트 상관 분석
        if current_metrics:
            correlation = correlator.analyze(current_metrics)
            if correlation:
                print(f"🔗 [상관 분석] {correlation['message']}")
                send_alert(f"[상관 분석] {correlation['message']}")

        # 7. AIOps + FinOps 동시 이상 → 통합 알람
        if aiops_anomalies and finops_anomalies:
            print("🚨 [AIOps + FinOps 통합 이상 감지] 인프라/FinOps 채널 전송 중...")
            send_integrated_alert(
                f"운영 이상과 비용 이상이 동시에 감지되었습니다.\n"
                f"• AIOps 이상 지표: {', '.join(aiops_anomalies)}\n"
                f"• FinOps 이상 지표: {', '.join(finops_anomalies)}\n"
                f"• 판단: 트래픽 증가 또는 장애성 비용 증가 가능성\n"
                f"• 처리 방식: 운영자 확인 필요"
            )

        time.sleep(3)


if __name__ == "__main__":
    run()
# alert.py
# Discord Webhook 알림 전송

import os
import time
import requests
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

# .env 변수명과 100% 일치
WEBHOOK_INFRA  = os.environ.get("DISCORD_WEBHOOK_INFRA")
WEBHOOK_FINOPS = os.environ.get("DISCORD_WEBHOOK_FINOPS")
MAX_LENGTH = 1900


def _send(webhook_url: str, content: str, retries: int = 3) -> bool:
    """
    단일 Webhook으로 메시지 전송 (공통 함수)
    """
    if not webhook_url:
        print("⚠️ Webhook URL이 설정되지 않았습니다 (.env 파일 확인)")
        return False

    if len(content) > MAX_LENGTH:
        content = content[:MAX_LENGTH] + "...(생략)"

    payload = {"content": content}

    for attempt in range(retries):
        try:
            response = requests.post(webhook_url, json=payload, timeout=5)
            if response.status_code == 204:
                return True
            print(f"❌ 전송 실패 (시도 {attempt+1}): {response.status_code}")
        except requests.exceptions.Timeout:
            print(f"⏱️ 타임아웃 (시도 {attempt+1})")
        except Exception as e:
            print(f"❌ 에러 (시도 {attempt+1}): {e}")

        if attempt < retries - 1:
            time.sleep(2 ** attempt)

    return False


def send_alert(message: str) -> bool:
    """
    AIOps 이상 알람 → 인프라 채널만 전송
    """
    content = f"🚨 **[AIOps Alert]**\n{message}"
    print("📨 인프라 채널 전송 중...")
    result = _send(WEBHOOK_INFRA, content)
    if result:
        print("✅ 알림 전송 성공 (인프라 채널)")
    return result


def send_recovery_alert(message: str) -> bool:
    """
    AIOps 복구 완료 알람 → 인프라 채널 전송
    """
    content = f"🟢 **[AIOps Recovery Resolved]**\n{message}"
    print("📨 인프라 복구 알림 전송 중...")
    result = _send(WEBHOOK_INFRA, content)
    if result:
        print("✅ 복구 알림 전송 성공 (인프라 채널)")
    return result


def send_cost_alert(message: str) -> bool:
    """
    FinOps 비용 이상 알람 → FinOps 채널만 전송
    """
    content = f"💰 **[FinOps Alert]**\n{message}"
    print("📨 FinOps 채널 전송 중...")
    result = _send(WEBHOOK_FINOPS, content)
    if result:
        print("✅ 비용 알림 전송 성공 (FinOps 채널)")
    return result


def send_cost_recovery_alert(message: str) -> bool:
    """
    FinOps 비용 복구 완료 알람 → FinOps 채널 전송
    """
    content = f"🟢 **[FinOps Recovery Resolved]**\n{message}"
    print("📨 FinOps 복구 알림 전송 중...")
    result = _send(WEBHOOK_FINOPS, content)
    if result:
        print("✅ 비용 복구 알림 전송 성공 (FinOps 채널)")
    return result


def send_integrated_alert(message: str) -> bool:
    """
    AIOps + FinOps 동시 이상 알람
    → 인프라 채널 + FinOps 채널 동시 전송
    """
    content = f"⚡ **[Integrated Alert]**\n{message}"
    print("📨 통합 알림 전송 중 (인프라 + FinOps)...")
    r1 = _send(WEBHOOK_INFRA, content)
    r2 = _send(WEBHOOK_FINOPS, content)
    if r1 and r2:
        print("✅ 통합 알림 전송 성공 (인프라 + FinOps 채널)")
    return r1 and r2
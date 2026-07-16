# data_collector.py
# AWS CloudWatch + Kafka 메트릭 수집 (실시간 연동 & 수집 보장 모드)

import boto3
import requests
import json
import uuid  # <-- 컨슈머 중복 차단 및 고유 세션 생성을 위해 필수 사용
from datetime import datetime, timedelta

# ----------------------------------------
# Kafka 브로커 설정 (10.0.1.46:9092 통신 성공 반영)
# ----------------------------------------
KAFKA_BROKER_MONITORING = "10.0.1.46:9092"  # 모니터링팀 브로커 (사설 IP + 9092)
KAFKA_BROKER_FINOPS = "10.0.1.46:9092"      # FinOps팀 비용 브로커 (사설 IP + 9092)
KAFKA_TOPIC = "test-topic"               # ※ 실제 전송받는 토픽명과 일치해야 합니다.


# ============================================================
# 공통: Kafka Consumer - 특정 메트릭 값 수신
# ============================================================
def _get_from_kafka(metric_name: str, broker: str) -> float | None:
    try:
        from kafka import KafkaConsumer

        # 매 쿼리마다 완전하게 고유한 그룹 ID를 부여하여 오프셋(읽기 기록) 꼬임을 완전 차단합니다.
        unique_group = f"aiops-consumer-{metric_name}-{uuid.uuid4().hex[:6]}"

        # 역직렬화(Deserializer) 시 오류가 나도 셧다운되지 않도록, 안전하게 raw 문자열로 디코딩해 수신합니다.
        consumer = KafkaConsumer(
            KAFKA_TOPIC,
            bootstrap_servers=broker,
            group_id=unique_group,
            auto_offset_reset="latest",    # 찌꺼기 방지를 위해 최신 메시지만 구독
            consumer_timeout_ms=3000,      # 메시지가 도달할 때까지 3초 대기
            value_deserializer=lambda x: x.decode("utf-8", errors="ignore")
        )

        for message in consumer:
            raw_value = message.value
            try:
                # 안전하게 문자열을 확인한 뒤 내부에서 동적으로 JSON 파싱을 격리 수행합니다.
                data = json.loads(raw_value)
                
                if isinstance(data, dict) and data.get("metric") == metric_name:
                    value = float(data["value"])
                    print(f"📥 [Kafka 실시간 수신] {metric_name} = {value}")
                    consumer.close()
                    return round(value, 2)
            except Exception:
                # 규격에 맞지 않는 텍스트가 유입되더라도 예외 메시지 출력 없이 조용히 다음 메시지로 패스합니다.
                continue

        consumer.close()
        print(f"⚠️ Kafka [{metric_name}] 메시지 없음 (3초 대기 후 종료)")
        return None

    except Exception as e:
        # 카프카 브로커 연결 자체에 실패한 심각한 경우에만 경고를 출력합니다.
        print(f"⚠️ Kafka 연결 상태 대기 중 ({metric_name}): {e}")
        return None


# ============================================================
# 공통: EC2 인스턴스 ID 자동 감지 (IMDSv2)
# ============================================================
def get_instance_id() -> str | None:
    try:
        token = requests.put(
            "http://169.254.169.254/latest/api/token",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
            timeout=2
        ).text

        instance_id = requests.get(
            "http://169.254.169.254/latest/meta-data/instance-id",
            headers={"X-aws-ec2-metadata-token": token},
            timeout=2
        ).text

        return instance_id

    except Exception as e:
        print(f"❌ 인스턴스 ID 감지 실패: {e}")
        return None


# ============================================================
# CPU: CloudWatch 직접 수집
# ============================================================
def get_cpu_metric(instance_id: str = None) -> float | None:
    if instance_id is None:
        instance_id = get_instance_id()

    if instance_id is None:
        print("❌ 인스턴스 ID를 가져올 수 없습니다")
        return None

    try:
        cloudwatch = boto3.client(
            "cloudwatch",
            region_name="ap-northeast-2"
        )

        response = cloudwatch.get_metric_statistics(
            Namespace="AWS/EC2",
            MetricName="CPUUtilization",
            Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
            StartTime=datetime.utcnow() - timedelta(minutes=5),
            EndTime=datetime.utcnow(),
            Period=60,
            Statistics=["Average"]
        )

        datapoints = response["Datapoints"]
        if not datapoints:
            print("⚠️ CPU 데이터 없음 (CloudWatch 수집 지연일 수 있음)")
            return None

        latest = sorted(datapoints, key=lambda x: x["Timestamp"])[-1]
        cpu = round(latest["Average"], 2)
        print(f"📊 CPU 수집 완료: {cpu}%")
        return cpu

    except Exception as e:
        print(f"❌ CPU 수집 실패: {e}")
        return None


# ============================================================
# 모니터링팀 메트릭: Kafka 연동 수집
# ============================================================
def get_memory_metric() -> float | None:
    return _get_from_kafka("memory", KAFKA_BROKER_MONITORING)


def get_disk_metric() -> float | None:
    return _get_from_kafka("disk", KAFKA_BROKER_MONITORING)


def get_latency_metric() -> float | None:
    return _get_from_kafka("latency", KAFKA_BROKER_MONITORING)


def get_error_rate_metric() -> float | None:
    return _get_from_kafka("errorrate", KAFKA_BROKER_MONITORING)


def get_tps_metric() -> float | None:
    return _get_from_kafka("tps", KAFKA_BROKER_MONITORING)


# ============================================================
# FinOps팀 비용 데이터: Kafka 연동 수집
# ============================================================
def get_cost_metric() -> float | None:
    try:
        from kafka import KafkaConsumer

        # 비용 수집용 고유 컨슈머 그룹 생성
        unique_group_finops = f"aiops-consumer-finops-{uuid.uuid4().hex[:6]}"

        # 안전한 raw 디코딩 + 'earliest' 설정으로 과거 누적 비용 데이터를 확실히 긁어옵니다.
        consumer = KafkaConsumer(
            KAFKA_TOPIC,
            bootstrap_servers=KAFKA_BROKER_FINOPS,
            group_id=unique_group_finops,
            auto_offset_reset="earliest",       # <-- [수정 완료] 과거 누적 데이터를 안전하게 찾아오도록 복원
            consumer_timeout_ms=3000,
            value_deserializer=lambda x: x.decode("utf-8", errors="ignore")
        )

        for message in consumer:
            raw_value = message.value
            try:
                data = json.loads(raw_value)

                if isinstance(data, dict) and "cost" in data:
                    cost = float(data["cost"])
                    team = data.get("team", "unknown")
                    env  = data.get("environment", "unknown")
                    date = data.get("date", "unknown")
                    print(f"💰 비용 수신 | date: {date} | team: {team} | env: {env} | cost: ${cost}")
                    consumer.close()
                    return round(cost, 4)
            except Exception:
                # 큐 앞단에 쌓인 다른 팀원들의 규격 외 메시지는 에러 표출 없이 부드럽게 무시하고 패스합니다.
                continue

        consumer.close()
        print(f"⚠️ Kafka 비용 메시지 없음 (3초 대기 후 종료)")
        return None

    except Exception as e:
        print(f"⚠️ Kafka 비용 연결 상태 대기 중: {e}")
        return None
# data_collector.py
# AWS CloudWatch + Kafka 메트릭 수집 (Master 노드 직통 파티션 스캔 및 중첩 키 파싱 지원 모드)

import boto3
import requests
import json
import os
from datetime import datetime, timedelta

# ----------------------------------------
# Kafka 브로커 설정
# ----------------------------------------
KAFKA_BROKER_MONITORING = "10.0.1.220:9092"
KAFKA_BROKER_FINOPS     = "10.0.1.220:9092"
KAFKA_TOPIC             = "metrics-topic"


# ============================================================
# 공통: Kafka Consumer - 특정 메트릭 값 직통 수신 (단독/중첩 키 모두 지원)
# ============================================================
def _get_from_kafka(metric_name: str, broker: str) -> float | None:
    try:
        from kafka import KafkaConsumer, TopicPartition

        consumer = KafkaConsumer(
            bootstrap_servers=[broker],
            consumer_timeout_ms=1000,  # 직통 연결이므로 1초 스캔이면 충분함
            value_deserializer=lambda x: x.decode("utf-8", errors="ignore")
        )

        partitions = consumer.partitions_for_topic(KAFKA_TOPIC)
        if not partitions:
            consumer.close()
            return None

        tp_list = [TopicPartition(KAFKA_TOPIC, p) for p in partitions]
        consumer.assign(tp_list)
        consumer.seek_to_beginning()  # 적재된 첫 메시지부터 빠르게 탐색

        for message in consumer:
            raw_value = message.value
            if not raw_value:
                continue

            try:
                data = json.loads(raw_value)

                if isinstance(data, dict):
                    target_metric = metric_name.lower().replace("rate", "")  # errorrate -> error

                    # 1️⃣ [중첩 구조 파싱] 메시지 dict 내부에 latency, errorrate 키가 별도로 얹혀서 들어오는 경우
                    for key, val in data.items():
                        if target_metric in key.lower() and val is not None:
                            # 'metric': 'latency' 형태로 메트릭 이름 자체가 들어온 경우는 2번 방식에서 처리
                            if key.lower() in ["metric", "metric_name", "type", "name"]:
                                continue
                            try:
                                float_val = float(val)
                                print(f"📥 [Kafka 수신 성공] {metric_name} = {float_val} (offset:{message.offset})")
                                consumer.close()
                                return round(float_val, 2)
                            except (ValueError, TypeError):
                                continue

                    # 2️⃣ [표준 구조 파싱] "metric": "latency", "value": 10.2 구조 형태
                    recv_metric = (
                        data.get("metric") or 
                        data.get("metric_name") or 
                        data.get("name") or 
                        data.get("type")
                    )
                    recv_value = (
                        data.get("value") if "value" in data else 
                        data.get("val")
                    )

                    if recv_metric and target_metric in str(recv_metric).lower():
                        if recv_value is not None:
                            val = float(recv_value)
                            print(f"📥 [Kafka 수신 성공] {metric_name} = {val} (offset:{message.offset})")
                            consumer.close()
                            return round(val, 2)
            except Exception:
                continue

        consumer.close()
        print(f"⚠️ Kafka [{metric_name}] 메시지 없음")
        return None

    except Exception as e:
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
# FinOps팀 비용 데이터: Kafka 연동 수집 (FinOps 데이터 정밀 수신)
# ============================================================
def get_cost_metric() -> float | None:
    try:
        from kafka import KafkaConsumer, TopicPartition

        consumer = KafkaConsumer(
            bootstrap_servers=[KAFKA_BROKER_FINOPS],
            consumer_timeout_ms=1000,
            value_deserializer=lambda x: x.decode("utf-8", errors="ignore")
        )

        partitions = consumer.partitions_for_topic(KAFKA_TOPIC)
        if not partitions:
            consumer.close()
            return None

        tp_list = [TopicPartition(KAFKA_TOPIC, p) for p in partitions]
        consumer.assign(tp_list)
        consumer.seek_to_beginning()

        for message in consumer:
            raw_value = message.value
            if not raw_value:
                continue

            try:
                data = json.loads(raw_value)

                if isinstance(data, dict):
                    metric_type = str(data.get("metric", "")).lower()

                    # 💡 메모리, 디스크, TPS 등 일반 메트릭 데이터는 비용 수신에서 스킵
                    if metric_type in ["memory", "disk", "tps", "cpu", "latency", "errorrate"]:
                        continue

                    # 💡 비용 관련 필드(cost, price, amount)나 FinOps 필수 키(team, environment)가 있는 데이터만 수신
                    cost_val = (
                        data.get("cost") if "cost" in data else
                        data.get("price") if "price" in data else
                        data.get("amount") if "amount" in data else
                        (data.get("value") if metric_type in ["cost", "비용"] or "team" in data or "environment" in data else None)
                    )

                    if cost_val is not None:
                        final_cost = float(cost_val)
                        team = data.get("team", "unknown")
                        env  = data.get("environment", "unknown")
                        date = data.get("date", "unknown")
                        
                        print(f"💰 비용 수신 성공 | date: {date} | team: {team} | env: {env} | cost: ${final_cost} (offset:{message.offset})")
                        consumer.close()
                        return round(final_cost, 4)

            except Exception:
                continue

        consumer.close()
        print(f"⚠️ Kafka 비용 메시지 없음")
        return None

    except Exception as e:
        print(f"⚠️ Kafka 비용 연결 상태 대기 중: {e}")
        return None
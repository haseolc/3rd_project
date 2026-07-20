import json
from kafka import KafkaProducer

KAFKA_BROKER = "10.0.1.220:9092"
KAFKA_TOPIC = "metrics-topic"

producer = KafkaProducer(
    bootstrap_servers=[KAFKA_BROKER],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

def send_metric(metric_name, value, latency=None, errorrate=None):
    try:
        data = {
            "metric": metric_name,
            "value": value,
            "latency": latency,
            "errorrate": errorrate
        }
        producer.send(KAFKA_TOPIC, value=data)
        producer.flush()
        print(f"✅ 전송 성공: {data}")
    except Exception as e:
        print(f"❌ 전송 실패: {e}")

if __name__ == "__main__":
    send_metric("memory", 85.5, latency=10.2, errorrate=0.01)
    send_metric("disk", 42.0, latency=5.1, errorrate=0.0)
    send_metric("tps", 120.5, latency=2.3, errorrate=0.05)
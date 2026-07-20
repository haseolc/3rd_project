import time
import json
import requests
from kafka import KafkaProducer

PROMETHEUS_URL = 'http://10.0.1.220:9090'
KAFKA_BROKER = 'localhost:9092'
TOPIC = 'metrics_stream' # 토픽을 다시 metrics_stream으로 맞춥니다.

producer = KafkaProducer(
    bootstrap_servers=[KAFKA_BROKER],
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    acks='all'
)

def fetch_metrics():
    query = 'up'
    try:
        response = requests.get(f'{PROMETHEUS_URL}/api/v1/query', params={'query': query}, timeout=10)
        return response.json().get('data', {}).get('result', [])
    except Exception as e:
        print(f"❌ 프로메테우스 연결 오류: {e}")
        return []

while True:
    data = fetch_metrics()
    if data:
        try:
            for entry in data:
                future = producer.send(TOPIC, value=entry)

                # 💡 핵심: 카프카가 진짜로 받았다고 응답할 때까지 최대 10초 대기
                record_metadata = future.get(timeout=10)

            print(f"✅ 진짜 성공! 파티션: {record_metadata.partition}, 오프셋: {record_metadata.offset}")
        except Exception as e:
            # 카프카가 거절하거나 통신에 실패하면 여기서 에러가 터집니다.
            print(f"❌ 카프카 적재 실패 (진짜 에러): {e}")
    else:
        print("⚠️ 프로메테우스에서 가져온 데이터가 없습니다.")
    time.sleep(10)
from confluent_kafka import Consumer
import json

conf = {
    'bootstrap.servers': '127.0.0.1:9092',
    'group.id': 'metrics-group',
    'auto.offset.reset': 'earliest'
}

c = Consumer(conf)
c.subscribe(['metrics-topic'])

print("Consumer 시작됨. 데이터 수신 대기 중...", flush=True)

try:
    while True:
        msg = c.poll(1.0)
        if msg is None: continue
        if msg.error():
            print(f"Consumer error: {msg.error()}")
            continue

        data = json.loads(msg.value().decode('utf-8'))
        print(f"수신된 데이터: {data}", flush=True)
except KeyboardInterrupt:
    pass
finally:
    c.close()
from confluent_kafka import Consumer, Producer
import json
c = Consumer({'bootstrap.servers': '127.0.0.1:9092', 'group.id': 'bridge', 'auto.offset.reset': 'earliest'})
p = Producer({'bootstrap.servers': '127.0.0.1:9092'})
c.subscribe(['metrics-topic'])
print("Bridge 시작", flush=True)
while True:
    msg = c.poll(1.0)
    if msg is None: continue
    data = json.loads(msg.value().decode('utf-8'))
    data['bridge'] = 'processed'
    p.produce('processed-metrics', json.dumps(data).encode('utf-8'))
    p.poll(0)
    print(f"중계 완료: {data}", flush=True)
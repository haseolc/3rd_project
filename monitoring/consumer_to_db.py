from confluent_kafka import Consumer
import json, psycopg2
c = Consumer({'bootstrap.servers': '127.0.0.1:9092', 'group.id': 'db-saver', 'auto.offset.reset': 'earliest'})
c.subscribe(['processed-metrics'])
conn = psycopg2.connect(host="project-postgres-db.ctcqu224uqrj.ap-northeast-2.rds.amazonaws.com", database="projectdb", user="postgres", password="postgres1234")
cur = conn.cursor()
print("DB Consumer 시작", flush=True)
while True:
    msg = c.poll(1.0)
    if msg is None: continue
    data = json.loads(msg.value().decode('utf-8'))

    # 테이블 구조에 맞게 INSERT (metric 값을 cpu 컬럼에 저장)
    sql = "INSERT INTO metrics (cpu, mem, created_at, node_name) VALUES (%s, %s, to_timestamp(%s), %s)"
    cur.execute(sql, (data.get('value', 0), 0, data.get('timestamp'), 'worker-2'))

    conn.commit()
    print(f"DB 저장 성공: {data}", flush=True)
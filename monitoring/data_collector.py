import json
import psycopg2
from kafka import KafkaConsumer

# 💡 RDS 접속 정보 반영
DB_CONFIG = {
    "host": "project-postgres-db.ctcqu224uqrj.ap-northeast-2.rds.amazonaws.com",
    "database": "projectdb",
    "user": "postgres",
    "password": "postgres1234",
    "port": 5432
}
TABLE_NAME = "metric_logs"

# 💡 RDS 연결
try:
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    print("✅ RDS 연결 성공")
except Exception as e:
    print(f"❌ RDS 연결 실패: {e}")
    exit()

consumer = KafkaConsumer(
    'metrics_stream',
    bootstrap_servers=['10.0.1.220:9092'],
    value_deserializer=lambda x: json.loads(x.decode('utf-8'))
)

print("🚀 DB 적재 시작")

for message in consumer:
    data = message.value
    try:
        if 'metric' in data:
            query = f"INSERT INTO {TABLE_NAME} (metric_name, value) VALUES (%s, %s)"
            cur.execute(query, (data['metric'], data['value']))
        elif 'cost' in data:
            query = f"INSERT INTO {TABLE_NAME} (metric_name, value) VALUES (%s, %s)"
            cur.execute(query, ('cost', data['cost']))

        conn.commit()
        print(f"✅ 저장 완료: {data}")
    except Exception as e:
        print(f"❌ DB 저장 오류: {e}")
        conn.rollback()
import json
import os
from kafka import KafkaProducer

def json_serializer(data):
    return json.dumps(data).encode('utf-8')

def lambda_handler(event, context):
    print("1. 수집가(Lambda A)로부터 데이터 수신 완료!")
    
    # Lambda A가 넘겨준 데이터를 event에서 꺼냅니다.
    parsed_data = event.get('cost_data', [])
    
    if not parsed_data:
        return {'statusCode': 400, 'body': "데이터가 없습니다."}

    KAFKA_BOOTSTRAP_SERVERS = ['10.0.1.46:9092'] # AIOps 담당자에게 받을 카프카 IP 주소
    KAFKA_TOPIC = 'metrics-topic'            # AIOps 담당자가 파놓은 토픽 이름
    KAFKA_PASS = os.environ.get('KAFKA_PASSWORD')

    try:
        producer = KafkaProducer(
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            value_serializer=json_serializer,
            #security_protocol='SASL_PLAINTEXT',
            #sasl_mechanism='PLAIN',
            #sasl_plain_username='', 
            #sasl_plain_password=KAFKA_PASS
        )
        
        for record in parsed_data:
            producer.send(KAFKA_TOPIC, value=record)
        
        producer.flush()
        print(f"2. ✅ {len(parsed_data)}건의 데이터를 Kafka로 전송 성공!")
        return {'statusCode': 200, 'body': "Kafka 전송 성공"}
        
    except Exception as e:
        print(f"❌ Kafka 전송 실패: {e}")
        return {'statusCode': 500, 'body': str(e)}
import boto3
import time
import json
from datetime import datetime

# --- 설정 변수 ---
DATABASE_NAME = 'athenadataexports_finops_hourly_cur'
TABLE_NAME = 'data'
S3_OUTPUT_LOCATION = 's3://finops-cur-data-416170614736-us-east-1-an/athena-results/'

def json_serializer(data):
    """딕셔너리를 JSON 바이트로 변환하는 헬퍼 함수"""
    return json.dumps(data).encode('utf-8')

def lambda_handler(event, context):
    client = boto3.client('athena', region_name='us-east-1')
    
    query = f"""
        SELECT 
            COALESCE(tags['team'], '팀 미지정') AS team,
            COALESCE(tags['environment'], '환경 미지정') AS environment,
            SUM(line_item_unblended_cost) AS daily_cost
        FROM "{DATABASE_NAME}"."{TABLE_NAME}"
        WHERE CAST(line_item_usage_start_date AS DATE) = current_date - INTERVAL '1' DAY
          AND line_item_unblended_cost > 0
        GROUP BY 1, 2
        ORDER BY daily_cost DESC;
    """
    
    print("1. Athena 쿼리 실행 시작...")
    
    try:
        response = client.start_query_execution(
            QueryString=query,
            ResultConfiguration={'OutputLocation': S3_OUTPUT_LOCATION}
        )
        query_execution_id = response['QueryExecutionId']
        
        while True:
            status = client.get_query_execution(QueryExecutionId=query_execution_id)
            state = status['QueryExecution']['Status']['State']
            if state in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                break
            time.sleep(1)
            
        if state == 'SUCCEEDED':
            print("2. 쿼리 성공! 데이터 파싱 중...")
            results = client.get_query_results(QueryExecutionId=query_execution_id)
            
            parsed_data = []
            for row in results['ResultSet']['Rows'][1:]:
                data = row['Data']
                parsed_data.append({
                    'date': datetime.now().strftime('%Y-%m-%d'),
                    'team': data[0].get('VarCharValue', ''),
                    'environment': data[1].get('VarCharValue', ''),
                    'cost': float(data[2].get('VarCharValue', '0.0'))
                })
            
            print(f"3. 파싱 완료 (총 {len(parsed_data)}건). Kafka로 전송 시도...")
            
            # ==============================================================
            # 🚀 [Lambda B (Kafka 배달부) 호출 로직]
            # ==============================================================
            lambda_client = boto3.client('lambda', region_name='ap-northeast-2')
            
            # Lambda B에게 넘겨줄 짐(Payload)을 쌉니다.
            payload = {
                'cost_data': parsed_data
            }
            
            try:
                # Lambda B(finops-kafka-sender)를 비동기(Event)로 호출합니다.
                response = lambda_client.invoke(
                    FunctionName='finops-kafka-sender', # Lambda B의 이름
                    InvocationType='Event', # Event: 던지고 바로 쿨하게 잊음 (기다리지 않음)
                    Payload=json.dumps(payload)
                )
                print("4. ✅ Lambda B 호출 성공! (배달 맡김)")
                return {'statusCode': 200, 'body': "Triggered Kafka Sender successfully."}
                
            except Exception as invoke_err:
                print(f"❌ Lambda B 호출 실패: {invoke_err}")
                return {'statusCode': 500, 'body': str(invoke_err)}
            
        else:
            return {'statusCode': 500, 'body': "Athena Query Failed."}
            
    except Exception as e:
        print(f"오류 발생: {e}")
        return {'statusCode': 500, 'body': str(e)}

import boto3

def lambda_handler(event, context):
    REGION = 'ap-northeast-2' # 서울 리전
    
    ec2 = boto3.client('ec2', region_name=REGION)
    rds = boto3.client('rds', region_name=REGION)

    print("🔍 [1/2] EC2 인스턴스 검색 시작...")
    
    # 1차 필터링: 켜져있고, environment=sandbox, auto-stop=true 인 것들 먼저 가져옴
    ec2_filters = [
        {'Name': 'instance-state-name', 'Values': ['running']},
        {'Name': 'tag:environment', 'Values': ['sandbox']},
        {'Name': 'tag:auto-stop', 'Values': ['true']}
    ]
    
    ec2_to_stop = []
    try:
        ec2_response = ec2.describe_instances(Filters=ec2_filters)
        for reservation in ec2_response['Reservations']:
            for instance in reservation['Instances']:
                # 태그 리스트를 파이썬 딕셔너리로 변환하여 검사하기 쉽게 만듦
                tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                
                # 2차 필터링: created-by 태그가 'terraform'이 아닌 것만 추가 (핵심!)
                if tags.get('created-by') != 'terraform':
                    ec2_to_stop.append(instance['InstanceId'])
                    
        if ec2_to_stop:
            print(f"🛑 중지 대상 EC2 발견 ({len(ec2_to_stop)}대): {ec2_to_stop}")
            ec2.stop_instances(InstanceIds=ec2_to_stop)
        else:
            print("✅ 조건에 맞는 중지 대상 EC2가 없습니다.")
    except Exception as e:
        print(f"❌ EC2 처리 중 오류 발생: {e}")


    print("🔍 [2/2] RDS 데이터베이스 검색 시작...")
    rds_to_stop = []
    try:
        # RDS는 상태가 'available'인 것들을 가져와서 태그를 직접 검사
        rds_response = rds.describe_db_instances()
        
        for db in rds_response['DBInstances']:
            if db['DBInstanceStatus'] == 'available':
                tags = {tag['Key']: tag['Value'] for tag in db.get('TagList', [])}
                
                # 조건 검사: environment=sandbox 이고 auto-stop=true 이며 created-by!=terraform 인 것
                if tags.get('environment') == 'sandbox' and tags.get('auto-stop') == 'true' and tags.get('created-by') != 'terraform':
                    # 오로라(Aurora) 클러스터 소속인 경우 처리가 다르므로 일반 RDS만 안전하게 종료
                    if 'DBClusterIdentifier' not in db:
                        rds_to_stop.append(db['DBInstanceIdentifier'])
        
        if rds_to_stop:
            print(f"🛑 중지 대상 RDS 발견 ({len(rds_to_stop)}대): {rds_to_stop}")
            for db_id in rds_to_stop:
                rds.stop_db_instance(DBInstanceIdentifier=db_id)
        else:
            print("✅ 조건에 맞는 중지 대상 RDS가 없습니다.")
    except Exception as e:
        print(f"❌ RDS 처리 중 오류 발생: {e}")

    # 최종 결과 반환
    return {
        'statusCode': 200,
        'body': f"Task Completed. Stopped EC2s: {ec2_to_stop}, Stopped RDSs: {rds_to_stop}"
    }

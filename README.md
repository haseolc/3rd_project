# AIOps 통합 모니터링 플랫폼

AWS EC2 환경에서 실시간 이상 탐지, 성능 예측, 비용 분석을 수행하는 AIOps 플랫폼입니다.
Z-score / Isolation Forest 기반 이상 탐지, Prophet 성능 예측, 이벤트 상관 분석, Discord 알림까지 하나의 파이프라인으로 동작합니다.

---

## 전체 구조

```
[ AWS CloudWatch ]         [ Kafka (metrics-topic) ]
        ↓                          ↓
   CPU 수집                메모리 / Latency / ErrorRate / TPS / 비용 수신
        ↓                          ↓
              data_collector.py
                     ↓
               detector.py         ← Z-score + Isolation Forest 이상 탐지
                     ↓
              forecaster.py        ← Prophet 성능 예측
                     ↓
              correlator.py        ← 이벤트 상관 분석
                     ↓
             recommender.py        ← 액션 추천
                     ↓
               alert.py            ← Discord 알림
                     ↓
               main.py             ← 전체 파이프라인 실행
```

---

## 파일 구조

```
aiops/
├── main.py               # 전체 파이프라인 실행
├── detector.py           # Z-score + Isolation Forest 이상 탐지
├── forecaster.py         # Prophet 기반 성능 예측
├── correlator.py         # 이벤트 상관 분석
├── recommender.py        # 이상 탐지 → 액션 추천
├── alert.py              # Discord Webhook 알림
├── data_collector.py     # CloudWatch + Kafka 메트릭 수집
├── pretrain.py           # SMD 데이터셋 기반 사전 학습
├── test_local.py         # 로컬 테스트 (EC2 없이 동작 확인)
├── requirements.txt      # 패키지 목록
├── .env.example          # 환경변수 템플릿
└── models/               # 사전 학습된 Isolation Forest 모델
    ├── iso_cpu.pkl
    ├── iso_memory.pkl
    ├── iso_latency.pkl
    └── iso_errorrate.pkl
```

---

## 인프라 구성

| 항목 | 내용 |
|------|------|
| EC2 | k8s-master (t3.medium) |
| Region | ap-northeast-2 (서울) |
| Kafka Broker | 10.0.1.46:9092 |
| Kafka Topic | metrics-topic |
| IAM 권한 | CloudWatchReadOnlyAccess |

---

## 시작하기

### 1. 패키지 설치

```bash
pip3 install -r requirements.txt
```

### 2. 환경변수 설정

```bash
cp .env.example .env
```

`.env` 파일에 실제 값 입력:

```
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/실제_URL
```

### 3. AWS 자격증명 설정

```bash
mkdir -p ~/.aws

cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = 액세스키_ID
aws_secret_access_key = 시크릿키
EOF

cat > ~/.aws/config << EOF
[default]
region = ap-northeast-2
EOF
```

### 4. 사전 학습 실행 (최초 1회)

SMD(Server Machine Dataset) 기반으로 Isolation Forest 모델을 사전 학습합니다.

```bash
# OmniAnomaly 데이터셋 다운로드
git clone https://github.com/NetManAIOps/OmniAnomaly

# 사전 학습 실행
python3 pretrain.py
```

학습 완료 후 `models/` 폴더에 4개 모델이 생성됩니다:
```
models/iso_cpu.pkl
models/iso_memory.pkl
models/iso_latency.pkl
models/iso_errorrate.pkl
```

### 5. 로컬 테스트 (EC2 없이 Discord 알림 확인)

```bash
python3 test_local.py
```

### 6. 실제 실행

```bash
python3 main.py
```

### 7. 백그라운드 실행 (EC2 접속 끊어도 계속 실행)

```bash
nohup python3 main.py > aiops.log 2>&1 &

# 로그 실시간 확인
tail -f aiops.log
```

---

## 주요 기능

### 이상 탐지 (detector.py)

**Z-score 기반**

| 파라미터 | 기본값 | 설명 |
|---------|--------|------|
| `window_size` | 10 | 최근 몇 개 데이터 기준 |
| `threshold` | 2 | Z-score 임계값 |

**Isolation Forest 기반**

| 파라미터 | 기본값 | 설명 |
|---------|--------|------|
| `n_estimators` | 100 | 트리 개수 |
| `contamination` | 0.0416 | 이상 데이터 비율 (SMD 실측 기준) |
| `min_samples` | 50 | 학습 최소 데이터 수 |

---

### 성능 예측 (forecaster.py)

Prophet 기반으로 10분 후 성능을 예측하여 장애를 사전에 방지합니다.

| 메트릭 | WARNING | CRITICAL |
|--------|---------|----------|
| CPU | 70% | 85% |
| 메모리 | 75% | 90% |
| Latency | 200ms | 500ms |
| ErrorRate | 1% | 5% |

---

### 이벤트 상관 분석 (correlator.py)

| 시나리오 | 조건 | 추론 |
|---------|------|------|
| 서버 과부하 | CPU + Latency 동시 이상 | 트래픽 급증 또는 무한 루프 |
| 장애 발생 | ErrorRate + Latency 동시 이상 | 외부 API 장애 또는 DB 문제 |
| 트래픽 급증 | TPS + CPU 동시 이상 | 갑작스러운 사용자 유입 |
| 리소스 고갈 | 메모리 + CPU 동시 이상 | 메모리 누수 또는 배치 작업 |

---

### 수집 메트릭 현황 (data_collector.py)

| 메트릭 | 수집 방법 | 상태 |
|--------|---------|------|
| CPU 사용률 | AWS CloudWatch | ✅ 활성화 |
| 메모리 사용률 | Kafka (metrics-topic) | ⏳ 모니터링팀 연동 후 |
| 디스크 사용률 | Kafka (metrics-topic) | ⏳ 모니터링팀 연동 후 |
| Latency (p95) | Kafka (metrics-topic) | ⏳ 모니터링팀 연동 후 |
| Error Rate | Kafka (metrics-topic) | ⏳ 모니터링팀 연동 후 |
| TPS | Kafka (metrics-topic) | ⏳ 모니터링팀 연동 후 |
| AWS 비용 | Kafka (metrics-topic) | ⏳ FinOps팀 연동 후 |

---

## 모니터링팀 연동 방법

Prometheus URL과 job 이름을 받으면 `main.py`에서 주석 해제:

```python
collectors = {
    "CPU":        get_cpu_metric,
    "메모리":     get_memory_metric,     # 주석 해제
    "디스크":     get_disk_metric,       # 주석 해제
    "Latency":    get_latency_metric,    # 주석 해제
    "ErrorRate":  get_error_rate_metric, # 주석 해제
    "TPS":        get_tps_metric,        # 주석 해제
}
```

---

## FinOps팀 연동 방법

Kafka 비용 데이터 연동 후 `main.py`에서 주석 해제:

```python
collectors = {
    ...
    "비용": get_cost_metric,  # 주석 해제
}
```

---

## 사전 학습 모델 정보

| 모델 | 학습 데이터 | 데이터 수 | 스케일 |
|------|-----------|---------|--------|
| iso_cpu.pkl | SMD train+test | 약 141만개 | 0~100% |
| iso_memory.pkl | SMD train+test | 약 141만개 | 0~100% |
| iso_latency.pkl | SMD train+test | 약 141만개 | 0~100% |
| iso_errorrate.pkl | SMD train+test | 약 141만개 | 0~100% |

---

## 주의사항

- `.env` 파일은 절대 GitHub에 커밋하지 마세요
- `models/` 폴더는 용량이 크므로 `.gitignore`에 추가 권장
- `OmniAnomaly/` 폴더도 `.gitignore`에 추가
- CloudWatch 메트릭은 최대 15분 지연될 수 있습니다
- Isolation Forest는 50개 이상 데이터가 쌓인 후 동작합니다
- Prophet 예측은 30개 이상 데이터가 쌓인 후 동작합니다

---

## .gitignore 권장 설정

```
.env
models/
OmniAnomaly/
__pycache__/
*.pyc
*.log
~/.aws/
```

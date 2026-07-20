# AWS 기반 FinOps · AIOps · DR 통합 운영 플랫폼

AWS 환경의 **인프라 상태와 비용 데이터를 통합 분석**하고, 이상 상황에 대한 알림·자동 조치·재해 복구를 지원하는 클라우드 운영 플랫폼입니다.

Terraform과 Ansible을 활용해 AWS 인프라와 Kubernetes 클러스터를 자동으로 구성하며, Prometheus·Kafka·PostgreSQL 기반 데이터 파이프라인을 통해 운영 메트릭과 비용 데이터를 분석합니다.

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [아키텍처 다이어그램](#2-아키텍처-다이어그램)
3. [사용 기술 스택 및 버전](#3-사용-기술-스택-및-버전)
4. [실행 및 배포 방법](#4-실행-및-배포-방법)
5. [환경 변수 및 Secret 설정 방법](#5-환경-변수-및-secret-설정-방법)
6. [디렉터리 구조](#6-디렉터리-구조)
7. [검증 결과](#7-검증-결과)
8. [팀 역할](#8-팀-역할)
9. [보안 및 운영 주의사항](#9-보안-및-운영-주의사항)

---

# 1. 프로젝트 개요

## 1.1 프로젝트 배경

클라우드 환경이 복잡해질수록 시스템 장애와 비용 증가를 개별적으로 관리하기 어려워집니다.

기존 운영 방식에는 다음과 같은 문제가 존재합니다.

- 인프라 생성과 서버 설정의 반복 작업
- 시스템 장애 징후와 비용 이상 현상의 분리된 관리
- 수동 장애 대응으로 인한 복구 시간 증가
- 장기 AWS Access Key 사용에 따른 보안 위험
- 리전 장애 발생 시 서비스 연속성 확보의 어려움
- 인프라 상태, 비용, 보안 이벤트를 통합적으로 판단하기 어려움

본 프로젝트는 이러한 문제를 해결하기 위해 **FinOps, AIOps, CI/CD, Security, Monitoring, DR을 통합한 AWS 기반 운영 플랫폼**을 구축하는 것을 목표로 합니다.

---

## 1.2 프로젝트 목표

- Terraform 기반 AWS 인프라 자동 생성 및 삭제
- Ansible 기반 Kubernetes 클러스터 자동 구성
- GitHub Actions 기반 End-to-End CI/CD 구축
- Prometheus 기반 Kubernetes 운영 메트릭 수집
- Kafka 기반 메트릭 및 비용 데이터 스트리밍
- PostgreSQL 기반 분석 데이터 저장
- 통합 AIOps 모듈을 통한 인프라·비용 이상 분석
- Decision Engine 기반 자동 조치 및 운영 권고
- Discord 기반 ChatOps 알림 제공
- AWS KMS·Secrets Manager·ESO 기반 비밀정보 관리
- Checkov·Trivy 기반 배포 전 Security Gate 구성
- 서울–오사카 Active-Passive DR 환경 구축

---

## 1.3 주요 기능

### Infrastructure as Code

- Terraform을 이용한 AWS 인프라 코드화
- VPC, Subnet, Security Group, EC2, ALB 등 자동 생성
- S3 Remote State 기반 Terraform 상태 중앙 관리
- Provision과 Destroy가 동일한 State를 공유하도록 구성

### CI/CD

- GitHub Actions 기반 인프라 생성·구성·검증 자동화
- Terraform Output 기반 EC2 IP 동적 조회
- Ansible Dynamic Inventory 자동 생성
- Kubernetes 클러스터 및 플랫폼 구성 자동화
- GitHub Hosted Runner의 공인 IP만 `/32`로 임시 허용
- 배포 완료 후 임시 SSH Security Group 규칙 자동 회수

### Kubernetes

- EC2 기반 Self-managed Kubernetes
- Control Plane 1대, Worker 3대 구성
- kubeadm 기반 클러스터 구성
- containerd 기반 Container Runtime
- Cilium CNI 기반 Pod 네트워크 및 NetworkPolicy 적용
- Application, Monitoring, Kafka, ESO 워크로드 통합 운영

### Monitoring

- Prometheus 기반 Kubernetes 메트릭 수집
- Grafana 기반 대시보드 시각화
- Alertmanager 기반 운영 이벤트 전달
- Node Exporter 기반 노드 메트릭 수집
- kube-state-metrics 기반 Kubernetes 리소스 상태 수집

### FinOps · AIOps

- AWS 비용 데이터와 Kubernetes 운영 메트릭 수집
- Kafka를 통한 데이터 스트리밍
- PostgreSQL 기반 분석 데이터 저장
- 통합 AIOps 모듈에서 메트릭과 비용 데이터 종합 분석
- Decision Engine을 통한 대응 정책 판단
- AIOps 이상 상황은 Kubernetes 자동 조치 수행
- FinOps 결과는 Discord로 권고·알림을 제공하고 운영자가 수동 조치

### Security

- AWS KMS Customer Managed Key 기반 Secret 암호화
- AWS Secrets Manager 기반 PostgreSQL 접속정보 중앙 관리
- External Secrets Operator를 통한 Kubernetes Secret 동기화
- GitHub OIDC·AWS STS 기반 단기 자격 증명 사용
- Checkov·Trivy 기반 CI/CD Security Gate 구성
- Kubernetes RBAC, PSA, SecurityContext 적용
- Cilium NetworkPolicy 기반 Pod 간 통신 제어
- AWS WAF 기반 비정상 요청 차단
- CloudTrail 및 S3 기반 감사 로그 관리

### Disaster Recovery

- 서울 Primary Region과 오사카 DR Region 구성
- Active-Passive 방식 적용
- PostgreSQL Primary → Read Replica 리전 간 복제
- DR 전환 시 오사카 Kubernetes 환경 활성화
- Application 재배포 및 Kafka 재구축
- Route 53 Failover Routing을 통한 트래픽 전환

---

## 1.4 주요 운영 흐름

```text
Kubernetes Cluster
        │
        ▼
Prometheus
        │
        ▼
Kafka ◀──── AWS 비용 데이터
        │
        ▼
PostgreSQL
        │
        ▼
통합 AIOps 분석
        │
        ▼
Decision Engine
        ├─ AIOps 자동 조치 → Kubernetes Cluster
        └─ 운영 알림 / FinOps 권고 → Discord
```

### 운영 데이터 흐름

1. Prometheus가 Kubernetes 노드·Pod·서비스 메트릭을 수집합니다.
2. 수집된 메트릭은 Kafka로 전달됩니다.
3. AWS 비용 데이터도 Kafka로 전달됩니다.
4. Kafka가 수집한 데이터는 PostgreSQL에 저장됩니다.
5. 통합 AIOps 모듈이 메트릭과 비용 데이터를 함께 분석합니다.
6. Decision Engine이 이상 유형과 대응 방식을 판단합니다.
7. AIOps 정책은 Kubernetes Cluster에 자동 조치를 수행합니다.
8. 운영 알림과 FinOps 권고는 Discord로 전달됩니다.

---

## 1.5 AIOps 자동 조치

Decision Engine은 분석 결과에 따라 다음과 같은 자동 조치를 수행할 수 있습니다.

- Scale Out
- Scale In
- Pod Restart
- Rollback
- Traffic Distribution

FinOps 분석 결과는 비용과 관련된 의사결정이므로 자동으로 인프라를 변경하지 않고, Discord를 통해 운영자에게 권고·알림만 전달합니다.

---

## 1.6 DR 구성

| 구분 | 구성 |
|---|---|
| Primary Region | 서울 `ap-northeast-2` |
| DR Region | 오사카 `ap-northeast-3` |
| 운영 방식 | Active-Passive |
| Primary VPC | `10.0.0.0/16` |
| DR VPC | `10.1.0.0/16` |
| Database | PostgreSQL Primary → Read Replica |
| Application | DR 전환 시 오사카 리전에 재배포 |
| Kafka | DR 전환 시 오사카 리전에 재구축 |
| Traffic | Route 53 Failover Routing을 통해 오사카 ALB로 전환 |

### DR 전환 흐름

```text
서울 Primary Region 장애
        │
        ▼
운영자 DR 전환 판단
        │
        ▼
Terraform + Ansible 수동 실행
        │
        ▼
오사카 Kubernetes 환경 활성화
        │
        ├─ Control Plane 1대
        ├─ Worker 2대
        ├─ Cilium 설치
        ├─ External Secrets Operator 구성
        ├─ Application 재배포
        └─ Kafka 재구축
        │
        ▼
ALB Health Check 및 Smoke Test
        │
        ▼
Route 53 Failover Traffic 전환
```

---

# 2. 아키텍처 다이어그램

<img width="2398" height="1014" alt="image" src="https://github.com/user-attachments/assets/14e563c4-da66-49e4-a02d-d5ee27e24d6f" />
<img width="13524" height="5692" alt="image" src="https://github.com/user-attachments/assets/c08fe1a7-54e6-4f3a-a6e2-a500c6a88b03" />



## 2.1 아키텍처 핵심 구성

- 사용자는 Route 53을 통해 서울 Primary 환경으로 접근합니다.
- AWS WAF Web ACL은 ALB에 연결되어 외부 요청을 검사합니다.
- ALB는 NodePort와 Kubernetes Service를 통해 Application Pod로 요청을 전달합니다.
- Kubernetes Cluster는 Control Plane 1대와 Worker 3대로 구성됩니다.
- Cilium CNI가 Pod 네트워크와 NetworkPolicy를 담당합니다.
- External Secrets Operator가 AWS Secrets Manager의 Secret을 조회합니다.
- Prometheus가 Kubernetes 운영 메트릭을 수집합니다.
- 수집된 메트릭과 AWS 비용 데이터는 Kafka로 전달됩니다.
- Kafka 데이터는 PostgreSQL에 저장됩니다.
- 통합 AIOps 모듈이 인프라 상태와 비용 데이터를 함께 분석합니다.
- Decision Engine이 자동 조치 또는 운영자 권고 여부를 판단합니다.
- 장애 발생 시 오사카 DR 환경을 활성화합니다.
- PostgreSQL 데이터는 서울 Primary에서 오사카 Read Replica로 복제됩니다.
- Kafka는 DR 전환 시 오사카 리전에 재구축됩니다.
- Route 53 Failover Routing을 통해 오사카 ALB로 트래픽을 전환합니다.

---

# 3. 사용 기술 스택 및 버전

## 3.1 기술 스택

| 영역 | 기술 |
|---|---|
| Cloud & Networking | AWS, EC2, VPC, ALB, Route 53, AWS WAF |
| OS & Runtime | Ubuntu, containerd, Python |
| Container Platform | Kubernetes, kubeadm, Cilium, External Secrets Operator |
| IaC & Automation | Terraform, Ansible |
| CI/CD | GitHub Actions, GitHub OIDC, AWS STS |
| Data Platform | Apache Kafka, PostgreSQL |
| Observability | Prometheus, Grafana, Alertmanager, Node Exporter, kube-state-metrics |
| Security | AWS KMS, AWS Secrets Manager, Checkov, Trivy, CloudTrail |
| Collaboration & Tools | GitHub, Discord, VS Code, draw.io |

---

## 3.2 확인된 운영 버전

| 영역 | 기술 | 버전 또는 기준 |
|---|---|---|
| Cloud | AWS | Seoul `ap-northeast-2`, Osaka `ap-northeast-3` |
| OS | Ubuntu | `22.04.2 LTS` |
| Container Runtime | containerd | `2.2.1` |
| Container Orchestration | Kubernetes | `v1.30.14` |
| Cluster Bootstrap | kubeadm | Kubernetes `v1.30.14` 기준 |
| Programming Language | Python | Python 3.x |
| IaC | Terraform | Workflow 및 설치 스크립트 기준 |
| Configuration Management | Ansible | Workflow 및 설치 스크립트 기준 |
| CNI | Cilium | Kubernetes 배포 설정 기준 |
| Messaging | Apache Kafka | Kubernetes 배포 설정 기준 |
| Database | PostgreSQL | Primary / Read Replica 구성 |
| Monitoring | Prometheus | Kubernetes 배포 설정 기준 |
| Visualization | Grafana | Kubernetes 배포 설정 기준 |
| Alerting | Alertmanager | Kubernetes 배포 설정 기준 |
| Security Scan | Checkov | GitHub Actions Workflow 기준 |
| Vulnerability Scan | Trivy | GitHub Actions Workflow 기준 |
| Secret Delivery | External Secrets Operator | Kubernetes 배포 설정 기준 |

> Terraform, Ansible, Cilium, Kafka, PostgreSQL, Prometheus, Grafana 등의 정확한 버전은 각 Workflow, Manifest, Helm Values 또는 설치 스크립트를 기준으로 확인합니다.

---

## 3.3 Kubernetes 구성

| 항목 | 구성 |
|---|---|
| Cluster Type | EC2 기반 Self-managed Kubernetes |
| Control Plane | 1대 |
| Worker | 3대 |
| Cluster Bootstrap | kubeadm |
| Container Runtime | containerd |
| CNI | Cilium |
| Secret Sync | External Secrets Operator |
| External Traffic | ALB → NodePort → Service → Pod |
| Primary Region | `ap-northeast-2` |
| DR Region | `ap-northeast-3` |

---

## 3.4 주요 AWS 서비스

- Amazon EC2
- Amazon VPC
- Application Load Balancer
- Amazon Route 53
- AWS WAF
- AWS IAM
- AWS STS
- AWS KMS
- AWS Secrets Manager
- AWS CloudTrail
- Amazon S3

---

# 4. 실행 및 배포 방법

## 4.1 사전 요구사항

로컬에서 프로젝트를 검증하거나 관리하려면 다음 도구가 필요합니다.

- Git
- AWS CLI
- Terraform
- Ansible
- kubectl
- Python 3
- SSH Client

---

## 4.2 저장소 복제

```bash
git clone https://github.com/haseolc/3rd_project.git
cd 3rd_project
```

현재 Git Branch를 확인합니다.

```bash
git branch
```

원격 저장소의 최신 내용을 가져옵니다.

```bash
git pull origin main
```

---

## 4.3 AWS CLI 인증 확인

본 프로젝트의 로컬 AWS CLI 작업은 `team-leader` Profile을 기준으로 합니다.

```bash
aws sts get-caller-identity \
  --profile team-leader
```

Primary Region을 확인합니다.

```bash
aws configure get region \
  --profile team-leader
```

정상 설정값:

```text
ap-northeast-2
```

---

## 4.4 GitHub Actions Workflow

| Workflow | 파일 | 역할 |
|---|---|---|
| Infrastructure Provision | `.github/workflows/infra-provision.yml` | AWS 인프라 생성 및 Kubernetes 구성 |
| Infrastructure Destroy | `.github/workflows/infra-destroy.yml` | 생성된 AWS 인프라 삭제 |
| Infrastructure CI | `.github/workflows/infra-ci.yml` | Terraform 및 인프라 코드 검증 |
| Security Scan | `.github/workflows/security-scan.yml` | Checkov·Trivy 기반 보안 검증 |

---

## 4.5 Infrastructure Provision

GitHub Repository에서 다음 순서로 실행합니다.

```text
GitHub Repository
→ Actions
→ Infrastructure Provision
→ Run workflow
→ confirm_provision: yes
```

Provision Workflow는 다음 순서로 실행됩니다.

```text
Security Gate
→ GitHub OIDC 인증
→ AWS STS 단기 자격 증명 발급
→ Terraform Init
→ Terraform Validate
→ Terraform Plan
→ Terraform Apply
→ EC2 Public IP 동적 조회
→ GitHub Runner Public IP 조회
→ SSH 22번 포트 /32 임시 허용
→ Ansible Dynamic Inventory 생성
→ Kubernetes 설치
→ Worker Node Join
→ Cilium 설치
→ Monitoring 및 플랫폼 배포
→ Application 및 Smoke Test 배포
→ Kubernetes Node Ready 검증
→ ALB Health Check
→ 임시 SSH Security Group 규칙 회수
```

---

## 4.6 Infrastructure Destroy

GitHub Repository에서 다음 순서로 실행합니다.

```text
GitHub Repository
→ Actions
→ Infrastructure Destroy
→ Run workflow
→ confirm_destroy: destroy
```

Destroy Workflow는 S3 Remote State를 기준으로 실제 생성된 AWS 리소스를 식별하여 삭제합니다.

```text
S3 Remote State 조회
→ Terraform Init
→ Terraform Plan 확인
→ Terraform Destroy
→ 삭제 결과 검증
```

---

## 4.7 Terraform 로컬 검증

Terraform 디렉터리로 이동합니다.

```bash
cd terraform
```

Terraform 코드 포맷을 확인합니다.

```bash
terraform fmt -check -recursive
```

Terraform 초기화를 수행합니다.

```bash
terraform init
```

Terraform 코드 유효성을 검증합니다.

```bash
terraform validate
```

실제 변경 예정 리소스를 확인합니다.

```bash
terraform plan
```

> 실제 운영 인프라 생성은 Remote State 충돌 방지를 위해 GitHub Actions Workflow 사용을 권장합니다.

---

## 4.8 Ansible 검증

Ansible Playbook 구문을 확인합니다.

```bash
ansible-playbook \
  --syntax-check \
  -i ansible/inventory.ini \
  ansible/playbook.yml
```

Inventory를 확인합니다.

```bash
ansible-inventory \
  -i ansible/inventory.ini \
  --graph
```

> 실제 Inventory 파일명과 Playbook 경로는 저장소 구조에 맞게 수정합니다.

---

## 4.9 Kubernetes 상태 확인

Master Node에 접속합니다.

```bash
ssh \
  -i ~/.ssh/k8s-key.pem \
  ubuntu@<MASTER_PUBLIC_IP>
```

Kubernetes Node 상태를 확인합니다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf \
kubectl get nodes -o wide
```

정상 상태 예시:

```text
NAME           STATUS   ROLES           VERSION
k8s-master     Ready    control-plane   v1.30.14
k8s-worker-1   Ready    <none>          v1.30.14
k8s-worker-2   Ready    <none>          v1.30.14
k8s-worker-3   Ready    <none>          v1.30.14
```

전체 Namespace의 Pod 상태를 확인합니다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf \
kubectl get pods -A
```

전체 Service를 확인합니다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf \
kubectl get service -A
```

Deployment 상태를 확인합니다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf \
kubectl get deployment -A
```

---

## 4.10 External Secrets 상태 확인

ExternalSecret을 확인합니다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf \
kubectl get externalsecret -A
```

정상 상태 예시:

```text
NAMESPACE      NAME                     STORE                  STATUS         READY
ops-platform   postgresql-credentials   aws-secrets-manager    SecretSynced   True
```

생성된 Kubernetes Secret을 확인합니다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf \
kubectl get secret \
  -n ops-platform
```

Secret Metadata만 확인합니다.

```bash
sudo KUBECONFIG=/etc/kubernetes/admin.conf \
kubectl describe secret \
  postgresql-credentials \
  -n ops-platform
```

> Secret 데이터의 실제 값을 평문으로 출력하거나 로그에 기록하지 않습니다.

---

## 4.11 Security Scan

Checkov로 Terraform 코드를 검사합니다.

```bash
checkov -d terraform
```

Checkov로 Kubernetes Manifest를 검사합니다.

```bash
checkov -d k8s
```

Checkov로 Ansible 코드를 검사합니다.

```bash
checkov -d ansible
```

Trivy로 Repository Secret을 검사합니다.

```bash
trivy fs \
  --scanners secret \
  .
```

Trivy로 IaC 설정을 검사합니다.

```bash
trivy config .
```

민감정보 패턴을 검사합니다.

```bash
git grep -nEi \
'AKIA[0-9A-Z]{16}|secret[_-]?key|private[_-]?key|password'
```

Terraform 생성 파일을 검사합니다.

```bash
find . \
  \( \
    -name '*.tfplan' \
    -o -name 'terraform.tfstate' \
    -o -name 'terraform.tfstate.*' \
    -o -name '.terraform' \
  \)
```

Git Diff 오류를 검사합니다.

```bash
git diff --check
```

---

# 5. 환경 변수 및 Secret 설정 방법

## 5.1 설정 원칙

- AWS Access Key와 Secret Key를 GitHub에 장기 저장하지 않습니다.
- GitHub Actions는 OIDC와 AWS STS를 이용해 단기 자격 증명을 발급받습니다.
- PostgreSQL 비밀번호는 코드와 Terraform State에 저장하지 않습니다.
- 비밀정보는 AWS Secrets Manager에서 중앙 관리합니다.
- External Secrets Operator를 통해 Kubernetes Secret으로 전달합니다.
- `.env`, PEM Key, Terraform State는 Git에 커밋하지 않습니다.

---

## 5.2 GitHub Repository 설정

GitHub Repository에서 다음 메뉴로 이동합니다.

```text
Settings
→ Secrets and variables
→ Actions
```

## 5.3 GitHub OIDC 설정

GitHub Actions는 장기 AWS Access Key 대신 OIDC를 사용합니다.

OIDC Provider 기준:

```text
Provider URL: https://token.actions.githubusercontent.com
Audience: sts.amazonaws.com
```

Trust Policy는 Repository와 Branch를 제한합니다.

```text
Repository: haseolc/3rd_project
Branch: main
```

Workflow 권한 예시:

```yaml
permissions:
  id-token: write
  contents: read
```

AWS 인증 예시:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@<PINNED_SHA>
  with:
    role-to-assume: ${{ vars.AWS_PROVISION_ROLE_ARN }}
    aws-region: ${{ vars.AWS_REGION }}
```

> GitHub Actions는 가능한 경우 Commit SHA로 Pinning합니다.

---

## 5.4 Terraform Remote State

Terraform State는 S3 Bucket에 중앙 저장합니다.

```text
Bucket: ${TF_STATE_BUCKET}
Key: 3rd_project/terraform.tfstate
Region: ap-northeast-2
```

Terraform Backend 예시:

```hcl
terraform {
  backend "s3" {}
}
```

Terraform 초기화 예시:

```bash
terraform init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=3rd_project/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}"
```

Terraform State 관련 파일은 Git에 커밋하지 않습니다.

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
```

---

## 5.5 Security Terraform State

보안 리소스는 `terraform-security/` 디렉터리에서 별도 State로 관리합니다.

주요 관리 리소스:

- AWS KMS Customer Managed Key
- KMS Alias
- AWS Secrets Manager Secret
- Secret 관련 IAM Policy
- External Secrets Operator용 권한

일반 인프라 State와 보안 State를 분리하여 비밀정보와 보안 리소스의 변경 범위를 제한합니다.

---

## 5.6 AWS Secrets Manager

PostgreSQL 접속정보는 다음 Secret에서 관리합니다.

```text
3rd-project/sandbox/postgresql
```

Secret 데이터 구조:

```json
{
  "username": "platform_app",
  "password": "<자동 생성 비밀번호>",
  "database": "ops_platform",
  "port": "5432"
}
```

Secret 생성 예시:

```bash
aws secretsmanager create-secret \
  --name 3rd-project/sandbox/postgresql \
  --kms-key-id <KMS_KEY_ARN> \
  --secret-string '{
    "username":"platform_app",
    "password":"<SECURE_PASSWORD>",
    "database":"ops_platform",
    "port":"5432"
  }' \
  --profile team-leader \
  --region ap-northeast-2
```

> 실제 비밀번호는 README, Source Code, Terraform State 또는 GitHub Actions 로그에 기록하지 않습니다.

---

## 5.7 External Secrets Operator

External Secrets Operator는 AWS Secrets Manager의 Secret을 조회해 Kubernetes Secret으로 동기화합니다.

### SecretStore

```text
Name: aws-secrets-manager
Provider: AWS Secrets Manager
Region: ap-northeast-2
```

### ExternalSecret

```text
Namespace: ops-platform
Name: postgresql-credentials
SecretStore: aws-secrets-manager
Refresh Interval: 1h
```

### 생성되는 Kubernetes Secret

```text
Namespace: ops-platform
Name: postgresql-credentials
Type: Opaque
```

정상 동기화 기준:

```text
STATUS: SecretSynced
READY: True
```

---

## 5.8 로컬 환경 변수

로컬 테스트용 `.env.example` 파일 예시입니다.

```env
AWS_REGION=ap-northeast-2
TF_STATE_BUCKET=your-tfstate-bucket

POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=ops_platform
POSTGRES_USER=platform_app
POSTGRES_PASSWORD=change-me

KAFKA_BOOTSTRAP_SERVERS=localhost:9092

DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
```

실제 `.env` 파일은 Git에 커밋하지 않습니다.

```gitignore
.env
.env.*
!.env.example

*.pem
*.key
*.p12

.terraform/
*.tfstate
*.tfstate.*
*.tfplan
```

---

# 6. 디렉터리 구조

```text
3rd_project/
├── .github/
│   └── workflows/
│       ├── infra-provision.yml
│       ├── infra-destroy.yml
│       ├── infra-ci.yml
│       └── security-scan.yml
│
├── terraform/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── terraform-security/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── ansible/
│   ├── inventory.ini
│   ├── playbook.yml
│   └── roles/
│
├── k8s/
│   └── smoke-test/
│       ├── deployment.yml
│       ├── service.yml
│       └── network-policy.yml
│
├── docs/
│   └── images/
│       └── architecture.png
│
├── .gitignore
└── README.md
```

> 실제 디렉터리와 파일 이름이 다른 경우 현재 Repository 구조에 맞게 수정합니다.

---

# 7. 검증 결과

## 7.1 Infrastructure

- Terraform 기반 AWS 인프라 생성 성공
- VPC, Subnet, Security Group, EC2 구성 확인
- S3 Remote State 저장 확인
- Provision과 Destroy 동일 State 공유 확인
- 인프라 Destroy 이후 Re-Provision 성공

---

## 7.2 Kubernetes

- Control Plane 1대 Ready
- Worker Node 3대 Ready
- 총 4개 Kubernetes Node Ready
- Cilium CNI 구성 확인
- Application Deployment 및 Service 생성 확인
- Smoke Test Application 정상 실행 확인
- NodePort 기반 서비스 연결 확인

---

## 7.3 CI/CD

- `infra-provision` Workflow 성공
- `infra-destroy` Workflow 성공
- Terraform → Ansible → Kubernetes End-to-End 자동화 확인
- GitHub Runner Public IP `/32` 임시 SSH 허용 확인
- 배포 완료 후 SSH Security Group 규칙 자동 회수 확인
- 동일 Pipeline 기반 Re-Provision 검증 완료

---

## 7.4 Security

- GitHub OIDC·AWS STS 기반 단기 자격 증명 적용
- 장기 AWS Access Key 제거
- 최소 권한 IAM Role 분리
- AWS KMS Customer Managed Key 구성
- AWS Secrets Manager Secret 생성
- ExternalSecret `SecretSynced=True` 확인
- Kubernetes Secret 자동 생성 확인
- Checkov Hard Gate 통과
- Trivy Secret·Image·IaC Scan 통과
- Kubernetes RBAC, PSA, SecurityContext 검증
- WAF 정상 요청 HTTP 200 확인
- 비정상 요청 HTTP 403 확인
- CloudTrail 및 감사 로그 적재 확인

---

## 7.5 ALB Health Check Troubleshooting

NetworkPolicy 적용 이후 일부 ALB Target이 `unhealthy` 상태로 남는 문제가 발생했습니다.

### 원인

Cross-node Pod 통신에 필요한 Pod 네트워크 대역이 NetworkPolicy에서 허용되지 않았습니다.

### 해결

NetworkPolicy에 다음 Pod 네트워크 대역을 추가했습니다.

```text
192.168.0.0/16
```

Deployment를 Rollout Restart한 뒤 ALB Target Health를 재검증했습니다.

### 결과

```text
ALB Target Health: healthy 2/2
```

NetworkPolicy의 접근 통제는 유지하면서 Cross-node 통신과 ALB Health Check 경로를 정상화했습니다.

---

# 8. 팀 역할

| 담당자 | 역할 |
|---|---|
| 봉하석 | PM · CI/CD · Security |
| 조영대 | Infrastructure · DR |
| 주인재 | AIOps |
| 정민재 | FinOps |
| 차정민 | Monitoring · Kafka |

---

# 9. 보안 및 운영 주의사항

## 9.1 AWS Credentials

- AWS Access Key와 Secret Key를 Source Code에 저장하지 않습니다.
- GitHub Actions에서는 OIDC와 STS 기반 단기 자격 증명을 사용합니다.
- IAM Role은 Workflow별 최소 권한으로 분리합니다.

---

## 9.2 SSH 접근

- EC2 SSH `22/tcp`를 `0.0.0.0/0`으로 상시 개방하지 않습니다.
- GitHub Runner Public IP 또는 운영자 IP만 `/32`로 허용합니다.
- CI/CD 실행 종료 후 임시 SSH 규칙을 자동 회수합니다.
- Private Key 파일을 Git Repository에 커밋하지 않습니다.

---

## 9.3 Service Port

다음 관리 포트를 `0.0.0.0/0`에 불필요하게 공개하지 않습니다.

- SSH: `22`
- PostgreSQL: `5432`
- Grafana: `3000`
- Prometheus: `9090`
- Kafka: `9092`
- Kubernetes API Server: `6443`
- Kubelet API: `10250`

관리 포트는 VPC CIDR, Security Group Reference 또는 허용된 운영자 IP로 제한합니다.

---

## 9.4 Secret 관리

- Secret 값을 README에 직접 기록하지 않습니다.
- Kubernetes Secret을 평문으로 출력하지 않습니다.
- Secret 값이 GitHub Actions 로그에 출력되지 않도록 합니다.
- PostgreSQL 비밀번호를 Terraform State에 저장하지 않습니다.
- Secret은 AWS Secrets Manager와 KMS를 통해 관리합니다.

---

## 9.5 Terraform State

- Terraform State 파일을 Git에 커밋하지 않습니다.
- 동일한 Remote State에 동시에 여러 Apply를 실행하지 않습니다.
- 일반 인프라와 보안 인프라의 State를 분리합니다.
- 인프라 삭제 전 Terraform Plan을 반드시 확인합니다.

---

## 9.6 운영 종료 후 정리

- 사용하지 않는 EC2 인스턴스를 종료합니다.
- 임시 Security Group 규칙을 제거합니다.
- 불필요한 Elastic IP와 ALB를 제거합니다.
- 테스트용 Secret과 Key를 정리합니다.
- Terraform Destroy 이후 잔존 리소스를 확인합니다.
- S3, CloudTrail, Snapshot 등 비용 발생 리소스를 점검합니다.

---

# 10. 프로젝트 요약

본 프로젝트는 AWS 환경에서 다음 영역을 통합했습니다.

```text
Infrastructure as Code
        +
CI/CD Automation
        +
Self-managed Kubernetes
        +
Monitoring
        +
FinOps
        +
AIOps
        +
Security
        +
Disaster Recovery
```

Terraform과 Ansible을 이용해 인프라 생성부터 Kubernetes 구성까지 자동화했으며, Prometheus·Kafka·PostgreSQL 기반 데이터 파이프라인을 통해 운영 메트릭과 비용 데이터를 통합 분석합니다.

통합 AIOps 모듈과 Decision Engine은 이상 상황에 대한 자동 조치 또는 운영자 권고를 판단합니다. AWS KMS, Secrets Manager, External Secrets Operator, GitHub OIDC, Checkov, Trivy를 적용하여 비밀정보 보호와 배포 전 보안 검증을 수행합니다.

서울 Primary Region에 장애가 발생하면 오사카 DR Region을 활성화하고 Route 53 Failover Routing을 통해 서비스 트래픽을 전환합니다.

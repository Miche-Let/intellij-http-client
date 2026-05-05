# HTTP MVP 테스트 가이드

## 파일 구성

```
http-mvp/
├── owner.http              # 점주 셋업 시나리오 (식당·코스·타임슬롯 생성)
├── user.http               # 소비자 예약 시나리오 (대기 → 예약)
├── http-client.env.json    # 환경 변수 (seed 데이터용 고정 ID)
├── sql/
│   ├── seed_mvp_data.sql   # 빠른 테스트용 사전 데이터 삽입
│   └── reset_mvp_data.sql  # 데이터 초기화
└── GUIDE.md                # 이 파일
```

---

## 사전 조건

### 1. 인프라 기동
```bash
cd infra
docker-compose -f docker-compose.infra.yml up -d
# PostgreSQL(5432), Redis(6379), MongoDB(27017) 확인
```

### 2. Eureka 기동
```bash
cd eureka-server
./gradlew bootRun
# http://localhost:8761 접속하여 Eureka 대시보드 확인
```

### 3. 서비스 기동
```bash
# 또는 개별 기동
source infra/.env && cd user-service        && ./gradlew bootRun --args='--spring.profiles.active=local'
source infra/.env && cd restaurant-service  && ./gradlew bootRun --args='--spring.profiles.active=local'
source infra/.env && cd timeslot-service    && ./gradlew bootRun --args='--spring.profiles.active=local'
source infra/.env && cd waiting-service     && ./gradlew bootRun --args='--spring.profiles.active=local'
source infra/.env && cd reservation-service && ./gradlew bootRun --args='--spring.profiles.active=local'
source infra/.env && cd api-gateway         && ./gradlew bootRun --args='--spring.profiles.active=local'
```

### 4. Eureka 등록 확인 (6개 서비스 모두 UP)
```
API-GATEWAY / USER-SERVICE / RESTAURANT-SERVICE
TIMESLOT-SERVICE / WAITING-SERVICE / RESERVATION-SERVICE
```

---

## 실행 방법

### 방법 A — owner.http 먼저 실행 (전체 흐름 검증)

```
owner.http  →  user.http
```

1. IntelliJ에서 `owner.http` 열기
2. 환경: `local` 선택
3. STEP 1 ~ STEP 5 순서대로 실행
   - STEP 3 실행 후 → `restaurantId`가 전역 변수에 자동 저장됨
   - STEP 4 실행 후 → `courseId`, `courseUnitPrice` 자동 저장됨
   - STEP 5 실행 후 → 2026년 7월 타임슬롯 생성 완료
4. `user.http`로 이동하여 STEP 1 ~ 10 실행

### 방법 B — seed SQL 적용 후 user.http만 실행 (빠른 테스트)

```bash
# 시드 데이터 삽입
docker exec -i db psql -U admin -d michelet_db < http-mvp/sql/seed_mvp_data.sql
```

- `http-client.env.json`의 고정 ID가 자동으로 사용됨
- `user.http`만 실행

---

## 변수 흐름

### owner.http 실행 시 설정되는 전역 변수

| 변수 | 설정 STEP | 값 |
|------|-----------|----|
| `ownerToken` | STEP 2 (로그인) | 점주 Bearer 토큰 |
| `restaurantId` | STEP 3 (식당 등록) | 새로 생성된 식당 UUID |
| `courseId` | STEP 4 (코스 등록) | 새로 생성된 코스 UUID |
| `courseUnitPrice` | STEP 4 | 150000 (고정) |

### user.http 실행 시 설정되는 전역 변수

| 변수 | 설정 STEP | 값 |
|------|-----------|----|
| `userToken` | STEP 2 (로그인) | 소비자 Bearer 토큰 |
| `restaurantId` | STEP 3 (식당 검색) | 검색 결과 첫 번째 식당 UUID |
| `courseId` | STEP 5 (코스 조회) | 코스 목록 첫 번째 UUID |
| `courseUnitPrice` | STEP 5 | 코스 단가 |
| `waitingId` | STEP 6a (대기 등록) | 대기 항목 UUID |
| `waitingToken` | STEP 6a | queueToken (순번 조회용) |
| `waitingAccessToken` | STEP 6a-i (ACTIVE 시) | accessToken (예약 생성용) |
| `targetDate` | STEP 6b (달력 조회) | 예약 가능 첫 날짜 |
| `timeSlotId` | STEP 7 (타임슬롯) | 선택된 타임슬롯 UUID |
| `slotStartTime` | STEP 7 | 타임슬롯 시작 시각 |
| `reservationId` | STEP 8 (예약 생성) | 생성된 예약 UUID |

---

## 주의사항

### 대기열 토큰 두 종류 구분

| 토큰 | 변수명 | 용도 | 발급 시점 |
|------|--------|------|-----------|
| `queueToken` | `waitingToken` | 순번 조회 (STEP 6a-i) | 대기 등록 즉시 |
| `accessToken` | `waitingAccessToken` | 예약 생성 (STEP 8 X-Waiting-Token) | ACTIVE 전환 시 |

> **핵심**: STEP 8의 `X-Waiting-Token`에는 반드시 `waitingAccessToken`을 사용해야 합니다.
> `waitingToken`(queueToken)을 사용하면 예약이 실패합니다.

### STEP 6a-i 재실행 가능

- `status: WAITING` 응답 시 → 10초 대기 후 STEP 6a-i 재실행
- `status: ACTIVE` 응답 시 → `waitingAccessToken` 자동 저장 → STEP 6b 진행
- STEP 6a-i를 여러 번 실행해도 `waitingToken`(queueToken)은 변경되지 않음

### `waitingAccessToken` 1회 사용

- 예약 완료 후 해당 accessToken은 만료(소프트 삭제)됩니다.
- 동일 토큰으로 예약을 재시도하면 실패합니다.
- 재테스트 시 reset SQL 후 seed SQL을 다시 실행하거나, 새로운 대기 등록부터 진행하세요.

---

## 데이터 초기화 후 재테스트

```bash
# 1. 초기화
docker exec -i db psql -U admin -d michelet_db < http-mvp/sql/reset_mvp_data.sql

# 2. 시드 재삽입
docker exec -i db psql -U admin -d michelet_db < http-mvp/sql/seed_mvp_data.sql

# 3. IntelliJ HTTP Client 전역 변수 초기화
#    Tools > HTTP Client > Remove All Global Variables
```

---

## 서비스별 포트

| 서비스 | 포트 |
|--------|------|
| API Gateway | 19000 |
| User Service | 19100 |
| Waiting Service | 19200 |
| Restaurant Service | 19300 |
| Timeslot Service | 19400 |
| Reservation Service | 19500 |
| Eureka | 8761 |

# HTTP MVP 테스트 가이드

# 현재 코드기준 다른값

## rasturants service

    server:
    port: 19300
    
    spring:
    config:
    activate:
    on-profile: local
    
    application:
    name: restaurant-service
    
    datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/michelet_db}
    username: ${DB_USERNAME:admin}
    password: ${DB_PASSWORD:admin}
    driver-class-name: org.postgresql.Driver
    
    jpa:
    hibernate:
    ddl-auto: update
    properties:
    hibernate:
    default_schema: restaurant_service
    format_sql: true
    open-in-view: false
    show-sql: true
    
    eureka:
    client:
    # local에서는 DB/API 테스트만 할 수 있도록 Eureka client를 기본 비활성화
    enabled: ${EUREKA_CLIENT_ENABLED:true}
    service-url:
    defaultZone: ${EUREKA_DEFAULT_ZONE:http://localhost:8761/eureka/}


build.gradle 의존성

    plugins {
    id 'java'
    id 'org.springframework.boot' version '3.5.14'
    id 'io.spring.dependency-management' version '1.1.7'
    id 'org.asciidoctor.jvm.convert' version '4.0.2'
    }
    
    group = 'com.michelet'
    version = '0.0.1-SNAPSHOT'
    
    java {
    toolchain {
    languageVersion = JavaLanguageVersion.of(17)
    }
    }
    
    configurations {
    compileOnly {
    extendsFrom annotationProcessor
    }
    }
    
    repositories {
    mavenCentral()
    maven { url 'https://jitpack.io' }
    }
    
    ext {
    set('springCloudVersion', "2025.0.1")
    }
    
    dependencies {
    //	DB 연결 후 사용
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-web'
    //	eureka server 등록할 때 사용 권장
    implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-client'
    implementation 'org.springframework.cloud:spring-cloud-starter-openfeign'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'com.querydsl:querydsl-jpa:5.1.0:jakarta'
    implementation 'com.github.Miche-Let:common:dev-SNAPSHOT'
    implementation 'io.github.openfeign:feign-hc5'
    implementation 'com.github.Miche-Let:common-auth-feign:0.1.2'
    implementation 'com.github.Miche-Let:common-auth-webmvc:0.1.5'
    
        runtimeOnly 'org.postgresql:postgresql'
    
        compileOnly 'org.projectlombok:lombok'
        annotationProcessor 'org.projectlombok:lombok'
        annotationProcessor 'com.querydsl:querydsl-apt:5.1.0:jakarta'
        annotationProcessor 'jakarta.annotation:jakarta.annotation-api'
        annotationProcessor 'jakarta.persistence:jakarta.persistence-api'
    
        testImplementation 'org.springframework.boot:spring-boot-starter-test'
        testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
        testRuntimeOnly 'com.h2database:h2'
    }
    
    dependencyManagement {
    imports {
    mavenBom "org.springframework.cloud:spring-cloud-dependencies:${springCloudVersion}"
    }
    }
    
    def snippetsDir = file("build/generated-snippets")
    
    tasks.named('test') {
    useJUnitPlatform()
    outputs.dir snippetsDir
    }
    
    tasks.named('asciidoctor') {
    inputs.dir snippetsDir
    dependsOn tasks.named('test')
    baseDirFollowsSourceFile()
    attributes(
    'snippets': snippetsDir
    )
    }

## timeslot service

TimeSlotInternalServiceImpl.java

    package com.michelet.timeslotservice.presentation.controller;
    
    import java.util.UUID;
    
    import org.springframework.web.bind.annotation.PathVariable;
    import org.springframework.web.bind.annotation.PostMapping;
    import org.springframework.web.bind.annotation.RequestBody;
    import org.springframework.web.bind.annotation.RequestMapping;
    import org.springframework.web.bind.annotation.RestController;
    
    import com.michelet.common.response.ApiResponse;
    import com.michelet.timeslotservice.application.service.TimeSlotService;
    import com.michelet.timeslotservice.presentation.code.TimeSlotSuccessCode;
    import com.michelet.timeslotservice.presentation.dto.request.TimeSlotDeductCapacityRequest;
    
    import jakarta.validation.Valid;
    import lombok.RequiredArgsConstructor;
    
    @RestController
    @RequestMapping("/internal/v1/timeslots")
    @RequiredArgsConstructor
    public class TimeSlotInternalController {

    private final TimeSlotService timeSlotService;
    
    /**
     * 특정 타임슬롯의 예약 가능 인원을 차감하는 내부 API 엔드포인트.
     * 트랜잭션 및 낙관적 락을 통해 데이터 일관성을 보장합니다.
     * * @param timeSlotId 차감 대상 타임슬롯 식별자
     * @param request 차감 요청 정보 (인원 수)
     * @return 공통 응답 규격
     */

    
    @PostMapping("/{timeSlotId}/deduct")
    public ApiResponse<Void> deductCapacity(
            @PathVariable UUID timeSlotId, 
            @Valid @RequestBody TimeSlotDeductCapacityRequest request) {

        timeSlotService.deductCapacity(timeSlotId, request.requiredCapacity());
        return ApiResponse.ok(TimeSlotSuccessCode.DEDUCT_SUCCESS, null);
        
    }

    }   

application.yml

    server:
    port: 19400
    
    spring:
    application:
    name: timeslot-service
    
    datasource:
    url: jdbc:postgresql://localhost:${POSTGRES_PORT:5432}/${POSTGRES_DB:michelet_db}
    username: ${POSTGRES_USER:admin}
    password: ${POSTGRES_PASSWORD:admin}
    driver-class-name: org.postgresql.Driver
    
    jpa:
    hibernate:
    ddl-auto: update
    show-sql: true
    properties:
    hibernate:
    default_schema: timeslot_service
    format_sql: true
    highlight_sql: true
    
    internal:
    auth:
    secret: ${SPRING_INTERNAL_AUTH_SECRET}
    
    eureka:
    client:
    register-with-eureka: true
    fetch-registry: true
    service-url:
    defaultZone: http://localhost:${EUREKA_PORT:8761}/eureka/

## user service

application-local.yml

        eureka:
        client:
        service-url:
        defaultZone: http://localhost:${EUREKA_PORT:8761}/eureka/
        
        spring:
        datasource:
        url: jdbc:postgresql://localhost:${POSTGRES_PORT:5432}/${POSTGRES_DB:michelet_db}
        username: ${POSTGRES_USER:admin}
        password: ${POSTGRES_PASSWORD:admin}
        driver-class-name: org.postgresql.Driver
        data:
        redis:
        host: localhost
        port: ${REDIS_PORT:6379}
        
        jpa:
        hibernate:
        ddl-auto: create
        properties:
        hibernate:
        default_schema: user_service
        format_sql: true
        show-sql: true
    
## waiting-service

bulid.gradle

    plugins {
    id 'java'
    id 'org.springframework.boot' version '3.5.14'
    id 'io.spring.dependency-management' version '1.1.7'
    }
    
    group = 'com.michelet'
    version = '0.0.1-SNAPSHOT'
    
    java {
    toolchain {
    languageVersion = JavaLanguageVersion.of(21)
    }
    }
    
    repositories {
    mavenCentral()
    maven { url 'https://jitpack.io' }
    }
    
    ext {
    set('springCloudVersion', "2025.0.2")
    }
    
    dependencies {
    // Common
    implementation 'com.github.Miche-Let:common-auth-feign:0.1.1'
    implementation 'com.github.Miche-Let:common-auth-webmvc:0.1.3'
    implementation 'com.github.Miche-Let:common:aaf3b1d'
    implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-client'
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-data-redis'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    
        // Lombok
        compileOnly 'org.projectlombok:lombok'
        annotationProcessor 'org.projectlombok:lombok'
    
        // Eureka
        implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-client'
    
        // QueryDSL
        implementation 'com.querydsl:querydsl-jpa:5.0.0:jakarta'
        annotationProcessor 'com.querydsl:querydsl-apt:5.0.0:jakarta'
        annotationProcessor 'jakarta.annotation:jakarta.annotation-api'
        annotationProcessor 'jakarta.persistence:jakarta.persistence-api'
    
        // PostgreSQL
        runtimeOnly 'org.postgresql:postgresql'
    
        // Flyway
        implementation 'org.flywaydb:flyway-core'
        implementation 'org.flywaydb:flyway-database-postgresql'
    
        // Test
        testImplementation 'org.springframework.boot:spring-boot-starter-test'
        testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
        testImplementation 'com.h2database:h2'
    }
    
    dependencyManagement {
    imports {
    mavenBom "org.springframework.cloud:spring-cloud-dependencies:${springCloudVersion}"
    }
    }
    
    tasks.named('test') {
    useJUnitPlatform()
    }



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

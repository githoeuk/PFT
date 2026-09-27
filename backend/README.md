# 비콘 기반 출석 관리 시스템

아파트 페인트 작업 현장의 출퇴근을 블루투스 비콘 기반으로 관리하는 출석 시스템입니다.

직원은 모바일 앱에서 현장 비콘 범위 안에 들어왔을 때 출근/퇴근을 요청하고, 서버는 등록된 비콘 정보와 작업 일정을 기준으로 출석 상태를 판단합니다. 관리자는 작업 현장, 작업 일정, 비콘, 직원 계정, 출석 기록, 급여 기준을 관리할 수 있습니다.

## 프로젝트 목표

이 프로젝트는 현장 근무자의 출퇴근 기록을 수기 장부 대신 모바일 앱과 서버 API로 관리하기 위해 설계했습니다.

핵심 목표는 다음과 같습니다.

- 직원과 관리자가 하나의 앱을 사용하되 역할에 따라 화면과 기능을 분리
- 비콘 UUID, major, minor, RSSI를 이용한 현장 근접 여부 검증
- 작업 일정 기준 출근, 지각, 조퇴, 결석 상태 관리
- 관리자 수기 수정 기능과 수정 이력 저장을 통한 감사 추적
- 직원별 현장 일급과 세율 설정을 통한 급여 계산 기반 마련

## 주요 기능

### 인증 및 권한

- JWT 기반 로그인
- 관리자/직원 역할 분리
- Spring Security 기반 API 접근 제어
- 로그인 후 발급받은 Bearer Token으로 API 호출

### 직원 기능

- 비콘 정보 기반 출근 처리
- 비콘 정보 기반 퇴근 처리
- 본인 출석 내역 조회
- 마이페이지 정보 조회 및 수정
- 비밀번호 변경

### 관리자 기능

- 직원 계정 생성, 조회, 수정, 비활성화
- 직원 임시 비밀번호 발급 및 초기화
- 작업 현장 생성, 조회, 수정, 비활성화
- 작업 일정 생성, 조회, 수정
- 비콘 등록, 조회, 수정, 비활성화
- 직원별 작업 현장 일급 및 세율 설정
- 출석 현황 조건 검색
- 출석 기록 수기 수정
- 결석 처리
- 출석 수정 이력 조회

## 출석 처리 방식

출근/퇴근 요청은 직원 모바일 앱에서 전송합니다.

요청에는 다음 정보가 포함됩니다.

- 비콘 UUID
- 비콘 major
- 비콘 minor
- RSSI
- 기기 ID
- 위치 정보

서버는 요청받은 비콘 정보가 등록된 활성 비콘인지 확인하고, RSSI 값이 출석 가능 기준 안에 있는지 검증합니다. 이후 비콘이 속한 작업 현장의 오늘 작업 일정을 조회하여 출석 상태를 판단합니다.

## 출석 상태

| 상태 | 설명 |
| --- | --- |
| `NORMAL` | 정상 출근 |
| `LATE` | 지각 |
| `EARLY_LEAVE` | 조퇴 |
| `LATE_AND_EARLY_LEAVE` | 지각 및 조퇴 |
| `ABSENT` | 결석 |
| `MANUAL_FIXED` | 관리자 수기 보정 |

## 기술 스택

### Backend

- Java 21
- Spring Boot 4.1.0
- Spring Security
- JWT
- Spring Data JPA
- Hibernate
- MySQL
- H2
- Gradle
- Lombok

### Mobile 예정

- Flutter
- Bluetooth Beacon
- REST API 연동
- Secure Storage 기반 토큰 저장
- 역할 기반 화면 분기

## 프로젝트 구조

```text
src/main/java/com/example/demo
├── domain
│   ├── attendance
│   ├── assignment
│   ├── auth
│   ├── beacon
│   ├── payroll
│   ├── schedule
│   ├── user
│   └── worksite
└── global
    ├── common
    ├── config
    ├── exception
    └── security
```

## 실행 방법

### 1. MySQL 데이터베이스 생성

```sql
CREATE DATABASE beacon_attendance
DEFAULT CHARACTER SET utf8mb4
DEFAULT COLLATE utf8mb4_unicode_ci;
```

### 2. 환경 변수 설정

개발 환경에서는 프로젝트 루트에 `.env` 파일을 둘 수 있습니다.

```properties
DB_USERNAME=root
DB_PASSWORD=your_password
JWT_SECRET=dev-secret-key-dev-secret-key-dev-secret-key
```

### 3. 서버 실행

```bash
./gradlew.bat bootRun
```

기본 실행 주소는 다음과 같습니다.

```text
http://localhost:8080
```

## 개발용 테스트 계정

`dev` 프로필에서는 `src/main/resources/data.sql`을 통해 테스트 데이터가 등록됩니다.

| 역할 | 아이디 | 비밀번호 |
| --- | --- | --- |
| 관리자 | `admin` | `password` |
| 직원 | `employee01` | `password` |

## API 문서

자세한 문서는 아래 파일을 참고합니다.

- [API 명세](docs/API_SPEC.md)
- [API 컨벤션](docs/API_CONVENTION.md)
- [ERD](docs/ERD.md)
- [서비스 설계](docs/SERVICE_DESIGN.md)
- [테스트 가이드](docs/TEST_GUIDE.md)

## 현재 구현 범위

- 백엔드 MVP 구현 완료
- JWT 인증 및 권한 제어 완료
- 관리자 출석 관리 기능 구현 완료
- 직원 출근/퇴근 API 구현 완료
- 직원별 현장 일급/세율 설정 구현 완료
- dev 환경 샘플 데이터 구성 완료
- dev CORS 설정 완료
- 모바일 앱은 Flutter로 구현 예정

## 보류 및 확장 예정

- 작업 배정 정책은 엔티티와 Repository만 준비하고 실제 서비스 사용은 보류
- Flutter 앱에서 비콘 스캔 및 역할 기반 화면 분기 구현 예정
- 운영 환경에서는 `data.sql` 자동 실행을 비활성화해야 함
- 관리자 출석 현황 응답에 최신 수기 수정/결석 처리 사유를 포함하도록 개선 예정
- 아이디 찾기와 비밀번호 재설정 요청은 휴대폰 인증 등 본인 확인 정책 확정 후 API 구현 예정
- 작업 일정 수정 시 과거 날짜와 동일 현장 중복 날짜 검증 강화 예정
- 비콘 수정 시 UUID, major, minor도 수정할 수 있도록 API 확장 예정
- 비활성화 데이터는 일정 기간 이후 완전 삭제 또는 익명화하는 정책 검토 예정

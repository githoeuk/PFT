# 서비스 설계

## 1. 1차 MVP 범위

1차 MVP는 작업 배정 없이 다음 기준으로 출퇴근을 처리합니다.

```text
로그인한 직원
+ 앱이 감지한 비콘
+ 비콘이 속한 작업 현장
+ 오늘 날짜의 작업 일정
```

`WorkAssignment`는 엔티티와 Repository만 준비되어 있으며, 작업 배정 정책이 확정될 때까지 실제 출퇴근 서비스에서는 사용하지 않습니다.

## 2. 역할 기반 기능 분리

하나의 앱을 사용하되 로그인한 사용자 역할에 따라 화면과 API 접근을 분리합니다.

| 역할 | 주요 기능 |
| --- | --- |
| `ADMIN` | 직원, 현장, 일정, 비콘, 급여, 출석 관리 |
| `EMPLOYEE` | 출근, 퇴근, 본인 출석 조회, 마이페이지 |

Spring Security에서는 다음 경로를 기준으로 권한을 제한합니다.

```text
/api/v1/admin/**    -> ADMIN
/api/v1/employee/** -> EMPLOYEE
/api/v1/me/**       -> 로그인 사용자
```

## 3. 인증 흐름

```text
1. 사용자가 loginId, password로 로그인 요청
2. 서버가 활성 사용자 조회
3. BCrypt로 비밀번호 검증
4. JWT accessToken 발급
5. 클라이언트는 이후 요청에 Authorization 헤더 포함
6. JwtAuthenticationFilter가 토큰 검증 후 SecurityContext에 사용자 정보 저장
```

요청 헤더:

```http
Authorization: Bearer {accessToken}
```

## 4. 출근 처리 흐름

```text
1. JWT에서 로그인 직원 ID 확인
2. 직원 ID로 활성 직원 조회
3. 요청받은 uuid, major, minor로 활성 비콘 조회
4. RSSI 값이 비콘의 rssiThreshold 기준 안에 있는지 확인
5. 비콘이 속한 현장의 오늘 작업 일정 조회
6. 같은 직원과 같은 작업 일정에 출석 기록이 이미 있는지 확인
7. 현재 시간과 기준 출근 시간을 비교해서 NORMAL 또는 LATE 판정
8. attendance_records에 출근 기록 저장
```

출근 요청에 포함되는 주요 값:

```text
beaconUuid
beaconMajor
beaconMinor
rssi
deviceId
latitude
longitude
```

## 5. 퇴근 처리 흐름

```text
1. JWT에서 로그인 직원 ID 확인
2. 직원 ID로 활성 직원 조회
3. 요청받은 uuid, major, minor로 활성 비콘 조회
4. RSSI 값이 비콘의 rssiThreshold 기준 안에 있는지 확인
5. 비콘이 속한 현장의 오늘 작업 일정 조회
6. 같은 직원과 같은 작업 일정의 출근 기록 조회
7. 이미 퇴근 처리된 기록인지 확인
8. 현재 시간과 기준 퇴근 시간을 비교해서 조퇴 여부 판단
9. attendance_records에 퇴근 시간과 퇴근 증빙 데이터 저장
```

## 6. 출석 상태 판정

출근 판정:

```text
checkedInAt <= workDate + startTime + lateGraceMinutes -> NORMAL
checkedInAt >  workDate + startTime + lateGraceMinutes -> LATE
```

퇴근 판정:

```text
checkedOutAt >= workDate + endTime - earlyLeaveGraceMinutes -> 기존 상태 유지
checkedOutAt <  workDate + endTime - earlyLeaveGraceMinutes -> EARLY_LEAVE
```

이미 지각인 직원이 조퇴도 하면 다음 상태가 됩니다.

```text
LATE + EARLY_LEAVE -> LATE_AND_EARLY_LEAVE
```

## 7. RSSI 판정

RSSI는 비콘 신호 세기를 의미합니다. 일반적으로 값이 0에 가까울수록 신호가 강하고, 음수 값이 작아질수록 멀다고 볼 수 있습니다.

예시:

```text
-60 >= -75 -> 기준 안쪽, 출석 가능
-85 <  -75 -> 기준 바깥, 출석 불가
```

서버는 다음 조건으로 비콘 범위를 판단합니다.

```text
요청 RSSI < 비콘 rssiThreshold -> 출석 가능 범위 밖
```

## 8. 관리자 출석 관리 흐름

### 출석 현황 조회

관리자는 다음 조건으로 출석 기록을 검색할 수 있습니다.

```text
employeeId
workSiteId
startDate
endDate
status
```

조회 시 직원, 작업 일정, 작업 현장 정보를 함께 조회하여 응답에 필요한 정보를 반환합니다.

### 수기 출석 수정

관리자는 기존 출석 기록의 상태와 출근/퇴근 시간을 수기로 수정할 수 있습니다.

처리 흐름:

```text
1. JWT에서 관리자 ID 확인
2. 관리자 계정 활성 상태와 역할 검증
3. 수정 대상 출석 기록 조회
4. 요청 상태와 시간 조합 검증
5. 수정 전 값을 AttendanceAdjustment에 저장
6. AttendanceRecord 상태와 시간 수정
7. manualAdjusted 값을 true로 변경
8. 수정된 출석 기록 반환
```

수기 입력 검증 규칙:

```text
ABSENT 상태 -> checkedInAt, checkedOutAt 모두 null이어야 함
ABSENT가 아닌 상태 -> checkedInAt 필수
checkedOutAt이 있으면 checkedInAt보다 빠를 수 없음
```

### 결석 처리

관리자는 특정 직원과 작업 일정에 대해 결석 기록을 생성할 수 있습니다.

처리 흐름:

```text
1. JWT에서 관리자 ID 확인
2. 관리자 계정 활성 상태와 역할 검증
3. 대상 직원 활성 상태와 역할 검증
4. 작업 일정 조회
5. 같은 직원과 같은 일정의 출석 기록이 이미 있는지 확인
6. ABSENT 상태의 AttendanceRecord 생성
7. AttendanceAdjustment에 결석 처리 이력 저장
```

결석 상태에서는 출근/퇴근 시간이 존재하지 않습니다.

## 9. 급여 설정 흐름

관리자는 직원별 작업 현장 일급과 세율을 설정할 수 있습니다.

입력 값:

```text
employeeId
workSiteId
dailyWage
taxRate
```

응답에서는 세금과 세후 일급을 함께 계산해서 반환합니다.

```text
taxAmount = dailyWage * taxRate / 100
netDailyWage = dailyWage - taxAmount
```

계산 시 세금은 소수점 없이 내림 처리합니다.

## 10. 개발용 데이터 흐름

`dev` 프로필에서는 `src/main/resources/data.sql`을 실행하여 기본 데이터를 등록합니다.

샘플 데이터:

```text
관리자 1명
직원 1명
작업 현장 1개
비콘 1개
오늘 날짜 작업 일정 1개
직원별 현장 급여 설정 1개
```

테스트 계정:

```text
admin / password
employee01 / password
```

## 11. CORS 정책

`dev` 프로필에서는 브라우저 기반 프론트 개발을 위해 다음 출처를 허용합니다.

```text
http://localhost:*
http://127.0.0.1:*
```

허용 메서드:

```text
GET, POST, PATCH, DELETE, OPTIONS
```

허용 헤더:

```text
Authorization, Content-Type
```

Flutter Android/iOS 앱은 브라우저 CORS 정책의 영향을 거의 받지 않지만, Flutter Web 또는 React 기반 관리자 화면을 고려하여 dev CORS 설정을 추가했습니다.

## 12. 예외 처리 정책

현재 공통 응답 형식은 `ApiResponse`를 사용합니다.

주요 예외 처리:

| 예외 | 응답 코드 | 설명 |
| --- | --- | --- |
| `IllegalArgumentException` | `BAD_REQUEST` | 잘못된 요청 또는 비즈니스 검증 실패 |
| `IllegalStateException` | `INVALID_STATE` | 현재 상태에서 처리할 수 없는 요청 |
| `MethodArgumentNotValidException` | `VALIDATION_ERROR` | DTO 검증 실패 |
| `HttpMessageNotReadableException` | `INVALID_JSON` | JSON 파싱 실패 |
| 인증 실패 | `UNAUTHORIZED` | 토큰 없음 또는 유효하지 않은 토큰 |
| 권한 부족 | `FORBIDDEN` | 역할 권한 부족 |

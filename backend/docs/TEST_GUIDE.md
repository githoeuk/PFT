# 테스트 가이드

이 문서는 개발 환경에서 백엔드 API를 직접 확인하기 위한 테스트 순서입니다.

## 1. 사전 준비

### MySQL 데이터베이스 생성

```sql
CREATE DATABASE beacon_attendance
DEFAULT CHARACTER SET utf8mb4
DEFAULT COLLATE utf8mb4_unicode_ci;
```

### dev 프로필 확인

`src/main/resources/application.yaml`에서 `dev` 프로필이 활성화되어 있어야 합니다.

```yaml
spring:
  profiles:
    active:
      - dev
```

`dev` 프로필에서는 `src/main/resources/data.sql`을 통해 테스트 데이터가 들어갑니다.

## 2. 서버 실행

```bash
./gradlew.bat bootRun
```

성공 기준:

```text
Tomcat started on port 8080
Started DemoApplication
```

## 3. 테스트 계정

| 역할 | 아이디 | 비밀번호 |
| --- | --- | --- |
| 관리자 | `admin` | `password` |
| 직원 | `employee01` | `password` |

## 4. 관리자 로그인

```bash
curl.exe -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"loginId":"admin","password":"password"}'
```

응답의 `accessToken`을 변수에 저장합니다.

```bash
ADMIN_TOKEN='관리자_accessToken'
```

## 5. 직원 로그인

```bash
curl.exe -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"loginId":"employee01","password":"password"}'
```

응답의 `accessToken`을 변수에 저장합니다.

```bash
EMPLOYEE_TOKEN='직원_accessToken'
```

## 6. 관리자 기본 데이터 조회

### 작업 현장 조회

```bash
curl.exe -i "http://localhost:8080/api/v1/admin/work-sites" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"
```

### 작업 일정 조회

```bash
curl.exe -i "http://localhost:8080/api/v1/admin/work-schedules/work-sites/1" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"
```

### 비콘 조회

```bash
curl.exe -i "http://localhost:8080/api/v1/admin/beacons/work-sites/1" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"
```

## 7. 직원 출근 테스트

```bash
curl.exe -i -X POST "http://localhost:8080/api/v1/employee/attendance/check-in" \
  -H "Authorization: Bearer ${EMPLOYEE_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-raw '{"beaconUuid":"fda50693-a4e2-4fb1-afcf-c6eb07647825","beaconMajor":101,"beaconMinor":1,"rssi":-60,"deviceId":"test-device-001"}'
```

성공 기준:

```json
{
  "success": true,
  "data": {
    "recordId": 1,
    "status": "LATE",
    "checkedInAt": "2026-08-17T21:56:30",
    "checkedOutAt": null,
    "siteName": "101동 외벽 페인트 작업"
  }
}
```

현재 시간이 작업 시작 시간보다 늦으면 `LATE`가 나오는 것이 정상입니다.

## 8. 직원 퇴근 테스트

```bash
curl.exe -i -X POST "http://localhost:8080/api/v1/employee/attendance/check-out" \
  -H "Authorization: Bearer ${EMPLOYEE_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-raw '{"beaconUuid":"fda50693-a4e2-4fb1-afcf-c6eb07647825","beaconMajor":101,"beaconMinor":1,"rssi":-60,"deviceId":"test-device-001"}'
```

성공 기준:

```text
checkedOutAt 값이 null이 아니면 퇴근 처리 성공
```

## 9. 직원 본인 출석 내역 조회

```bash
curl.exe -i "http://localhost:8080/api/v1/employee/attendance" \
  -H "Authorization: Bearer ${EMPLOYEE_TOKEN}"
```

기간 조건을 넣을 수도 있습니다.

```bash
curl.exe -i "http://localhost:8080/api/v1/employee/attendance?startDate=2026-08-01&endDate=2026-08-31" \
  -H "Authorization: Bearer ${EMPLOYEE_TOKEN}"
```

## 10. 관리자 출석 현황 조회

```bash
curl.exe -i "http://localhost:8080/api/v1/admin/attendance?employeeId=2&workSiteId=1" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"
```

상태 조건 예시:

```bash
curl.exe -i "http://localhost:8080/api/v1/admin/attendance?employeeId=2&workSiteId=1&status=NORMAL" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"
```

## 11. 관리자 수기 출석 수정

```bash
curl.exe -i -X PATCH "http://localhost:8080/api/v1/admin/attendance/1" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-raw '{"status":"NORMAL","checkedInAt":"2026-08-17T08:00:00","checkedOutAt":"2026-08-17T17:00:00","reason":"test"}'
```

성공 기준:

```text
status = NORMAL
manualAdjusted = true
```

### Git Bash 한글 JSON 주의

Windows Git Bash에서 `curl` 요청 본문에 한글을 직접 넣으면 JSON 인코딩이 깨질 수 있습니다.

예시:

```json
{"reason":"테스트용 정상 출근 처리"}
```

이 경우 서버 로그에 다음과 같은 오류가 나올 수 있습니다.

```text
JSON parse error: Invalid UTF-8 middle byte
```

테스트 명령에서는 `reason` 값을 영어로 보내거나, 실제 앱/프론트에서 UTF-8 JSON으로 전송해 확인하는 것을 권장합니다.

## 12. 출석 수정 이력 조회

```bash
curl.exe -i "http://localhost:8080/api/v1/admin/attendance/1/adjustments" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"
```

성공 기준:

```text
수기 수정 전후 상태와 시간이 목록으로 조회됨
```

## 13. 결석 처리 테스트

이미 출석 기록이 있는 일정에는 결석 처리를 할 수 없습니다. 결석 테스트를 하려면 새 작업 일정을 먼저 생성합니다.

### 새 작업 일정 생성

```bash
curl.exe -i -X POST "http://localhost:8080/api/v1/admin/work-schedules" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-raw '{"workSiteId":1,"workDate":"2026-08-18","startTime":"08:00:00","endTime":"17:00:00","lateGraceMinutes":5,"earlyLeaveGraceMinutes":5}'
```

응답의 `id`를 확인합니다.

예시:

```text
scheduleId = 2
```

### 결석 처리

```bash
curl.exe -i -X POST "http://localhost:8080/api/v1/admin/attendance/absences" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  --data-raw '{"employeeId":2,"scheduleId":2,"reason":"absence test"}'
```

성공 기준:

```text
status = ABSENT
checkedInAt = null
checkedOutAt = null
manualAdjusted = true
```

### 결석 기록 조회

```bash
curl.exe -i "http://localhost:8080/api/v1/admin/attendance?employeeId=2&workSiteId=1&status=ABSENT" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"
```

## 14. CORS 테스트

```bash
curl.exe -i -X OPTIONS "http://localhost:8080/api/v1/admin/work-sites" \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Authorization,Content-Type"
```

성공 기준:

```text
Access-Control-Allow-Origin: http://localhost:5173
Access-Control-Allow-Methods: GET,POST,PATCH,DELETE,OPTIONS
Access-Control-Allow-Headers: Authorization, Content-Type
```

## 15. 전체 테스트 실행

```bash
./gradlew.bat test
```

## 16. 자주 발생하는 문제

### Unknown database 'beacon_attendance'

MySQL 데이터베이스가 없는 상태입니다.

```sql
CREATE DATABASE beacon_attendance
DEFAULT CHARACTER SET utf8mb4
DEFAULT COLLATE utf8mb4_unicode_ci;
```

### 아이디 또는 비밀번호가 일치하지 않습니다

dev DB에 샘플 계정이 없거나 비밀번호 해시가 다른 상태입니다. `data.sql` 실행 여부를 확인합니다.

### 401 Unauthorized

다음 항목을 확인합니다.

```text
Authorization 헤더 존재 여부
Bearer 접두사 포함 여부
토큰 만료 여부
관리자/직원 토큰 혼동 여부
```

### 403 Forbidden

로그인은 되었지만 역할 권한이 맞지 않는 상태입니다.

예시:

```text
직원 토큰으로 /api/v1/admin/** 호출
관리자 토큰으로 /api/v1/employee/** 호출
```

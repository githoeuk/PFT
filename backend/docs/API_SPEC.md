# API 명세

기본 경로는 `/api/v1`입니다. 모든 응답은 `ApiResponse` 형식을 사용합니다.

## 공통 응답 형식

성공 응답:

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

실패 응답:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "BAD_REQUEST",
    "message": "요청 값이 올바르지 않습니다."
  }
}
```

인증이 필요한 API는 다음 헤더를 사용합니다.

```http
Authorization: Bearer {accessToken}
Content-Type: application/json
```

## 1. 인증 API

### 로그인

권한: 전체 허용

```http
POST /api/v1/auth/login
```

요청:

```json
{
  "loginId": "admin",
  "password": "password"
}
```

응답:

```json
{
  "success": true,
  "data": {
    "accessToken": "jwt-token",
    "user": {
      "id": 1,
      "loginId": "admin",
      "name": "관리자",
      "phone": "010-0000-0000",
      "role": "ADMIN",
      "active": true
    }
  },
  "error": null
}
```

## 2. 마이페이지 API

### 내 정보 조회

권한: 로그인 사용자

```http
GET /api/v1/me
```

응답:

```json
{
  "success": true,
  "data": {
    "id": 2,
    "loginId": "employee01",
    "name": "홍길동",
    "phone": "010-1111-1111",
    "role": "EMPLOYEE",
    "active": true
  },
  "error": null
}
```

### 내 정보 수정

권한: 로그인 사용자

```http
PATCH /api/v1/me
```

요청:

```json
{
  "name": "홍길동",
  "phone": "010-2222-2222"
}
```

### 내 비밀번호 변경

권한: 로그인 사용자

```http
PATCH /api/v1/me/password
```

요청:

```json
{
  "currentPassword": "password",
  "newPassword": "newPassword123"
}
```

## 3. 직원 출석 API

### 출근 처리

권한: 직원

```http
POST /api/v1/employee/attendance/check-in
```

요청:

```json
{
  "beaconUuid": "fda50693-a4e2-4fb1-afcf-c6eb07647825",
  "beaconMajor": 101,
  "beaconMinor": 1,
  "rssi": -60,
  "deviceId": "test-device-001",
  "latitude": 37.5665,
  "longitude": 126.9780
}
```

응답:

```json
{
  "success": true,
  "data": {
    "recordId": 1,
    "status": "LATE",
    "checkedInAt": "2026-08-17T21:56:30.3787967",
    "checkedOutAt": null,
    "siteName": "101동 외벽 페인트 작업"
  },
  "error": null
}
```

### 퇴근 처리

권한: 직원

```http
POST /api/v1/employee/attendance/check-out
```

요청:

```json
{
  "beaconUuid": "fda50693-a4e2-4fb1-afcf-c6eb07647825",
  "beaconMajor": 101,
  "beaconMinor": 1,
  "rssi": -60,
  "deviceId": "test-device-001",
  "latitude": 37.5665,
  "longitude": 126.9780
}
```

응답:

```json
{
  "success": true,
  "data": {
    "recordId": 1,
    "status": "NORMAL",
    "checkedInAt": "2026-08-17T08:00:00",
    "checkedOutAt": "2026-08-17T17:00:00",
    "siteName": "101동 외벽 페인트 작업"
  },
  "error": null
}
```

### 내 출석 내역 조회

권한: 직원

```http
GET /api/v1/employee/attendance?startDate=2026-08-01&endDate=2026-08-31
```

쿼리 파라미터는 선택입니다.

| 이름 | 설명 |
| --- | --- |
| `startDate` | 조회 시작일 |
| `endDate` | 조회 종료일 |

응답:

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "employeeId": 2,
      "employeeName": "홍길동",
      "scheduleId": 1,
      "workSiteId": 1,
      "workSiteName": "101동 외벽 페인트 작업",
      "workDate": "2026-08-17",
      "checkedInAt": "2026-08-17T08:00:00",
      "checkedOutAt": "2026-08-17T17:00:00",
      "status": "NORMAL",
      "manualAdjusted": true
    }
  ],
  "error": null
}
```

## 4. 관리자 직원 관리 API

### 직원 생성

권한: 관리자

```http
POST /api/v1/admin/employees
```

요청:

```json
{
  "loginId": "employee02",
  "name": "김철수",
  "phone": "010-2222-2222"
}
```

응답:

```json
{
  "success": true,
  "data": {
    "employee": {
      "id": 3,
      "loginId": "employee02",
      "name": "김철수",
      "phone": "010-2222-2222",
      "role": "EMPLOYEE",
      "active": true
    },
    "temporaryPassword": "임시비밀번호"
  },
  "error": null
}
```

### 직원 목록 조회

권한: 관리자

```http
GET /api/v1/admin/employees
```

### 직원 단건 조회

권한: 관리자

```http
GET /api/v1/admin/employees/{employeeId}
```

### 직원 정보 수정

권한: 관리자

```http
PATCH /api/v1/admin/employees/{employeeId}
```

요청:

```json
{
  "name": "김철수",
  "phone": "010-3333-3333"
}
```

### 직원 비밀번호 초기화

권한: 관리자

```http
PATCH /api/v1/admin/employees/{employeeId}/password/reset
```

응답:

```json
{
  "success": true,
  "data": {
    "temporaryPassword": "임시비밀번호"
  },
  "error": null
}
```

### 직원 비활성화

권한: 관리자

```http
DELETE /api/v1/admin/employees/{employeeId}
```

## 5. 관리자 작업 현장 API

### 작업 현장 생성

권한: 관리자

```http
POST /api/v1/admin/work-sites
```

요청:

```json
{
  "name": "101동 외벽 페인트 작업",
  "address": "서울시 테스트구 테스트로 101",
  "description": "출석 서비스 테스트용 작업 현장"
}
```

### 활성 작업 현장 목록 조회

권한: 관리자

```http
GET /api/v1/admin/work-sites
```

### 작업 현장 단건 조회

권한: 관리자

```http
GET /api/v1/admin/work-sites/{workSiteId}
```

### 작업 현장 수정

권한: 관리자

```http
PATCH /api/v1/admin/work-sites/{workSiteId}
```

요청:

```json
{
  "name": "101동 외벽 페인트 작업",
  "address": "서울시 테스트구 테스트로 101",
  "description": "외벽 도장 작업"
}
```

### 작업 현장 비활성화

권한: 관리자

```http
DELETE /api/v1/admin/work-sites/{workSiteId}
```

## 6. 관리자 작업 일정 API

### 작업 일정 생성

권한: 관리자

```http
POST /api/v1/admin/work-schedules
```

요청:

```json
{
  "workSiteId": 1,
  "workDate": "2026-08-18",
  "startTime": "08:00:00",
  "endTime": "17:00:00",
  "lateGraceMinutes": 5,
  "earlyLeaveGraceMinutes": 5
}
```

### 작업 일정 단건 조회

권한: 관리자

```http
GET /api/v1/admin/work-schedules/{scheduleId}
```

### 작업 현장별 일정 목록 조회

권한: 관리자

```http
GET /api/v1/admin/work-schedules/work-sites/{workSiteId}
```

### 작업 일정 수정

권한: 관리자

```http
PATCH /api/v1/admin/work-schedules/{scheduleId}
```

요청:

```json
{
  "workDate": "2026-08-18",
  "startTime": "08:00:00",
  "endTime": "17:00:00",
  "lateGraceMinutes": 5,
  "earlyLeaveGraceMinutes": 5
}
```

## 7. 관리자 비콘 API

### 비콘 등록

권한: 관리자

```http
POST /api/v1/admin/beacons
```

요청:

```json
{
  "workSiteId": 1,
  "uuid": "fda50693-a4e2-4fb1-afcf-c6eb07647825",
  "major": 101,
  "minor": 1,
  "name": "101동 입구 비콘",
  "rssiThreshold": -75
}
```

### 작업 현장별 비콘 목록 조회

권한: 관리자

```http
GET /api/v1/admin/beacons/work-sites/{workSiteId}
```

### 비콘 수정

권한: 관리자

```http
PATCH /api/v1/admin/beacons/{beaconId}
```

요청:

```json
{
  "name": "101동 입구 비콘",
  "rssiThreshold": -75
}
```

### 비콘 비활성화

권한: 관리자

```http
DELETE /api/v1/admin/beacons/{beaconId}
```

## 8. 관리자 출석 관리 API

### 출석 현황 조건 조회

권한: 관리자

```http
GET /api/v1/admin/attendance?employeeId=2&workSiteId=1&startDate=2026-08-01&endDate=2026-08-31&status=NORMAL
```

쿼리 파라미터는 모두 선택입니다.

| 이름 | 설명 |
| --- | --- |
| `employeeId` | 직원 ID |
| `workSiteId` | 작업 현장 ID |
| `startDate` | 조회 시작일 |
| `endDate` | 조회 종료일 |
| `status` | 출석 상태 |

### 출석 수기 수정

권한: 관리자

```http
PATCH /api/v1/admin/attendance/{attendanceRecordId}
```

요청:

```json
{
  "status": "NORMAL",
  "checkedInAt": "2026-08-17T08:00:00",
  "checkedOutAt": "2026-08-17T17:00:00",
  "reason": "관리자 확인 후 정상 출근 처리"
}
```

수기 입력 검증 규칙:

- `ABSENT` 상태는 출근/퇴근 시간이 없어야 함
- `ABSENT`가 아닌 상태는 출근 시간이 필요함
- 퇴근 시간은 출근 시간보다 빠를 수 없음

### 결석 처리

권한: 관리자

```http
POST /api/v1/admin/attendance/absences
```

요청:

```json
{
  "employeeId": 2,
  "scheduleId": 2,
  "reason": "absence test"
}
```

응답:

```json
{
  "success": true,
  "data": {
    "id": 2,
    "employeeId": 2,
    "employeeName": "홍길동",
    "scheduleId": 2,
    "workSiteId": 1,
    "workSiteName": "101동 외벽 페인트 작업",
    "workDate": "2026-08-18",
    "checkedInAt": null,
    "checkedOutAt": null,
    "status": "ABSENT",
    "manualAdjusted": true
  },
  "error": null
}
```

### 출석 수정 이력 조회

권한: 관리자

```http
GET /api/v1/admin/attendance/{attendanceRecordId}/adjustments
```

응답:

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "attendanceRecordId": 1,
      "adjustedByUserId": 1,
      "adjustedByName": "관리자",
      "beforeStatus": "LATE",
      "afterStatus": "NORMAL",
      "beforeCheckedInAt": "2026-08-17T21:56:30",
      "afterCheckedInAt": "2026-08-17T08:00:00",
      "beforeCheckedOutAt": "2026-08-17T22:00:27",
      "afterCheckedOutAt": "2026-08-17T17:00:00",
      "reason": "관리자 확인 후 정상 출근 처리",
      "createdAt": "2026-08-17T22:23:37"
    }
  ],
  "error": null
}
```

## 9. 관리자 급여 설정 API

### 직원별 현장 급여 설정 생성

권한: 관리자

```http
POST /api/v1/admin/pay-settings
```

요청:

```json
{
  "employeeId": 2,
  "workSiteId": 1,
  "dailyWage": 150000,
  "taxRate": 3.30
}
```

응답:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "employeeId": 2,
    "employeeName": "홍길동",
    "workSiteId": 1,
    "workSiteName": "101동 외벽 페인트 작업",
    "dailyWage": 150000,
    "taxRate": 3.30,
    "taxAmount": 4950,
    "netDailyWage": 145050,
    "active": true
  },
  "error": null
}
```

### 현장별 급여 설정 조회

권한: 관리자

```http
GET /api/v1/admin/pay-settings/work-sites/{workSiteId}
```

### 직원별 급여 설정 조회

권한: 관리자

```http
GET /api/v1/admin/pay-settings/employees/{employeeId}
```

### 직원 + 현장 급여 설정 조회

권한: 관리자

```http
GET /api/v1/admin/pay-settings/employees/{employeeId}/work-sites/{workSiteId}
```

### 급여 설정 수정

권한: 관리자

```http
PATCH /api/v1/admin/pay-settings/{paySettingId}
```

요청:

```json
{
  "dailyWage": 160000,
  "taxRate": 3.30
}
```

### 급여 설정 비활성화

권한: 관리자

```http
DELETE /api/v1/admin/pay-settings/{paySettingId}
```

## 10. 주요 에러 코드

| 코드 | 설명 |
| --- | --- |
| `BAD_REQUEST` | 잘못된 요청 또는 비즈니스 검증 실패 |
| `INVALID_STATE` | 현재 상태에서 처리할 수 없는 요청 |
| `VALIDATION_ERROR` | DTO 검증 실패 |
| `INVALID_JSON` | JSON 파싱 실패 |
| `UNAUTHORIZED` | 인증 필요 |
| `FORBIDDEN` | 접근 권한 없음 |

## 11. 개발용 샘플 데이터

`dev` 프로필에서 사용할 수 있는 테스트 계정입니다.

| 역할 | 아이디 | 비밀번호 |
| --- | --- | --- |
| 관리자 | `admin` | `password` |
| 직원 | `employee01` | `password` |

샘플 비콘 정보:

```json
{
  "beaconUuid": "fda50693-a4e2-4fb1-afcf-c6eb07647825",
  "beaconMajor": 101,
  "beaconMinor": 1,
  "rssi": -60,
  "deviceId": "test-device-001"
}
```

# REST API 컨벤션

## 1. 기본 규칙

- 기본 경로: `/api/v1`
- 데이터 형식: JSON
- 인증 방식: JWT Bearer Token
- 시간 형식: ISO-8601
- 기준 시간대: `Asia/Seoul`
- 사용자 역할:
  - `ADMIN`: 관리자
  - `EMPLOYEE`: 직원

인증이 필요한 요청은 다음 헤더를 사용합니다.

```http
Authorization: Bearer {accessToken}
Content-Type: application/json
```

## 2. URL 작성 규칙

URL은 기능 이름보다 자원 이름을 기준으로 작성합니다.

관리자 API는 `/api/v1/admin` 하위에 둡니다.

```text
GET    /api/v1/admin/work-sites
POST   /api/v1/admin/work-sites
GET    /api/v1/admin/work-sites/{workSiteId}
PATCH  /api/v1/admin/work-sites/{workSiteId}
DELETE /api/v1/admin/work-sites/{workSiteId}
```

직원 API는 `/api/v1/employee` 하위에 둡니다.

```text
GET  /api/v1/employee/attendance
POST /api/v1/employee/attendance/check-in
POST /api/v1/employee/attendance/check-out
```

피해야 할 예:

```text
/api/v1/getWorkSites
/api/v1/createAttendance
/api/v1/updateUser
```

출근, 퇴근처럼 행위 자체가 중요한 업무 기능은 예외적으로 명령형 API를 사용합니다.

```text
POST /api/v1/employee/attendance/check-in
POST /api/v1/employee/attendance/check-out
POST /api/v1/admin/attendance/absences
```

## 3. HTTP 메서드

| 메서드 | 용도 |
| --- | --- |
| `GET` | 데이터 조회 |
| `POST` | 데이터 생성 또는 명령 실행 |
| `PATCH` | 데이터 일부 수정 |
| `PUT` | 전체 데이터 교체, 필요한 경우에만 사용 |
| `DELETE` | 데이터 삭제 또는 비활성화 |
| `OPTIONS` | CORS preflight 요청 |

현재 삭제 API는 실제 데이터를 즉시 삭제하기보다 `active=false`로 비활성화하는 방식으로 사용합니다.

## 4. HTTP 상태 코드

| 상태 코드 | 의미 |
| --- | --- |
| `200 OK` | 조회, 생성, 수정, 삭제 요청 처리 성공 |
| `400 Bad Request` | 잘못된 요청 또는 비즈니스 검증 실패 |
| `401 Unauthorized` | 인증 필요 |
| `403 Forbidden` | 권한 없음 |
| `409 Conflict` | 현재 상태에서 처리할 수 없는 요청 |
| `500 Internal Server Error` | 서버 오류 |

현재 구현은 생성 API도 `200 OK`를 반환합니다. 추후 API 성숙도를 높일 때 생성 응답을 `201 Created`로 분리할 수 있습니다.

## 5. 응답 형식

성공 응답:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "101동 외벽 페인트 작업"
  },
  "error": null
}
```

목록 응답:

```json
{
  "success": true,
  "data": [],
  "error": null
}
```

에러 응답:

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "BAD_REQUEST",
    "message": "출석 가능한 비콘 범위 안에 있지 않습니다."
  }
}
```

## 6. 날짜와 시간

API 요청과 응답의 날짜와 시간은 ISO-8601 형식을 사용합니다.

```json
{
  "workDate": "2026-08-17",
  "startTime": "08:00:00",
  "endTime": "17:00:00",
  "checkedInAt": "2026-08-17T08:03:20"
}
```

현재 `LocalDateTime` 응답은 오프셋 없이 반환됩니다. 클라이언트에서는 서버 기준 시간대를 `Asia/Seoul`로 해석합니다.

## 7. 페이지네이션

현재 MVP의 목록 API는 페이지네이션 없이 `List`를 반환합니다.

추후 데이터가 많아지면 다음 형태를 도입할 수 있습니다.

```text
GET /api/v1/admin/attendance?page=0&size=20&sort=workDate,desc
```

권장 페이지 응답 형식:

```json
{
  "success": true,
  "data": {
    "items": [],
    "page": 0,
    "size": 20,
    "totalElements": 100,
    "totalPages": 5
  },
  "error": null
}
```

## 8. 패키지 컨벤션

현재 프로젝트 루트 패키지:

```text
com.example.demo
```

현재 구조:

```text
global
- common
- config
- exception
- security

domain
- attendance
- assignment
- auth
- beacon
- payroll
- schedule
- user
- worksite
```

각 도메인 내부 구조는 가능하면 다음 형태를 유지합니다.

```text
attendance
- controller
- service
- repository
- dto
- entity
```

## 9. Java 네이밍

| 종류 | 예시 |
| --- | --- |
| Controller | `AttendanceController` |
| Service | `AttendanceService` |
| Repository | `AttendanceRecordRepository` |
| Entity | `AttendanceRecord` |
| Request DTO | `AttendanceCheckRequest` |
| Response DTO | `AttendanceRecordResponse` |

## 10. DB 네이밍

테이블명과 컬럼명은 snake_case를 사용합니다.

```text
users
work_sites
beacons
work_schedules
work_assignments
attendance_records
attendance_adjustments
employee_project_pay_setting
```

## 11. 출석 처리 규칙

- 모바일 앱은 비콘 감지와 출퇴근 요청 전송을 담당합니다.
- 출석 가능 여부와 출석 상태 판정은 서버에서 처리합니다.
- 서버는 `NORMAL`, `LATE`, `EARLY_LEAVE`, `LATE_AND_EARLY_LEAVE`, `ABSENT` 상태를 관리합니다.
- 관리자가 수기로 수정한 출석은 수정 이력을 남깁니다.
- 비콘 ID, RSSI, 기기 ID, 위치 정보는 출석 증빙 데이터로 보관합니다.

## 12. Enum

```java
public enum UserRole {
    ADMIN,
    EMPLOYEE
}
```

```java
public enum AttendanceStatus {
    NORMAL,
    LATE,
    EARLY_LEAVE,
    LATE_AND_EARLY_LEAVE,
    ABSENT,
    MANUAL_FIXED
}
```

## 13. CORS

`dev` 프로필에서는 브라우저 기반 프론트 개발을 위해 다음 출처를 허용합니다.

```text
http://localhost:*
http://127.0.0.1:*
```

허용 헤더:

```text
Authorization
Content-Type
```

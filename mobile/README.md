# PFT Mobile App

아파트 페인트 작업 현장의 직원 출퇴근과 관리자 기능을 제공하는 Flutter 앱입니다.

## 실행 전 준비

백엔드 서버를 먼저 실행해야 합니다.

```bash
cd /d/demo/backend
./gradlew.bat bootRun
```

기본 백엔드 주소는 다음과 같습니다.

```text
http://localhost:8080/api/v1
```

## 실행 방법

### Chrome

개발 중 가장 빠르게 확인할 때 사용합니다.

```bash
cd /d D:\demo\PFT\mobile
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

### Android 에뮬레이터

Android 에뮬레이터에서 PC의 `localhost`에 접근할 때는 `10.0.2.2`를 사용합니다.

```bash
cd /d D:\demo\PFT\mobile
flutter run -d emulator --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

실제 에뮬레이터 ID는 아래 명령으로 확인할 수 있습니다.

```bash
flutter devices
```

### Android 실기기

휴대폰과 PC가 같은 와이파이에 연결되어 있어야 합니다.

`192.168.x.x` 부분은 PC의 실제 내부 IP로 바꿉니다.

```bash
cd /d D:\demo\PFT\mobile
flutter run -d {deviceId} --dart-define=API_BASE_URL=http://192.168.x.x:8080/api/v1
```

## 현재 비콘 처리 방식

`BeaconScannerService`는 실행 플랫폼에 따라 다르게 동작합니다.

- Chrome/Web: 개발 편의를 위해 테스트 비콘 값을 반환
- Android/iOS: `dchs_flutter_beacon`을 이용해 실제 iBeacon을 스캔하고 RSSI가 가장 강한 비콘을 선택

테스트 비콘 값:

```text
UUID  fda50693-a4e2-4fb1-afcf-c6eb07647825
major 101
minor 1
RSSI  -60
```

Android/iOS에서 스캔할 iBeacon UUID는 기본값으로 샘플 비콘 UUID를 사용합니다.

다른 UUID를 테스트할 때는 실행 시 `IBEACON_UUID`를 지정합니다.

```bash
flutter run -d {deviceId} \
  --dart-define=API_BASE_URL=http://192.168.x.x:8080/api/v1 \
  --dart-define=IBEACON_UUID=fda50693-a4e2-4fb1-afcf-c6eb07647825
```

Windows에서 Flutter 플러그인을 사용할 때 `flutter pub get`이 symlink 오류로 실패하면 Windows 개발자 모드를 활성화해야 합니다.

## 주요 기능

- 로그인
- 로그인 아이디 저장
- 자동 로그인
- 로그아웃
- 역할 기반 관리자/직원 홈 분기
- 직원 출근/퇴근
- 직원 출석 내역 조회
- 마이페이지 조회, 수정, 비밀번호 변경
- 관리자 작업 현장 관리
- 관리자 작업 일정 관리
- 관리자 비콘 관리
- 관리자 직원 관리
- 관리자 급여 설정
- 관리자 출석 현황 조회, 필터, 수기 수정, 결석 처리
- 관리자 출석 수정 이력 조회

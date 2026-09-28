# PFT

PFT는 외벽 도장 공사를 관리하는 단말기용 로컬 ERP 앱입니다.

Vue와 TypeScript로 화면과 업무 로직을 구성하고, Capacitor를 통해 Android 앱으로 실행합니다. Android에서는 SQLite에 데이터를 저장하므로 별도의 서버나 인터넷 연결 없이 사용할 수 있습니다.

## 주요 기능

- 현장 등록, 수정, 상태 관리
- 근로자 등록, 수정, 활동 상태 관리
- 현장별 수기 출석 및 작업 직책 기록
- 현장별 투입 인원, 도장공, 작업일, 인건비 조회
- 근로자별 현장, 직책, 출석, 인건비 이력 조회
- 대시보드 현황 및 인건비 요약

## 프로젝트 구조

```text
PFT/
└─ mobile-vue/
   ├─ src/       Vue 및 TypeScript 소스
   └─ android/   Capacitor Android 프로젝트
```

## 개발 실행

```bash
cd mobile-vue
npm install
npm run dev
```

기본 개발 주소는 `http://127.0.0.1:5173/`입니다.

## 검사 및 빌드

```bash
npm run type-check
npm run test:unit -- --run
npm run lint
npm run build
npx cap sync android
```

Android 디버그 APK 빌드:

```powershell
cd mobile-vue\android
.\gradlew.bat assembleDebug
```

생성된 APK는 `mobile-vue/android/app/build/outputs/apk/debug/app-debug.apk`에 저장됩니다.

## 데이터 저장

- Android 앱: SQLite
- 브라우저 개발 미리보기: `localStorage`
- 서버 및 Spring Boot 백엔드: 사용하지 않음

브라우저 미리보기 데이터와 Android SQLite 데이터는 서로 분리되어 있습니다.

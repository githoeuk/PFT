# Android 릴리스 APK 관리

## 반드시 보관할 파일

- `pft-release.jks`: 모든 릴리스 APK에 사용하는 서명 키
- `keystore.properties`: 키 별칭과 비밀번호

두 파일은 Git에서 제외된다. 분실하면 기존 앱을 업데이트할 수 없으므로 서로 다른 안전한
위치에 별도로 백업한다. `keystore.properties`에는 비밀번호가 평문으로 들어 있으므로 외부에
공개하지 않는다.

## 새 버전 빌드

1. `app/build.gradle`의 `versionCode`를 이전보다 1 이상 높인다.
2. 사용자에게 표시할 `versionName`을 변경한다.
3. 프로젝트 루트에서 다음 명령을 실행한다.

```bash
npm run build
npx cap sync android
cd android
./gradlew assembleRelease
```

Windows PowerShell에서는 마지막 명령을 `.\gradlew.bat assembleRelease`로 실행한다.

완성된 파일은 `app/build/outputs/apk/release/app-release.apk`에 생성된다.

## 업데이트 설치 조건

- `applicationId`는 계속 `com.paintfieldtracker.pft`를 사용한다.
- 모든 릴리스 APK는 같은 `pft-release.jks`로 서명한다.
- 새 APK의 `versionCode`는 설치된 버전보다 높아야 한다.
- 기존 앱을 삭제하지 않고 APK를 실행해 `업데이트`를 선택한다.

디버그 키로 설치한 앱에는 릴리스 키로 만든 APK를 바로 덮어쓸 수 없다. 처음 한 번은 기존
앱에서 JSON 백업을 내보내고 디버그 앱을 삭제한 다음 릴리스 앱을 설치해 복원해야 한다.

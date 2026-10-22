# 맥(Apple Silicon)에서 Tomoni 실행하기

> 작성: 김예나 · 테스트 환경: MacBook Air (arm64), Flutter 3.47.5 / Dart 3.13.4, Android Studio 에뮬레이터

README의 실행 방법은 Windows(PowerShell) 기준이라, 맥에서 처음 세팅하며 겪은 문제와 해결 방법을 정리했습니다.

---

## 1. 기본 도구 설치

```bash
xcode-select --install                                     # 이미 있으면 "already installed"
sudo softwareupdate --install-rosetta --agree-to-license   # Apple Silicon(arm64)만
```

칩 확인: `uname -m` → `arm64`면 Apple Silicon.

Homebrew가 없으면 [brew.sh](https://brew.sh) 설치 후, 설치 끝에 안내되는 PATH 설정 두 줄을 꼭 실행하세요. 오래된 Homebrew면 먼저 업데이트합니다.

```bash
brew update
```

---

## 2. Flutter 설치

```bash
brew install --cask flutter
flutter --version     # Dart 3.11.5 이상이어야 함 (pubspec 요구사항)
flutter doctor
```

---

## 3. Android Studio · 에뮬레이터

```bash
brew install --cask android-studio
```

1. Android Studio 첫 실행 → **Standard** 설치, 라이선스는 모두 **Accept**
2. **More Actions → SDK Manager → SDK Tools** → `Android SDK Command-line Tools (latest)` 체크 → Apply
3. **More Actions → Virtual Device Manager → +** → Medium Phone 또는 Pixel 선택 → 추천(★) `arm64-v8a` 이미지 다운로드 → Finish

> `flutter doctor --android-licenses`에서 "sdkmanager is deprecated / --licenses option is no longer needed" 경고가 나와도 정상입니다.

에뮬레이터가 `flutter run` 목록에 안 보이면:

```bash
flutter config --android-sdk ~/Library/Android/sdk
flutter emulators                       # 이름 확인
flutter emulators --launch Medium_Phone # 홈 화면까지 부팅된 뒤 실행
```

---

## 4. ⚠️ Java 버전 문제 (빌드 실패 시)

최신 Android Studio에 포함된 **Java 25는 프로젝트의 Gradle 8.14와 호환되지 않아** 안드로이드 빌드가 실패합니다. 프로젝트 파일을 바꾸지 않고, Flutter가 Java 21을 쓰도록 설정합니다.

```bash
brew install --cask temurin@21
flutter config --jdk-dir="$(/usr/libexec/java_home -v 21)"
```

> 근본 해결은 `android/gradle/wrapper/gradle-wrapper.properties`의 Gradle 버전을 올리는 것입니다 (팀 협의 필요).

---

## 5. 코드 받기

```bash
cd ~/Desktop
git clone https://github.com/OJS-dev-code/Tomoni.git
cd Tomoni
git checkout eunso     # 최신 앱 코드 브랜치
```

| 브랜치 | 내용 |
|---|---|
| `eunso` | 최신 UI + 전체 기능 (실행은 이 브랜치) |
| `js-0.6` | Render 운영 서버 배포 브랜치 (직접 푸시 금지) |
| `jeongseo`, `backup-onboarding-v1` | 6월 이전 UI 저장본 |
| `main`, `yena` | 초기 상태 |

`git checkout`이 `pubspec.lock` 등의 로컬 변경 때문에 막히면 (Flutter가 자동 수정한 파일입니다):

```bash
git stash
git checkout eunso
```

---

## 6. ⚠️ 빈 이미지 폴더 만들기

`pubspec.yaml`에 등록된 `backgrounds`, `characters`, `scenario` 폴더가 저장소에 없어서 (Git은 빈 폴더를 올리지 않음) 빌드 시 에러가 납니다.

```bash
mkdir -p assets/images/backgrounds assets/images/characters assets/images/scenario
flutter pub get
```

---

## 7. 실행

```bash
flutter run --dart-define=API_BASE_URL=https://tomoni-api.onrender.com
```

> **`--dart-define`을 빼면 안 됩니다.** 기본 서버 주소가 로컬(`10.0.2.2:8000`)이라 로그인부터 실패합니다.

- 기기 선택: 에뮬레이터 번호 입력 (크롬은 `-d chrome`)
- 첫 빌드는 5~10분 소요, Gradle/AGP/Kotlin 버전 **경고는 무시해도 됨**
- 시작 시 "서버 준비중"이 1분 가까이 뜰 수 있음 (무료 서버가 sleep에서 깨어나는 중)
- 서버 상태 확인: 브라우저에서 `https://tomoni-api.onrender.com/api/v1/health` → `"status":"ok"`

### 실행 단축 명령 (선택)

`~/.zshrc`에 추가하면 `tomoni` 한 단어로 에뮬레이터 부팅 + 앱 실행:

```bash
tomoni() {
  local ADB=~/Library/Android/sdk/platform-tools/adb
  cd ~/Desktop/Tomoni || return
  if ! "$ADB" devices | grep -q "^emulator-"; then
    flutter emulators --launch Medium_Phone
  fi
  "$ADB" wait-for-device
  until [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 2; done
  flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://tomoni-api.onrender.com
}
```

---

## 8. ⚠️ 에뮬레이터 마이크 설정

Tomoni 대화는 음성 입력이라, 에뮬레이터가 맥 마이크를 쓰도록 설정해야 합니다. 안 하면 "녹음 중"은 뜨지만 빈 소리가 전송되어 음성 인식이 실패합니다.

1. 에뮬레이터 오른쪽 툴바 **⋯ (Extended controls) → Microphone**
2. **Virtual microphone uses host audio input** 켜기
3. 맥 **시스템 설정 → 개인정보 보호 및 보안 → 마이크**에서 에뮬레이터 허용

> 에뮬레이터를 재시작하면 이 설정이 꺼질 수 있으니 매번 확인하세요. 마이크가 안 되면 대화 화면의 키보드 버튼으로 텍스트 입력이 가능합니다.

---

## 9. APK 빌드 (공유용)

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://tomoni-api.onrender.com
open build/app/outputs/flutter-apk/    # app-release.apk
```

- 안드로이드에서만 설치 가능, "출처를 알 수 없는 앱" 허용 필요
- 공유는 구글 드라이브 링크 권장

---

## 10. 문제 해결 요약

| 증상 | 원인 | 해결 |
|---|---|---|
| `Unsupported class file major version` / Gradle 오류 | Java 25 ↔ Gradle 8.14 | 4장: Java 21 설정 |
| `unable to find directory entry in pubspec.yaml` | 빈 assets 폴더 없음 | 6장: `mkdir -p` |
| 기기 목록에 에뮬레이터 없음 | 미부팅 또는 SDK 경로 | 3장: 부팅 확인, `flutter config --android-sdk` |
| 로그인 실패 | 서버 주소 미지정 | 7장: `--dart-define` |
| 파란 화면 온보딩(옛 디자인) | `jeongseo` 브랜치 실행 중 | `git checkout eunso` |
| 음성 인식 실패 | 에뮬레이터 마이크 꺼짐 | 8장 |
| 대화가 한 턴 만에 끝남 | 목표 1개 + 관대한 판정 설계 | 목표를 2~3개 선택 |

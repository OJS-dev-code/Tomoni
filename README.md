# Tomoni (トモニ)

한국인을 위한 **일본어 경어(敬語) 학습** Flutter 앱 + FastAPI 백엔드.

AI와 역할극 형태의 상황 대화를 통해 실전 경어를 연습하고, 세션 종료 후 피드백 노트로 복습하는 것을 목표로 합니다.

---

## 진행 현황 (Phase)

| Phase | 내용 | 상태 |
|-------|------|------|
| **1** | FastAPI + Firebase Auth/Firestore, 프로필 API, Flutter 로그인·초기 설정·설정 화면 | ✅ 완료 |
| **2** | Gemini/OpenAI 상황극 (주제·목표·세션·대화), Flutter 상황극 플로우 연동 | ✅ 완료 |
| **3** | OpenAI STT/TTS, 음성 채팅 UI, 힌트 패널, TTS 캐시 | ✅ 완료 |
| **4** | 세션 종료 후 **피드백 노트** 생성 API + Flutter `note_page` 연동 | ✅ 완료 |
| **5** | **오답 패턴 분석** (반복 실수 추적·추천) | ⏸️ 코드 작성됨, **배포 최소화로 비활성** |
| **6** | **Render** 백엔드 배포 | ✅ `tomoni-api.onrender.com` 운영 중 |

**현재:** 백엔드 Render 배포 완료 · Flutter는 로컬/Web 실행 (`API_BASE_URL`로 Render 연동) · Phase 5 UI/API는 주석 처리 상태

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 클라이언트 | Flutter 3.11+, Dart |
| 인증 | Firebase Auth |
| DB | Cloud Firestore (프로필) |
| 백엔드 | FastAPI, Python 3.11+ |
| 대화 LLM | **OpenAI `gpt-4o-mini`** (권장) · Gemini (폴백/대체) |
| 음성 | OpenAI Whisper (STT), OpenAI TTS |
| TTS 캐시 | Firebase Storage (실패 시 base64 인라인 + 메모리 캐시) |

---

## LLM 제공자: Gemini → OpenAI 전환

초기에는 **Gemini**(`gemini-2.0-flash` / `gemini-2.5-flash`)로 주제·목표·대화를 생성했습니다.

개발 중 아래 문제로 **대화 엔진을 OpenAI로 전환**했습니다.

- Gemini **429(할당량)** 빈번
- mock/반복 응답으로 대화 품질 저하
- 목표·대화 프롬프트 개선 후에도 OpenAI가 더 자연스러움

### 현재 구조

```
DIALOGUE_PROVIDER=openai  →  gpt-4o-mini 우선
                          →  실패 시 gemini 자동 폴백 (try_generate_json)
DIALOGUE_PROVIDER=gemini  →  gemini 우선
                          →  실패 시 openai 폴백
```

- **STT/TTS**는 처음부터 **OpenAI 전용** (Whisper + TTS)
- **주제·목표·세션·대화** 로직은 `gemini_service.py`에 프롬프트가 모여 있으나, 실제 호출은 `llm_service.py`가 provider에 따라 OpenAI/Gemini를 선택

---

## 앱 기능 요약

### 인증·온보딩
- Firebase 이메일 로그인/회원가입
- 스플래시 → 온보딩 → 초기 설정(6단계) → 메인

### 초기 설정 (Setup Step 1~6)
| Step | 항목 |
|------|------|
| 1 | 성별, 생년월일 |
| 2 | 일본어 실력 수준 |
| 3 | 학습 기간 |
| 4 | 학습 목적 (복수 선택) |
| 5 | 취미 (복수 선택) |
| 6 | AI·표시 설정 (아래 참고) |

설정 완료 후 FastAPI `/users/profile`에 저장됩니다.

### 앱 기본 설정 (Step 6 / 설정 화면)

| 설정 키 | 옵션 | 설명 |
|---------|------|------|
| `aiSpeed` | `천천히` / `현지인 속도로` | AI TTS 재생 속도 |
| `showContentFromStart` | `예` / `아니오` | 대화 일본어를 처음부터 텍스트로 표시 |
| `showKoreanTranslation` | `예` / `아니오` | AI 발화 아래 한국어 번역 표시 |
| `showKoreanPronunciation` | `예` / `아니오` | 추천 답변(힌트) 한국어 발음 표시 |

로컬 기본값은 `lib/services/user_data_service.dart`에, 서버 프로필은 Firestore에 저장됩니다.

### 상황극 플로우
1. **홈** → 마이크 권한 → **주제 선택** (`scenario_topic_page`)
2. **목표 선택** (`scenario_goal_page`) — AI 추천 `~하기` 형태 대화 목표
3. **확인 화면** (`scenario_confirm_page`) — AI 역할·사용자 역할·장소 preview API
4. **음성 채팅** (`scenario_chat_page`)
   - 텍스트 입력 없음, **마이크 녹음만**
   - AI 말: 응답 시 **자동 TTS** + 다시듣기
   - 사용자 말: STT 후 전송, **다시듣기만** (자동 재생 없음)
   - **목표 배지** 탭 → 바텀시트 체크리스트
   - **힌트 버튼** (마이크 옆) 탭 시 AI 추천 답변 패널 표시
   - 힌트 내용대로 말한 발화 → **피드백 노트 상세** 「힌트대로 답한 표현」 섹션에 기록

### Phase 5 — 오답 패턴 (⏸️ 비활성, 코드만 보관)

> 배포 최소화를 위해 **런타임 연동은 꺼 둠**. 재활성화 시 코드에서 `Phase 5 (보류)` 주석 검색.

- `home_mistake_patterns.dart`, `mistake_service.py` 등 파일은 유지
- 비활성: 홈 「자주 하는 실수」 카드, `/api/v1/mistakes/*`, 약점 기반 주제 병합, 피드백→패턴 Firestore 기록

### 피드백 노트 (Phase 4)
- 세션 종료 시 LLM이 대화를 분석해 **피드백 노트** 자동 생성 (Firestore 저장)
- **1~5점** 평가 + 항목별 교정·추천 표현 (일본어/발음/번역)
- 종료 후 **피드백 상세 화면**으로 자동 이동 (`showHomeButton` — 상황극 종료 시에만 「홈 화면으로」)
- **노트 탭** · **홈 캘린더**에서 월별 조회 (◀ 연월 ▶ 바텀시트)

### 홈 화면
- **학습 캘린더** (제목 없음) → 아래 **「AI와 상황극 시작하기」** 버튼
- 상황극 시작 전 **마이크 권한** 요청 · 거부 시 「마이크 접근을 허용해야 AI와 상황극이 가능합니다.」

### Render 콜드 스타트 UX
- **스플래시**: primary 배경 + Tomoni + 「서버 준비중」 + 상단 로딩 바 (`/health` 재시도)
- **Web 부트**: `web/index.html` — Flutter 로드 전에도 동일 primary + Tomoni (흰 화면 방지)
- **API 요청 중**: 화면 최상단 primary `LinearProgressIndicator` (`ApiLoadingService`)

### 메인 탭
- 홈 / 노트 / 설정 (`lib/screens/main_screen.dart`)

---

## 프로젝트 구조

```
Tomoni_flutter/
├── lib/                          # Flutter 앱
│   ├── main.dart
│   ├── config/
│   │   └── api_config.dart       # 플랫폼별 API URL
│   ├── constants/
│   │   └── app_constants.dart
│   ├── models/
│   │   └── feedback_note.dart
│   ├── services/
│   │   ├── api_service.dart      # HTTP + Firebase ID 토큰
│   │   ├── auth_service.dart
│   │   ├── audio_service.dart    # 녹음, STT, TTS 재생
│   │   ├── scenario_service.dart # 상황극 API
│   │   └── user_data_service.dart
│   ├── screens/
│   │   ├── auth/                 # login, signup
│   │   ├── setup/                # step1~6, summary
│   │   ├── scenario/             # topic, goal, confirm, chat
│   │   ├── note/                 # note, note_detail (mock)
│   │   ├── settings/
│   │   └── home/
│   └── widgets/
│       ├── chat_bubble.dart
│       ├── hint_panel.dart       # AI 추천 답변 카드
│       └── ...
├── assets/images/                # 배경, 캐릭터, 아이콘, 상황극 이미지
├── android/app/google-services.json
└── backend/                      # FastAPI
    ├── .env.example
    ├── Dockerfile
    ├── render.yaml               # Phase 6 배포 템플릿
    ├── requirements.txt
    └── app/
        ├── main.py
        ├── config.py             # 환경변수, DIALOGUE_PROVIDER
        ├── dependencies/auth.py  # Firebase ID 토큰 검증
        ├── models/
        │   ├── user_profile.py
        │   ├── scenario.py
        │   └── audio.py
        ├── routers/
        │   ├── health.py
        │   ├── users.py          # GET/PUT /profile
        │   ├── scenarios.py      # topics, goals, preview, sessions
        │   └── audio.py          # STT, TTS
        └── services/
            ├── firebase.py
            ├── user_service.py
            ├── session_service.py
            ├── gemini_service.py # 주제·목표·대화 프롬프트
            ├── llm_service.py    # OpenAI/Gemini JSON 생성 + 폴백
            ├── openai_audio_service.py
            ├── tts_cache_service.py
            ├── storage_service.py
            └── voice_service.py  # AI 역할별 TTS voice 배정
```

---

## API 엔드포인트

Base URL: `http://localhost:8000` (개발)

| Method | Path | 설명 |
|--------|------|------|
| GET | `/api/v1/health` | 헬스체크 |
| GET | `/api/v1/users/profile` | 프로필 조회 |
| PUT | `/api/v1/users/profile` | 프로필 저장 |
| GET | `/api/v1/scenarios/topics` | 추천 주제 (최대 3) |
| GET | `/api/v1/scenarios/goals?topic=` | 추천 목표 (최대 3) |
| POST | `/api/v1/scenarios/preview` | 역할·장소 미리보기 |
| POST | `/api/v1/scenarios/sessions` | 세션 생성 |
| POST | `/api/v1/scenarios/sessions/{id}/messages` | 메시지 전송 + AI 응답 |
| POST | `/api/v1/scenarios/sessions/{id}/end` | 세션 종료 + 피드백 노트 생성 |
| GET | `/api/v1/notes?year=&month=` | 월별 피드백 노트 목록 |
| GET | `/api/v1/notes/{id}` | 피드백 노트 상세 |
| GET | `/api/v1/mistakes/patterns?limit=` | ⏸️ 비활성 — 오답 패턴 목록 |
| GET | `/api/v1/mistakes/recommendations` | ⏸️ 비활성 — 약점 기반 주제 |
| POST | `/api/v1/audio/stt` | 음성 → 텍스트 (Whisper) |
| POST | `/api/v1/audio/tts` | 텍스트 → 음성 (TTS) |

인증: `Authorization: Bearer <Firebase ID Token>`

---

## 환경 설정

### 백엔드 (`backend/.env`)

`backend/.env.example`을 복사해 사용합니다. **`.env`는 git에 커밋하지 마세요.**

```env
# Server
ENVIRONMENT=development
PORT=8000
ALLOW_MOCK_AUTH=true          # Firebase 없이 로컬 테스트 시 true

# Firebase
FIREBASE_PROJECT_ID=tomoni-22782
FIREBASE_CREDENTIALS_PATH=credentials/firebase-adminsdk.json
FIREBASE_STORAGE_BUCKET=tomoni-22782.firebasestorage.app

# 대화 엔진 (권장: openai)
DIALOGUE_PROVIDER=openai
OPENAI_API_KEY=sk-...
OPENAI_CHAT_MODEL=gpt-4o-mini
OPENAI_WHISPER_MODEL=whisper-1
OPENAI_TTS_MODEL=tts-1
OPENAI_TTS_VOICE=nova

# Gemini (폴백 또는 DIALOGUE_PROVIDER=gemini)
GEMINI_API_KEY=...
GEMINI_MODEL=gemini-2.5-flash
```

필수 파일:
- `backend/credentials/firebase-adminsdk.json` — Firebase Admin SDK (gitignore 권장)
- `android/app/google-services.json` — Flutter Android Firebase

### Flutter API URL (`lib/config/api_config.dart`)

| 플랫폼 | 기본 URL |
|--------|----------|
| Web (Chrome) | `http://localhost:8000` |
| Android 에뮬레이터 | `http://10.0.2.2:8000` |
| Windows / 기타 | `http://127.0.0.1:8000` |
| 실기기 | `--dart-define=API_BASE_URL=http://<PC_IP>:8000` |
| **Render 배포 후** | `--dart-define=API_BASE_URL=https://tomoni-api.onrender.com` |

**운영 API:** `https://tomoni-api.onrender.com`

---

## Render 배포 (Phase 6)

백엔드만 Render에 올립니다. Flutter 앱은 로컬·스토어 빌드 시 `API_BASE_URL`로 배포 URL을 지정합니다.

### 1. Render Blueprint

1. [Render Dashboard](https://dashboard.render.com/) → **New** → **Blueprint**
2. GitHub 저장소 연결 · 브랜치 `js-0.6` · Blueprint path: **`backend/render.yaml`**
3. **Environment** 탭에서 아래 시크릿 입력 (`sync: false` 항목):

| 변수 | 설명 |
|------|------|
| `FIREBASE_PROJECT_ID` | Firebase 프로젝트 ID |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Admin SDK JSON **한 줄** (줄바꿈 없이 붙여넣기) |
| `FIREBASE_STORAGE_BUCKET` | 예: `tomoni-22782.firebasestorage.app` |
| `OPENAI_API_KEY` | STT·TTS·대화 엔진 |
| `GEMINI_API_KEY` | (선택) OpenAI 폴백용 |

`ALLOW_MOCK_AUTH`는 Blueprint에서 `false`로 고정됩니다. Firebase 자격 증명 없이는 기동하지 않습니다.

### 2. 배포 확인

```text
GET https://tomoni-api.onrender.com/api/v1/health
→ {"status":"ok","environment":"production",...}
```

Free 플랜은 **15분 미사용 시 sleep** → 앱 스플래시에서 헬스체크 재시도로 대응. 항상 켜두려면 Starter 유료 플랜 또는 외부 ping(UptimeRobot 등).

### 3. Flutter에서 Render API 사용

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://tomoni-api.onrender.com
```

Web `index.html` 변경 후에는 **hot reload 불가** — `flutter run` 재시작 필요.

### 4. Git push → Render 자동 재배포

```powershell
git add .
git status   # .env / credentials 미포함 확인
git commit -m "변경 요약"
git push origin js-0.6
```

### 5. 로컬 Docker 빌드 (선택)

```powershell
cd backend
docker build -t tomoni-api .
docker run --rm -p 8000:8000 --env-file .env tomoni-api
```

---

## 로컬 실행

### 1. 백엔드

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
# .env 에 API 키·Firebase 경로 입력
python -m uvicorn app.main:app --reload --port 8000
```

### 2. Flutter

```powershell
flutter pub get
flutter run -d chrome    # Web
flutter run              # Android
```

---

### iOS 마이크 권한

- `ios/Runner/Info.plist` — `NSMicrophoneUsageDescription`
- `ios/Podfile` — `PERMISSION_MICROPHONE=1` (Mac에서 `pod install` 필요)

---

## 2026-06-06 작업 요약

### Render · 배포
- Blueprint `backend/render.yaml` → **`tomoni-api`** Web Service 배포 (`js-0.6` 브랜치)
- Firebase Admin JSON · OpenAI 키 등 Render Environment 설정
- Flutter ↔ Render 연동: `--dart-define=API_BASE_URL=https://tomoni-api.onrender.com`

### 앱 UX
- **서버 준비중** 스플래시 + 헬스체크 재시도 (`ServerWarmupService`)
- API 요청 시 **상단 로딩 바** (`ApiLoadingService` + `TopLoadingBar`)
- **Web** `index.html` 부트 스플래시 — Flutter 로드 전 흰 화면 제거
- **홈**: 「학습 캘린더」 제목 제거, 주간 간격 축소, 상황극 버튼을 캘린더 아래로 이동

### 권한 · 피드백
- **마이크** Android/iOS/Web 공통 거부 메시지: 「마이크 접근을 허용해야 AI와 상황극이 가능합니다.」
- iOS `Podfile` + `MicrophonePermissionService`
- **힌트대로 답한 표현** → 피드백 노트 상세 `hintResponses` 섹션

### Phase 5 보류
- 홈 「자주 하는 실수」, mistakes API, 약점 주제 추천 — **주석 처리** (코드는 repo에 유지)

---

## 2026-06-05 작업 요약

### 대화·LLM
- Gemini 429·반복 응답 이슈 → **`DIALOGUE_PROVIDER=openai`** (`gpt-4o-mini`) 전환
- `llm_service.py`: OpenAI 우선 + Gemini 자동 폴백
- 주제: **상대방 있는 역할극만** (편지·혼자 활동 제외)
- 목표: 일본어 표현 나열 X → **`~하기` 형태 대화 행동 목표**, 뻔한 목표 필터
- 세션 시작: 기본 **`speakerFirst=user`** (사용자가 먼저 말하기)
- 확인 화면: preview API로 AI·사용자 역할·장소 표시

### 음성·UI (Phase 3)
- OpenAI STT/TTS 연동, 마이크 녹음 UI (녹음 앱 스타일 하단바)
- TTS: Firebase Storage 캐시, **404 시 base64 인라인** 폴백
- `ChatBubble`: AI 자동 재생 / 사용자 다시듣기만
- **`HintPanel`**: AI 추천 답변 — **10초 자동 표시 → 마이크 옆 힌트 버튼 탭 시 표시**로 변경

### 기타
- Chrome Web API URL 플랫폼 분기 (`api_config.dart`)
- Cursor 대화는 워크스페이스별 로컬 저장(재시작 후 대부분 유지, 100% 보장 X) — 중요 결정은 README·코드에 기록

---

## 다음 작업 (권장 순서)

1. **Flutter Web 배포** — Firebase Hosting + `flutter build web --dart-define=API_BASE_URL=...`
2. **Phase 5 재활성** — `Phase 5 (보류)` 주석 해제 후 E2E
3. **Android** — `flutter build appbundle` · Play Store (또는 APK 테스트)
4. **iOS** — Mac에서 `pod install` · TestFlight (Windows만으로는 불가)
5. Render **Starter** 업그레이드 (콜드 스타트 제거, 선택)

### 현재 부족한 점

| 항목 | 상태 |
|------|------|
| Flutter 앱 URL 배포 | ❌ 로컬/`flutter run`만 — Hosting·스토어 미배포 |
| `API_BASE_URL` | ⚠️ 빌드/실행 시 매번 `--dart-define` 필요 (기본값은 localhost) |
| Render Free sleep | ⚠️ 15분 후 sleep — 스플래시 워밍업으로 UX만 완화 |
| Phase 5 기능 | ⏸️ 코드만 있고 UI·API 비활성 |
| iOS 실기기 검증 | ⚠️ Podfile 추가됨, Mac `pod install`·실기 테스트 미완 |
| Firebase Web Auth | ⚠️ Hosting URL 배포 시 승인된 도메인 추가 필요 |
| Git 원격 동기화 | ⚠️ 로컬 변경분 push 여부 팀별 확인 |

---

## 라이선스 / 기타

개인 학습 프로젝트. `publish_to: 'none'` (pub.dev 미배포).

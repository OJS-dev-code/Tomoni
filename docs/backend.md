# Tomoni 백엔드 문서

> 작성: 김예나 (백엔드 담당) · 기준 코드: `eunso` 브랜치의 `backend/` (운영 배포 브랜치 `js-0.6`과 백엔드 코드 동일)

Tomoni 백엔드는 **앱과 AI·데이터베이스 사이의 중계 서버**입니다. 앱은 화면 표시와 녹음·재생만 하고, 프롬프트 작성, AI 호출, 응답 검증, 데이터 저장, 인증은 모두 서버가 처리합니다.

---

## 1. 시스템 구조

```
┌────────────┐   REST (Bearer 토큰)   ┌──────────────────┐ ──▶ OpenAI   gpt-4o-mini / Whisper / TTS
│ Flutter 앱 │ ─────────────────────▶ │  FastAPI 서버    │
│ Android·Web│                        │  (Render, Docker)│ ──▶ Firebase Firestore / Storage
└─────┬──────┘                        └──────────────────┘
      │  로그인·토큰 발급
      └──────────────────────────────▶ Firebase Authentication
```

| 구성 요소 | 역할 |
|---|---|
| Flutter 앱 | 화면, 녹음, 음성 재생. 로그인만 Firebase Auth에 직접 요청 |
| FastAPI 서버 | 프롬프트 설계, AI 호출, 응답 검증·보정, 저장, 인증 검증 |
| OpenAI | `gpt-4o-mini` 대화·판정·피드백, `whisper-1` 음성 인식, `tts-1` 음성 합성 |
| Gemini | OpenAI 실패 시 예비 모델 (`GEMINI_MODEL`) |
| Firebase | Auth 로그인, Firestore 프로필·세션·노트 저장, Storage TTS 음성 캐시 |
| Render | Docker 이미지로 서버 배포 (`tomoni-api.onrender.com`) |

**보안 원칙**: OpenAI·Firebase 관리자 키는 서버 환경변수에만 있고 앱에는 없습니다.

---

## 2. 폴더 구조

```
backend/
├── Dockerfile            # 서버 이미지 설계도 (Python 3.12 + uvicorn)
├── render.yaml           # Render 배포 설정
├── requirements.txt
├── .env.example          # 환경변수 예시 (실제 키 없음)
├── app/
│   ├── main.py           # FastAPI 앱 생성, 라우터 등록, Firebase 초기화
│   ├── config.py         # 환경변수 로딩 (pydantic-settings)
│   ├── dependencies/
│   │   └── auth.py       # Firebase ID 토큰 검증
│   ├── routers/          # API 엔드포인트 (health, users, scenarios, audio, notes, mistakes*)
│   ├── services/         # 실제 로직
│   │   ├── gemini_service.py         # 주제·목표·상황·대화 프롬프트 (이름과 달리 OpenAI도 사용)
│   │   ├── llm_service.py            # OpenAI/Gemini 호출, JSON 파싱, 폴백
│   │   ├── goal_completion_service.py# 목표 판정 규칙·정규화
│   │   ├── korean_text_service.py    # 발음·번역 필드 정제
│   │   ├── session_service.py        # 세션 생성·메시지 처리·종료
│   │   ├── feedback_service.py       # 피드백 노트 생성·조회
│   │   ├── openai_audio_service.py   # STT·TTS
│   │   ├── tts_cache_service.py      # TTS 메모리 캐시
│   │   ├── storage_service.py        # TTS Firebase Storage 캐시
│   │   └── voice_service.py          # 역할·성별별 목소리, 말하기 속도
│   └── models/           # 요청·응답 스키마 (pydantic)
└── tests/
```

`*` `mistakes` 라우터(오답 패턴, Phase 5)는 `main.py`에서 주석 처리되어 비활성 상태입니다.

---

## 3. API 목록

모든 경로 앞에 `/api/v1`이 붙습니다. `health` 외에는 `Authorization: Bearer <Firebase ID 토큰>`이 필요합니다.

| 메서드 | 경로 | 설명 |
|---|---|---|
| GET | `/health` | 서버 상태 (앱 시작 시 서버 깨우기용) |
| GET / PUT | `/users/profile` | 초기 설정 프로필 조회·저장 |
| GET | `/scenarios/topics` | AI 추천 주제 최대 3개 |
| GET | `/scenarios/goals?topic=` | AI 추천 목표 최대 3개 |
| POST | `/scenarios/preview` | AI 역할·사용자 역할·장소 미리보기 |
| POST | `/scenarios/sessions` | 대화 세션 생성 |
| POST | `/scenarios/sessions/{id}/messages` | 사용자 발화 전송 → AI 대사·힌트·목표 판정 |
| POST | `/scenarios/sessions/{id}/end` | 세션 종료 + 피드백 노트 생성 |
| GET | `/notes?year=&month=` | 월별 피드백 노트 목록 |
| GET | `/notes/{id}` | 피드백 노트 상세 |
| POST | `/audio/stt` | 음성 → 텍스트 (최대 10MB) |
| POST | `/audio/tts` | 텍스트 → 음성 URL |

---

## 4. 대화 한 턴 처리 흐름

앱은 한 턴에 두 번 요청합니다: ① `/audio/stt`로 음성을 텍스트로 바꾸고, ② `/messages`로 텍스트를 보냅니다.

`/messages` 서버 처리 순서 (`session_service.send_message`):

1. **인증·세션 확인**: 토큰에서 uid 추출, 세션 소유자 확인, 세션이 `active`인지 확인
2. **기록 조회**: Firestore에서 대화 기록을 읽고 사용자 메시지 저장
3. **GPT 1회 생성** (`generate_reply`): 대사·발음·번역·힌트·목표 판정을 JSON 하나로 받음
4. **검증·보정**: JSON 파싱, 한글 필드 정제, 목표 번호 정규화 (5장 참고)
   - 새로 달성한 목표가 0개면 **재판정** (temperature 0.2)
   - 발음·번역이 비면 **해당 필드만 재생성**
5. **저장·상태 갱신**: AI 메시지 저장, 달성 목표·힌트 갱신, 모든 목표 달성 시 세션 `ended`
6. **음성 합성**: 메모리 캐시 → Storage 캐시 → 없을 때만 TTS 생성

**장애 대비**: OpenAI 실패 → Gemini → 미리 준비한 기본값(`_mock_*`) 순으로 대체. TTS가 실패해도 대화는 계속되고 음성만 빠집니다.

---

## 5. 프롬프트 설계

| 단계 | 함수 | temperature | 핵심 지시 |
|---|---|---|---|
| 주제 추천 | `generate_topics` | 0.85 | 상대방과 실시간 대화하는 상황만, 편지·일기 등 금지 |
| 목표 추천 | `generate_goals` | 0.85 | "~하기" 형태의 구체적 행동, 좋은 예·나쁜 예 제시 |
| 상황 설정 | `generate_session_start` | 0.85 | 역할·장소·목소리, 원칙적으로 학습자가 먼저 말함 |
| 대화 진행 | `generate_reply` | 0.85 | 1~3문장 구어체 경어, 힌트, 목표 판정 |
| 목표 재판정 | `build_lenient_goal_eval_prompt` | 0.2 | 의도·맥락 중심으로 관대하게 판정 |
| 발음·번역 보충 | `_fix_korean_fields` | 0.2 | 한글 발음과 한국어 뜻만 |
| 피드백 노트 | `_generate_feedback` | 0.4 | 학습자 발화만 평가, 1~5점, 교정 항목 1~4개 |

**공통 설계 원칙**
- 출력 JSON 틀을 프롬프트 끝에 고정 + OpenAI `response_format=json_object`
- 입력 압축: 프로필은 `수준:초급, 목적:여행` 한 줄, 대화는 최근 8턴(`MAX_HISTORY_TURNS`)
- 공통 규칙 블록 재사용: `KOREAN_FIELD_RULES`, `GOAL_COMPLETION_RULES`
- temperature 기준: 다양성이 필요한 생성은 높게, 정답이 있는 판정·번역은 낮게 (경험적 설정, 실험 검증 전)

---

## 6. 응답 검증·보정 규칙

| 단계 | 위치 | 내용 |
|---|---|---|
| JSON 복구 | `llm_service._extract_json` | 코드 블록 표시 제거 후 파싱, 실패 시 `{…}` 구간만 추출 |
| 필수 항목 | `generate_reply` | `aiMessage` 없으면 응답 폐기 → 대체 경로 |
| 한글 필드 정제 | `korean_text_service` | 발음·번역에서 한글·숫자·문장부호 외 문자 제거, 비면 재생성 |
| 목표 번호 정규화 | `normalize_goal_completion` | 숫자 변환, 범위 밖·중복·이미 달성한 번호 제거 |
| 종료 조건 재계산 | `normalize_goal_completion` | "모두 달성"은 AI 응답이 아니라 실제 번호 개수로 판단 |
| 주제·목표 필터 | `_is_conversation_topic`, `_is_bad_goal` | 혼자 하는 활동, 추상적·뻔한 목표, 일본어 섞인 목표 제거 |

**검증하지 않는 것**: AI 대사가 실제로 일본어인지, 발음과 번역이 같은 내용인지, 목표 판정 내용이 맞는지. 형식만 코드로 검증하고 내용은 GPT 판단을 따릅니다.

---

## 7. 배포 (Render)

1. `js-0.6` 브랜치에 푸시하면 Render가 자동 감지
2. `render.yaml` → `Dockerfile`대로 이미지 빌드 (`rootDir: backend`)
3. `uvicorn app.main:app` 실행, `/api/v1/health`로 정상 확인 후 교체

- 비밀값(`OPENAI_API_KEY`, `FIREBASE_SERVICE_ACCOUNT_JSON` 등)은 `sync: false`로 Render 대시보드에서만 입력
- 운영에서는 `ALLOW_MOCK_AUTH=false` (개발용 가짜 로그인 차단)
- 무료 플랜: 15분 미사용 시 서버 sleep → 앱 스플래시에서 health 재시도로 대응

> ⚠️ `js-0.6`에 직접 푸시하면 운영 서버가 즉시 바뀝니다. 작업은 별도 브랜치 + PR로 진행하세요.

---

## 8. 로컬 실행

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # OPENAI_API_KEY 등 입력 (팀원에게 전달받기)
python -m uvicorn app.main:app --reload --port 8000
```

- Firebase 없이 테스트: `.env`에서 `ALLOW_MOCK_AUTH=true`, 토큰 `mock-dev-token`
- 실제 Firebase 사용: `backend/credentials/firebase-adminsdk.json` 필요 (git에 올리지 말 것)
- 테스트: `pytest`

---

## 9. 알려진 한계와 개선 방향

| 항목 | 현재 상태 | 개선 방향 |
|---|---|---|
| 대화 난이도 | 수준이 주제·목표·상황 프롬프트에만 반영, 대화 프롬프트엔 없음 | `generate_reply`에 수준별 규칙 블록 추가 |
| 관심사 | 초기 설정에서 수집만, 프롬프트 미사용 | `_slim_profile`에 관심사 추가 |
| 판정 정확도 | 측정하지 않음, 턴별 판정 기록도 저장 안 됨 | 턴별 판정·재판정·모델·응답시간 기록 → 정밀도·재현율 측정 |
| 판정 temperature | 대사와 같은 호출이라 0.85로 판정 | 판정 분리 또는 낮은 temperature 실험 |
| 동시 처리 | `async def` 안에서 동기 호출 → 요청이 순차 처리됨 | 라우터를 `def`로 변경 (안정성 패치) |
| TTS 실패 처리 | `audio.py`에 `logger` 미정의 → 실패 시 500 | 로거 정의 (안정성 패치) |
| 입력 제한 | 주제·목표·메시지 길이 제한 없음 | pydantic 제약 추가 (안정성 패치) |
| 사용량 제한 | 사용자별 호출 제한 없음 → 비용 위험 | 사용자별 일일 한도 |
| 메모리 캐시 | 200개 차면 전체 삭제 | LRU 방식으로 교체 |
| 예비 모델 | `gemini-2.5-flash`는 2026-10-16 종료 | `GEMINI_MODEL=gemini-3.5-flash`로 변경 |
| 실수 분석 | 코드는 있으나 비활성 (Phase 5) | 활성화 + 교정 항목 유형 분류 |

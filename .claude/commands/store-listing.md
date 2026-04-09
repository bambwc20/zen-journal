# /store-listing 스킬

## 입력
$ARGUMENTS = MVP md 파일명 (docs/ 내 배치 전제)

예시: `/store-listing 1_ZenJournal_AI_Daily_Journal.md`

## 개요

MVP 기획서를 읽고 **앱 스토어 출시에 필요한 모든 메타데이터, 스크린샷, 심사 설문 답변, 구독 설정 가이드**를 생성한다.
대화형으로 사용자에게 레퍼런스 이미지와 앱 스크린샷을 수집하고, Gemini API + Perplexity로 최신 스토어 정책을 반영한다.

---

## 전제 조건

- `.env` 파일에 `GEMINI_API_KEY` 설정 완료
- `docs/` 폴더에 MVP md 파일 배치됨
- `docs/build_app_context.json` 존재하면 함께 활용

---

## 실행 순서

### Phase 1: MVP 파일 + 앱소싱 데이터 통합 분석 (자동)

1. `docs/$ARGUMENTS` 읽기
2. `docs/build_app_context.json` 존재하면 함께 읽기
3. **앱소싱 데이터 자동 탐색** — `docs/` 및 `build_app_context.json`의 `sourcing_data` 경로에서:
   - `앱_설명_모음.md` → 경쟁사 50개 앱의 스토어 설명/포지셔닝/키워드 참고
   - `앱소싱 리포트*.md` → 키워드 검색량/CPC, 경쟁사 포지셔닝 분석
   - `앱소싱_*.xlsx` → 키워드 시트(검색량 순위, Trends 계절성), 경쟁사 시트(평점, 리뷰수)
4. MVP에서 추출:
   - 앱 이름, 카테고리, 타겟 국가, 가격 (섹션 1)
   - 핵심 차별점 목록 (섹션 3) — 각 차별점의 Problem/Solution
   - 경쟁사 약점 (섹션 2) — ASO 키워드 소재
   - 무료/유료 기능 구분 (섹션 5, 6)
   - 기본 필수 기능 (섹션 4)
   - 화면 목록 (섹션 8)
   - 기술 스택 (섹션 8) — 권한 키 추출용
   - 스토어 메타데이터 (섹션 1 — title, subtitle, short_desc, long_desc)
   - 디자인 가이드 (섹션 15 or build_app_context.json design)
   - UA 키워드 (섹션 10) — Keywords 필드용
5. **소싱 데이터 활용 포인트** (있는 파일만 활용, 없으면 해당 항목 스킵):
   - 앱소싱 xlsx 키워드 시트 → **Keywords 필드** 고검색량 키워드 우선 배치
   - 앱설명모음 → **Long Description** 차별화 표현 (경쟁사와 겹치지 않는 키워드)
   - 앱설명모음 → **Title/Subtitle** 미사용 니치 키워드 발굴
   - 앱소싱 리포트 → **What's New** 및 설명에 리뷰 불만 해결 강조
   - 앱소싱 xlsx 경쟁사 시트 → **스크린샷 캡션** 비교 우위 강조
   > 소싱 데이터가 전혀 없으면 MVP 섹션 1/10의 메타데이터만으로 생성

---

### Phase 2: 대화형 레퍼런스 & 스크린샷 수집

AskUserQuestion 도구를 사용하여 순차적으로 수집한다.
사용자가 파일을 넣으면 Read 도구로 이미지를 확인하고 스타일을 분석한다.

#### Q1: 아이콘 레퍼런스 수집

```
앱 아이콘을 생성하기 위해 레퍼런스가 필요합니다.

원하는 스타일의 앱 아이콘 이미지 2~5개를
references/icons/ 폴더에 넣어주세요.

예시: 경쟁사 앱 아이콘, 마음에 드는 스타일의 아이콘 등
(App Store/Google Play에서 캡처)

넣으셨으면 'done'을 입력해주세요.
```

→ `references/icons/` 내 이미지 파일을 Read 도구로 확인
→ 스타일 특성 분석 (컬러, 형태, 3D/flat, 그라데이션 등)

#### Q2: 스크린샷 레퍼런스 수집

```
스토어 상세페이지 스크린샷 스타일 레퍼런스가 필요합니다.

잘 만들어진 앱의 스토어 스크린샷 3~5개를
references/screenshots/ 폴더에 넣어주세요.

좋은 레퍼런스: 폰 목업 + 기능 설명 텍스트가 깔끔한 것
(App Store/Google Play 상세페이지에서 캡처)

넣으셨으면 'done'을 입력해주세요.
```

→ `references/screenshots/` 내 이미지 파일을 Read 도구로 확인
→ 레이아웃 패턴 분석 (텍스트 위치, 목업 스타일, 배경 처리 등)

#### Q3: 차별점별 실제 앱 스크린샷 수집

MVP 분석 결과의 차별점을 기반으로 질문:

```
앱의 핵심 차별점을 분석했습니다:

1. {차별점1 이름} — {한줄 설명}
2. {차별점2 이름} — {한줄 설명}
3. {차별점3 이름} — {한줄 설명}

각 차별점을 가장 잘 보여주는 현재 앱 스크린샷이 있다면
경로를 알려주세요. (예: /path/to/screenshot.png)

없는 항목은 'skip'이라고 적어주세요 — Gemini가 레퍼런스 스타일로 생성합니다.

형식:
1: /path/to/ai_reflection.png
2: skip
3: /path/to/backup_screen.png
```

→ 제공된 스크린샷은 Read 도구로 확인
→ skip된 항목은 Phase 4에서 Gemini가 레퍼런스 기반 생성

#### Q4: 추가 화면 수집

```
추가로 스토어에 보여주고 싶은 화면이 있으면
경로를 알려주세요. (예: 온보딩, 설정, 통계 등)

없으면 'done'을 입력해주세요.
```

#### Q5: Feature Graphic 레퍼런스 (선택)

```
Google Play 피처 그래픽(1024×500 배너) 레퍼런스가 있으면
references/feature_graphic/ 에 넣어주세요.

없으면 'skip' — MVP 디자인 토큰 기반으로 자동 생성합니다.
```

---

### Phase 3: 스토어 메타데이터 생성

수집된 정보를 기반으로 iOS/Android 각각의 메타데이터를 생성한다.

#### 3-1. Apple App Store 메타데이터

```markdown
## Apple App Store

### App Name (30자 이내)
{앱이름}: {핵심 기능 한마디}

### Subtitle (30자 이내)
{가치 제안 — 차별점 중심}

### Description (4,000자 이내)
{Long Description — 구조:
  1줄: 핵심 가치 제안
  기능 목록 (불릿)
  차별점 상세 설명
  무료/유료 구분
  구독 가격 명시
  개인정보 보호 강조}

### Keywords (100자, 쉼표 구분)
{UA 키워드 + 카테고리 키워드 — 중복/복수형 제거}

### Promotional Text (170자)
{리뷰 없이 수시 업데이트 가능한 프로모션 문구}

### Primary Category
{카테고리}

### Secondary Category
{보조 카테고리}
```

#### 3-2. Google Play 메타데이터

```markdown
## Google Play

### App Name (50자 이내)
{앱이름}: {부제}

### Short Description (80자 이내)
{핵심 가치 + 차별점 1줄}

### Full Description (4,000자 이내)
{Apple Description 기반 — Google Play 스타일 최적화
  이모지 사용 가능, 키워드 자연 삽입}

### Category
{Health & Fitness 또는 Lifestyle}

### Tags
{관련 태그 5개}
```

---

### Phase 4: 스크린샷 & 아이콘 생성

#### 4-1. 앱 아이콘 생성 (Gemini API)

아이콘은 텍스트가 거의 없으므로 Gemini API로 생성한다.
`.env`에서 `GEMINI_API_KEY`를 읽어 Gemini API를 호출한다.
`references/icons/` 이미지를 multipart로 함께 전송하여 스타일을 맞춘다.

```bash
REF_IMAGE=$(base64 -i references/icons/ref_icon_01.png)

curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [
        {"inline_data": {"mime_type": "image/png", "data": "'${REF_IMAGE}'"}},
        {"text": "이 스타일을 참고하여 다음 앱 아이콘을 만들어주세요: {프롬프트}"}
      ]
    }],
    "generationConfig": {"responseModalities": ["IMAGE", "TEXT"]}
  }'
```

| 에셋 | 사이즈 | 용도 | 파일명 |
|------|--------|------|--------|
| App Icon | 512×512 | Google Play 아이콘 | `icon_512.png` |
| App Icon | 1024×1024 | Apple App Store 아이콘 | `icon_1024.png` |

Gemini API 실패 시 → 아이콘 생성 프롬프트만 텍스트로 제공 (스킬 중단 금지)

#### 4-2. 스토어 스크린샷 생성 (HTML + Playwright)

스크린샷은 텍스트(캡션)가 핵심이므로 AI 이미지 생성을 사용하지 않는다.
HTML/CSS 템플릿 + Playwright 스크린샷으로 텍스트 정확도 100%를 보장한다.

**생성할 에셋:**

| 플랫폼 | 사이즈 | 장수 | 파일명 패턴 |
|--------|--------|------|------------|
| Apple (iPhone 6.9") | 1320×2868 | 5장 | `apple_screen_01~05.png` |
| Google Play (Phone) | 1080×1920 | 5장 | `google_screen_01~05.png` |
| Feature Graphic | 1024×500 | 1장 | `feature_graphic.png` |

**스크린샷 생성 절차:**

1. MVP 차별점 + Q3에서 수집한 스크린샷 경로를 기반으로 `docs/ad_image_config.json` 생성:

```json
{
  "app_name": "{앱이름}",
  "headline": "{핵심 차별점}",
  "subtext": "{부제}",
  "cta": "Install Free",
  "features": ["{차별점1}", "{차별점2}", "{차별점3}"],
  "icon_path": "docs/store_assets/icon_1024.png",
  "screenshot_path": "{Q3에서 수집한 첫 번째 스크린샷}",
  "screenshots": ["{Q3 스크린샷 1~5}"],
  "captions": [
    "{차별점1 한줄 캡션}",
    "{차별점2 한줄 캡션}",
    "{차별점3 한줄 캡션}",
    "{핵심 기능 캡션}",
    "{추가 화면 캡션}"
  ],
  "subcaptions": [
    "{차별점1 부제}",
    "{차별점2 부제}",
    "{차별점3 부제}",
    "{핵심 기능 부제}",
    "{추가 화면 부제}"
  ]
}
```

2. `ad_image_generator.py` 실행:

```bash
cd script/python
python3 ad_image_generator.py \
  --config ../../docs/ad_image_config.json \
  --output ../../docs/store_assets/ \
  --store
```

3. 생성 결과 검증:
   - Apple 5장 + Google 5장 + Feature Graphic 1장 = 11파일 존재 확인
   - 해상도/파일크기 자동 검증
   - 샘플 2~3장 시각 확인 (Read 도구)

**스크린샷 생성 전략:**

1. **사용자가 실제 앱 스크린샷을 제공한 경우 (Q3):**
   - 스크린샷을 iPhone 프레임 안에 배치 + 캡션 텍스트 오버레이
   - 레퍼런스 스크린샷 스타일(Q2)의 색상/레이아웃 참고하여 CSS 변수 조정

2. **사용자가 skip한 경우:**
   - 디자인 토큰(seed_color, style) 기반 그라디언트 배경 + 플레이스홀더 폰 목업
   - 캡션 텍스트는 정확히 렌더링됨

**Graceful Degradation:**
- 스크린샷 없음 → CSS 그라디언트 + 플레이스홀더 (폰 목업은 빈 화면)
- Playwright 미설치 → 설치 안내 출력 후 스크린샷 생성 프롬프트 텍스트 폴백
- 모든 실패에서 스킬 중단 금지 (경고만 출력)

---

### Phase 5: 심사 설문 사전 작성

**Perplexity MCP**로 최신 Apple/Google 정책을 조사한 후 답변을 생성한다.
Perplexity 사용 불가 시 조사 에이전트(WebSearch)로 폴백.

#### 5-1. Apple App Store 심사

##### Privacy Nutrition Labels

MVP 기능 기반으로 수집 데이터를 자동 매핑:

```markdown
## Apple Privacy Labels

| 데이터 유형 | 수집 여부 | 사용자 연결 | 추적 | 목적 |
|------------|----------|-----------|------|------|
| {앱 기능별 자동 매핑} |
```

매핑 규칙:
- Firebase Analytics → Usage Data: Product Interaction (수집, 연결, 분석)
- Firebase Crashlytics → Diagnostics: Crash Data (수집, 미연결, 앱 기능)
- RevenueCat → Purchase History (수집, 연결, 앱 기능)
- AdMob → Identifiers: Device ID (수집, 연결, 써드파티 광고)
- FCM → Identifiers: Device ID (수집, 연결, 앱 기능)
- 로컬 DB (Drift/SQLCipher) → User Content (미수집 — 기기에만 저장)
- 클라우드 백업 선택 시 → User Content (수집, 연결, 앱 기능)

##### Age Rating 설문

```markdown
## Age Rating 답변

| 질문 | 답변 | 근거 |
|------|------|------|
| 폭력/유혈 | 없음 | {앱 내용 기반} |
| 비속어 | 없음 | |
| 성적 테마 | 없음 | |
| 도박 | 없음 | |
| UGC | {사용자 일기 = UGC 해당 여부} | |
| 약물 | 없음 | |
| 공포 | 없음 | |
| 의료/웰니스 | {해당 여부} | |

예상 등급: {4+ / 9+ / 13+ / 16+}
```

##### Export Compliance

```markdown
## Export Compliance

| 질문 | 답변 | 근거 |
|------|------|------|
| 암호화 사용 여부 | 예 (HTTPS) | |
| Apple OS 표준 외 추가 암호화 | {SQLCipher 사용 시 예} | |
| 비표준 암호화 | 아니오 | |

Info.plist 설정:
<key>ITSAppUsesNonExemptEncryption</key>
<{true/false}/>
```

##### IDFA / ATT

```markdown
## IDFA 사용 여부

| 질문 | 답변 |
|------|------|
| IDFA 사용 | {AdMob 사용 시 예} |
| 추적 목적 | {광고 최적화} |

필요한 Info.plist 키:
<key>NSUserTrackingUsageDescription</key>
<string>{사용 목적 설명}</string>
```

##### Info.plist 필수 권한 키

앱 기능 기반으로 자동 생성:

```markdown
## Info.plist 필수 키

| 키 | 필요 여부 | 설명 문구 |
|----|----------|----------|
| NSUserTrackingUsageDescription | {AdMob 시 필수} | {문구} |
| NSCameraUsageDescription | {사진 첨부 시 필수} | {문구} |
| NSPhotoLibraryUsageDescription | {사진 첨부 시 필수} | {문구} |
| NSSpeechRecognitionUsageDescription | {음성 입력 시 필수} | {문구} |
| NSMicrophoneUsageDescription | {음성 입력 시 필수} | {문구} |
| NSFaceIDUsageDescription | {생체인증 시 필수} | {문구} |
```

#### 5-2. Google Play 심사

##### Data Safety Section

```markdown
## Google Play Data Safety

| 데이터 유형 | 수집 | 공유 | 암호화 | 삭제 가능 |
|------------|------|------|--------|----------|
| {앱 기능별 자동 매핑} |
```

##### IARC 콘텐츠 등급

```markdown
## IARC 답변

| 질문 | 답변 |
|------|------|
| 폭력 | 아니오 |
| 성적 콘텐츠 | 아니오 |
| 욕설 | 아니오 |
| 약물 | 아니오 |
| 13세 미만 대상 | 아니오 |
| 광고 포함 | {예/아니오} |
| 인앱 구매 | {예/아니오} |
| 도박 | 아니오 |

예상 등급: {Everyone / Everyone 10+ / Mature 13+}
```

##### Ads Declaration

```markdown
## 광고 선언

| 항목 | 답변 |
|------|------|
| 광고 포함 여부 | {예/아니오} |
| 광고 형식 | {배너, 인터스티셜, 리워드 등} |
```

##### Target Audience

```markdown
## 대상 연령

| 항목 | 답변 |
|------|------|
| 연령 그룹 | {18세 이상} |
| 아동 대상 | 아니오 |
```

##### AndroidManifest 권한

```markdown
## AndroidManifest 권한

| 권한 | 필요 여부 | 사유 |
|------|----------|------|
| INTERNET | 필수 | API 통신 |
| CAMERA | {사진 첨부 시} | 사진 촬영 |
| RECORD_AUDIO | {음성 입력 시} | STT |
| READ_EXTERNAL_STORAGE | {사진 첨부 시} | 갤러리 접근 |
| POST_NOTIFICATIONS | {FCM 시} | 푸시 알림 |
| SCHEDULE_EXACT_ALARM | {리마인더 시} | 알림 예약 |
```

---

### Phase 6: 구독 상품 설정 가이드

**Perplexity MCP**로 최신 구독 정책을 조사 후 생성.

#### 6-1. Apple 구독 설정

```markdown
## Apple In-App Purchase 설정

### 구독 그룹
- Group Reference Name: {앱이름}_premium
- Display Name: {앱이름} Pro

### 월간 구독
| 필드 | 값 |
|------|---|
| Product ID | {bundle_id}.monthly |
| Duration | 1개월 |
| Price | {월간 가격} (Price Tier) |
| Display Name | {앱이름} Pro Monthly |
| Description | {유료 기능 요약} |

### 연간 구독
| 필드 | 값 |
|------|---|
| Product ID | {bundle_id}.yearly |
| Duration | 1년 |
| Price | {연간 가격} (Price Tier) |
| Display Name | {앱이름} Pro Yearly |
| Description | {유료 기능 요약 + 할인율 표시} |

### 평생 구독 (Non-Consumable)
| 필드 | 값 |
|------|---|
| Product ID | {bundle_id}.lifetime |
| Type | Non-Consumable |
| Price | {평생 가격} |

### Introductory Offer
- 무료 체험: {7일}
- 체험 종료 후 자동 갱신 고지 필수

### 페이월 필수 표시 항목 (Guideline 3.1.2)
- [ ] 구독 가격 (정확한 금액)
- [ ] 결제 주기 ("month" / "year" 풀네임)
- [ ] 자동 갱신 안내 문구
- [ ] 취소 방법 안내
- [ ] Privacy Policy 링크 (기능하는 URL)
- [ ] Terms of Use / EULA 링크 (기능하는 URL)
```

#### 6-2. Google Play 구독 설정

```markdown
## Google Play Subscription 설정

### 월간 Base Plan
| 필드 | 값 |
|------|---|
| Product ID | {package_name}.monthly |
| Billing Period | 1개월 |
| Price | {월간 가격} |
| Free Trial | {7일} |
| Grace Period | {3일} |

### 연간 Base Plan
| 필드 | 값 |
|------|---|
| Product ID | {package_name}.yearly |
| Billing Period | 1년 |
| Price | {연간 가격} |
| Free Trial | {7일} |

### 평생 (One-Time Purchase)
| 필드 | 값 |
|------|---|
| Product ID | {package_name}.lifetime |
| Type | One-Time |
| Price | {평생 가격} |

### Offers
- Introductory: 첫 {7}일 무료
- Win-back: 이탈 유저 {30}% 할인 (90일 이내)
```

---

### Phase 7: 출력

최종 산출물 2개:

1. **`docs/STORE_LISTING.md`** — 위 전체 내용 (메타데이터 + 심사 답변 + 구독 설정)
2. **`docs/store_assets/`** — 생성된 이미지 파일들

```
docs/store_assets/
├── icon_512.png
├── icon_1024.png
├── apple_screen_01.png ~ 05.png
├── google_screen_01.png ~ 05.png
└── feature_graphic.png
```

---

## 규칙

- MVP 파일에 없는 정보를 추측하지 않는다
- 레퍼런스 이미지가 없으면 MVP 디자인 토큰 기반으로 생성
- Gemini API 실패 시 이미지 생성 프롬프트를 텍스트로 제공 (스킬 중단 금지)
- Perplexity 사용 불가 시 WebSearch 에이전트로 폴백
- 글자 수 제한을 반드시 준수 (Apple Name 30자, Google Name 50자 등)
- 가격 표기 시 현지 통화 사용 (US → $)
- Apple Guideline 3.1.2 페이월 필수 항목을 반드시 포함
- 스크린샷은 실제 앱 UI 기반 — 허위 목업 금지 (스토어 정책)
- `docs/store_assets/`는 `.gitignore`에 추가 (생성물이므로)

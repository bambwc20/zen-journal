# /marketing-ads 스킬

## 입력
$ARGUMENTS = MVP md 파일명 (docs/ 내 배치 전제)

예시: `/marketing-ads 1_ZenJournal_AI_Daily_Journal.md`

## 개요

MVP 기획서의 핵심 차별점을 기반으로 **광고 소재**(텍스트 + 이미지 프롬프트)를 생성한다.
Gemini API를 활용하여 광고 카피 변형, A/B 테스트 소재, 타겟 오디언스별 메시지를 자동 생성한다.

---

## 전제 조건

- `.env` 파일에 `GEMINI_API_KEY` 설정 완료
- `docs/` 폴더에 MVP md 파일 배치됨

---

## 실행 순서

### Step 1: MVP 파일 + 앱소싱 데이터 통합 분석

1. `docs/$ARGUMENTS` 읽기
2. `docs/build_app_context.json` 존재하면 함께 읽기
3. **앱소싱 데이터 자동 탐색** — `docs/` 및 `build_app_context.json`의 `sourcing_data` 경로에서:
   - `앱_설명_모음.md` → 경쟁사 50개 앱의 포지셔닝/기능/약점 상세
   - `앱소싱 리포트*.md` → CPC/CPI 실데이터, 키워드 검색량, 경쟁사 월수익
   - `앱소싱_*.xlsx` → 키워드 시트(Trends 계절성) + 경쟁사 시트(IAP 가격/광고) + 리뷰 시트(불만 카테고리)
4. MVP에서 추출:
   - 앱 이름, 카테고리, 타겟 국가 (섹션 1)
   - **핵심 차별점** (섹션 3) — 광고 메시지의 핵심
   - 경쟁사 약점 (섹션 2) — 포지셔닝 각도
   - 무료 기능 (섹션 5) — 다운로드 유도 훅
   - 유료 기능 (섹션 6) — 전환 유도 메시지
   - 브릿지 포인트 (섹션 7) — 무료→유료 전환 소재
   - 가격 정보 (섹션 1) — CTA에 활용
   - 디자인 가이드 (섹션 15) — 비주얼 톤앤매너
5. **소싱 데이터 활용 포인트**:
   - 앱소싱 xlsx 키워드 시트 → CPC → **ASA/UAC 키워드 그룹** 실제 입찰 가격 기반 예산 가이드
   - 앱소싱 xlsx 키워드 시트 → Trends 계절성 → **광고 시기 최적화** (피크 시즌 예산 증액)
   - 앱소싱 xlsx 경쟁사 시트 → IAP 가격 → **가격 소구 광고** 경쟁사 대비 가성비 강조
   - 앱소싱 리포트 → 리뷰 불만 카테고리 → **감정 소구 카피** 실제 유저 페인포인트 반영
   - 앱소싱 xlsx 경쟁사 시트 → 월수익/다운로드 → **타겟 세그먼트** 경쟁사 이탈 유저 규모 추정
   - 앱설명모음 → 50개 앱 기능 분석 → **차별점 강조** 경쟁사 미보유 기능 광고
   > 소싱 데이터가 전혀 없으면 MVP 섹션 2/3/10만으로 생성 (Gemini 프롬프트에서 시장 데이터 섹션 생략)

---

### Step 2: 타겟 오디언스 세그먼트 정의

MVP 파일 기반으로 3~5개 타겟 세그먼트를 정의한다:

```markdown
## 타겟 세그먼트

| # | 세그먼트 | 페인포인트 | 앱이 주는 가치 | 광고 각도 |
|---|---------|-----------|--------------|----------|
| 1 | {핵심 타겟} | {주요 불편} | {차별점 기능} | {감정적 훅} |
| 2 | {확장 타겟} | {관련 불편} | {기본 기능} | {실용적 훅} |
| 3 | {경쟁사 이탈 유저} | {경쟁사 약점} | {대안 포지셔닝} | {비교 훅} |
```

---

### Step 3: Gemini API로 광고 카피 생성

`.env`에서 `GEMINI_API_KEY`를 읽어 Gemini API를 호출한다.

**Gemini 프롬프트 구조**:
```
당신은 모바일 앱 퍼포먼스 마케팅 전문가입니다.

앱 정보:
- 이름: {앱이름}
- 카테고리: {카테고리}
- 핵심 차별점: {차별점 목록}
- 타겟: {세그먼트}
- 무료 기능: {무료 기능}
- 가격: {가격}

[앱소싱 데이터가 있으면 아래 섹션 추가]
시장 데이터 (앱소싱 리포트 기반):
- 키워드 검색량: {search_traffic} / 인기도: {popularity}
- CPC: 최저 {cpc_low} ~ 최고 {cpc_high} (실측치 또는 추정)
- 상위 경쟁사 월수익: {경쟁사1} ${월수익}, {경쟁사2} ${월수익}, ...
- 경쟁사 가격대: {경쟁사 구독 가격 범위}

유저 불만 패턴 (리뷰 분석 기반):
- 1위 불만: {카테고리} ({비율}%) — 예: "Too expensive for what it offers"
- 2위 불만: {카테고리} ({비율}%) — 예: "App crashes after update"
- 3위 불만: {카테고리} ({비율}%) — 예: "Missing feature X"

연관 키워드 (ASO/ASA 타겟):
{키워드1} (트래픽 {N}), {키워드2} (트래픽 {N}), ...

아래 광고 채널별로 카피를 작성하세요:

1. Apple Search Ads (30자 제한 헤드라인 + 설명)
   - 키워드 그룹별: 브랜드 / 카테고리 / 경쟁사 / 연관 키워드
   - CPC 데이터 기반 입찰 가이드 포함
2. Google UAC (헤드라인 30자 + 설명 90자, 5개 변형)
3. Instagram/Facebook 광고 (프라이머리 텍스트 + 헤드라인 + CTA)
   - 유저 불만 패턴을 감정 소구에 직접 활용
4. TikTok 광고 (훅 + 바디 + CTA, 15초 스크립트)
   - Hook에 실제 유저 불만 인용 ("I was tired of...")

각 채널마다:
- A/B 테스트용 변형 3개씩
- 감정 소구 / 기능 소구 / 사회적 증거 각 1개
- 타겟 세그먼트별 맞춤 메시지
- 경쟁사 가격 대비 가성비 메시지 (비교 훅)
```

**API 호출 방법** (Bash):
```bash
curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{"parts": [{"text": "프롬프트 내용"}]}],
    "generationConfig": {"temperature": 0.8, "maxOutputTokens": 4096}
  }'
```

**Gemini API 호출 실패 시 폴백**:
- API 키 없음 / 만료 → Claude가 직접 광고 카피 생성 (Gemini 없이)
- 네트워크 오류 → 1회 재시도 후 Claude 폴백

---

### Step 4: 채널별 광고 소재 생성

#### 4-1. Apple Search Ads (ASA)

```markdown
## Apple Search Ads 소재

### 키워드 그룹 A: 브랜드 키워드
| 키워드 | 헤드라인 (30자) | 설명 | 검색량 | 예상 CPC |
|--------|---------------|------|--------|---------|

### 키워드 그룹 B: 카테고리 키워드 (앱소싱 리포트 연관 키워드 기반)
| 키워드 | 헤드라인 (30자) | 설명 | 검색량 | 예상 CPC |
|--------|---------------|------|--------|---------|
[앱소싱 리포트의 연관 키워드 분석 데이터 직접 반영]

### 키워드 그룹 C: 경쟁사 키워드 (앱설명모음 상위 앱 기반)
| 키워드 | 헤드라인 (30자) | 설명 | 검색량 | 예상 CPC |
|--------|---------------|------|--------|---------|
[앱설명모음 50개 앱 중 상위 경쟁사 앱명을 키워드로 활용]

### 키워드 그룹 D: 니치 롱테일 (앱소싱 리포트 저경쟁 키워드)
| 키워드 | 헤드라인 (30자) | 설명 | 검색량 | 예상 CPC |
|--------|---------------|------|--------|---------|
[리포트에서 결과수 대비 트래픽이 높은 저경쟁 키워드 추출]

### 예산 가이드
- 일 예산: $5~$20 (카테고리 경쟁도에 따라)
- 입찰 전략: CPA 목표
- 타겟 CPI: ${카테고리 평균}
```

#### 4-2. Google UAC (Universal App Campaigns)

```markdown
## Google UAC 소재

### 헤드라인 (30자 이내, 5개)
1. {감정 소구}
2. {기능 소구}
3. {가격 소구}
4. {사회적 증거}
5. {긴급성}

### 설명 (90자 이내, 5개)
1. {차별점 강조}
2. {무료 기능 강조}
3. {문제 해결 강조}
4. {경쟁사 대비 강조}
5. {리뷰/평점 강조}

### 비디오 스크립트 (15초)
- 0-3초: {Hook — 페인포인트 질문}
- 3-8초: {앱 데모 — 핵심 기능}
- 8-12초: {결과/혜택}
- 12-15초: {CTA — 무료 다운로드}
```

#### 4-3. Meta (Instagram/Facebook) 광고

```markdown
## Meta 광고 소재

### 소재 세트 A: 감정 소구
- 프라이머리 텍스트: {2-3문장}
- 헤드라인: {40자 이내}
- 설명: {30자 이내}
- CTA 버튼: Install Now / Learn More
- 비주얼 가이드:
  - 형식: 단일 이미지 / 카루셀 / 릴스
  - 톤: {디자인 가이드 style}
  - 컬러: {seed_color} 기반
  - 구도: [구체적 레이아웃 설명]

### 소재 세트 B: 기능 소구
[동일 구조]

### 소재 세트 C: 사회적 증거
[동일 구조]

### 타겟팅 가이드
| 세그먼트 | 관심사 | 연령 | 예상 CPI |
|----------|--------|------|---------|
```

#### 4-4. TikTok 광고

```markdown
## TikTok 광고 소재

### 스크립트 A: 문제 공감형 (15초)
- [0-3초] Hook: "{페인포인트 질문}" (텍스트 오버레이 + 얼굴)
- [3-8초] "그래서 {앱이름}을 만들었다" (앱 데모)
- [8-12초] "{핵심 기능} 보여주기" (스크린 레코딩)
- [12-15초] CTA: "링크 바이오에 → 무료" (텍스트 오버레이)
- 오디오: 트렌딩 사운드 / 보이스오버

### 스크립트 B: Before→After형 (15초)
[동일 구조]

### 스크립트 C: 숫자 강조형 (15초)
[동일 구조]

### 스파크 광고 가이드
- 오가닉 포스트 중 반응 좋은 것 → Spark Ads로 부스팅
- /marketing-build-public의 콘텐츠를 재활용
```

#### 4-5. 이미지 생성 프롬프트

각 광고 소재에 대해 **Gemini Imagen / Midjourney / DALL-E 용 프롬프트**를 생성:

```markdown
## 이미지 생성 프롬프트

### 소재 1: {소재명}
- 프롬프트: "A clean mobile app screenshot mockup of {앱이름}, showing {기능},
  {style} design style, {seed_color} color scheme, {typography} font,
  iPhone 15 Pro frame, white background, minimal, professional"
- **Google Ads Responsive Display (필수)**:
  - Landscape 1.91:1 → 1200×628 (권장) / 최소 600×314
  - Square 1:1 → 1200×1200 (권장) / 최소 300×300
  - Portrait 4:5 → 960×1200 (선택, 권장)
  - 로고 Square 1:1 → 1200×1200 / 최소 128×128
  - 로고 Wide 4:1 → 1200×300 / 최소 512×128
  - 파일: JPG/PNG, ≤5MB, 텍스트 20% 이하
- **Google Ads Uploaded Banners (Top 5)**:
  - Medium Rectangle: 300×250 (필수 — 90%+ 인벤토리)
  - Leaderboard: 728×90
  - Half Page: 300×600
  - Large Mobile Banner: 320×100
  - Mobile Banner: 320×50
  - 파일: JPG/PNG/GIF, ≤150KB
- **Meta (Facebook/Instagram)**:
  - Feed: 1200×628 (1.91:1) 또는 1080×1080 (1:1)
  - Stories/Reels: 1080×1920 (9:16)
  - Carousel: 1080×1080 (1:1)
- **TikTok**: 1080×1920 (9:16)
- **Apple Search Ads**: 1242×2208 (iPhone), 2048×2732 (iPad)
- 변형: 라이트모드 / 다크모드

### 소재 2: {소재명}
[동일 구조]
```

---

### Step 5: A/B 테스트 매트릭스

```markdown
## A/B 테스트 계획

| 테스트 | 변수 A | 변수 B | 측정 지표 | 최소 샘플 |
|--------|--------|--------|----------|----------|
| 헤드라인 | 감정 소구 | 기능 소구 | CTR | 1,000 imp |
| CTA | "무료 다운로드" | "지금 시작하기" | CVR | 500 clicks |
| 비주얼 | 스크린샷 | 라이프스타일 | CPI | $50 spend |
| 오디언스 | 핵심 타겟 | 확장 타겟 | ROAS | $100 spend |

### 예산 배분 가이드
| 채널 | 일 예산 | 우선순위 | 이유 |
|------|--------|---------|------|
| Apple Search Ads | $5~10 | 1순위 | 높은 의도, 낮은 CPI |
| Google UAC | $10~20 | 2순위 | 넓은 도달 |
| Meta | $5~15 | 3순위 | 정밀 타겟팅 |
| TikTok | $5~10 | 4순위 | 젊은 층 + 바이럴 |
```

---

### Step 6: 출력

최종 산출물: `docs/MARKETING_ADS.md`

1개 파일에 위 전체를 포함:
1. 타겟 세그먼트
2. Apple Search Ads 소재
3. Google UAC 소재
4. Meta 광고 소재
5. TikTok 광고 소재
6. 이미지 생성 프롬프트
7. A/B 테스트 매트릭스

---

### Step 7: 광고 이미지 자동 생성 (HTML + Playwright)

MARKETING_ADS.md 저장 완료 후, 광고 이미지를 자동 생성한다.
AI 이미지 생성(Gemini/DALL-E)은 텍스트가 깨지므로 사용하지 않는다.
대신 HTML/CSS 템플릿 + Playwright 스크린샷으로 텍스트 정확도 100%를 보장한다.

#### 7-1. 설정 JSON 생성

MVP 파일과 MARKETING_ADS.md에서 추출한 정보로 `docs/ad_image_config.json`을 생성:

```json
{
  "app_name": "{앱이름}",
  "headline": "{Google UAC 헤드라인 1번}",
  "subtext": "{Google UAC 설명 1번}",
  "cta": "Install Free",
  "features": ["{차별점1}", "{차별점2}", "{차별점3}", "{차별점4}"],
  "icon_path": "{앱 아이콘 경로 — 없으면 생략}",
  "screenshot_path": "{앱 스크린샷 경로 — 없으면 생략}",
  "screenshots": ["{화면1}", "{화면2}", "{화면3}", "{화면4}", "{화면5}"],
  "captions": ["{스크린샷 캡션1~5}"],
  "subcaptions": ["{서브캡션1~5}"],
  "design": {
    "primary_color": "{seed_color}",
    "secondary_color": "{secondary_color}",
    "style": "{style}"
  }
}
```

#### 7-2. 스크린샷 확인

- `assets/screenshots/` 폴더에 앱 스크린샷 존재 확인
- 없으면: 사용자에게 안내 → "iOS 시뮬레이터에서 핵심 화면 5개를 캡처하여 assets/screenshots/에 저장해주세요"
- 없어도 진행 가능 (플레이스홀더 자동 생성)

#### 7-3. 이미지 생성 실행

```bash
cd script/python
python3 ad_image_generator.py \
  --config ../../docs/ad_image_config.json \
  --output ../../assets/ads/ \
  --ads
```

생성되는 이미지 (19종):
- Google: 320x50, 320x100, 728x90, 300x250, 970x250, 160x600, 300x600, 1200x628, 1200x1200, 960x1200, 1200x300
- Meta: 1080x1080, 1080x1350, 1080x1920
- TikTok: 1080x1920
- ASA: 1242x2208

#### 7-4. 검증

- 19종 파일 존재 확인 (자동 검증 내장)
- 해상도/파일크기 자동 검증 (배너 ≤150KB, 피드/스토리 ≤5MB)
- 샘플 3장 시각 확인 (Read 도구)

#### 7-5. MARKETING_ADS.md 업데이트

섹션 8(체크리스트) 하단에 생성 결과 기록:
```markdown
## 9. 생성된 광고 이미지

이미지 자동 생성 완료: `assets/ads/`
- Google Ads: 11종
- Meta: 3종
- TikTok: 1종
- ASA: 1종
- 로고: 2종 (사이즈별)
```

#### Graceful Degradation

- 스크린샷 없음 → CSS 그라디언트 배경 + 텍스트만 (폰 목업은 플레이스홀더)
- 프레임 PNG 없음 → CSS 폴백 프레임 자동 적용
- Pillow 미설치 → `pip install Pillow` 자동 실행
- Playwright 미설치 → `pip install playwright && playwright install chromium` 안내
- 모든 실패에서도 **스킬은 중단하지 않는다** (이미지 생성 실패 시 경고만 출력, MARKETING_ADS.md는 정상 저장)

---

## 규칙

- Gemini API 호출 실패 시 Claude가 직접 생성 (스킬 중단 금지)
- 경쟁사 직접 비하 광고 금지 — "대안" 포지셔닝만
- 광고 정책 준수:
  - Apple: 30자 헤드라인 제한, 과장 표현 금지
  - Google: 상표 키워드 주의, 느낌표 남용 금지
  - Meta: Before→After 주의
  - TikTok: 네이티브 톤 유지, 광고스러운 느낌 최소화
- 가격 표기 시 현지 통화 사용 (US → $, KR → ₩)
- 디자인 가이드(섹션 15) 컬러/스타일을 비주얼 가이드에 일관 적용
- MVP에 없는 기능을 광고하지 않는다
- 광고 이미지는 AI 생성이 아닌 HTML+Playwright 파이프라인으로 생성한다 (텍스트 정확도 100% 보장)

# /launch-site 스킬

## 입력
$ARGUMENTS = MVP md 파일명 (docs/ 내 배치 전제)

예시: `/launch-site 1_ZenJournal_AI_Daily_Journal.md`

## 개요

MVP 기획서를 읽고 **Next.js 기반 앱 랜딩 사이트**를 자동 생성하고 **Vercel CLI로 배포**까지 완료한다.
개인정보처리방침, 이용약관(EULA 통합), 지원 페이지를 포함하여 Apple/Google 스토어 심사에 필요한 모든 URL을 한번에 준비한다.

---

## 전제 조건

- Node.js 18+ 설치
- `docs/` 폴더에 MVP md 파일 배치됨
- `docs/build_app_context.json` 존재하면 함께 활용
- Vercel CLI 설치 (`npm i -g vercel`) — 없으면 스킬이 자동 설치
- Vercel 로그인 완료 (`vercel login`) — 미완료 시 스킬이 안내

---

## 실행 순서

### Phase 1: MVP 파일 + 앱소싱 데이터 통합 분석

1. `docs/$ARGUMENTS` 읽기
2. `docs/build_app_context.json` 존재하면 함께 읽기
3. **앱소싱 데이터 자동 탐색** — `docs/` 및 `build_app_context.json`의 `sourcing_data` 경로에서:
   - `앱_설명_모음.md` → 경쟁사 50개 앱의 포지셔닝/기능 요약
   - `앱소싱 리포트*.md` → 시장 규모, 경쟁 환경, 리뷰 불만 패턴
   - `앱소싱_*.xlsx` → 경쟁사 월수익/다운로드, 키워드 데이터
4. MVP에서 추출:
   - 앱 이름, 카테고리, 타겟 국가 (섹션 1)
   - 핵심 차별점 (섹션 3) — Hero/Features 섹션용
   - 무료/유료 기능 (섹션 5, 6) — Pricing 섹션용
   - 가격 정보 (섹션 1) — 월간/연간/평생
   - 브릿지 포인트 (섹션 7) — FAQ 소재
   - 스토어 메타데이터 (섹션 1 — title, subtitle, short_desc, long_desc)
   - 디자인 가이드 — seed_color, secondary_color, style, typography
   - 기술 스택 (섹션 8) — 암호화 방식 등 Privacy 페이지용
   - 경쟁사 정보 (섹션 2) — FAQ "다른 앱과 차이점" 소재
   - 리스크 & 대응 (섹션 13) — Privacy 페이지 보안 조치 소재
5. **소싱 데이터 활용 포인트** (있는 파일만 활용, 없으면 해당 항목 스킵):
   - 앱소싱 xlsx → 경쟁사 월수익 → **Hero 섹션** 시장 검증 배지 ("Join a $10M+ market")
   - 앱설명모음 → 50개 앱 기능 분석 → **Features 섹션** 경쟁사 미보유 기능 강조
   - 앱소싱 리포트 → 리뷰 불만 패턴 → **Hero 카피** 페인포인트 직접 호소 ("Tired of X?")
   - 앱소싱 xlsx → 경쟁사 가격 비교 → **Pricing 섹션** 가성비 강조 ("vs $69.99/yr competitors")
   - 앱소싱 리포트 → 키워드 데이터 → **SEO 메타태그** 고검색량 키워드 반영
   - 앱소싱 리포트 → 경쟁사 약점 상세 → **FAQ "다른 앱과 차이점"** 구체적 비교 포인트
   > 소싱 데이터가 전혀 없으면 MVP 섹션 2/3의 경쟁사 요약만으로 생성
6. `references/` 폴더 확인 — 스크린샷 이미지가 있으면 랜딩에 활용

---

### Phase 2: Next.js 프로젝트 생성

#### 2-0. 환경 확인

```bash
# Vercel CLI 설치 확인 — 없으면 자동 설치
which vercel || npm i -g vercel

# Vercel 로그인 확인
vercel whoami || echo "VERCEL_NOT_LOGGED_IN"
```

Vercel 미로그인 시 사용자에게 안내:
```
Vercel에 로그인이 필요합니다.
터미널에서 `vercel login`을 실행해주세요.
완료되면 'done'을 입력해주세요.
```

#### 2-1. 프로젝트 초기화

```bash
cd {보일러플레이트 루트}
npx create-next-app@latest web \
  --typescript \
  --tailwind \
  --app \
  --src-dir \
  --no-import-alias \
  --eslint
```

#### 2-2. 페이지 구조

```
web/
├── src/app/
│   ├── layout.tsx          ← 공통 레이아웃 (head, nav, footer)
│   ├── page.tsx            ← / 랜딩 페이지
│   ├── privacy/
│   │   └── page.tsx        ← /privacy 개인정보처리방침
│   ├── terms/
│   │   └── page.tsx        ← /terms 이용약관 + EULA
│   └── support/
│       └── page.tsx        ← /support FAQ + 연락처
├── public/
│   ├── .well-known/
│   │   └── assetlinks.json ← Android App Links
│   ├── screenshots/        ← 스토어 스크린샷 (있으면)
│   └── icon.png            ← 앱 아이콘
├── next.config.ts
├── tailwind.config.ts
└── package.json
```

#### 2-3. 각 페이지 상세

##### layout.tsx — 공통 레이아웃

```
- <head>: Smart App Banner 메타 태그
  <meta name="apple-itunes-app" content="app-id={APP_STORE_ID}">
- 네비게이션: 앱 로고 + 홈/Privacy/Terms/Support 링크
- 푸터: © {년도} {개발자명} | Privacy | Terms | Support
- 폰트: MVP 디자인 가이드 typography 반영
- 컬러: Tailwind config에 seed_color, secondary_color 등록
```

##### page.tsx — 랜딩 (/)

```
섹션 구성:

1. Hero
   - 헤드라인: {store_metadata.title}
   - 서브헤드: {store_metadata.subtitle}
   - 앱 스크린샷 또는 목업 이미지
   - CTA: App Store / Google Play 다운로드 버튼 (배지 이미지)
   - 배경: seed_color 그라데이션

2. Features (핵심 기능 3~5개)
   - 차별점 섹션 3에서 추출
   - 아이콘 + 제목 + 1줄 설명
   - 스크린샷 첨부 (있으면)

3. How It Works (사용 흐름)
   - 3스텝: 기록 → AI 분석 → 인사이트
   - 간단한 일러스트 또는 번호 배지

4. Pricing
   - 무료 티어 vs Pro 비교 테이블
   - 무료 기능 목록 (섹션 5)
   - Pro 기능 목록 (섹션 6)
   - 가격: $4.99/mo · $29.99/yr · $79.99 lifetime
   - CTA: "Start Free" 버튼

5. FAQ (4~6개)
   - "다른 저널 앱과 뭐가 다른가요?" → 차별점
   - "데이터는 안전한가요?" → 암호화 설명
   - "무료로 뭘 할 수 있나요?" → 무료 기능
   - "구독 취소는 어떻게 하나요?" → App Store/Google Play 설정
   - "어떤 기기에서 쓸 수 있나요?" → iOS/Android
   - 아코디언 UI

6. Download CTA (하단)
   - App Store + Google Play 배지
   - "Start your journaling journey today"

7. Footer
   - Privacy Policy | Terms of Service | Support
   - © {년도} {개발자명}
   - 소셜 링크 (있으면)
```

##### privacy/page.tsx — 개인정보처리방침

```
GDPR + CCPA + Apple/Google 요구사항 준수.
MVP 기능 기반으로 자동 생성.

필수 섹션:
1. 수집하는 정보 (앱 기능별 매핑)
   - 로컬 저장 데이터 (일기, 감정 등) → "기기에만 저장, 서버 미전송"
   - 클라우드 백업 (선택) → "사용자 동의 시에만, E2E 암호화"
   - 분석 데이터 (Firebase) → "익명화된 사용 통계"
   - 광고 ID (AdMob) → "무료 유저에게만, 맞춤 광고"

2. 데이터 사용 목적
3. 데이터 공유 (제3자: Firebase, RevenueCat, AdMob 등)
4. 데이터 보안 (AES-256, TLS 1.3 등)
5. 데이터 보존 및 삭제
6. 사용자 권리 (열람, 수정, 삭제 요청)
7. 어린이 정책 ("13세 미만 대상 아님")
8. 정책 변경 고지 방법
9. 연락처 (이메일)

마지막 업데이트 날짜 표시.
```

##### terms/page.tsx — 이용약관 + EULA 통합

```
구독 앱 필수 항목 포함 (Apple Guideline 3.1.2).

필수 섹션:
1. 서비스 소개 및 약관 동의
2. 계정 관리 (가입, 연령 제한 13세+, 계정 책임)
3. 허용/금지 사용
4. 구독 및 결제 조건
   - 가격: $4.99/mo · $29.99/yr · $79.99 lifetime
   - 자동 갱신 고지
   - 무료 체험: {7}일, 체험 종료 후 자동 과금
   - 취소 방법: App Store 설정 → 구독 → 취소
5. 환불 정책 (Apple/Google 표준 정책 따름)
6. 지적재산권
7. 서비스 가용성 및 면책
8. 책임 제한 (Limitation of Liability)
9. 개인정보 (Privacy Policy 링크)
10. 준거법 및 분쟁 해결
11. 연락처

마지막 업데이트 날짜 표시.
```

##### support/page.tsx — 지원

```
Apple Support URL 요구사항 충족.

구성:
1. 헤더: "{앱이름} 지원"
2. FAQ 섹션 (5~8개 — 랜딩 FAQ 확장)
   - 일반 사용법
   - 구독/결제 문제
   - 데이터 백업/복구
   - 계정 삭제 방법
   - 버그 신고 방법
3. 연락처
   - 이메일: support@{도메인}
   - 응답 시간: "영업일 기준 48시간 이내"
4. 앱 버전 정보
```

##### .well-known/assetlinks.json — Android App Links

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "{package_name}",
    "sha256_cert_fingerprints": ["{TODO: 앱 서명 후 입력}"]
  }
}]
```

---

### Phase 3: 빌드 검증

```bash
cd web && npm run build
```

빌드 실패 시:
1. 에러 메시지 분석
2. 코드 수정
3. 재빌드
4. 최대 3회 반복 후 사용자에게 보고

빌드 성공 후 4개 페이지 경로 확인:
- `/` → 200 OK
- `/privacy` → 200 OK
- `/terms` → 200 OK
- `/support` → 200 OK

---

### Phase 4: Vercel 자동 배포

```bash
cd web

# Vercel 프로젝트 생성 + 배포 (풀 자동)
vercel --yes

# 배포 URL 확인
vercel ls
```

#### 배포 완료 후 출력

```markdown
## 배포 완료

| 항목 | URL |
|------|-----|
| 랜딩 | https://{project}.vercel.app |
| 개인정보처리방침 | https://{project}.vercel.app/privacy |
| 이용약관 | https://{project}.vercel.app/terms |
| 지원 | https://{project}.vercel.app/support |

### App Store Connect에 입력할 URL
- Privacy Policy URL: https://{project}.vercel.app/privacy
- Support URL: https://{project}.vercel.app/support
- Marketing URL: https://{project}.vercel.app

### 추후 작업
- [ ] 커스텀 도메인 연결: `vercel domains add {도메인}`
- [ ] App Store ID 발급 후 Smart App Banner 메타 태그 업데이트
- [ ] Android 앱 서명 후 assetlinks.json SHA256 fingerprint 업데이트
- [ ] 스토어 배지 이미지를 실제 스토어 링크로 연결
```

---

### Phase 5: 산출물 정리

1. **`web/`** — Next.js 프로젝트 (Vercel에 배포 완료)
2. 사용자에게 배포 URL + 스토어 제출용 URL 목록 제공
3. TODO 항목 안내 (도메인, App Store ID, SHA256 등)

---

## 규칙

- MVP 파일에 없는 정보를 추측하지 않는다
- 개인정보처리방침은 GDPR + CCPA + Apple/Google 요구사항 모두 충족
- 이용약관에 Apple Guideline 3.1.2 구독 필수 항목 반드시 포함
- 가격은 MVP 파일의 정확한 금액 사용 (임의 변경 금지)
- 디자인은 MVP seed_color + secondary_color를 Tailwind에 등록하여 일관 적용
- Support URL은 실제 로드 가능해야 함 (Apple이 확인)
- assetlinks.json의 SHA256은 TODO로 남김 (앱 서명 후 입력)
- Smart App Banner app-id는 TODO로 남김 (App Store 등록 후 입력)
- Vercel 배포 실패 시 에러 분석 후 수정, 최대 3회 재시도
- `web/` 폴더는 `.gitignore`에 추가하지 않음 (레포에 포함)
- 타겟 국가가 US면 영어, KR이면 한글로 페이지 작성

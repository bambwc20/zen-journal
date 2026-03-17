# Flutter 1인개발 보일러플레이트

> MVP md 파일 1개를 Claude Code에게 주면, 코드 생성 → 테스트 → 빌드 → 서버 배포까지 자동 완료하는 보일러플레이트.
> 20개 앱 모두 CRM, 결제, 푸시, 백업, 광고를 지원하되, 운영 부담 0, 월 비용 $5 이하로 시작한다.

**대상**: 4개 카테고리 20개 MVP 앱 (Journal US 5, 캘린더 KR 5, 계산기 KR 5, 생리주기 KR 5)

---

## 아키텍처: Local-first + 선택적 클라우드

```
┌─────────────────────────────────────────────────────┐
│  Flutter App (클라이언트)                               │
│                                                     │
│  Drift SQLite (로컬, 유일한 소스 오브 트루스)              │
│  → 핵심 데이터는 전부 로컬. 오프라인 완벽 동작             │
│                                                     │
│  api_client.dart → HTTPS → Cloudflare Workers       │
│  → 서버는 부가 기능(백업, 푸시, CRM)만 담당               │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│  Cloudflare Workers (서버)                            │
│                                                     │
│  /api/backup/*     → R2 (백업/복원)                   │
│  /api/user/*       → D1 (유저 프로필, FCM 토큰)        │
│  /api/ai/*         → 외부 AI API 프록시                │
│  /webhook/revenuecat → D1 (구독 상태 변경 처리)         │
│  Cron Triggers     → FCM HTTP v1 API (스케줄 푸시)     │
└─────────────────────────────────────────────────────┘
```

---

## 기술 스택

### 코어 프레임워크

| 영역 | 선택 | 이유 |
|------|------|------|
| **프레임워크** | Flutter 3.x | 크로스플랫폼, 위젯 지원, 1인개발 최적 |
| **상태관리** | Riverpod + riverpod_generator | 코드생성 기반, AI가 일관된 패턴 생성 가능, 타입 안전 |
| **로컬 DB** | Drift (SQLite ORM) | 타입 안전 쿼리, 마이그레이션 내장, 코드생성으로 AI 친화적 |
| **라우팅** | go_router | 선언적, 딥링크 내장, 공식 추천 |
| **코드생성** | freezed + json_serializable + build_runner | 불변 모델 + JSON 직렬화 자동화 |

### 수익화

| 영역 | 선택 | 이유 |
|------|------|------|
| **구독 관리** | RevenueCat (Free ~$2,500 MTR) | Flutter SDK 성숙도 1위, A/B 테스트, 영수증 검증 자동 |
| **광고** | google_mobile_ads (AdMob) | 앱 5개 이상 매출 발생 시 AppLovin MAX 미디에이션 검토 |
| **페이월 UI** | RevenueCat Paywalls (Flutter SDK) | 서버사이드 페이월 A/B 테스트, 코드 변경 없이 디자인 교체 |
| **OTA 코드 푸시** | Shorebird (Free 5,000 installs/yr) | 스토어 심사 없이 Dart 코드 패치 즉시 배포 |

### 인프라 (서버리스)

| 서비스 | 용도 | 무료 한도 | 월 비용 |
|--------|------|----------|---------|
| **Firebase Auth** | 사용자 인증 | 50K MAU | $0 |
| **Firebase Analytics** | 앱 분석 + 유저 세그먼트 | 무제한 | $0 |
| **FCM** | 푸시 알림 | 무제한 | $0 |
| **Cloudflare Workers** | 서버 로직 (백업/CRM/푸시/AI 프록시) | 100K req/day | $0→$5 |
| **Cloudflare D1** | Edge SQLite DB (유저 프로필, FCM 토큰) | 5GB, 5M reads/day | $0 |
| **Cloudflare R2** | 프리미엄 백업 저장소 | 10GB, 1M req/mo | $0 |
| **Workers KV** | 캐시/세션 스토어 | 100K reads/day | $0 |
| **Workers Cron** | 스케줄 (푸시, 구독 만료) | 무료 | $0 |
| **Shorebird** | OTA 코드 푸시 | 5,000 installs/yr | $0→$20 |
| **GitHub Actions** | Android CI/CD | 2,000min/mo | $0 |
| **Codemagic** | iOS CI/CD | 500min/mo | $0→$95 |

---

## 프로젝트 구조

```
flutter_boilerplate/
├── .claude/
│   ├── commands/
│   │   └── build-app.md          # MVP md → 앱 자동 생성 스킬
│   └── settings.json
├── CLAUDE.md                      # Claude Code 코딩 지침서
├── lib/
│   ├── main.dart                  # 앱 진입점 (환경설정 주입)
│   ├── app.dart                   # MaterialApp + Router + Theme
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart  # Drift DB 정의 (테이블은 feature에서)
│   │   │   ├── backup_service.dart # 로컬 JSON 백업 (7일 로테이션)
│   │   │   └── migration.dart     # DB 마이그레이션 관리
│   │   ├── subscription/
│   │   │   ├── subscription_provider.dart  # RevenueCat 래퍼
│   │   │   ├── paywall_screen.dart        # 온보딩 페이월 템플릿
│   │   │   └── entitlement.dart           # 프리미엄 기능 게이트
│   │   ├── ads/
│   │   │   ├── ad_provider.dart    # AdMob 초기화 + 배너/전면 관리
│   │   │   └── ad_widgets.dart     # AdBanner, RewardedAdButton
│   │   ├── analytics/
│   │   │   └── analytics_service.dart  # Firebase Analytics 래퍼
│   │   ├── push/
│   │   │   └── push_service.dart   # FCM + 로컬 알림
│   │   ├── theme/
│   │   │   ├── app_theme.dart      # 라이트/다크 테마 정의
│   │   │   └── theme_provider.dart # 테마 전환 상태
│   │   ├── l10n/
│   │   │   └── app_localizations.dart  # 다국어 (ko, en, ja)
│   │   ├── settings/
│   │   │   ├── settings_screen.dart    # 공통 설정 화면
│   │   │   └── settings_provider.dart  # SharedPreferences 래퍼
│   │   └── network/
│   │       └── api_client.dart     # Cloudflare Workers API 클라이언트
│   ├── features/                   # ← 앱별 커스텀 영역
│   │   └── .gitkeep
│   └── shared/
│       ├── widgets/
│       │   ├── onboarding_flow.dart    # 3-step 온보딩 위젯
│       │   ├── empty_state.dart        # 빈 상태 일러스트
│       │   ├── loading_overlay.dart    # 로딩 오버레이
│       │   └── confirm_dialog.dart     # 확인 다이얼로그
│       └── utils/
│           ├── date_utils.dart         # 날짜 포맷, 음력 변환
│           └── string_utils.dart       # 문자열 유틸
├── pubspec.yaml
├── analysis_options.yaml
├── build.yaml                      # build_runner 격리 설정
├── android/
│   └── app/src/main/AndroidManifest.xml
├── ios/
│   └── Runner/Info.plist
├── test/
│   ├── helpers/
│   │   └── test_database.dart      # Drift 인메모리 DB 헬퍼
│   ├── core/                       # core 모듈 테스트
│   ├── features/                   # 앱별 테스트 (lib/ 미러링)
│   └── shared/                     # 공유 위젯 테스트
├── workers/                        # Cloudflare Workers (서버 사이드)
│   ├── wrangler.toml              # Workers + D1 + R2 + Cron 설정
│   ├── src/
│   │   ├── index.ts               # 라우터 진입점
│   │   ├── routes/
│   │   │   ├── backup.ts          # /api/backup/*
│   │   │   ├── user.ts            # /api/user/*
│   │   │   ├── push.ts            # /api/push/*
│   │   │   └── webhook.ts         # /webhook/revenuecat
│   │   ├── cron/
│   │   │   └── scheduled.ts       # Cron 핸들러 (스케줄 푸시)
│   │   └── lib/
│   │       ├── auth.ts            # Firebase Auth 토큰 검증
│   │       ├── fcm.ts             # FCM HTTP v1 API 헬퍼
│   │       └── d1.ts              # D1 쿼리 헬퍼
│   ├── schema.sql                 # D1 초기 스키마
│   └── package.json
├── codecov.yml
└── .github/
    └── workflows/
        ├── test.yml                # 테스트 + 분석 + 커버리지
        └── android-release.yml     # Android 빌드 + Play Store 배포
```

---

## 서버 사이드 (Workers + D1)

### D1 스키마

```sql
-- 유저 프로필 (CRM 기본)
CREATE TABLE user_profiles (
  firebase_uid TEXT PRIMARY KEY,
  fcm_token TEXT,
  device_os TEXT,
  segments TEXT DEFAULT 'free',  -- 'free', 'premium', 'churned'
  utm_source TEXT,
  utm_medium TEXT,
  last_online_at INTEGER,
  created_at INTEGER DEFAULT (unixepoch())
);

-- 푸시 발송 이력
CREATE TABLE push_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  target_segment TEXT,
  title TEXT,
  body TEXT,
  sent_count INTEGER,
  sent_at INTEGER DEFAULT (unixepoch())
);
```

### CRM 기능 매핑

| 기능 | 담당 |
|------|------|
| 유저 프로필 | D1 `user_profiles` (Workers API) |
| 무료/유료 구분 | RevenueCat `CustomerInfo.entitlements` (앱 클라이언트) |
| 구독 만료 자동 처리 | RevenueCat 서버 자동 + Webhook → Workers |
| 구매 이력 | RevenueCat REST API `/v1/subscribers/{uid}` |
| 유저 세그먼트 | RevenueCat Webhook → D1 segments 업데이트 |
| UTM 추적 | Firebase Analytics + D1 utm_* 컬럼 |
| 접근 레벨 제어 | RevenueCat entitlement 기반 게이팅 (앱 클라이언트) |

### 푸시 알림 전략

| 푸시 유형 | 구현 방법 | 트리거 |
|----------|----------|--------|
| **스케줄 푸시** (매주 금/토) | Workers Cron → FCM HTTP v1 API | `wrangler.toml` crons |
| **타겟 푸시** (유료 유저만) | D1에서 segments='premium' 조회 → FCM 배치 | Workers API |
| **이벤트 푸시** (구독 만료 등) | RevenueCat Webhook → Workers → FCM | Webhook 수신 |
| **로컬 알림** (리마인더) | `flutter_local_notifications` zonedSchedule | 앱 클라이언트 |
| **토픽 구독/해제** | FCM topic subscribe/unsubscribe | 앱 클라이언트 |

### RevenueCat Webhook 처리

```
RevenueCat 서버 → POST /webhook/revenuecat → Workers
     │
     ├── INITIAL_PURCHASE → D1 segments='premium'
     ├── RENEWAL → 로깅만
     ├── CANCELLATION → D1 segments='churned'
     ├── EXPIRATION → FCM 만료 푸시 + D1 segments='free'
     └── BILLING_ISSUE → FCM 결제 실패 알림
```

---

## OTA 코드 푸시 — Shorebird

스토어 심사 없이 Dart 코드를 즉시 패치하는 서비스. 긴급 버그 수정에 필수.

```bash
# 최초 릴리즈 (스토어 제출용)
shorebird release --platforms android,ios

# 긴급 패치 (스토어 심사 없이 OTA 배포)
shorebird patch --platforms android,ios

# 문제 발생 시 즉시 롤백
shorebird patch rollback
```

- **Dart 코드만 패치 가능** (네이티브 코드 변경은 스토어 재심사 필요)
- App Store / Google Play 정책 준수
- `shorebird` CLI는 Flutter CLI를 래핑 → 기존 빌드 파이프라인에 최소 변경

| 플랜 | 가격 | 패치 설치 수 |
|------|------|-------------|
| **Starter** | **무료** | 5,000/년 |
| **Pro** | $240/년 ($20/월) | 50,000/년 |
| **Business** | $4,800/년 | 12,000,000/년 |

---

## 클라우드 백업 전략

```
[Flutter App] → Drift SQLite (로컬, 유일한 소스 오브 트루스)
     │
     ├── 무료 유저: 로컬 자동백업 (7일분) + Google Drive 수동 내보내기
     │
     └── 프리미엄 구독자:
          [Firebase Auth 토큰] → [Cloudflare Worker] → [R2 버킷]
                                  (upload/download/list 3개 API)
```

- 스냅샷 백업/복원만 지원 (실시간 동기화 없음)
- 충돌 해결: "최신 백업 우선" 단순 전략 (MVP에 충분)
- 확장 시점: MAU 1만+ & 동기화 니즈 검증 시 Supabase Pro 도입

---

## 구독-광고 연동 패턴

```dart
// core/subscription/subscription_provider.dart
@riverpod
Stream<CustomerInfo> customerInfo(Ref ref) {
  return Purchases.addCustomerInfoUpdateListener;
}

// core/ads/ad_provider.dart
@riverpod
bool showAds(Ref ref) {
  final subscription = ref.watch(customerInfoProvider);
  return subscription.when(
    data: (info) => !info.entitlements.active.containsKey('premium'),
    loading: () => false,  // 로딩 중 광고 숨김 (깜빡임 방지)
    error: (_, __) => true, // 에러 시 광고 표시 (안전측)
  );
}
```

### iOS 초기화 순서 (AppDelegate)

```
1. Firebase.initializeApp()     ← 반드시 첫 번째
2. Purchases.configure()        ← Firebase 이후
3. AdMob MobileAds.initialize() ← 마지막
```

> 순서 위반 시 `EXC_BAD_ACCESS` 크래시.

---

## Claude Code 자동화

### /build-app 스킬 (MVP md → 앱 자동 생성)

```
Phase 1: MVP md 파싱 → 앱 이름, 수익 모델, 핵심 기능 추출
Phase 2: Feature 생성 → lib/features/{app_name}/{data,domain,presentation}/
Phase 3: 설정 연결 → Firebase/RevenueCat/AdMob 초기화, 라우트 등록
Phase 4: 수익화 연결 → 페이월, EntitlementGate, 광고 배치
Phase 5: 코드 생성 → build_runner + analyze + 빌드 확인
Phase 6: 테스트 → 유닛/위젯/UI/네이티브/릴리즈 빌드 검증
```

### 4단계 테스트 피라미드

```
┌─────────────────────────────────────────────────┐
│  Level 4: 릴리즈 빌드 검증                        │
│  xcode-build + android-build MCP                 │
├─────────────────────────────────────────────────┤
│  Level 3: 네이티브 기능 테스트                      │
│  mobile-mcp + 에뮬레이터/시뮬레이터                 │
├─────────────────────────────────────────────────┤
│  Level 2: UI 플로우 테스트                         │
│  playwright MCP + Flutter Web                    │
├─────────────────────────────────────────────────┤
│  Level 1: 유닛 + 위젯 테스트 (가장 빠름, 가장 많이)  │
│  Bash: flutter test                              │
└─────────────────────────────────────────────────┘
```

> Level 1-2는 매 편집마다, Level 3-4는 기능 완성 시에만 실행.

### MCP 서버 구성

| MCP | 역할 | 테스트 레벨 |
|-----|------|-----------|
| **context7** | 라이브러리 최신 문서 조회 | 개발 참조 |
| **mobile-mcp** | iOS/Android 에뮬레이터 직접 조작 | Level 3 |
| **playwright** | Flutter Web UI 검증 | Level 2 |
| **xcode-build** | iOS 빌드 검증 | Level 4 |
| **android-build** | Android 빌드 검증 | Level 4 |

### Claude Code의 역할 경계

| 작업 | Claude Code가 하는 것 | Claude Code가 할 수 없는 것 |
|------|---------------------|--------------------------|
| CRM | Workers/D1 코드 생성·수정 | 런타임에 유저 데이터 조회 |
| 푸시 | FCM 발송 코드 생성, Cron 코드 작성 | 프로덕션에서 직접 푸시 발송 |
| 결제 | RevenueCat 연동 코드 작성 | 실시간 결제 처리·환불 |
| 테스트 | `flutter test` 실행, 실패 시 수정 | MCP로 테스트 실행 |
| 빌드 | `flutter build` 실행, 에러 수정 | 앱스토어 심사·배포 |

---

## Google Play 스팸 정책 대응

20개 앱을 1개 계정에서 출시하면 스팸 정책 위반으로 계정 정지 리스크.

| 계정 | 앱 수 | 카테고리 |
|------|-------|----------|
| 계정 A | 5개 | Journal (US) |
| 계정 B | 10개 | 캘린더 + 계산기 (KR) |
| 계정 C | 5개 | 생리주기 (KR) |

### 차별화 규칙

1. **UI 테마**: 같은 카테고리 내 앱끼리 다른 색상 팔레트 + 아이콘 스타일
2. **기능 세트**: 각 앱은 고유 핵심 차별점 1개 이상
3. **패키지명**: 카테고리별 다른 도메인 (`com.zenjournal.app`, `com.smartplan.calendar` 등)
4. **개발자명**: 계정별 다른 개발자 표시명
5. **점진적 출시**: 한 계정에서 주 1개씩 (한번에 5개 동시 출시 금지)

---

## 실행 로드맵

### Phase 1: 보일러플레이트 구축 (1주)

| Task | 상세 | 검증 |
|------|------|------|
| 1.1 | Flutter 프로젝트 생성 + 패키지 설치 | `flutter pub get` 성공 |
| 1.2 | core/ 모듈 구현 (DB, 구독, 광고, 분석, 푸시, 테마, 설정) | `flutter analyze` 경고 0 |
| 1.3 | shared/ 위젯 구현 (온보딩, 페이월, 빈 상태) | 위젯 테스트 통과 |
| 1.4 | build-app.md 스킬 작성 + CLAUDE.md 작성 | 스킬 dry-run |
| 1.5 | CI/CD 파이프라인 (GitHub Actions + Codemagic) | 테스트 빌드 성공 |
| 1.6 | test/helpers/ 테스트 유틸 | 헬퍼 import 성공 |
| 1.7 | core/ 모듈 테스트 | `flutter test test/core/` 통과 |
| 1.8 | Claude Code hooks 설정 | .dart 편집 시 자동 analyze 확인 |
| 1.9 | Workers 서버 구축 (D1 + API + Cron) | `wrangler deploy` + curl 테스트 |
| 1.10 | RevenueCat Webhook + FCM 서버 발송 테스트 | D1 업데이트 확인 |
| 1.11 | MCP 서버 설정 | 각 MCP 연결 확인 |
| 1.12 | Shorebird CLI 설치 + 초기 설정 | `shorebird doctor` 통과 |

### Phase 2: 파일럿 앱 2개 (1주)

| 앱 | 이유 | 예상 기간 |
|----|------|----------|
| 실생활 다용도 계산기 (KR) | Tier 1, 가장 단순, 보일러플레이트 검증용 | 3일 |
| 달토리 생리주기 (KR) | Tier 2, 중간 복잡도, 핵심 패턴 검증 | 4일 |

### Phase 3: 본격 출시 (6~8주)

- 주 1~2개 앱 완성 → Play Store 출시
- 카테고리별 순서: 계산기 (간단) → 캘린더 → 생리주기 → Journal (복잡)
- 각 앱 현실적 소요: **5~7일** (개발 3~4일 + 스토어 심사/메타데이터 1~2일 + 버그픽스 1일)

### Phase 4: 수익 최적화 (출시 후)

- RevenueCat A/B 페이월 테스트
- 앱 5개 이상 매출 발생 시 AdMob → AppLovin MAX 미디에이션 검토
- MTR $2,500 돌파 시 RevenueCat Starter ($99/mo) 전환

---

## 리스크 & 대응

| # | 리스크 | 심각도 | 대응 |
|---|--------|--------|------|
| 1 | Google Play 스팸 정책 | **Critical** | 3개 계정 분산 + UI/기능 차별화 + 점진적 출시 |
| 2 | Workers 무료 CPU 한계 (10ms) | **Critical** | AI 앱은 유료 $5/mo 전환 |
| 3 | Codemagic 500min 빌드 한계 | Important | Phase별 대응 (무료→유료) |
| 4 | RevenueCat $2,500 MTR 초과 | Important | $99는 매출 대비 미미, 모니터링 |
| 5 | build_runner 격리 미설정 | **Critical** | build.yaml 격리 필수 |
| 6 | AI Riverpod/freezed 오생성 | **Critical** | CLAUDE.md 패턴 예시 + context7 MCP |
| 7 | iOS 초기화 순서 충돌 | Important | Firebase → RevenueCat → AdMob 순서 고정 |
| 8 | Shorebird 무료 한도 | Minor | Phase 1-3 충분, 성장기 Pro $20/mo |

---

## 비용 요약

### Phase 1-2 (앱 5개 이하)

| 항목 | 월 비용 |
|------|---------|
| Cloudflare Workers (AI 앱용) | $5 |
| Shorebird / 기타 인프라 | $0 |
| Google Play 개발자 등록 (1회, 3계정) | $75 (일회성) |
| Apple Developer (연간) | $99/yr |
| **총 월 운영비** | **$5** |

### Phase 3+ (앱 10개+, 매출 발생 시)

| 항목 | 월 비용 |
|------|---------|
| Cloudflare Workers | $5 |
| Shorebird Pro (MAU 1만+ 시) | $20 |
| Codemagic Teams (필요 시) | $95 |
| RevenueCat (MTR $2,500 초과 시) | $99 |
| **총 월 운영비** | **$5~$219** |

---

## 외부 설정 & API 키 체크리스트

> 보일러플레이트 구축 전 반드시 완료해야 하는 외부 플랫폼 설정.

### 계정 생성

| # | 플랫폼 | 비용 | 필요 시점 |
|---|--------|------|----------|
| 1 | **Cloudflare** 계정 | 무료 (유료 $5/mo) | Phase 1 |
| 2 | **Firebase** 프로젝트 | 무료 | Phase 1 |
| 3 | **RevenueCat** 계정 | 무료 (~$2,500 MTR) | Phase 1 |
| 4 | **AdMob** 계정 | 무료 | Phase 1 |
| 5 | **GitHub** 계정 + 리포 | 무료 | Phase 1 |
| 6 | **Codemagic** 계정 | 무료 (500min/mo) | Phase 1 |
| 7 | **Shorebird** 계정 | 무료 (5,000 installs/yr) | Phase 1 |
| 8 | **Google Play Console** × 3개 | $25 × 3 = $75 (1회) | Phase 3 |
| 9 | **Apple Developer Program** | $99/yr | Phase 3 |

### API 키 & 시크릿

#### Phase 1 (보일러플레이트 구축 시 필수)

| # | 키/시크릿 | 발급 위치 | 사용처 |
|---|----------|----------|--------|
| 1 | **google-services.json** | Firebase Console → Android 앱 추가 | `android/app/` |
| 2 | **GoogleService-Info.plist** | Firebase Console → iOS 앱 추가 | `ios/Runner/` |
| 3 | **FCM 서비스 계정 키 (JSON)** | Firebase Console → 서비스 계정 → 새 비공개 키 | `workers/src/lib/fcm.ts` |
| 4 | **RevenueCat SDK API Key** | RevenueCat Dashboard → API Keys | `Purchases.configure(apiKey)` |
| 5 | **RevenueCat Webhook Secret** | RevenueCat Dashboard → Webhooks | `workers/src/routes/webhook.ts` |
| 6 | **Cloudflare API Token** | Cloudflare → API Tokens | `wrangler deploy` |
| 7 | **Cloudflare Account ID** | Cloudflare → Workers 개요 | `wrangler.toml` |
| 8 | **AdMob App ID** (iOS/Android) | AdMob Console → 앱 추가 | `AndroidManifest.xml`, `Info.plist` |
| 9 | **AdMob Ad Unit ID** | AdMob Console → 광고 단위 생성 | `lib/core/ads/ad_provider.dart` |

#### Phase 2+ (백업 기능)

| # | 키/시크릿 | 발급 위치 | 사용처 |
|---|----------|----------|--------|
| 10 | **Google OAuth Client ID** | Google Cloud Console → 사용자 인증 정보 | `google_sign_in` |

#### Phase 3 (스토어 출시)

| # | 키/시크릿 | 발급 위치 | 사용처 |
|---|----------|----------|--------|
| 11 | **Play Store 서비스 계정 키** | Google Play Console → API 액세스 | GitHub Actions 배포 |
| 12 | **Android Keystore** (.jks) | `keytool -genkey` | APK/AAB 서명 |
| 13 | **iOS Distribution Certificate** (.p12) | Apple Developer → Certificates | Codemagic |
| 14 | **iOS Provisioning Profile** | Apple Developer → Profiles | Codemagic |

### 플랫폼 대시보드 설정

#### Firebase Console

```
1. 프로젝트 생성
2. Android 앱 등록 → google-services.json 다운로드
3. iOS 앱 등록 → GoogleService-Info.plist 다운로드
4. Authentication → 로그인 방법 활성화
5. Cloud Messaging → FCM 활성화
6. 서비스 계정 → 새 비공개 키 생성 (Workers FCM 발송용)
```

#### Cloudflare Dashboard

```
1. Workers & Pages → Account ID 확인
2. D1 → 데이터베이스 생성 → schema.sql 실행
3. R2 → 버킷 생성 (backup-bucket)
4. Workers 환경변수: FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY,
   REVENUECAT_WEBHOOK_SECRET, FCM_SERVICE_ACCOUNT_EMAIL
5. Cron Triggers 설정 (wrangler.toml)
```

#### RevenueCat Dashboard

```
1. 프로젝트 생성
2. App Store / Google Play 앱 연결
3. Entitlements 정의: "premium", "ad_free"
4. Offerings 구성: 월간/연간 구독 상품
5. Webhooks: https://your-worker.workers.dev/webhook/revenuecat
```

#### AdMob Console

```
1. 앱 등록 (iOS/Android) → App ID 발급
2. 광고 단위 생성 (배너, 전면, 보상형)
3. 테스트 기기 등록
```

### 로컬 개발 환경 (CLI 도구)

| # | 도구 | 설치 | 용도 |
|---|------|------|------|
| 1 | **Flutter SDK** 3.29.2+ | `brew install flutter` | 앱 개발 |
| 2 | **Xcode** 15+ | Mac App Store | iOS 빌드 |
| 3 | **Android Studio** + SDK | 공식 다운로드 | Android 빌드 |
| 4 | **Shorebird CLI** | 공식 설치 스크립트 | OTA 코드 푸시 |
| 5 | **Wrangler CLI** | `npm install -g wrangler` | Workers 배포 |
| 6 | **Node.js** 18+ | `brew install node` | Workers 개발 |
| 7 | **CocoaPods** | `sudo gem install cocoapods` | iOS 의존성 |

### 시크릿 저장 위치 매핑

```
┌─────────────────────────────────────────────────────┐
│  Flutter 앱 (빌드 타임)                               │
│  - google-services.json       → android/app/        │
│  - GoogleService-Info.plist   → ios/Runner/          │
│  - AdMob App ID               → AndroidManifest.xml │
│  -                            → Info.plist           │
│  - RevenueCat API Key         → main.dart 환경변수    │
├─────────────────────────────────────────────────────┤
│  Cloudflare Workers (런타임)                          │
│  wrangler secret put:                               │
│  - FIREBASE_PRIVATE_KEY                              │
│  - REVENUECAT_WEBHOOK_SECRET                         │
│  - FCM_SERVICE_ACCOUNT_EMAIL                         │
├─────────────────────────────────────────────────────┤
│  GitHub Actions (CI/CD)                              │
│  - PLAY_STORE_SERVICE_ACCOUNT_KEY                    │
│  - ANDROID_KEYSTORE_BASE64                           │
│  - ANDROID_KEY_ALIAS / KEY_PASSWORD                  │
├─────────────────────────────────────────────────────┤
│  Codemagic (iOS CI/CD)                               │
│  - APPLE_TEAM_ID                                     │
│  - CODE_SIGNING_IDENTITY                             │
│  - PROVISIONING_PROFILE (파일 업로드)                  │
│  - CERTIFICATE_P12 (파일 업로드)                       │
└─────────────────────────────────────────────────────┘
```

### Phase별 설정 우선순위

#### Phase 1 (보일러플레이트 구축 전 필수) — 약 4~5시간

| 순서 | 작업 | 예상 시간 |
|------|------|----------|
| 1 | Firebase 프로젝트 생성 + config 파일 2개 | 30분 |
| 2 | Cloudflare 계정 + D1/R2 생성 | 30분 |
| 3 | RevenueCat 계정 + API Key 발급 | 30분 |
| 4 | AdMob 계정 + 테스트 Ad Unit 생성 | 30분 |
| 5 | Flutter + Xcode + Android Studio 설치 | 2~3시간 |
| 6 | Wrangler CLI + `wrangler login` | 10분 |
| 7 | Shorebird CLI + `shorebird login` + `shorebird init` | 15분 |

#### Phase 3 (출시 전) — 약 4~5시간

| 순서 | 작업 | 예상 시간 |
|------|------|----------|
| 8 | Google Play 개발자 계정 3개 | 1시간 |
| 9 | Apple Developer + 인증서/프로비저닝 | 2시간 |
| 10 | Android Keystore 생성 | 10분 |
| 11 | Codemagic 연동 | 30분 |
| 12 | Google OAuth 설정 (Drive 백업용) | 30분 |

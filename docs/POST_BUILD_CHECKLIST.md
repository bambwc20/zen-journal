# ZenJournal Post-Build Checklist

## App Signing & Distribution
- [ ] Android Keystore 생성 (`keytool -genkey -v -keystore zen-journal.jks`)
- [ ] iOS Certificate + Provisioning Profile 생성 (Apple Developer Console)
- [ ] Google Play Console 앱 등록 (com.yourcompany.zenjournal)
- [ ] App Store Connect 앱 등록

## Firebase Setup
- [ ] Firebase 프로젝트 생성 (firebase.google.com)
- [ ] Android: `google-services.json` → `android/app/`
- [ ] iOS: `GoogleService-Info.plist` → `ios/Runner/`
- [ ] Firebase Analytics 활성화
- [ ] Firebase Crashlytics 활성화
- [ ] Firebase Cloud Messaging 설정

## RevenueCat Setup
- [ ] RevenueCat 콘솔에서 앱 등록 (docs/REVENUECAT_SETUP.md 참조)
- [ ] Product ID 등록: `zen_journal_monthly`, `zen_journal_yearly`, `zen_journal_lifetime`
- [ ] Entitlement "premium" 생성 및 제품 연결
- [ ] App Store Connect / Google Play Console에서 구독 상품 등록
- [ ] Sandbox 테스트 계정 설정
- [ ] `REVENUECAT_API_KEY` 환경변수 설정

## AdMob Setup
- [ ] AdMob 계정에서 앱 등록
- [ ] 프로덕션 광고 유닛 ID 생성 (docs/AD_UNIT_IDS.md 참조)
- [ ] 테스트 ID → 프로덕션 ID 교체:
  - AndroidManifest.xml: `com.google.android.gms.ads.APPLICATION_ID`
  - Info.plist: `GADApplicationIdentifier`
  - 코드 내 배너/인터스티셜/네이티브/리워드 유닛 ID

## AI API Backend
- [ ] Cloudflare Workers (또는 프록시 서버) 배포
- [ ] Claude API 키 설정 (Haiku 모델)
- [ ] `/api/reflect` 엔드포인트 구현 (7일 컨텍스트 윈도우)
- [ ] `/api/weekly-report` 엔드포인트 구현
- [ ] `API_BASE_URL` 환경변수 설정
- [ ] Rate limiting + API 비용 모니터링 설정

## Store Listing
- [ ] ASO 키워드 최적화 (docs/ASO_KEYWORDS.md 참조)
- [ ] 스토어 등록 정보 입력 (docs/STORE_LISTING.md 참조)
- [ ] 스크린샷 5종 준비 (iPhone 6.7", iPhone 5.5", Android Phone)
- [ ] Feature Graphic (Google Play) 준비
- [ ] 개인정보 처리방침 URL 준비
- [ ] 앱 아이콘 교체 (현재 Flutter 기본 아이콘)

## Pre-Launch Testing
- [ ] Android 실기기 테스트 (APK 설치)
- [ ] iOS 실기기 테스트 (TestFlight)
- [ ] RevenueCat Sandbox 구매 테스트
- [ ] 푸시 알림 수신 테스트
- [ ] 암호화 백업/복원 테스트
- [ ] 다크모드 UI 확인

## Launch
- [ ] 베타 유저 50명 모집 (docs/MARKETING_PLAN.md Stage 1)
- [ ] Product Hunt 런칭 페이지 준비
- [ ] Google Play 내부 테스트 → 프로덕션 배포
- [ ] App Store 심사 제출

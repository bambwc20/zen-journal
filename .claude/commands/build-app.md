# /build-app 스킬

## 입력
$ARGUMENTS = MVP md 파일 경로

## 실행 순서

### Phase 1: MVP 파싱
1. MVP md 파일을 읽고 다음 추출:
   - 앱 이름, 카테고리, 타겟 국가
   - 수익 모델 (구독/IAP/하이브리드)
   - 핵심 기능 목록
   - 가격 정보
   - 기술 요구사항

### Phase 2: Feature 생성
1. lib/features/{app_name}/ 디렉토리 생성
2. 핵심 기능별 서브 feature 생성:
   - data/tables/ → Drift 테이블 정의
   - domain/models/ → freezed 모델
   - domain/use_cases/ → 비즈니스 로직
   - presentation/screens/ → UI 화면
   - presentation/providers/ → Riverpod providers
   - presentation/routes.dart → go_router 라우트

### Phase 3: 설정 연결
1. main.dart에 Firebase/RevenueCat/AdMob 초기화 코드
2. app.dart에 라우트 등록
3. pubspec.yaml에 앱별 추가 패키지 (있으면)
4. AndroidManifest.xml / Info.plist 권한 추가

### Phase 4: 수익화 연결
1. RevenueCat offering ID 설정
2. 페이월 화면 구성 (온보딩 3-step → 페이월)
3. 프리미엄 기능 EntitlementGate 적용
4. 광고 배치 (하이브리드 모델이면)

### Phase 5: 코드 생성 & 검증
1. `dart run build_runner build --delete-conflicting-outputs`
2. `dart analyze`
3. `flutter build apk --debug` (빌드 확인)

### Phase 6: 테스트 작성 & 검증

#### 6-1. 필수 유닛 테스트 생성
1. MVP md에서 핵심 비즈니스 로직 식별
2. domain/use_cases/ 각 use case에 대해 테스트 파일 생성
   - 정상 케이스 + 엣지 케이스 + 에러 케이스
3. data/repositories/ Drift 인메모리 테스트 생성
   - CRUD 전체 + 쿼리 필터/정렬 검증
4. core/subscription/ 구독 상태 분기 테스트
   - 무료→프리미엄, 프리미엄→만료, 에러 시 폴백

#### 6-2. 핵심 위젯 테스트 생성
1. 온보딩 → 페이월 전환 플로우
2. 메인 리스트 화면 (빈 상태, 데이터 있음, 로딩)
3. CRUD 폼 (입력 검증, 저장 성공/실패)

#### 6-3. 테스트 실행 & 자동 수정 루프
1. `flutter test` 실행
2. 실패 시 유형 분류:
   - 유형 A (소스 버그): expect 불일치 → 소스 코드 수정
   - 유형 B (테스트 설정 오류): mock 누락, MissingPluginException → 테스트 설정 수정
   - 유형 C (설계 불일치): 인터페이스 변경 → 소스+테스트 동시 수정
3. assert 삭제/expect 완화로 통과시키는 것 금지
4. 동일 파일 동일 에러 2회 반복 시 루프 즉시 중단
5. 최대 5회 루프. 실패 시 BLOCKED.md 파일 생성 + 사람에게 보고
6. `dart analyze` 경고 0 확인

#### 6-4. UI 플로우 테스트 (Level 2: Playwright MCP)
1. `flutter run -d chrome --web-port=8080` 실행
2. playwright `browser_navigate` → http://localhost:8080
3. 온보딩 → 페이월 전환 플로우 검증
4. 메인 화면 CRUD 동작 확인
5. 다크모드 전환 + 빈 상태 화면 확인

#### 6-5. 네이티브 기능 테스트 (Level 3: mobile-mcp)
1. `flutter run -d emulator` 실행
2. mobile-mcp로 앱 화면 스크린샷 + 인터랙션
3. 검증: 푸시 권한, AdMob 배너, RevenueCat 샌드박스, 홈 위젯

#### 6-6. 릴리즈 빌드 검증 (Level 4)
1. `flutter build apk --release`
2. `xcode-build` MCP로 iOS Archive 빌드

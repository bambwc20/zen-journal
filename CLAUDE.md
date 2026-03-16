# Flutter Boilerplate CLAUDE.md

## 아키텍처 규칙
- 상태관리: Riverpod + @riverpod 어노테이션 (riverpod_generator)
- DB: Drift 테이블 → features/{feature}/data/tables/ 에 정의
- 모델: freezed + @JsonSerializable 필수
- 라우팅: go_router, features/{feature}/presentation/routes.dart
- 구독 체크: core/subscription/entitlement.dart의 isPremium 사용
- 광고: core/ads/ad_widgets.dart의 AdBanner 위젯 사용

## 파일 구조 규칙
- feature 추가 시: lib/features/{name}/{data,domain,presentation}/ 구조
- data/: tables (Drift), repositories, data_sources
- domain/: models (freezed), use_cases
- presentation/: screens, widgets, providers, routes

## 코드 생성 (순서 중요)
- 반드시 이 순서로 실행: 1) Drift 스키마 → 2) freezed 모델 → 3) riverpod_generator
- 명령어: dart run build_runner build --delete-conflicting-outputs
- Drift 마이그레이션: schemaVersion 증가 + migration 함수 추가
- Drift 테이블은 features/{feature}/data/tables/에만 배치
- freezed 모델은 features/{feature}/domain/models/에만 배치

## AI 코드 생성 필수 패턴 (Claude가 자주 틀리는 부분)
- Riverpod: `@riverpod` 함수의 첫 인자는 `Ref ref` (❌ ItemsRef ref 아님)
- freezed: union type 사용 시 Dart 3.0 sealed class와 혼용 금지, freezed만 사용
- Drift TypeConverter: `TypeConverter<DartType, SqlType>` 정확한 제네릭 순서
- 구독 상태 확인: 반드시 `ref.watch(showAdsProvider)` 사용 (직접 API 호출 금지)

## 수익화 규칙
- 프리미엄 기능은 반드시 EntitlementGate 위젯으로 감싸기
- 페이월은 RevenueCat Paywalls SDK 사용 (하드코딩 금지)
- 광고는 무료 유저에게만 표시: `ref.watch(showAdsProvider)` 체크
- CustomerInfo는 StreamProvider로 캐시 (go_router redirect에서 직접 API 호출 금지)

## 테스트 규칙
- Mock 라이브러리: mocktail (mockito 사용 금지)
- Drift 테스트: NativeDatabase.memory() 인메모리 DB 사용 (mock 금지)
- 외부 서비스 (RevenueCat, AdMob, Firebase): mocktail로 mock
- 테스트 파일 위치: test/ 하위에 lib/ 구조를 미러링
- assert 삭제/expect 값 완화로 테스트 통과시키는 것 금지
- 코드 수정 후 반드시: `flutter test` 전체 통과 확인
- 5회 후에도 실패하면 `// TODO: fix` 주석과 함께 남기고 사람에게 보고

### Riverpod Widget 테스트 필수 패턴
```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      journalRepositoryProvider.overrideWithValue(mockRepo),
      customerInfoProvider.overrideWith((_) => Stream.value(mockInfo)),
    ],
    child: const MaterialApp(home: JournalListScreen()),
  ),
);
```
- ProviderScope() 빈 overrides로 Widget 테스트 금지
- ProviderContainer를 Widget 테스트에서 사용 금지

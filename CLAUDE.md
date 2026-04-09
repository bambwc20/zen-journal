# Flutter Boilerplate CLAUDE.md

## 커스텀 스킬 (Custom Commands)

| 스킬 | 입력 | 기능 |
|------|------|------|
| `/app-plan` | MVP md 파일명 | MVP 기획서를 분석하여 앱 구현 계획서 생성. 기능별 우선순위, 일정, 기술 스택 매핑 |
| `/build-app` | MVP md 파일명 | MVP 기획서 기반 **앱 전체 자동 구현**. Phase 0(파싱) → 1(멀티에이전트 코딩) → 2(통합) → 2.5(테스트) → 3(검증) → 4(`/verify-app` 자동 호출) |
| `/verify-app` | 반복 간격 (예: `30m`) | 앱 화면을 mobile-mcp/playwright로 스크린샷 찍고 MVP 기획서와 비교하여 **24시간 연속 검증-수정 루프** 실행. P0~P4 이슈 분류, 자동 수정 |
| `/store-listing` | MVP md 파일명 | **대화형** 스토어 출시 준비. 사용자에게 레퍼런스/스크린샷 수집 → Apple/Google 메타데이터 + Gemini 아이콘 + **HTML+Playwright 스크린샷** 생성 + 심사 설문 답변 + 구독 설정 가이드 |
| `/launch-site` | MVP md 파일명 | Next.js 랜딩사이트 자동 생성 (`web/`). 랜딩/개인정보처리방침/이용약관(EULA)/지원 4페이지 + **Vercel CLI로 자동 배포** |
| `/marketing-build-public` | MVP md 파일명 | Build in Public 마케팅 전략 기획. Threads/Instagram 계정 컨셉, 콘텐츠 필러, 기능별 스크립트, 캘린더, 템플릿 |
| `/marketing-ads` | MVP md 파일명 | 광고 소재 자동 생성. ASA/Google UAC/Meta/TikTok 채널별 카피 + **HTML+Playwright로 19종 광고 이미지 자동 생성** + A/B 테스트 매트릭스 |

### 스킬 실행 흐름 (권장 순서)

```
0. docs/에 파일 배치:
   - MVP md 파일 (필수): docs/1_ZenPulse_Meditation_Timer.md
   - 앱설명모음 (권장): docs/앱_설명_모음.md
   - 앱소싱리포트 (권장): docs/앱소싱 리포트 - meditation.md
   - 앱소싱엑셀 (권장): docs/앱소싱_meditation_24_2026-03-24.xlsx
   또는 report 디렉토리 원본 경로를 $ARGUMENTS로 전달

1. /app-plan → 기획서 생성 (소싱 데이터 기반 질문 최소화)
2. /build-app → 앱 자동 구현 (완료 시 /verify-app 자동 시작)
3. /store-listing → 스토어 메타데이터 + 에셋 준비
4. /launch-site → 랜딩사이트 배포
5. /marketing-build-public → Build in Public 전략
6. /marketing-ads → 광고 소재 생성
```

### 공통 전제 조건

- `.env` 파일에 `GEMINI_API_KEY` 설정 (마케팅/스토어 스킬용)
- `docs/` 폴더에 MVP md 파일 사전 배치
- `references/` 폴더에 레퍼런스 이미지 배치 (icons/, screenshots/, feature_graphic/)

### 앱소싱 데이터 통합 (모든 스킬 공통)

모든 스킬은 MVP md 외에 **앱소싱 데이터 3종**을 자동 탐색하여 분석에 활용한다:

| 파일 | 패턴 | 주요 활용 |
|------|------|----------|
| 앱설명모음 | `앱_설명_모음.md` | 경쟁사 50개 앱 상세 (기능/포지셔닝/수익모델) |
| 앱소싱리포트 | `앱소싱 리포트 - *.md` | 시장 분석, CPC, 리뷰 불만, 스코어링 |
| 앱소싱엑셀 | `앱소싱_*.xlsx` | 경쟁사 정량 데이터, 키워드 Trends, 리뷰 시트 |

**탐색 순서**:
1. `docs/` 폴더에서 직접 탐색
2. `build_app_context.json`의 `sourcing_data.sourcing_dir`에서 탐색
3. MVP 파일 경로가 `report/앱소싱_*/mvp/` 패턴이면 상위 디렉토리 탐색

**docs/ 배치 방법** (2가지 중 택 1):

**방법 A**: report 디렉토리의 파일을 docs/에 복사/심볼릭링크
```bash
# 예시: meditation 앱소싱 데이터 배치
cp report/앱소싱_meditation_24_2026-03-24/앱_설명_모음.md docs/
cp report/앱소싱_meditation_24_2026-03-24/앱소싱\ 리포트\ -\ meditation.md docs/
cp report/앱소싱_meditation_24_2026-03-24/앱소싱_meditation_24_2026-03-24.xlsx docs/
cp report/앱소싱_meditation_24_2026-03-24/mvp/1_ZenPulse_Meditation_Timer.md docs/
```

**방법 B**: `build_app_context.json`에 원본 경로 지정 (복사 불필요)
```json
{
  "sourcing_data": {
    "sourcing_dir": "/Users/.../report/앱소싱_meditation_24_2026-03-24"
  }
}
```
→ 스킬이 `sourcing_dir` 내에서 3종 파일을 자동 탐색

**xlsx 파싱 방법**:
- xlsx는 바이너리이므로 Read 도구로 직접 읽을 수 없음
- **Python openpyxl로 파싱**: `script/python/app_sourcing/xlsx_report.py`의 기존 함수 활용
- **또는 Bash에서 빠른 추출**:
  ```bash
  cd /path/to/flutter-boilerplate
  python3 -c "
  import openpyxl
  wb = openpyxl.load_workbook('docs/앱소싱_xxx.xlsx', data_only=True)
  for sheet in wb.sheetnames:
      ws = wb[sheet]
      print(f'=== {sheet} ({ws.max_row} rows) ===')
      for row in ws.iter_rows(max_row=min(5, ws.max_row), values_only=True):
          print(row)
  "
  ```
- 스킬 실행 시 xlsx가 발견되면 위 방식으로 **경쟁사 시트, 키워드 시트, 리뷰 시트** 헤더와 주요 데이터를 추출하여 분석에 활용

**Graceful Degradation** (소싱 데이터 부분 존재 시):
- 3종 중 일부만 있어도 있는 것만 활용, 없는 건 스킵 (스킬 중단 금지)
- xlsx만 없음 → md 파일 기반 정성 분석 (정량 데이터 없이 진행)
- 리포트만 없음 → 앱설명모음 + xlsx로 경쟁사 데이터 직접 구성
- 앱설명모음만 없음 → 리포트의 경쟁사 요약 + xlsx 활용
- 3종 모두 없음 → MVP md만으로 기존 방식대로 동작 (이전 버전과 동일)
- 각 스킬의 `[소싱 데이터가 있으면]` 조건부 섹션은 해당 파일이 실제로 존재할 때만 생성

**build_app_context.json에 저장** → 다운스트림 스킬이 재탐색 없이 재사용:
```json
{
  "sourcing_data": {
    "app_descriptions_path": "docs/앱_설명_모음.md 또는 null",
    "sourcing_report_path": "docs/앱소싱 리포트 - keyword.md 또는 null",
    "sourcing_xlsx_path": "docs/앱소싱_keyword_date.xlsx 또는 null",
    "sourcing_dir": "/absolute/path/to/report/dir 또는 null"
  }
}
```
→ 값이 null이면 해당 데이터 소스 미사용

---

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

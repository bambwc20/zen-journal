# /build-app 스킬

## 입력
$ARGUMENTS = MVP md 파일명 (docs/ 내 배치 전제)

> **사전 준비**: 사용자가 MVP md 파일을 `docs/` 폴더에 미리 배치해둔다.
> 예: `docs/1_ZenJournal_AI_Daily_Journal.md`
> 실행: `/build-app 1_ZenJournal_AI_Daily_Journal.md`

## MVP 문서 표준 형식 (15섹션)

이 스킬은 `docs/` 폴더에 배치된 MVP md 파일을 읽는다. 파싱 시 각 섹션 번호와 헤더를 기준으로 추출한다.

| # | 섹션 | 에이전트 매핑 |
|---|------|-------------|
| 1 | 앱 메타정보 | 파서 → 전 에이전트 공유 |
| 2 | 경쟁사 기능 분석 | 정보수집 에이전트 참조 (Tier 3+) |
| 3 | 핵심 차별점 기능 | 서버 + 프론트 에이전트 참조 |
| 4 | 기본 필수 기능 (Must-Have) | 서버 + 프론트 에이전트 참조 |
| 5 | 무료 유저 접근 가능 기능 | 인앱구매 + 광고 에이전트 참조 |
| 6 | 유료 유저 접근 가능 기능 | 인앱구매 에이전트 참조 |
| 7 | 무료→유료 브릿지 포인트 | 인앱구매 에이전트 참조 |
| 8 | MVP 개발 계획 (MoSCoW + 로드맵) | 전 에이전트 우선순위 기준 |
| 9 | 운영 전략 (CRM, 리뷰, 이탈방지) | 마케팅 에이전트 참조 |
| 10 | 광고 전략 (AdMob + UA) | 광고 에이전트 참조 |
| 11 | 마케팅 단계 (Stage 1~4) | 마케팅 에이전트 참조 |
| 12 | 핵심 KPI & 마일스톤 | 정보수집 에이전트 → METRICS.md (Tier 3+) |
| 13 | 리스크 & 대응 | 정보수집 에이전트 → RISKS.md (Tier 3+) |
| 14 | 레퍼런스 매칭 | 정보수집 에이전트 참조 (Tier 3+) |
| 15 | 디자인 가이드 | 프론트 에이전트 핵심 참조 |

---

## 실행 순서

### Phase 0: MVP 파싱 & 공유 컨텍스트 생성

메인 에이전트가 직접 수행한다 (서브에이전트 아님).

1. `docs/$ARGUMENTS` 경로에서 MVP md 파일을 읽고 다음을 `docs/build_app_context.json`으로 추출 저장:
   ```json
   {
     "app_name": "앱 이름 (영문 snake_case)",
     "app_name_display": "표시용 앱 이름",
     "category": "카테고리",
     "target_country": "타겟 국가",
     "currency": "통화 기호",
     "revenue_model": "구독/IAP/하이브리드/광고",
     "tier": "Tier 1~4 (MVP 문서에서 추출)",
     "pricing": { "monthly": "", "yearly": "", "lifetime": "" },
     "tech_stack": ["Flutter", "RevenueCat", ...],
     "features_must": ["기능1", "기능2", ...],
     "features_should": ["기능1", ...],
     "features_could": ["기능1", ...],
     "differentiators": ["차별점1", "차별점2", ...],
     "free_features": ["무료기능1", ...],
     "paid_features": ["유료기능1", ...],
     "bridge_points": ["브릿지1", ...],
     "ad_placements": [{"type": "", "position": "", "condition": ""}],
     "push_sequences": [{"timing": "", "message": "", "purpose": ""}],
     "store_metadata": {
       "title": "", "subtitle": "", "short_desc": "", "long_desc": ""
     },
     "screens": ["화면1", "화면2", ...],
     "kpi_targets": { "m1": {}, "m3": {}, "m6": {}, "m12": {} },
     "risks": [{"risk": "", "probability": "", "response": ""}],
     "design": {
       "style": "minimal_clean | warm_friendly | premium_elegant | bold_playful",
       "seed_color": "#HEX",
       "secondary_color": "#HEX",
       "border_radius": 16,
       "typography": "rounded | geometric | serif",
       "dark_mode": "default | paid_only | none",
       "card_style": "flat | elevated | glassmorphism | outlined",
       "button_style": "filled | tonal | outlined",
       "navigation": "bottom_nav | tab_bar | drawer",
       "reference_apps": ["앱1", "앱2"]
     },
     "mvp_md_path": "docs/{MVP파일명}.md",
     "sourcing_data": {
       "app_descriptions_path": "docs/앱_설명_모음.md 또는 null",
       "sourcing_report_path": "docs/앱소싱 리포트 - {키워드}.md 또는 null",
       "sourcing_xlsx_path": "docs/앱소싱_{키워드}_{날짜}.xlsx 또는 null",
       "sourcing_dir": "원본 리포트 디렉토리 절대경로 또는 null"
     }
   }
   ```

2. **Tier 판별** → MVP 문서의 "Tier" 항목을 추출하여 경량/전체 모드 결정:
   - **Tier 1~2**: 경량 모드 (5개 에이전트, 인터페이스 계약 생략)
   - **Tier 3~4**: 전체 모드 (6~7개 에이전트, 인터페이스 계약 포함)

3. **Tier 3~4 전용**: `build_app_context.json`에 인터페이스 계약 섹션 추가:
   ```json
   {
     "interface_contract": {
       "repositories": [
         {"name": "클래스명", "methods": [{"name": "메서드명", "params": "파라미터", "returnType": "반환 타입"}]}
       ],
       "models": [
         {"name": "모델명", "fields": [{"name": "필드명", "type": "타입"}]}
       ],
       "providers": [
         {"name": "프로바이더명", "dependency": "의존 repository"}
       ]
     }
   }
   ```

4. **Tier 1~2 전용**: Agent 1 작업을 Phase 0에서 직접 수행:
   - context7 MCP로 tech_stack 패키지 최신 문서 확인
   - 특수 기술 요구사항 조사 → `/tmp/tech_notes.md` 생성

5. **앱소싱 데이터 자동 탐색** — `docs/` 폴더에서 MVP md 외 소싱 파일을 자동 탐색:

   **탐색 순서** (발견 즉시 `sourcing_data` 필드에 경로 기록):
   1. `docs/앱_설명_모음.md` — 경쟁사 50개 앱의 이름/개발사/평점/핵심 기능 요약
   2. `docs/앱소싱 리포트*.md` — 키워드 수요, 경쟁 환경, 부정 리뷰, 스코어링, MVP 제안
   3. `docs/앱소싱_*.xlsx` — 경쟁사 시트(수익/IAP/광고), 키워드 시트(Trends/계절성), 리뷰 시트(불만 카테고리)
   4. 위 파일이 `docs/`에 없으면 MVP 파일의 원본 디렉토리를 역추적:
      - MVP 경로가 `report/앱소싱_*/mvp/*.md` 패턴이면 → 상위 `report/앱소싱_*/` 에서 탐색
      - 사용자에게 "앱소싱 리포트 디렉토리 경로를 알려주세요" 질문 (선택)

   **xlsx 파싱** (바이너리이므로 Read로 읽을 수 없음):
   ```bash
   python3 -c "
   import openpyxl
   wb = openpyxl.load_workbook('docs/앱소싱_xxx.xlsx', data_only=True)
   for sheet in wb.sheetnames:
       ws = wb[sheet]
       print(f'=== {sheet} ({ws.max_row} rows) ===')
       for row in ws.iter_rows(max_row=3, values_only=True):
           print(row)
   "
   ```
   → 헤더와 샘플 데이터를 추출하여 각 에이전트에 전달할 데이터 확인

   **탐색된 데이터의 활용**:
   - `앱_설명_모음.md` → Agent 1(정보수집)에 경쟁사 50개 상세 데이터 전달
   - `앱소싱 리포트*.md` → 키워드 수요/CPC/리뷰 패턴을 Agent 5(마케팅)에 전달
   - `*.xlsx` → 경쟁사 수익/IAP/광고 데이터를 Agent 4(인앱구매), Agent 6(광고)에 전달
   - `build_app_context.json`의 `sourcing_data`에 경로 저장 → 다운스트림 스킬(`/store-listing`, `/marketing-*`, `/launch-site`)이 재사용

6. 보일러플레이트의 기존 구조 확인: `lib/core/`, `lib/features/`, `pubspec.yaml`

7. Tier에 따라 Phase 1 에이전트 팀을 실행한다.

---

### Phase 1: 에이전트 팀 — Wave 분리 실행

> **핵심 변경**: 완전 병렬이 아닌 **Wave 1 → Wave 2** 순차-병렬 하이브리드.
> Agent 2(서버)가 완료 후 `agent2_manifest.json`을 생성해야 Agent 3~6이 실제 구현을 참조할 수 있다.
> 모든 에이전트는 `mode: "bypassPermissions"`로 실행한다.

---

#### Wave 1: 기반 레이어 (병렬 실행)

Wave 1 에이전트들을 **단일 메시지에서 Agent 도구로 병렬 호출**한다.

##### Agent 1: 정보수집 에이전트 (Research Agent) — Tier 3+ 전용
**참조 섹션**: 1, 2, 8, 12, 13, 14
**역할**: 외부 정보 조사 + 프로젝트 문서 생성
**산출물**:
- `docs/METRICS.md` — KPI 대시보드 (섹션 12 기반)
- `docs/RISKS.md` — 리스크 대응 매뉴얼 (섹션 13 기반)
- `docs/COMPETITORS.md` — 경쟁사 벤치마크 요약 (섹션 2 기반)
- context7 MCP로 사용할 Flutter 패키지들의 최신 문서 확인
- 특수 패키지 설치 방법 + API 사용법 → `/tmp/tech_notes.md`

**프롬프트 템플릿**:
```
MVP 앱 빌드를 위한 정보수집 에이전트입니다.
컨텍스트: docs/build_app_context.json 읽기
MVP 원본: docs/{mvp_md_path} 읽기

앱소싱 데이터 (있으면 반드시 활용):
- docs/앱_설명_모음.md → 경쟁사 50개 앱 상세 (앱명, 개발사, 평점, 다운로드, 핵심 기능)
- docs/앱소싱 리포트*.md → 시장 분석, 키워드 수요, CPC, 리뷰 패턴, 스코어링
- docs/앱소싱_*.xlsx → 경쟁사 수익/IAP/광고 정량 데이터, 키워드 Trends
(sourcing_data 경로가 context JSON에 있으면 해당 경로에서도 탐색)

작업:
1. context7 MCP로 tech_stack의 각 패키지 최신 문서 확인
2. 섹션 12 KPI를 docs/METRICS.md로 정리
3. 섹션 13 리스크를 docs/RISKS.md로 정리
4. 섹션 2 경쟁사를 docs/COMPETITORS.md로 정리 — 앱설명모음/리포트가 있으면 50개 앱 전체 데이터 활용
5. 특수 기술 요구사항 조사 → /tmp/tech_notes.md

산출물을 flutter-boilerplate 루트에 생성하세요.
```

---

##### Agent 2: 데이터/서버 에이전트 (Backend Agent)
**참조 섹션**: 1, 3, 4, 8
**역할**: 데이터 레이어 + 서버사이드 로직 구현
**산출물**:
- `lib/features/{app_name}/data/tables/` — Drift 테이블 정의
- `lib/features/{app_name}/data/repositories/` — Repository 구현
- `lib/features/{app_name}/data/data_sources/` — 외부 API 클라이언트 (있으면)
- `lib/features/{app_name}/domain/models/` — freezed 모델
- `lib/features/{app_name}/domain/use_cases/` — 비즈니스 로직
- **`/tmp/agent2_manifest.json`** — 생성한 파일/클래스/메서드 매니페스트
- `/tmp/required_packages_agent2.txt` — 필요한 추가 패키지

**구현 규칙**:
- **시작 전 `/tmp/tech_notes.md`를 읽고, 특수 DB 요구사항(SQLCipher 등)이 있으면 보일러플레이트 core/database/와의 호환 방법을 먼저 설계하라**
- Drift 테이블은 MVP 섹션 4 "기본 필수 기능"의 데이터 스펙을 기반으로 설계
- 섹션 3 "차별점 기능"의 Implementation을 충실히 반영
- MoSCoW의 Must Have만 구현 (Should/Could는 TODO 주석)
- `.g.dart`, `.freezed.dart` 파일은 생성하지 않음 (Phase 2에서 build_runner로 생성)
- **작업 완료 후 반드시 `/tmp/agent2_manifest.json` 생성**:
  ```json
  {
    "files": ["생성한 파일 절대 경로 목록"],
    "classes": [
      {
        "name": "클래스명",
        "file": "파일 경로",
        "methods": [
          {"name": "메서드명", "params": "파라미터 시그니처", "returnType": "반환 타입"}
        ]
      }
    ],
    "models": [
      {
        "name": "모델명",
        "file": "파일 경로",
        "fields": [
          {"name": "필드명", "type": "타입"}
        ]
      }
    ]
  }
  ```
- 사용하는 추가 패키지를 `/tmp/required_packages_agent2.txt`에 기록 (한 줄에 하나: `패키지명: ^버전`)

**프롬프트 템플릿**:
```
MVP 앱의 데이터/서버 레이어를 구현하는 에이전트입니다.
컨텍스트: docs/build_app_context.json 읽기
MVP 원본: docs/{mvp_md_path} 읽기
보일러플레이트 CLAUDE.md: flutter-boilerplate/CLAUDE.md 읽기

시작 전 반드시 읽기:
- /tmp/tech_notes.md (특수 기술 요구사항 — SQLCipher, STT 등)

기존 보일러플레이트 구조를 먼저 파악하세요:
- lib/core/ 구조 확인 (subscription, ads, database 등)
- lib/core/database/ 의 Drift 설정 확인
- lib/features/ 기존 feature 구조 참고

작업:
1. Must Have 기능의 Drift 테이블 설계 (data/tables/)
2. freezed 모델 정의 (domain/models/) — part 지시어 포함
3. Repository 인터페이스 + 구현 (data/repositories/)
4. Use Case 작성 (domain/use_cases/)
5. 외부 API 클라이언트 (필요시)
6. Should/Could 기능은 // TODO: v1.1 / v1.2 주석만
7. /tmp/agent2_manifest.json 생성 (파일/클래스/메서드 목록)
8. /tmp/required_packages_agent2.txt 생성

.g.dart, .freezed.dart 파일은 생성하지 마세요. build_runner가 생성합니다.
```

---

#### Wave 2: 프레젠테이션 + 수익화 레이어 (Wave 1 완료 후 병렬 실행)

Wave 1의 모든 에이전트가 완료된 후, Wave 2 에이전트들을 **단일 메시지에서 Agent 도구로 병렬 호출**한다.

##### Agent 3: 프론트엔드 에이전트 (Frontend Agent)
**참조 섹션**: 1, 3, 4, 5, 6, 8, 15
**역할**: UI 화면 + 네비게이션 + Riverpod Provider 구현
**산출물**:
- `lib/features/{app_name}/presentation/screens/` — 각 화면 (**온보딩/페이월 제외**)
- `lib/features/{app_name}/presentation/widgets/` — 공유 위젯
- `lib/features/{app_name}/presentation/providers/` — Riverpod providers
- `lib/features/{app_name}/presentation/routes.dart` — go_router 라우트
- `/tmp/required_packages_agent3.txt` — 필요한 추가 패키지

**구현 규칙**:
- **시작 전 반드시 읽기**:
  - `/tmp/agent2_manifest.json` (Agent 2가 생성한 실제 클래스/메서드 참조)
  - `/tmp/tech_notes.md` (특수 기술 요구사항)
  - `docs/build_app_context.json`
- **Provider에서 Repository를 참조할 때, `/tmp/agent2_manifest.json`의 실제 클래스명과 메서드 시그니처를 사용하세요. import 경로도 manifest의 파일 경로를 그대로 사용하세요.**
- MVP 섹션 8의 "화면 목록"을 기준으로 화면 생성
- 섹션 5/6의 무료↔유료 UI 차이 반영, 유료 기능은 `EntitlementGate` 위젯으로 감싸기
- @riverpod 어노테이션의 첫 인자는 `Ref ref`
- 구독 상태 확인: `ref.watch(showAdsProvider)` 사용
- **온보딩 화면은 생성하지 않음 (Agent 4 담당). 온보딩 완료 후 메인 화면으로의 라우팅 설정만 담당**
- `lib/shared/onboarding_flow.dart`가 존재하면 참고하되, 온보딩 화면 자체는 Agent 4가 생성
- **섹션 15 디자인 가이드의 토큰을 반드시 반영**:
  - `seed_color` → `ColorScheme.fromSeed(seedColor: Color(0x...))`
  - `border_radius` → 전역 `BorderRadius.circular(N)` 통일
  - `typography` → Google Fonts 또는 커스텀 TextTheme 적용
  - `card_style` → Card 위젯 elevation/shape/decoration 통일
  - `button_style` → ElevatedButton/FilledButton/OutlinedButton 테마 적용
  - `dark_mode` → ThemeMode 처리 (default=기본지원, paid_only=EntitlementGate)
  - `style` 기반 전체 분위기:
    - `minimal_clean`: 여백 넓게, 색상 최소, 얇은 구분선
    - `warm_friendly`: 라운드 코너 크게, 파스텔 톤, 부드러운 그림자
    - `premium_elegant`: 다크 배경, 골드/화이트 악센트, 높은 대비
    - `bold_playful`: 큰 타이포, 비비드 컬러, 두꺼운 보더

**프롬프트 템플릿**:
```
MVP 앱의 프론트엔드를 구현하는 에이전트입니다.
컨텍스트: docs/build_app_context.json 읽기 (design 섹션 핵심!)
MVP 원본: docs/{mvp_md_path} 읽기 (섹션 15 디자인 가이드 핵심!)
보일러플레이트 CLAUDE.md: flutter-boilerplate/CLAUDE.md 읽기

시작 전 반드시 읽기:
- /tmp/agent2_manifest.json (Agent 2가 생성한 실제 클래스/메서드)
- /tmp/tech_notes.md (특수 기술 요구사항)

기존 보일러플레이트 구조를 먼저 파악하세요:
- lib/core/theme/ (app_theme.dart, theme_provider.dart — 여기를 기반으로 앱 테마 커스터마이징)
- lib/core/subscription/ (EntitlementGate, isPremium)
- lib/core/ads/ (AdBanner, showAdsProvider)
- lib/shared/ (onboarding_flow, empty_state 등 기존 위젯)

작업:
1. **앱 테마 생성** — 섹션 15 디자인 토큰 기반:
   - lib/features/{app_name}/presentation/theme/app_theme.dart 생성
   - seed_color, border_radius, typography, card_style, button_style 반영
   - light + dark ThemeData 모두 정의
2. 섹션 8 화면 목록 기준으로 screens/ 생성 (온보딩/페이월 제외)
3. go_router 라우트 설정 (routes.dart)
4. Riverpod providers — agent2_manifest.json의 실제 클래스명/메서드 사용
5. 공유 위젯 (달력, 차트, 커스텀 버튼 등) — 디자인 토큰과 일관되게
6. 온보딩 완료 후 메인 화면으로의 라우팅 설정 (온보딩 화면 자체는 Agent 4가 담당)
7. 무료/유료 기능 분기 UI
8. /tmp/required_packages_agent3.txt 생성

디자인 원칙:
- 섹션 15의 style 값에 따라 전체 분위기를 일관되게 유지
- 레퍼런스 앱의 UI 패턴을 참고하되, 그대로 복사하지 않음
- Material 3 기반 + 커스텀 테마로 트렌디한 UI 구현
```

---

##### Agent 4: 인앱구매 에이전트 (IAP Agent)
**참조 섹션**: 1, 5, 6, 7
**역할**: RevenueCat 구독 + 페이월 + 온보딩 + 브릿지 포인트 구현
**산출물**:
- `lib/features/{app_name}/presentation/screens/paywall_screen.dart` — 페이월 화면
- `lib/features/{app_name}/presentation/screens/onboarding_screen.dart` — 온보딩 전체 플로우 (3스텝 + 페이월 전환)
- `lib/features/{app_name}/presentation/widgets/bridge_*.dart` — 브릿지 포인트 위젯
- `lib/features/{app_name}/presentation/widgets/entitlement_gates.dart` — 기능별 게이트
- `docs/REVENUECAT_SETUP.md` — RevenueCat 콘솔 설정 체크리스트
- `/tmp/required_packages_agent4.txt` — 필요한 추가 패키지

**구현 규칙**:
- RevenueCat Paywalls SDK 사용 (하드코딩 금지)
- 섹션 1의 가격 정보 반영 (offering ID는 플레이스홀더)
- 섹션 7의 각 브릿지 포인트를 개별 위젯으로 구현
- **온보딩 전체 플로우 담당 (3스텝 화면 + 마지막 스텝에서 Soft Paywall 연결)**
- **`lib/shared/onboarding_flow.dart`가 있으면 이를 상속/래핑하여 앱별 3스텝 커스터마이징 구현. shared/ 직접 수정 금지**
- **`core/subscription/paywall_screen.dart`가 존재하면 직접 수정하지 말고, `features/{app_name}/presentation/screens/paywall_screen.dart`에서 core의 기능을 활용하되 앱별 커스터마이징 구현. core가 base class를 제공하지 않으면 features/에 독립적으로 생성**
- CustomerInfo는 StreamProvider로 캐시
- `docs/REVENUECAT_SETUP.md` 포함 내용:
  - Offering 생성 방법
  - Product ID 등록 (App Store Connect / Google Play Console)
  - Entitlement 연결
  - 테스트 계정 설정 (Sandbox)

**프롬프트 템플릿**:
```
MVP 앱의 인앱구매/구독 시스템을 구현하는 에이전트입니다.
컨텍스트: docs/build_app_context.json 읽기
MVP 원본: docs/{mvp_md_path} 읽기
보일러플레이트 CLAUDE.md: flutter-boilerplate/CLAUDE.md 읽기

앱소싱 데이터 (있으면 반드시 활용):
- docs/앱소싱_*.xlsx 또는 sourcing_data 경로의 xlsx → 경쟁사 시트에서 IAP 가격 범위, 구독 비율 참조
- docs/앱소싱 리포트*.md → 구독 적합성 평가, 경쟁사 가격대 참조
→ 페이월 카피에 "Save X% vs competitors", 경쟁사 대비 가성비 강조 메시지 반영

기존 보일러플레이트 구조를 먼저 파악하세요:
- lib/core/subscription/ (RevenueCat 설정, EntitlementGate, paywall_screen.dart)
- lib/shared/onboarding_flow.dart (기존 온보딩 위젯)
- lib/core/config/ (앱 설정)

작업:
1. 온보딩 전체 플로우 (3스텝 + Soft Paywall) — shared/onboarding_flow.dart 활용
2. 페이월 화면 구성 (가격 표시, 플랜 비교, CTA) — 소싱 데이터의 경쟁사 가격 대비 포지셔닝 반영
3. 섹션 7의 브릿지 포인트별 위젯 구현
4. EntitlementGate 적용 가이드
5. 무료 체험 설정 (있으면)
6. docs/REVENUECAT_SETUP.md 생성 — 콘솔 설정 체크리스트
7. /tmp/required_packages_agent4.txt 생성

주의:
- 페이월은 RevenueCat Paywalls SDK 사용. 가격 하드코딩 금지.
- core/subscription/paywall_screen.dart가 존재하면 직접 수정하지 말 것.
- shared/onboarding_flow.dart가 존재하면 활용하되 직접 수정하지 말 것.
```

---

##### Agent 5: 광고 에이전트 (Ads Agent)
**참조 섹션**: 1, 5, 10
**역할**: AdMob 광고 배치 + 광고 정책 구현
**산출물**:
- `lib/features/{app_name}/presentation/widgets/ad_placements.dart` — 화면별 광고 배치 위젯
- `lib/features/{app_name}/presentation/providers/ad_providers.dart` — 광고 로직 providers
- `/tmp/manifest_additions_agent5.md` — AndroidManifest.xml / Info.plist 추가 항목 기록
- `docs/AD_UNIT_IDS.md` — 광고 유닛 ID 플레이스홀더 + 배치 가이드
- `/tmp/required_packages_agent5.txt` — 필요한 추가 패키지

**구현 규칙**:
- 섹션 10의 광고 배치 계획을 정확히 반영
- 무료 유저에게만 표시: `ref.watch(showAdsProvider)` 체크 필수
- 광고 유닛 ID는 테스트 ID 사용
- **AndroidManifest.xml / Info.plist를 직접 수정하지 마세요. 대신 `/tmp/manifest_additions_agent5.md`에 추가할 항목을 기록하세요:**
  - AdMob 앱 ID
  - 필요한 퍼미션
  - Info.plist 키-값

**프롬프트 템플릿**:
```
MVP 앱의 광고 시스템을 구현하는 에이전트입니다.
컨텍스트: docs/build_app_context.json 읽기
MVP 원본: docs/{mvp_md_path} 읽기
보일러플레이트 CLAUDE.md: flutter-boilerplate/CLAUDE.md 읽기

앱소싱 데이터 (있으면 반드시 활용):
- docs/앱소싱_*.xlsx → 경쟁사 시트에서 광고 유무(Y/N), eCPM 참고
- docs/앱소싱 리포트*.md → CPC/광고 시장 규모 데이터
→ 경쟁사의 광고 배치 패턴(배너/인터스티셜/리워드) 참고하여 eCPM 최적화

기존 보일러플레이트 구조를 먼저 파악하세요:
- lib/core/ads/ (AdBanner, showAdsProvider, ad_helper)

작업:
1. 섹션 10 광고 배치 계획을 위젯으로 구현
2. 화면별 광고 노출 조건 (횟수 제한, 타이밍)
3. 리워드 광고 보상 로직 (있으면)
4. 테스트 광고 유닛 ID 설정
5. docs/AD_UNIT_IDS.md 프로덕션 교체 가이드 — 소싱 데이터의 예상 eCPM 참고 수치 포함
6. AndroidManifest.xml / Info.plist를 직접 수정하지 마세요.
   대신 /tmp/manifest_additions_agent5.md에 기록하세요.
7. /tmp/required_packages_agent5.txt 생성

광고는 무료 유저에게만 노출. ref.watch(showAdsProvider) 필수.
```

---

##### Agent 6: 마케팅/CRM 에이전트 (Marketing Agent)
**참조 섹션**: 1, 9, 11
**역할**: 스토어 메타데이터 + CRM 푸시 + FCM 알림 구현
**산출물**:
- `docs/STORE_LISTING.md` — Google Play / App Store 등록 정보 (섹션 1 메타데이터)
- `docs/ASO_KEYWORDS.md` — ASO 키워드 전략 (섹션 14 키워드 테이블)
- `docs/MARKETING_PLAN.md` — 마케팅 단계별 실행 계획 (섹션 11)
- `docs/CRM_SEQUENCES.md` — CRM 푸시 시퀀스 + 리텐션 전략 (섹션 9)
- `docs/AB_TEST_PLAN.md` — A/B 테스트 변수 목록 + 적용 위치 (문서만, 코드 구현 없음)
- `lib/features/{app_name}/data/data_sources/notification_service.dart` — FCM 알림 로직
- `lib/features/{app_name}/domain/use_cases/schedule_notifications.dart` — 알림 스케줄링
- `/tmp/required_packages_agent6.txt` — 필요한 추가 패키지

**구현 규칙**:
- **`lib/core/push/`의 기존 FCM 코드를 반드시 확인하고, import하여 사용. 새로운 FCM 래퍼를 만들지 마세요. notification_service.dart는 core/push/를 import하여 앱 특화 알림 로직(CRM 시퀀스, 리텐션 푸시)만 작성**
- CRM 알림 범위 제한:
  - 온보딩 시퀀스(Day 0~30): **앱 실행 시 flutter_local_notifications로 예약**
  - 리텐션 푸시(N일 미접속): **앱 실행 시 다음 알림을 미리 예약하는 방식**
  - **서버사이드 FCM 발송은 MVP 범위 밖. 코드에 `// TODO: v1.1 서버사이드 FCM` 주석만 작성**
- 리뷰 요청: 긍정 경험 직후 InAppReview 호출 조건
- A/B 테스트: **코드 구현 없음, `docs/AB_TEST_PLAN.md` 문서화만** (MVP v1.0에서 Firebase Remote Config는 YAGNI)

**프롬프트 템플릿**:
```
MVP 앱의 마케팅/CRM 시스템을 구현하는 에이전트입니다.
컨텍스트: docs/build_app_context.json 읽기
MVP 원본: docs/{mvp_md_path} 읽기
보일러플레이트 CLAUDE.md: flutter-boilerplate/CLAUDE.md 읽기

앱소싱 데이터 (있으면 반드시 활용):
- docs/앱_설명_모음.md → 경쟁사 50개 앱의 스토어 타이틀/설명 패턴 → ASO 전략에 반영
- docs/앱소싱 리포트*.md → 키워드 검색량, 연관 키워드 → ASO_KEYWORDS.md에 실데이터 반영
- docs/앱소싱_*.xlsx → 키워드 시트(Trends/계절성) → MARKETING_PLAN.md 시기별 전략에 반영
- docs/앱소싱_*.xlsx → 리뷰 시트(불만 카테고리) → CRM_SEQUENCES.md 리텐션 메시지에 반영

기존 보일러플레이트 구조를 먼저 파악하세요:
- lib/core/push/ 의 기존 FCM 코드를 반드시 확인하고 import하여 사용
- 새로운 FCM 래퍼를 만들지 마세요

작업:
1. docs/STORE_LISTING.md — 스토어 등록 정보 (섹션 1 메타데이터 + 소싱 데이터의 키워드 보강)
2. docs/ASO_KEYWORDS.md — 키워드 우선순위 + 배치 전략 (소싱 리포트의 검색량/경쟁도 실데이터 반영)
3. docs/MARKETING_PLAN.md — Stage 1~4 체크리스트 (Trends 계절성 반영한 시기별 전략)
4. docs/CRM_SEQUENCES.md — 온보딩/리텐션/이탈방지 시퀀스 (리뷰 불만 패턴 기반 선제적 메시지)
5. docs/AB_TEST_PLAN.md — A/B 테스트 계획 문서 (코드 구현 없음)
6. notification_service.dart — core/push/ import하여 앱 특화 로직만
7. schedule_notifications.dart — 앱 실행 시 로컬 알림 예약 방식으로 구현
   - 서버사이드 FCM은 MVP 범위 밖 (TODO 주석)
8. 리뷰 요청 트리거 로직 (InAppReview)
9. /tmp/required_packages_agent6.txt 생성
```

---

### Phase 2: 통합 & 코드 생성

Phase 1의 모든 에이전트가 완료된 후 메인 에이전트가 수행한다.

#### 2-A. 설정 연결
1. `main.dart`에 Firebase/RevenueCat/AdMob 초기화 코드 추가
2. `app.dart`에 Agent 3의 라우트 + Agent 4의 온보딩/페이월 라우트 등록
3. `pubspec.yaml`: `/tmp/required_packages_agent*.txt` 전체 합산하여 추가
4. `AndroidManifest.xml`: `/tmp/manifest_additions_agent5.md` + FCM 권한 일괄 병합
5. `Info.plist`: 동일하게 일괄 병합

#### 2-B. 코드 통합
1. Agent 3(프론트)과 Agent 4(IAP)의 화면 연결:
   - Agent 3의 routes.dart에 Agent 4의 onboarding/paywall 라우트 추가
   - bridge 위젯의 페이월 네비게이션 연결
2. Agent 5(광고)의 위젯을 Agent 3의 화면에 배치
3. Agent 6(마케팅)의 알림 서비스를 Provider로 연결
4. import 경로 정합성 확인:
   - `/tmp/agent2_manifest.json` 기준으로 Agent 3~6의 import 검증
   - **agent2_manifest.json에 기록된 파일이 실제로 존재하는지 교차 검증. 누락 파일 발견 시 직접 생성 또는 Agent 2 재실행**
   - 불일치 시 manifest 기준으로 수정

#### 2-C. 코드 생성 & 빌드
1. `dart run build_runner build --delete-conflicting-outputs`
2. `dart analyze` — 경고 0 확인
3. `flutter build apk --debug` — 빌드 확인
4. 빌드 실패 시: 에러 분석 → 직접 수정 (최대 5회 루프)

---

### Phase 2.5: 테스트 에이전트 (Tier 3+ 선택적)

> **Tier 3~4 앱에서만** Agent 7을 실행한다. **Phase 2 완료 후 순차 실행** (병렬 아님).

#### Agent 7: 테스트 에이전트 (Test Agent)
**참조**: Phase 1 + Phase 2 전체 산출물
**역할**: 유닛 테스트 + 위젯 테스트 작성
**산출물**:
- `test/features/{app_name}/domain/use_cases/` — use case 테스트
- `test/features/{app_name}/data/repositories/` — repository 테스트 (Drift 인메모리)
- `test/features/{app_name}/presentation/screens/` — 핵심 위젯 테스트

**구현 규칙**:
- Mock 라이브러리: mocktail (mockito 사용 금지)
- Drift 테스트: NativeDatabase.memory() 인메모리 DB 사용 (mock 금지)
- 외부 서비스 (RevenueCat, AdMob, Firebase): mocktail로 mock
- assert 삭제/expect 값 완화로 테스트 통과시키는 것 금지

---

### Phase 3: 검증 & 빌드

#### 3-1. 테스트 실행 & 자동 수정 루프
1. `flutter test` 실행
2. 실패 시 유형 분류:
   - 유형 A (소스 버그): expect 불일치 → 소스 코드 수정
   - 유형 B (테스트 설정 오류): mock 누락, MissingPluginException → 테스트 설정 수정
   - 유형 C (설계 불일치): 인터페이스 변경 → 소스+테스트 동시 수정
3. assert 삭제/expect 완화로 통과시키는 것 금지
4. 동일 파일 동일 에러 2회 반복 시 루프 즉시 중단
5. 최대 5회 루프. 실패 시 BLOCKED.md 파일 생성 + 사람에게 보고
6. `dart analyze` 경고 0 확인

#### 3-2. `docs/POST_BUILD_CHECKLIST.md` 생성

에이전트가 빌드 완료 후 자동 생성하는 문서. 개발자가 수동으로 수행해야 하는 **모든** 외부 설정/키 교체/배포 작업을 파일 경로 + 플레이스홀더 → 실제 값 형태로 안내한다.

아래 템플릿을 기반으로, 빌드 시 실제 사용된 플레이스홀더/파일 경로를 반영하여 생성한다:

```markdown
# POST BUILD CHECKLIST

> 빌드 완료 후 사람이 직접 수행해야 하는 작업 목록.
> 각 항목의 "교체 위치"에 명시된 파일을 열어 플레이스홀더를 실제 값으로 교체하세요.

---

## 1. Firebase 설정 (필수 — 최우선)

- [ ] Firebase Console → 프로젝트 생성
- [ ] Android 앱 등록 → `google-services.json` 다운로드
  - 교체 위치: `android/app/google-services.json` (파일 배치)
- [ ] iOS 앱 등록 → `GoogleService-Info.plist` 다운로드
  - 교체 위치: `ios/Runner/GoogleService-Info.plist` (파일 배치)
- [ ] Authentication → 로그인 방법 활성화 (Google, Apple 등)
- [ ] Cloud Messaging → FCM 활성화
- [ ] Crashlytics → 활성화

---

## 2. RevenueCat 설정 (필수)

- [ ] RevenueCat Dashboard → 프로젝트 생성
- [ ] App Store / Google Play 앱 연결
- [ ] Entitlements 정의: `premium`
- [ ] Offerings 구성: monthly / yearly / lifetime 상품
- [ ] SDK API Key 발급 → 코드에 적용
  - 교체 위치: `lib/main.dart` 또는 `lib/core/config/`
  - 플레이스홀더: `YOUR_REVENUECAT_API_KEY` → 실제 Public SDK Key
- [ ] Webhook 설정 (Cloudflare Workers 사용 시)
  - URL: `https://your-worker.workers.dev/webhook/revenuecat`
  - 교체 위치: `workers/src/routes/webhook.ts` → `REVENUECAT_WEBHOOK_SECRET`
- [ ] Sandbox 테스트 계정 생성 (App Store / Google Play)
- [ ] docs/REVENUECAT_SETUP.md 참조하여 Offering ID가 코드와 일치하는지 확인

---

## 3. AdMob 설정 (필수)

- [ ] AdMob Console → 앱 등록 (iOS / Android)
- [ ] AdMob App ID 발급 → 네이티브 설정에 적용
  - Android 교체 위치: `android/app/src/main/AndroidManifest.xml`
    - 플레이스홀더: `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy` → 실제 App ID
    - 태그: `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="여기"/>`
  - iOS 교체 위치: `ios/Runner/Info.plist`
    - 키: `GADApplicationIdentifier` → 실제 App ID
- [ ] 광고 단위 생성 (배너 / 전면 / 보상형) → Ad Unit ID 교체
  - 교체 위치: `lib/core/ads/ad_widgets.dart`
    - Android 플레이스홀더: `ca-app-pub-3940256099942544/6300978111` (현재 테스트 ID)
    - iOS 플레이스홀더: `ca-app-pub-3940256099942544/2934735716` (현재 테스트 ID)
    - → 프로덕션 Ad Unit ID로 교체
  - 교체 위치: 앱별 `lib/features/{app_name}/presentation/widgets/ad_placements.dart` (Agent 5 생성)
- [ ] 테스트 기기 등록 (AdMob Console → 설정 → 테스트 기기)
- [ ] docs/AD_UNIT_IDS.md 참조

---

## 4. Cloudflare Workers 설정 (서버 사용 시)

- [ ] Cloudflare 계정 생성 + Account ID 확인
  - 교체 위치: `workers/wrangler.toml` → `account_id`
- [ ] D1 데이터베이스 생성 → schema.sql 실행
  - 교체 위치: `workers/wrangler.toml` → `database_id`
- [ ] R2 버킷 생성 (백업용)
  - 교체 위치: `workers/wrangler.toml` → `bucket_name`
- [ ] Workers 시크릿 등록:
  ```bash
  wrangler secret put FIREBASE_PRIVATE_KEY
  wrangler secret put REVENUECAT_WEBHOOK_SECRET
  wrangler secret put FCM_SERVICE_ACCOUNT_EMAIL
  ```
- [ ] Cron Triggers 설정 확인: `wrangler.toml` → `[triggers]`
- [ ] `wrangler deploy` 실행하여 배포 확인

---

## 5. Google OAuth 설정 (Google Drive 백업 사용 시)

- [ ] Google Cloud Console → 프로젝트 선택 (Firebase와 동일)
- [ ] 사용자 인증 정보 → OAuth 2.0 클라이언트 ID 생성
  - Android: SHA-1 지문 등록
  - iOS: 번들 ID 등록
- [ ] Google Drive API 활성화
- [ ] 교체 위치:
  - Android: `android/app/src/main/res/values/strings.xml` → `default_web_client_id`
  - iOS: `ios/Runner/Info.plist` → `GIDClientID`, URL Schemes

---

## 6. FCM 푸시 알림 설정

- [ ] Firebase Console → Cloud Messaging → 서비스 계정 키 생성 (JSON)
  - Workers 사용 시: `wrangler secret put FIREBASE_PRIVATE_KEY` (JSON 내용)
- [ ] Android: 추가 설정 불필요 (google-services.json에 포함)
- [ ] iOS: APNs 인증 키 업로드
  - Apple Developer → Keys → APNs 키 생성 (.p8)
  - Firebase Console → Cloud Messaging → iOS → APNs 인증 키 업로드

---

## 7. 앱 서명 (출시 전)

### Android
- [ ] Keystore 생성:
  ```bash
  keytool -genkey -v -keystore {app_name}.jks -keyalg RSA -keysize 2048 -validity 10000 -alias {app_name}
  ```
- [ ] 교체 위치: `android/key.properties` 생성
  ```properties
  storePassword=YOUR_STORE_PASSWORD
  keyPassword=YOUR_KEY_PASSWORD
  keyAlias={app_name}
  storeFile=../app/{app_name}.jks
  ```
- [ ] `android/app/build.gradle` → signingConfigs 활성화 확인

### iOS
- [ ] Apple Developer → Certificates → Distribution Certificate 생성 (.p12)
- [ ] Provisioning Profile 생성 (App Store Distribution)
- [ ] Xcode → Signing & Capabilities → Team / Bundle ID 설정

---

## 8. 스토어 등록 (출시 전)

### Google Play Console
- [ ] 앱 등록 (패키지명: `com.{developer}.{app_name}`)
- [ ] 스토어 등록 정보 입력 (docs/STORE_LISTING.md 참조)
- [ ] 콘텐츠 등급 설문 완료
- [ ] 개인정보 처리방침 URL 등록
- [ ] 앱 액세스 권한 설명 (로그인 필요 시 테스트 계정 제공)
- [ ] 스크린샷 5종 + 그래픽 이미지 업로드

### App Store Connect
- [ ] 앱 등록 (번들 ID: `com.{developer}.{app_name}`)
- [ ] 스토어 정보 입력 (docs/STORE_LISTING.md 참조)
- [ ] 앱 심사 정보 (로그인 필요 시 테스트 계정)
- [ ] 개인정보 처리방침 URL 등록
- [ ] 스크린샷 6.7" + 5.5" + iPad (필요 시) 업로드
- [ ] 앱 내 구입 상품 등록 (RevenueCat과 동일한 Product ID)

---

## 9. CI/CD 설정 (자동 배포 시)

### GitHub Actions (Android)
- [ ] Repository Secrets 등록:
  - `PLAY_STORE_SERVICE_ACCOUNT_KEY` — Play Console API 서비스 계정 JSON
  - `ANDROID_KEYSTORE_BASE64` — `base64 {app_name}.jks`
  - `ANDROID_KEY_ALIAS` — 키 별칭
  - `ANDROID_KEY_PASSWORD` — 키 비밀번호
  - `ANDROID_STORE_PASSWORD` — 스토어 비밀번호

### Codemagic (iOS)
- [ ] 앱 연결 (GitHub 리포)
- [ ] Code Signing:
  - `APPLE_TEAM_ID` — Apple Developer Team ID
  - Distribution Certificate (.p12) 업로드
  - Provisioning Profile 업로드
- [ ] 환경변수: `SHOREBIRD_TOKEN` (OTA 배포 시)

---

## 10. Shorebird OTA 설정

- [ ] `shorebird init` 실행 (이미 완료되었으면 스킵)
  - 교체 위치: `shorebird.yaml` → `app_id` 확인
- [ ] `shorebird login` 확인
- [ ] 첫 릴리즈: `shorebird release android` / `shorebird release ios`
- [ ] 패치 테스트: `shorebird patch android` / `shorebird patch ios`

---

## 11. 최종 검증

- [ ] 모든 플레이스홀더가 실제 값으로 교체되었는지 검색:
  ```bash
  grep -r "YOUR_\|PLACEHOLDER\|TODO.*교체\|ca-app-pub-3940" lib/ android/ ios/ workers/
  ```
- [ ] `flutter build apk --release` 성공
- [ ] `flutter build ipa` 성공 (macOS)
- [ ] 실기기에서 테스트:
  - 구독 구매 흐름 (Sandbox)
  - 광고 노출 (테스트 → 프로덕션 전환 확인)
  - 푸시 알림 수신
  - Google Drive 백업/복원 (사용 시)
```

**생성 시 동적 치환 규칙**:
- `{app_name}` → `docs/build_app_context.json`의 `app_name`
- `{developer}` → `docs/build_app_context.json`의 개발자/조직명 (없으면 플레이스홀더 유지)
- Cloudflare 섹션: 서버 사용 안 하는 앱이면 "해당 없음"으로 표시
- Google OAuth 섹션: 백업 기능 없는 앱이면 "해당 없음"으로 표시
- 각 섹션에서 빌드 시 실제 생성된 파일 경로를 정확히 반영
- Agent 5가 `/tmp/manifest_additions_agent5.md`에 기록한 항목을 섹션 3에 병합

#### 3-3. UI 플로우 테스트 (Level 2: Playwright MCP)
1. `flutter run -d chrome --web-port=8080` 실행
2. playwright `browser_navigate` → http://localhost:8080
3. 온보딩 → 페이월 전환 플로우 검증
4. 메인 화면 CRUD 동작 확인
5. 다크모드 전환 + 빈 상태 화면 확인

#### 3-4. 네이티브 기능 테스트 (Level 3: mobile-mcp)
1. `flutter run -d emulator` 실행
2. mobile-mcp로 앱 화면 스크린샷 + 인터랙션
3. 검증: 푸시 권한, AdMob 배너, RevenueCat 샌드박스, 홈 위젯

#### 3-5. 릴리즈 빌드 검증 (Level 4)
1. `flutter build apk --release`
2. `xcode-build` MCP로 iOS Archive 빌드

---

### Phase 4: 연속 검증-고도화 자동 시작

> Phase 3 완료 후, **안내 없이 바로 `/verify-app 30m`을 Skill 도구로 호출**하여 연속 검증-고도화 루프를 자동 시작한다.

**실행 방법**: Phase 3 완료 직후 아래를 수행:
1. 사용자에게 1줄 상태 출력: `Phase 3 완료. 연속 검증-고도화 루프(30분 간격) 자동 시작합니다.`
2. Skill 도구로 `/verify-app 30m` 호출

상세 동작은 `.claude/commands/verify-app.md` 참조.

---

## 충돌 방지 규칙

| 파일/영역 | 담당 에이전트 | 다른 에이전트 금지 |
|----------|-------------|-----------------|
| `data/tables/`, `domain/models/`, `domain/use_cases/` | Agent 2 (서버) | Agent 3,4,5,6 생성 금지 |
| `presentation/screens/` (일반 화면) | Agent 3 (프론트) | Agent 4,5,6 생성 금지 |
| `paywall_screen.dart`, `onboarding_screen.dart` | Agent 4 (IAP) | Agent 3 생성 금지 |
| `presentation/widgets/ad_*.dart` | Agent 5 (광고) | Agent 3,4 생성 금지 |
| `presentation/widgets/bridge_*.dart` | Agent 4 (IAP) | Agent 3,5 생성 금지 |
| `notification_service.dart`, `schedule_notifications.dart` | Agent 6 (마케팅) | Agent 2,3 생성 금지 |
| `docs/*.md` | 담당 에이전트별 | 타 에이전트 담당 문서 수정 금지 |
| `main.dart`, `app.dart`, `pubspec.yaml` | Phase 2 메인 | Agent 1~7 수정 금지 |
| `AndroidManifest.xml`, `Info.plist` | **Phase 2 메인** | **Agent 1~7 직접 수정 금지** |
| `test/**` | Agent 7 (테스트) / Phase 3 | Agent 1~6 생성 금지 |
| `/tmp/agent2_manifest.json` | Agent 2 | Agent 3~6 읽기 전용 |
| `/tmp/required_packages_agent{N}.txt` | 각 에이전트 | 타 에이전트 수정 금지 |
| `/tmp/manifest_additions_agent5.md` | Agent 5 | Phase 2만 읽기 |

## Tier 분기 요약

| 항목 | Tier 1~2 (경량 모드) | Tier 3~4 (전체 모드) |
|------|---------------------|---------------------|
| Agent 1 (정보수집) | Phase 0에 흡수 | 독립 에이전트 |
| Wave 1 | Agent 2 + Agent 6 | Agent 1 + Agent 2 |
| Wave 2 | Agent 3 + Agent 4 + Agent 5 | Agent 3 + Agent 4 + Agent 5 + Agent 6 |
| 인터페이스 계약 | 생략 | JSON으로 build_app_context.json에 포함 |
| Phase 2 | 단일 통합 | 2-A / 2-B / 2-C 서브스텝 |
| Agent 7 (테스트) | 없음 (Phase 3에서 메인 에이전트) | Phase 2 완료 후 순차 실행 |
| 에이전트 수 | 5개 | 6~7개 |
| 예상 비용 | ~$8.50/빌드 | ~$12.45/빌드 |

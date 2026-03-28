# /verify-app 스킬

## 입력
$ARGUMENTS = 반복 간격 (기본값: 30m)

예시:
- `/verify-app` → 30분 간격으로 반복
- `/verify-app 15m` → 15분 간격으로 반복
- `/verify-app 1h` → 1시간 간격으로 반복

## 개요

`/build-app` 완료 후 실행하는 **연속 검증-고도화 루프**.
mobile-mcp(에뮬레이터) 또는 playwright(웹)로 실제 앱 화면을 캡처하고,
MVP 기획서와 화면 단위로 대조하여 누락/불일치를 찾아 수정하는 사이클을 반복한다.

**최대 24시간** 동안 지정 간격으로 사이클을 반복하며, 사용자가 중단하거나 고도화 10항목 완료 시 종료한다.

---

## 전제 조건

- `/build-app`이 Phase 3까지 완료된 상태
- `docs/build_app_context.json` 존재 (Phase 0에서 생성)
- `docs/` 폴더에 MVP 원본 md 파일 배치됨 (build_app_context.json의 mvp_md_path 참조)
- `flutter test` 전체 통과 상태
- 앱이 빌드 가능한 상태 (`flutter build apk --debug` 성공)

---

## 루프 실행 구조

```
┌──────────────────────────────────────────────────────────────┐
│                /verify-app {interval} 실행                     │
│                                                                │
│  1. 초기화 (최초 1회)                                          │
│     - build_app_context.json + MVP md 읽기                    │
│     - screen_checklist.json 생성 (또는 기존 것 이어받기)       │
│     - 앱 프로세스 시작 (에뮬레이터 → 웹 폴백)                 │
│                                                                │
│  2. 사이클 반복 (매 {interval}마다)                            │
│     ┌──────────────────────────────────────────┐              │
│     │  Step A: 화면별 스크린샷 + 기획서 대조    │              │
│     │       ↓                                    │              │
│     │  Step B: 이슈 분류 + 수정 계획             │              │
│     │       ↓                                    │              │
│     │  Step C: 코드 수정                         │              │
│     │       ↓                                    │              │
│     │  Step D: 빌드 + 테스트 재검증              │              │
│     │       ↓                                    │              │
│     │  Step E: 수정 결과 재캡처 + 완료 판정      │              │
│     │       ↓                                    │              │
│     │  [P0~P3 = 0 → 고도화 모드(Step F)]        │              │
│     │  [미완료 → 다음 사이클]                    │              │
│     └──────────────────────────────────────────┘              │
│                                                                │
│  3. 종료 조건                                                  │
│     - 사용자 중단                                              │
│     - 24시간 경과                                              │
│     - 고도화 10항목 완료                                       │
│     → BUILD_REPORT.md 생성                                    │
└──────────────────────────────────────────────────────────────┘
```

---

## Step 0: 초기화

1. `$ARGUMENTS`에서 인터벌 파싱 (기본 `30m`):
   - `15m` → 15분, `30m` → 30분, `1h` → 60분
   - 최소 10분, 최대 2시간

2. `docs/build_app_context.json` 읽기 → `mvp_md_path`로 MVP 원본 md 읽기

3. `docs/screen_checklist.json` 확인:
   - **존재하면**: 이전 사이클 이어받기 (cycle_count, issues 상태 유지)
   - **없으면**: 새로 생성:
   ```json
   {
     "mvp_md_path": "MVP md 파일 경로",
     "platform": "emulator|web",
     "interval_minutes": 30,
     "max_hours": 24,
     "started_at": "ISO timestamp",
     "screens": [
       {
         "name": "화면명",
         "section": "MVP 섹션 번호",
         "features": ["기능1", "기능2"],
         "free_or_paid": "free|paid|both",
         "status": "pending|verified|blocked",
         "issues": [],
         "cycle_verified": 0
       }
     ],
     "cycle_count": 0,
     "last_cycle_at": "ISO timestamp",
     "mode": "verify|polish",
     "polish_completed": []
   }
   ```

4. 앱 프로세스 시작:
   - `flutter run -d emulator` 시도
   - 실패 시 `flutter run -d chrome --web-port=8080` 폴백
   - 플랫폼을 `screen_checklist.json`에 기록

---

## Step A: 화면별 스크린샷 + 기획서 대조

각 화면을 순회하며 **실제 앱 화면**과 **MVP 기획서 요구사항**을 비교한다.

### 에뮬레이터 모드 (mobile-mcp)
1. mobile-mcp로 현재 화면 스크린샷 촬영
2. mobile-mcp로 화면 인터랙션 (탭, 스와이프, 입력)
3. 다음 화면으로 네비게이션 → 반복

### 웹 폴백 모드 (Playwright MCP)
1. playwright `browser_snapshot` 또는 `browser_take_screenshot`으로 화면 캡처
2. playwright `browser_click`, `browser_fill_form`으로 인터랙션
3. 다음 화면으로 네비게이션 → 반복

### 화면별 검증 항목 (12항목)

| # | 검증 항목 | 기준 | MCP 도구 |
|---|----------|------|---------|
| 1 | 화면 존재 여부 | MVP 섹션 8 화면 목록 | 네비게이션 도달 가능 |
| 2 | UI 요소 완성도 | 섹션 3,4 기능 스펙 | 스크린샷 시각 확인 |
| 3 | CRUD 동작 | 섹션 4 Must-Have | 생성→조회→수정→삭제 인터랙션 |
| 4 | 무료/유료 분기 | 섹션 5,6 | 구독 상태별 UI 차이 확인 |
| 5 | 브릿지 포인트 | 섹션 7 | 무료→유료 전환 유도 UI 존재 |
| 6 | 광고 배치 | 섹션 10 | 광고 위젯 위치/조건 |
| 7 | 온보딩 플로우 | 섹션 7 | 3스텝 + 페이월 전환 |
| 8 | 디자인 일관성 | 섹션 15 | 컬러, 타이포, 카드 스타일 |
| 9 | 다크모드 | 섹션 15 dark_mode | 라이트↔다크 전환 |
| 10 | 빈 상태 | UX 기본 | 데이터 없을 때 empty state |
| 11 | 에러 상태 | UX 기본 | 네트워크 오프라인 등 |
| 12 | 네비게이션 | 섹션 15 navigation | 하단 탭/드로어/탭바 |

---

## Step B: 이슈 분류 + 수정 계획

| 이슈 등급 | 설명 | 예시 |
|----------|------|------|
| **P0 — 기능 누락** | 기획서에 있으나 구현 안 됨 | 화면 자체가 없음, CRUD 중 일부 미구현 |
| **P1 — 기능 오작동** | 구현되었으나 동작 안 함 | 버튼 탭 시 에러, 데이터 저장 안 됨 |
| **P2 — UI 불일치** | 디자인 가이드와 불일치 | 색상 틀림, 레이아웃 깨짐, 다크모드 미적용 |
| **P3 — UX 미흡** | 기능은 되지만 사용성 부족 | 빈 상태 없음, 로딩 표시 없음, 에러 처리 없음 |
| **P4 — 고도화** | 기획서 이상으로 품질 개선 | 애니메이션, 마이크로인터랙션, 성능 최적화 |

이슈를 `docs/screen_checklist.json`의 각 화면 `issues` 배열에 기록:
```json
{
  "issue": "설명",
  "priority": "P0|P1|P2|P3|P4",
  "file": "수정할 파일 경로",
  "action": "수정 방법 요약",
  "resolved": false,
  "cycle_found": 1,
  "cycle_resolved": null
}
```

**수정 순서**: P0 → P1 → P2 → P3 → P4

---

## Step C: 코드 수정

1. P0~P1 이슈: 즉시 수정 (기능 누락/오작동은 최우선)
2. P2~P3 이슈: P0~P1 해결 후 수정
3. P4 이슈: P0~P3 모두 해결된 후 고도화 모드에서 수정
4. 수정 시 CLAUDE.md 코딩 규칙 준수 (Riverpod 패턴, freezed, Drift 등)
5. 한 사이클에서 수정하는 파일이 10개 이상이면 중간에 `dart analyze` 실행

---

## Step D: 빌드 + 테스트 재검증

1. `dart run build_runner build --delete-conflicting-outputs` (모델/프로바이더 변경 시)
2. `dart analyze` — 경고 0 확인
3. `flutter test` — 전체 테스트 통과 확인
4. 테스트 실패 시 자동 수정 루프:
   - 유형 A (소스 버그): expect 불일치 → 소스 코드 수정
   - 유형 B (테스트 설정 오류): mock 누락 → 테스트 설정 수정
   - 유형 C (설계 불일치): 인터페이스 변경 → 소스+테스트 동시 수정
   - 동일 파일 동일 에러 2회 반복 시 중단
   - 최대 5회 루프
5. 핫 리로드/리스타트: `flutter run` 프로세스가 살아있으면 `r` 또는 `R`
6. 핫 리로드 실패 시 앱 프로세스 종료 → 재실행

---

## Step E: 수정 결과 재캡처 + 완료 판정

1. Step A와 동일 방식으로 수정한 화면만 재캡처
2. 이슈가 해결되었으면 `resolved: true` + `cycle_resolved: N`으로 마킹
3. **완료 판정 기준**:
   - P0 이슈: 0건
   - P1 이슈: 0건
   - P2 이슈: 0건
   - P3 이슈: 0건
   - 모든 화면 `status: "verified"`
4. 완료 판정 시 → `mode: "polish"` 전환 → **고도화 모드(Step F)**
5. 미완료 시 → `cycle_count += 1` 후 다음 사이클

---

## Step F: 고도화 모드 (Polish Mode)

> P0~P3 이슈가 모두 0이 된 후 진입. MVP 기획서 "이상"의 품질을 추구한다.

**고도화 체크리스트** (사이클마다 하나씩 적용):

| # | 항목 | 검증 방법 |
|---|------|----------|
| 1 | 화면 전환 애니메이션 | go_router 트랜지션 + Hero 위젯 |
| 2 | 로딩 상태 | Shimmer/Skeleton 로딩 위젯 |
| 3 | 마이크로인터랙션 | 버튼 탭 피드백, 리스트 아이템 스와이프 |
| 4 | 접근성 | Semantics 위젯, 폰트 스케일링 테스트 |
| 5 | 성능 | 불필요한 리빌드 제거, const 위젯 활용 |
| 6 | 에러 바운더리 | 전역 에러 핸들링 + 사용자 친화적 에러 화면 |
| 7 | 오프라인 대응 | 네트워크 상태 감지 + 오프라인 배너 |
| 8 | 키보드 대응 | 입력 필드 포커스 시 스크롤, 키보드 dismiss |
| 9 | 태블릿/폴더블 | 반응형 레이아웃 (LayoutBuilder) |
| 10 | 국제화 준비 | l10n 키 추출 + ARB 파일 구조 |

고도화 모드에서도 동일한 사이클 구조(Step A~E)를 따른다.
적용한 항목은 `polish_completed` 배열에 기록.

---

## 사이클 제어 규칙

| 규칙 | 내용 |
|------|------|
| **인터벌 반복** | 1 사이클 완료 후, 지정 간격({interval})만큼 대기 → 다음 사이클 자동 시작 |
| **24시간 타임아웃** | `started_at`으로부터 24시간 경과 시 자동 종료 → BUILD_REPORT.md 생성 |
| **사이클 간 리포트** | 각 사이클 완료 시 1줄 요약 출력: `Cycle N 완료: P0(0) P1(0) P2(2) P3(1) — 다음 사이클 {interval} 후` |
| **상태 파일 저장** | 매 사이클 완료 시 `docs/screen_checklist.json` 갱신 → 세션 끊겨도 이어받기 가능 |
| **플랫폼 전환** | 에뮬레이터 불안정 시 웹으로 자동 전환, 그 반대도 |
| **앱 프로세스 관리** | 사이클 시작 시 앱 프로세스 생존 확인 → 죽었으면 재시작 |
| **빌드 실패 루프** | 동일 빌드 에러 3회 반복 시 해당 수정 롤백 + 다음 이슈로 |
| **BLOCKED 판정** | 동일 P0/P1 이슈가 3사이클 연속 미해결 시 `BLOCKED.md`에 기록 + 사용자 알림 후 해당 이슈 스킵 |
| **고도화 완료** | 고도화 체크리스트 10개 항목 모두 적용 완료 시 루프 종료 + 최종 리포트 |
| **컨텍스트 보호** | 각 사이클은 독립적으로 동작. screen_checklist.json이 세션 간 상태를 전달 |

---

## 종료 시: `docs/BUILD_REPORT.md` 생성

모든 사이클 종료 시 (사용자 중단, 24시간 경과, 또는 고도화 완료) 자동 생성:

```markdown
# 빌드 리포트

## 요약
- 총 사이클: N회
- 총 소요 시간: N시간 N분
- 발견 이슈: P0(N) P1(N) P2(N) P3(N) P4(N)
- 해결 이슈: N건 / 미해결: N건
- 고도화 적용: N/10 항목

## 사이클별 기록
| Cycle | 발견 | 해결 | 주요 수정 |
|-------|------|------|----------|

## 미해결 이슈 (BLOCKED)
| 이슈 | 사유 | 권장 조치 |

## 화면별 최종 상태
| 화면 | 상태 | 검증 사이클 |
```

---

## 사용 예시

```bash
# /build-app 완료 후

# 기본 30분 간격으로 검증 루프 시작
/verify-app

# 15분 간격으로 빠르게
/verify-app 15m

# 1시간 간격으로 느긋하게
/verify-app 1h
```

## /build-app과의 관계

```
/build-app (1회 실행)
  Phase 0: MVP 파싱
  Phase 1: 에이전트 팀 코드 생성
  Phase 2: 통합
  Phase 3: 검증 + 빌드
  → 완료 후 안내: "/verify-app 으로 연속 검증을 시작하세요"

/verify-app {interval} (반복 실행)
  매 사이클: 스크린샷 → 기획서 대조 → 수정 → 테스트 → 판정
  P0~P3 해결 후 → 고도화 모드
  24시간 또는 고도화 완료 → BUILD_REPORT.md
```

# build-app.md 에이전트 팀 구조 재설계

> **War Room 산출물** | 참여: backend-architect(Lead), qa-strategist(Challenger), business-analyst
> **작성일**: 2026-03-18

---

## Executive Summary

build-app.md의 6개 에이전트 완전 병렬 구조를 **Wave 분리 + Tier 기반 분기**로 재설계. Agent 2↔3 의존성 충돌(Critical), Phase 2 과부하(Critical), AndroidManifest.xml 이중 수정(Critical) 3개 핵심 문제를 해결. Tier 1~2는 5개 에이전트 경량 모드, Tier 3~4는 6~7개 전체 모드로 앱 복잡도에 따라 구조가 자동 분기된다.

## 배경 & 현황

- MVP 기획서: 14섹션 표준 형식 (달토리, ZenJournal 등)
- 보일러플레이트: core/(subscription, ads, database, push, analytics, theme, settings, l10n) + shared/ + 빈 features/
- 원안: 6개 에이전트 완전 병렬 → Phase 2 통합 → Phase 3 테스트

## 검토된 접근법 (Lead 초안)

### 접근법 A: 현행 유지 + 인터페이스 계약 추가
- 장점: 변경 최소, 병렬 유지
- 단점: Agent 2↔3 불일치 잔존, Phase 2 부담 그대로

### 접근법 B: 2-Phase 파이프라인 (순차 → 병렬)
- 장점: Agent 2↔3 완전 해결
- 단점: 전체 실행 시간 증가

### 접근법 C: 7개 에이전트 + 인터페이스 계약 + 테스트 에이전트
- 장점: 범용적, 핵심 약점 동시 해결
- 단점: Phase 0 복잡도 증가

### 선택: C안 변형 (C + B의 Wave 분리 + Tier 분기)
이유: Challenger가 C안의 "인터페이스 계약만으로는 불충분, Wave 분리 필수" 지적 → C+B 하이브리드. business-analyst가 "Tier별 분기 필요" 권고 → Tier 조건부 적용.

## 실행 계획 (합의안)

### Phase 0: MVP 파싱 + Tier 판별
- `build_app_context.json` 추출 + Tier 기반 모드 선택
- Tier 3+: JSON 인터페이스 계약 추가
- Tier 1~2: Agent 1 작업을 Phase 0에 흡수

### Phase 1 Wave 1 (병렬): Agent 1(Tier3+) + Agent 2
- Agent 2 완료 시 `/tmp/agent2_manifest.json` 생성
- Agent 2 시작 전 `/tmp/tech_notes.md` 읽기 필수

### Phase 1 Wave 2 (병렬): Agent 3 + Agent 4 + Agent 5 + Agent 6
- Agent 3: manifest 기반 import (추측 금지)
- Agent 4: 온보딩 전체 담당 + REVENUECAT_SETUP.md
- Agent 5: AndroidManifest 직접 수정 금지 → 기록만
- Agent 6: core/push/ 래핑, CRM 범위 "로컬 예약"으로 제한

### Phase 2: 통합 (2-A → 2-B → 2-C)
- 2-A: 설정 연결 (main.dart, pubspec.yaml, AndroidManifest 일괄 병합)
- 2-B: 코드 통합 (화면 연결, 광고 배치, manifest 교차 검증)
- 2-C: 코드 생성 (build_runner, dart analyze)

### Phase 2.5: Agent 7 테스트 (Tier 3+ 선택)
- Phase 2 완료 후 순차 실행

### Phase 3: 검증 + POST_BUILD_CHECKLIST.md

## 리스크 & 대응

| # | 리스크 | 심각도 | 지적자 | 대응 |
|---|--------|--------|--------|------|
| 1 | Agent 2↔3 병렬 의존성 | Critical | Challenger | Wave 분리 + agent2_manifest.json |
| 2 | Phase 2 단일 에이전트 과부하 | Critical | Challenger | 2-A/2-B/2-C 서브스텝 분리 |
| 3 | AndroidManifest.xml 이중 수정 | Critical | Challenger+BA | Agent 5 직접 수정 금지, Phase 2 일괄 |
| 4 | Agent 3↔4 온보딩 중복 | Important | Lead | Agent 3 프롬프트에서 온보딩 제거, Agent 4 전담 |
| 5 | core/paywall 중복 | Important | Challenger | Agent 4 프롬프트에 처리 방침 명시 |
| 6 | CRM 서버사이드 불가 | Important | BA | "로컬 예약" 방식으로 범위 제한 |
| 7 | RevenueCat 콘솔 설정 누락 | Important | BA | REVENUECAT_SETUP.md 추가 |
| 8 | manifest 품질 | Minor | Challenger | Phase 2-B에서 교차 검증 |

## 전문가별 평가 요약

| 전문가 | 핵심 의견 | 반영 여부 |
|--------|----------|----------|
| backend-architect (Lead) | C안 추천: 7에이전트+계약+테스트 | 채택 (Wave 분리 + Tier 분기로 변형) |
| qa-strategist (Challenger) | Critical 3건, Wave 분리 필수, Phase 2 분리 필수 | 전부 반영 |
| business-analyst | ROI 검증 (~$12.45/빌드), YAGNI 적용, 비코드 작업 문서화 | 전부 반영 |

## 토론 기록

### 주요 논쟁점

| 쟁점 | Lead | Challenger | BA | 합의 |
|------|------|-----------|-----|------|
| Agent 2↔3 해결법 | 인터페이스 계약 | Wave 분리 필수 | Wave 분리 동의 | Wave 분리 + JSON 계약 보조 |
| Agent 7 추가 | 무조건 추가 | Phase 2 후 순차 | Tier 3+ 선택적 | Tier 3+ 선택, Phase 2 후 순차 |
| 계약 형식 | Dart abstract class | - | JSON이면 충분 | JSON (build_app_context.json 내) |
| A/B 테스트 | 코드 구현 | Important | YAGNI | 문서화만 (AB_TEST_PLAN.md) |
| Phase 2 구조 | 단일 | 3단계 분리 | Tier 2는 단일 가능 | Tier별 분기 |

### 반영된 개선사항

| 지적 (severity) | 지적자 | 수정 내용 |
|----------------|--------|----------|
| Agent 2↔3 의존성 (Critical) | Challenger | Wave 분리 + agent2_manifest.json |
| Phase 2 과부하 (Critical) | Challenger | 2-A/2-B/2-C 서브스텝 |
| AndroidManifest 이중 수정 (Critical) | Challenger+BA | 충돌 방지 테이블 추가 |
| 온보딩 중복 (Important) | Lead | Agent 3 프롬프트 수정 |
| core/ 중복 처리 (Important) | Challenger | Agent 4/6 프롬프트 명시 |
| tech_notes 단방향 단절 (Important) | Challenger | Agent 2에 읽기 지시 추가 |
| CRM 범위 미명시 (Important) | BA | "로컬 예약" 방식 명시 |
| RevenueCat 콘솔 누락 (Important) | BA | REVENUECAT_SETUP.md 추가 |
| 패키지 목록 전달 (Minor) | Challenger | required_packages_agentN.txt |
| POST_BUILD_CHECKLIST (Important) | BA | Phase 3 산출물 추가 |
| manifest 교차 검증 (Minor) | Challenger | Phase 2-B에 1줄 추가 |

## 다음 단계
- [x] build-app.md에 합의안 반영 완료
- [ ] 실제 MVP 파일로 빌드 테스트 (달토리 or ZenJournal)

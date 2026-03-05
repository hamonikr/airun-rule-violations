# AIRUN Rule Violations

AIRUN 프로젝트의 **규칙 위반 탐지 및 패턴 학습 (Rule Violation Detection & Learning)**을 위한 저장소입니다.

## 목적

Rule Guard가 발견한 규칙 위반을 추적하고, 패턴을 분석하여 자동으로 규칙을 생성합니다.

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  1. VIOLATION DETECTED                                      │
│  Rule Guard: 취약점 발견                                    │
│  → Issue 생성 (label: -violation, needs-analysis)          │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  2. PATTERN ANALYSIS                                       │
│  Rule Miner (주기적 실행):                                  │
│  → Similar violations grouping                             │
│  → Pattern issue 생성 (label: pattern-proposed)            │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  3. TEAM VALIDATION                                        │
│  팀원들이 Pattern issue 리뷰                                │
│  → Approved label 추가                                      │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  4. RULE GENERATION                                        │
│  Rule Miner:                                               │
│  → airun-team-knowledge repo에 PR 생성                      │
│  → .claude/rules/*.md에 규칙 추가                           │
└─────────────────────────────────────────────────────────────┘
```

## 라벨 구조

### Category
- `security-violation` - 보안 관련 위반
- `database-violation` - DB 쿼리 위반
- `api-violation` - API 설계 위반
- `frontend-violation` - 프론트엔드 위반

### State
- `needs-analysis` - 분석 필요
- `pattern-proposed` - 패턴 제안됨
- `ready-for-rule` - 규칙 생성 준비 완료
- `rule-created` - 규칙 생성됨

### Severity
- `critical` - 즉시 수정 필요
- `high` - 우선순위 높음
- `medium` - 일반적
- `low` - 개선 제안

## 자동화

### Rule Guard
```bash
# 위반 발견 시 자동 실행
.claude/scripts/create-violation-issue.sh
```

### Rule Miner
```bash
# 주기적으로 실행 (cron 또는 manual)
.claude/scripts/analyze-violations.sh
```

## 관련 저장소

- [airun-tasks](https://github.com/hamonikr/airun-tasks) - 작업 관리
- [airun-team-knowledge](https://github.com/hamonikr/airun-team-knowledge) - 공유 규칙

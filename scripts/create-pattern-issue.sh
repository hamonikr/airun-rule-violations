#!/bin/bash
set -e

# 패턴 issue 생성 스크립트
# Usage: ./create-pattern-issue.sh <category> <related_issues> <violations_json>

REPO="hamonikr/airun-rule-violations"
CATEGORY="$1"
RELATED="$2"
VIOLATIONS_JSON="$3"

if [ -z "$CATEGORY" ] || [ -z "$RELATED" ]; then
  echo "Usage: $0 <category> <related_issues> <violations_json>"
  exit 1
fi

# 패턴 이름 추출 (간단한 키워드 매칭)
PATTERN_NAME=""
case "$CATEGORY" in
  security)
    if jq -r '.[].body' "$VIOLATIONS_JSON" | grep -qi "SQL"; then
      PATTERN_NAME="SQL Injection"
    elif jq -r '.[].body' "$VIOLATIONS_JSON" | grep -qi "XSS\|innerHTML"; then
      PATTERN_NAME="XSS Vulnerability"
    elif jq -r '.[].body' "$VIOLATIONS_JSON" | grep -qi "auth\|authentication"; then
      PATTERN_NAME="Missing Authentication"
    fi
    ;;
  database)
    if jq -r '.[].body' "$VIOLATIONS_JSON" | grep -qi "query\|SELECT"; then
      PATTERN_NAME="Database Query"
    elif jq -r '.[].body' "$VIOLATIONS_JSON" | grep -qi "schema\|migration"; then
      PATTERN_NAME="Schema Change"
    fi
    ;;
  api)
    if jq -r '.[].body' "$VIOLATIONS_JSON" | grep -qi "localhost"; then
      PATTERN_NAME="LocalAddress Hardcoding"
    elif jq -r '.[].body' "$VIOLATIONS_JSON" | grep -qi "auth"; then
      PATTERN_NAME="Missing Auth Middleware"
    fi
    ;;
  frontend)
    if jq -r '.[].body' "$VIOLATIONS_JSON" | grep -qi "localhost"; then
      PATTERN_NAME="Hardcoded URL"
    fi
    ;;
esac

if [ -z "$PATTERN_NAME" ]; then
  PATTERN_NAME="${CATEGORY^} Pattern"
fi

# Issue body 생성
cat > /tmp/pattern_body.md << EOF
## 📊 패턴 분석: $PATTERN_NAME

**카테고리**: $CATEGORY
**발생 횟수**: $(jq 'length' "$VIOLATIONS_JSON")회
**관련 위반**: #$RELATED

## 🔍 관련 Issues

$(jq -r '.[] | "- #\(.number): \(.title)"' "$VIOLATIONS_JSON")

## 📋 공통 패턴

$(jq -r '.[] | "### #\(.number)\n**위치**: \(.body | split("\n")[1] // "N/A")\n**증거**:\n```\n\(.body | match("\\`\\`\\`([\\s\\S]*?)\\`\\`\\`") // "No evidence"\n```\n\n"' "$VIOLATIONS_JSON")

## 💡 제안된 규칙

TODO: 패턴을 기반으로 규칙 생성

## 🤝 팀원 리뷰 필요

이 패턴이 규칙으로 등록되어야 할까요?

- [ ] 규칙 내용 확인
- [ ] 적용 범위 검토
- [ ] 예외 사항 토론

## 🔗 다음 단계

승인 시:
1. \`rule-created\` label 추가
2. Rule Miner가 airun-team-knowledge에 PR 생성
3. 팀원 리뷰 후 merge
EOF

# Issue 생성
echo "📝 Creating pattern issue: $PATTERN_NAME"
gh issue create \
  --repo "$REPO" \
  --title "📊 Pattern: $PATTERN_NAME ($(jq 'length' "$VIOLATIONS_JSON") occurrences)" \
  --body-file /tmp/pattern_body.md \
  --label "$CATEGORY-violation,pattern-proposed,ready-for-rule"

# 임시 파일 삭제
rm -f /tmp/pattern_body.md

echo "✅ Pattern issue created"

#!/bin/bash
set -e

# Rule Guard가 위반을 발견했을 때 GitHub Issue를 생성하는 스크립트
# Usage: ./create-violation-issue.sh <title> <location> <rule_file> <rule_id> <evidence> <severity> <suggestion>

REPO="hamonikr/airun-rule-violations"
TITLE="$1"
LOCATION="$2"
RULE_FILE="$3"
RULE_ID="$4"
EVIDENCE="$5"
SEVERITY="$6"  # critical, high, medium, low
SUGGESTION="$7"

if [ -z "$TITLE" ] || [ -z "$LOCATION" ] || [ -z "$EVIDENCE" ]; then
  echo "Usage: $0 <title> <location> <rule_file> <rule_id> <evidence> <severity> <suggestion>"
  echo ""
  echo "Example:"
  echo '  $0 "SQL injection 취약점" "services/users/route.ts:45" "security.md" "SQL_INJECTION_001" \
         "const query = \`SELECT * FROM users WHERE id = \${userId}\`;" \
         "critical" "Parameterized query 사용: db.query(\"... \$1\", [userId])"'
  exit 1
fi

# Category 결정 (rule_file에서)
CATEGORY="${RULE_FILE%%.md}-violation"

# Issue body 생성
cat > /tmp/violation_body.md << EOF
## 🔴 규칙 위반 발견

**위반 위치**: \`$LOCATION\`

**규칙 파일**: \`$RULE_FILE\`
**규칙 ID**: \`$RULE_ID\`
**심각도**: $SEVERITY

## 📋 증거

\`\`\`
$EVIDENCE
\`\`\`

## 💡 제안

$SUGGESTION

## 📊 메타데이터

- **발생 시간**: $(date -Iseconds)
- **자동 생성**: Rule Guard
- **상태**: 분석 필요

## 🔗 관련

- 규칙 파일: [airun-team-knowledge/.claude/rules/$RULE_FILE](https://github.com/hamonikr/airun-team-knowledge/blob/main/.claude/rules/$RULE_FILE)
EOF

# Issue 생성
echo "📝 Creating issue: $TITLE"
ISSUE_URL=$(gh issue create \
  --repo "$REPO" \
  --title "$TITLE" \
  --body-file /tmp/violation_body.md \
  --label "$CATEGORY,$SEVERITY,needs-analysis")

# Issue 번호 추출
ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$' || echo "")

if [ -n "$ISSUE_NUMBER" ]; then
  echo "✅ Issue created: #$ISSUE_NUMBER"
  echo "🔗 $ISSUE_URL"

  # Monitoring DB에도 기록
  if [ -n "$MONITORING_DB" ]; then
    echo "💾 Logging to monitoring DB..."
    # TODO: MCP tool call to log_rule
  fi
else
  echo "❌ Failed to extract issue number"
  exit 1
fi

# 임시 파일 삭제
rm -f /tmp/violation_body.md

echo ""
echo "Next steps:"
echo "1. 유사한 위반이 있는지 검색: gh issue list --repo $REPO --search \"$CATEGORY\""
echo "2. Pattern analysis 필요: /rule-miner analyze"

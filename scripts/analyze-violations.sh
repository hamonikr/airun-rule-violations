#!/bin/bash
set -e

# Rule Miner가 위반 패턴을 분석하는 스크립트
# Usage: ./analyze-violations.sh [--days 30] [--category security]

REPO="hamonikr/airun-rule-violations"
DAYS=${DAYS:-30}
CATEGORY=${CATEGORY:-""}
OUTPUT_DIR="/tmp/rule-miner"

mkdir -p "$OUTPUT_DIR"

echo "🔍 Analyzing violations from last $DAYS days..."

# Category 필터
CATEGORY_FILTER=""
if [ -n "$CATEGORY" ]; then
  CATEGORY_FILTER="--label $CATEGORY-violation"
fi

# Closed issues 조회
echo "📥 Fetching closed issues..."
gh issue list \
  --repo "$REPO" \
  --limit 100 \
  --state closed \
  --search "closed:>$DAYS days ago $CATEGORY_FILTER" \
  --json title,body,labels,number,closedAt \
  > "$OUTPUT_DIR/closed_issues.json"

# Category별로 그룹화
echo "📊 Grouping by category..."

# Security violations
jq '[.[] | select(.labels[].name | contains("security-violation"))]' \
  "$OUTPUT_DIR/closed_issues.json" > "$OUTPUT_DIR/security_violations.json" || true

# Database violations
jq '[.[] | select(.labels[].name | contains("database-violation"))]' \
  "$OUTPUT_DIR/closed_issues.json" > "$OUTPUT_DIR/database_violations.json" || true

# API violations
jq '[.[] | select(.labels[].name | contains("api-violation"))]' \
  "$OUTPUT_DIR/closed_issues.json" > "$OUTPUT_DIR/api_violations.json" || true

# Frontend violations
jq '[.[] | select(.labels[].name | contains("frontend-violation"))]' \
  "$OUTPUT_DIR/closed_issues.json" > "$OUTPUT_DIR/frontend_violations.json" || true

# 패턴 추출
echo "🔄 Extracting patterns..."

for category in security database api frontend; do
  FILE="$OUTPUT_DIR/${category}_violations.json"
  if [ -s "$FILE" ]; then
    COUNT=$(jq 'length' "$FILE")
    echo "  $category-violation: $COUNT issues"

    if [ "$COUNT" -ge 2 ]; then
      # 패턴 분석 (간단한 키워드 기반)
      echo "    ⚠️  Pattern detected! Creating pattern issue..."

      # 관련 issue 번호들
      RELATED=$(jq -r '.[].number' "$FILE" | head -3 | tr '\n' ',' | sed 's/,$//')

      # Pattern issue 생성
      ./scripts/create-pattern-issue.sh "$category" "$RELATED" "$FILE"
    fi
  fi
done

echo ""
echo "✅ Analysis complete!"
echo "📁 Output directory: $OUTPUT_DIR"
echo ""
echo "Summary:"
echo "  - Total closed issues: $(jq 'length' "$OUTPUT_DIR/closed_issues.json")"
for category in security database api frontend; do
  FILE="$OUTPUT_DIR/${category}_violations.json"
  if [ -s "$FILE" ]; then
    COUNT=$(jq 'length' "$FILE")
    echo "  - $category-violation: $COUNT"
  fi
  fi
done

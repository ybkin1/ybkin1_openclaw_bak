#!/bin/bash
# OpenClaw 灾难恢复 - 脚本 5: 记忆恢复
# 用途：恢复记忆系统和学习数据
# 执行时间：约 2 分钟

set -e

echo "=========================================="
echo "OpenClaw 灾难恢复 - 步骤 5: 记忆恢复"
echo "=========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

BACKUP_DIR="~/openclaw-backup"
WORKSPACE="~/.openclaw/workspace"

# 1. 恢复记忆数据
log_info "恢复记忆数据..."

if [ -d "$BACKUP_DIR/memory" ]; then
  # 恢复记忆目录
  rsync -av $BACKUP_DIR/memory/ $WORKSPACE/memory/
  log_info "✅ 记忆数据已恢复"
  
  # 显示恢复的记忆文件统计
  echo ""
  echo "=== 记忆文件统计 ==="
  echo "Daily: $(find $WORKSPACE/memory/daily -name "*.md" 2>/dev/null | wc -l) 个文件"
  echo "Knowledge: $(find $WORKSPACE/memory/knowledge -name "*.md" 2>/dev/null | wc -l) 个文件"
  echo "Config: $(find $WORKSPACE/memory/config -name "*.md" 2>/dev/null | wc -l) 个文件"
  echo "Decisions: $(find $WORKSPACE/memory/decisions -name "*.md" 2>/dev/null | wc -l) 个文件"
  echo "Projects: $(find $WORKSPACE/memory/projects -name "*.md" 2>/dev/null | wc -l) 个文件"
  echo ""
else
  log_warn "记忆数据备份不存在"
fi

# 2. 恢复学习数据
log_info "恢复学习数据..."

if [ -d "$BACKUP_DIR/learnings" ]; then
  mkdir -p $WORKSPACE/.learnings
  
  for file in LEARNINGS.md ERRORS.md FEATURE_REQUESTS.md; do
    if [ -f "$BACKUP_DIR/learnings/$file" ]; then
      cp $BACKUP_DIR/learnings/$file $WORKSPACE/.learnings/
      log_info "✅ .learnings/$file 已恢复"
    fi
  done
else
  log_warn "学习数据备份不存在"
fi

# 3. 重建记忆索引
log_info "重建记忆索引..."

if [ -f "$WORKSPACE/memory/INDEX.md" ]; then
  log_info "✅ 记忆索引已存在"
else
  # 创建索引文件
  cat > $WORKSPACE/memory/INDEX.md << 'EOF'
# 记忆索引

_最后更新：自动恢复_

---

## 📊 概览

| 层级 | 文件数 | 最后更新 | 状态 |
|------|--------|----------|------|
| daily/ | 自动 | 自动 | 🟢 正常 |
| knowledge/ | 自动 | 自动 | 🟢 正常 |
| config/ | 自动 | 自动 | 🟢 正常 |
| decisions/ | 自动 | 自动 | 🟢 正常 |
| projects/ | 自动 | 自动 | 🟢 正常 |

---

## 🔍 快速查找

- **日常记录**: [memory/daily/](daily/)
- **知识库**: [memory/knowledge/](knowledge/)
- **配置**: [memory/config/](config/)
- **决策**: [memory/decisions/](decisions/)
- **项目**: [memory/projects/](projects/)

---

_此索引由恢复脚本自动生成_
EOF
  log_info "✅ 记忆索引已创建"
fi

# 4. 验证记忆完整性
log_info "验证记忆完整性..."

# 检查关键文件
CRITICAL_FILES=(
  "$WORKSPACE/memory/INDEX.md"
  "$WORKSPACE/memory/config/system.md"
  "$WORKSPACE/memory/knowledge/skills.md"
  "$WORKSPACE/.learnings/LEARNINGS.md"
)

echo ""
echo "=== 关键记忆文件验证 ==="
for file in "${CRITICAL_FILES[@]}"; do
  if [ -f "$file" ]; then
    log_info "✅ $(basename $file) 存在"
  else
    log_warn "⚠️  $(basename $file) 缺失"
  fi
done
echo ""

# 5. 验证记忆系统功能
log_info "测试记忆系统..."

# 尝试读取记忆
if openclaw skill-run memory-master recall "测试" 2>/dev/null | grep -q "success\|found"; then
  log_info "✅ 记忆系统功能正常"
else
  log_warn "⚠️  记忆系统功能测试失败 (可能需要手动验证)"
fi

log_info "✅ 记忆恢复完成！"
echo ""
echo "下一步：执行脚本 6 - Docker 恢复"
echo "  bash scripts/06-setup-docker.sh"

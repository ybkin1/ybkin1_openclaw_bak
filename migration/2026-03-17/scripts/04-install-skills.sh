#!/bin/bash
# OpenClaw 灾难恢复 - 脚本 4: 技能安装
# 用途：批量安装所有技能
# 执行时间：约 5-10 分钟

set -e

echo "=========================================="
echo "OpenClaw 灾难恢复 - 步骤 4: 技能安装"
echo "=========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

BACKUP_DIR="~/openclaw-backup"
SKILLS_DIR="~/.openclaw/workspace/skills"

# 1. 读取技能清单
log_info "读取技能清单..."
if [ ! -f "$BACKUP_DIR/skills/skills-to-install.txt" ]; then
  log_error "技能清单不存在：$BACKUP_DIR/skills/skills-to-install.txt"
  exit 1
fi

SKILLS=$(cat $BACKUP_DIR/skills/skills-to-install.txt)
SKILLS_COUNT=$(echo "$SKILLS" | wc -l)

log_info "检测到 $SKILLS_COUNT 个技能待安装"
echo ""

# 2. 批量安装技能
INSTALLED=0
FAILED=0
SKIPPED=0

for skill in $SKILLS; do
  # 跳过空行和注释
  [[ -z "$skill" || "$skill" =~ ^# ]] && continue
  
  # 检查技能是否已安装
  if [ -d "$SKILLS_DIR/$skill" ]; then
    log_info "⏭️  $skill 已安装，跳过"
    ((SKIPPED++))
    continue
  fi
  
  # 安装技能
  log_info "安装技能：$skill..."
  
  # 尝试从 skillhub 安装 (优先)
  if skillhub install "$skill" 2>/dev/null; then
    log_info "✅ $skill 安装成功 (skillhub)"
    ((INSTALLED++))
  # 回退到 clawhub
  elif clawhub install "$skill" 2>/dev/null; then
    log_info "✅ $skill 安装成功 (clawhub)"
    ((INSTALLED++))
  # 尝试从备份恢复
  elif [ -d "$BACKUP_DIR/skills/full/$skill" ]; then
    log_info "从备份恢复：$skill..."
    cp -r $BACKUP_DIR/skills/full/$skill $SKILLS_DIR/
    log_info "✅ $skill 恢复成功 (备份)"
    ((INSTALLED++))
  else
    log_warn "❌ $skill 安装失败"
    ((FAILED++))
  fi
done

# 3. 恢复技能配置
log_info "恢复技能配置..."
if [ -d "$BACKUP_DIR/skills/skill-sources" ]; then
  # 复制技能元数据
  find $BACKUP_DIR/skills/skill-sources -name "_meta.json" -exec cp --parents {} $SKILLS_DIR/ \; 2>/dev/null || true
  log_info "✅ 技能元数据已恢复"
fi

# 4. 验证技能
log_info "验证技能安装..."
echo ""
echo "=== 技能安装统计 ==="
echo "已安装：$INSTALLED"
echo "已存在：$SKIPPED"
echo "失败：$FAILED"
echo "总计：$SKILLS_COUNT"
echo ""

# 列出已安装技能
echo "=== 已安装技能列表 ==="
ls $SKILLS_DIR/ | grep -v "^\." | head -20
echo "... (共 $(ls $SKILLS_DIR/ | grep -v "^\." | wc -l) 个)"
echo ""

# 5. 验证关键技能
log_info "验证关键技能..."
CRITICAL_SKILLS=("self-improving-agent" "memory-master" "skill-vetting")

for skill in "${CRITICAL_SKILLS[@]}"; do
  if [ -d "$SKILLS_DIR/$skill" ]; then
    log_info "✅ 关键技能 $skill 已安装"
  else
    log_warn "⚠️  关键技能 $skill 未安装"
  fi
done

log_info "✅ 技能安装完成！"
echo ""
echo "下一步：执行脚本 5 - 记忆恢复"
echo "  bash scripts/05-restore-memory.sh"

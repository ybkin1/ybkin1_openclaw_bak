#!/bin/bash
# OpenClaw 灾难恢复 - 脚本 3: 配置恢复
# 用途：恢复所有配置文件
# 执行时间：约 5 分钟

set -e

echo "=========================================="
echo "OpenClaw 灾难恢复 - 步骤 3: 配置恢复"
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

# 1. 恢复 OpenClaw 主配置
log_info "恢复 OpenClaw 主配置..."
if [ -f "$BACKUP_DIR/configs/openclaw/openclaw.json" ]; then
  cp $BACKUP_DIR/configs/openclaw/openclaw.json ~/.openclaw/
  log_info "✅ openclaw.json 已恢复"
else
  log_warn "openclaw.json 备份不存在，使用默认配置"
fi

# 2. 恢复 Workspace 配置
log_info "恢复 Workspace 配置..."
for file in SOUL.md AGENTS.md USER.md TOOLS.md MEMORY.md HEARTBEAT.md IDENTITY.md; do
  if [ -f "$BACKUP_DIR/configs/workspace/$file" ]; then
    cp $BACKUP_DIR/configs/workspace/$file $WORKSPACE/
    log_info "✅ $file 已恢复"
  else
    log_warn "$file 备份不存在"
  fi
done

# 3. 恢复系统配置
log_info "恢复系统配置..."

# Cron 配置
if [ -f "$BACKUP_DIR/configs/system/crontab.bak" ]; then
  crontab $BACKUP_DIR/configs/system/crontab.bak
  log_info "✅ Cron 任务已恢复"
else
  log_warn "Cron 配置备份不存在"
fi

# SSH 配置 (可选)
if [ -f "$BACKUP_DIR/configs/system/sshd_config.bak" ]; then
  log_warn "检测到 SSH 配置备份，是否恢复？(y/N)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    cp $BACKUP_DIR/configs/system/sshd_config.bak /etc/ssh/sshd_config
    systemctl restart sshd
    log_info "✅ SSH 配置已恢复"
  fi
fi

# 4. 恢复环境变量
log_info "恢复环境变量..."
if [ -f "$BACKUP_DIR/configs/env/env-template.sh" ]; then
  # 检查是否已添加
  if ! grep -q "OPENCLAW_" ~/.bashrc; then
    cat $BACKUP_DIR/configs/env/env-template.sh >> ~/.bashrc
    source ~/.bashrc
    log_info "✅ 环境变量已恢复"
  else
    log_info "环境变量已存在，跳过"
  fi
fi

# 5. 恢复其他文档
log_info "恢复文档库..."
if [ -d "$BACKUP_DIR/configs/workspace/docs" ]; then
  rsync -av $BACKUP_DIR/configs/workspace/docs/ $WORKSPACE/docs/
  log_info "✅ 文档库已恢复"
fi

# 6. 恢复自定义脚本
log_info "恢复自定义脚本..."
if [ -d "$BACKUP_DIR/configs/workspace/scripts" ]; then
  rsync -av $BACKUP_DIR/configs/workspace/scripts/ $WORKSPACE/scripts/
  chmod +x $WORKSPACE/scripts/*.sh 2>/dev/null || true
  log_info "✅ 自定义脚本已恢复"
fi

# 7. 验证配置
log_info "验证配置..."
echo ""
echo "=== 配置验证 ==="
echo "OpenClaw 配置：$(test -f ~/.openclaw/openclaw.json && echo '✅ 存在' || echo '❌ 缺失')"
echo "SOUL.md: $(test -f $WORKSPACE/SOUL.md && echo '✅ 存在' || echo '❌ 缺失')"
echo "AGENTS.md: $(test -f $WORKSPACE/AGENTS.md && echo '✅ 存在' || echo '❌ 缺失')"
echo "MEMORY.md: $(test -f $WORKSPACE/MEMORY.md && echo '✅ 存在' || echo '❌ 缺失')"
echo ""

# 8. 重启 Gateway 应用配置
log_info "重启 Gateway 应用配置..."
openclaw gateway restart
sleep 3

if openclaw status | grep -q "running"; then
  log_info "✅ Gateway 运行正常"
else
  log_error "❌ Gateway 启动失败"
  exit 1
fi

log_info "✅ 配置恢复完成！"
echo ""
echo "下一步：执行脚本 4 - 技能安装"
echo "  bash scripts/04-install-skills.sh"

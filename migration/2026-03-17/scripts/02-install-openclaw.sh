#!/bin/bash
# OpenClaw 灾难恢复 - 脚本 2: OpenClaw 安装
# 用途：安装和配置 OpenClaw
# 执行时间：约 5 分钟

set -e

echo "=========================================="
echo "OpenClaw 灾难恢复 - 步骤 2: OpenClaw 安装"
echo "=========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. 安装 OpenClaw CLI
log_info "安装 OpenClaw CLI..."
if ! command -v openclaw &> /dev/null; then
  npm install -g openclaw
  log_info "OpenClaw 版本：$(openclaw --version)"
else
  log_info "OpenClaw 已安装：$(openclaw --version)"
fi

# 2. 初始化工作区
log_info "初始化工作区..."
if [ ! -d "~/.openclaw/workspace" ]; then
  openclaw init
  log_info "工作区初始化完成"
else
  log_info "工作区已存在"
fi

# 3. 恢复环境变量
log_info "恢复环境变量..."
if [ -f "~/openclaw-backup/configs/env/env-template.sh" ]; then
  cat ~/openclaw-backup/configs/env/env-template.sh >> ~/.bashrc
  source ~/.bashrc
  log_info "环境变量已恢复"
else
  log_warn "环境变量备份不存在"
fi

# 4. 恢复 API 密钥 (需要手动输入或从密钥管理器获取)
log_info "配置 API 密钥..."
if [ -f "~/openclaw-backup/security/api-keys.enc" ]; then
  log_warn "检测到加密的 API 密钥备份"
  log_info "请输入 GPG 密码解密:"
  gpg --decrypt ~/openclaw-backup/security/api-keys.enc.gpg >> ~/.bashrc
  source ~/.bashrc
else
  log_warn "需要手动配置 API 密钥"
  echo "请设置以下环境变量:"
  echo "export OPENCLAW_QWEN_API_KEY='sk-your-key-here'"
  echo "export MEMOS_TOKEN='your-memos-token'"
  echo "添加到 ~/.bashrc 并执行 source ~/.bashrc"
fi

# 5. 启动 Gateway
log_info "启动 OpenClaw Gateway..."
openclaw gateway start
sleep 5

# 6. 验证 Gateway 状态
log_info "验证 Gateway 状态..."
if openclaw status | grep -q "running"; then
  log_info "✅ Gateway 运行正常"
else
  log_error "❌ Gateway 启动失败"
  exit 1
fi

log_info "✅ OpenClaw 安装完成！"
echo ""
echo "下一步：执行脚本 3 - 配置恢复"
echo "  bash scripts/03-restore-configs.sh"

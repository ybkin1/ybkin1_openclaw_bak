#!/bin/bash
# OpenClaw 灾难恢复 - 脚本 1: 系统初始化
# 用途：系统重置后的初始化配置
# 执行时间：约 10 分钟

set -e

echo "=========================================="
echo "OpenClaw 灾难恢复 - 步骤 1: 系统初始化"
echo "=========================================="

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. 系统更新
log_info "更新系统包..."
yum update -y || {
  log_warn "yum update 失败，继续执行..."
}

# 2. 安装基础依赖
log_info "安装基础依赖..."
yum install -y \
  git \
  curl \
  wget \
  vim \
  net-tools \
  jq \
  tar \
  gzip \
  sha256sum \
  gpg || {
  log_warn "部分包安装失败，继续执行..."
}

# 3. 安装 Node.js v22
log_info "安装 Node.js v22..."
if ! command -v node &> /dev/null; then
  curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
  yum install -y nodejs
  log_info "Node.js 版本：$(node --version)"
else
  log_info "Node.js 已安装：$(node --version)"
fi

# 4. 安装 Docker
log_info "检查 Docker..."
if ! command -v docker &> /dev/null; then
  log_info "安装 Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
  log_info "Docker 版本：$(docker --version)"
else
  log_info "Docker 已安装：$(docker --version)"
fi

# 5. 配置 SSH 密钥
log_info "配置 SSH 密钥..."
if [ -d "~/openclaw-backup/security/ssh-keys" ]; then
  log_warn "检测到备份的 SSH 密钥，是否恢复？(y/N)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    cp -r ~/openclaw-backup/security/ssh-keys/* ~/.ssh/
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub
    chmod 600 ~/.ssh/authorized_keys
    log_info "SSH 密钥恢复完成"
  fi
else
  log_info "SSH 密钥目录不存在，跳过"
fi

# 6. 配置防火墙
log_info "配置防火墙规则..."
if command -v firewall-cmd &> /dev/null; then
  firewall-cmd --permanent --add-service=ssh
  firewall-cmd --permanent --add-port=18789/tcp
  firewall-cmd --permanent --add-port=5230/tcp
  firewall-cmd --permanent --add-port=8080/tcp
  firewall-cmd --permanent --add-port=5678/tcp
  firewall-cmd --reload
  log_info "防火墙规则已配置"
else
  log_warn "firewalld 未安装，跳过防火墙配置"
fi

# 7. 设置系统参数
log_info "设置系统参数..."
cat >> /etc/security/limits.conf << EOF
# OpenClaw 优化
root soft nofile 65535
root hard nofile 65535
EOF

# 8. 验证系统状态
log_info "验证系统状态..."
echo ""
echo "=== 系统状态 ==="
echo "操作系统：$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2)"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "Docker: $(docker --version)"
echo "Git: $(git --version)"
echo ""

log_info "✅ 系统初始化完成！"
echo ""
echo "下一步：执行脚本 2 - OpenClaw 安装"
echo "  bash scripts/02-install-openclaw.sh"

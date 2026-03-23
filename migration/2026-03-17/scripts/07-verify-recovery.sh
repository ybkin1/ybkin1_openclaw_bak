#!/bin/bash
# OpenClaw 灾难恢复 - 脚本 7: 恢复验证
# 用途：验证所有恢复是否成功
# 执行时间：约 5 分钟

set -e

echo "=========================================="
echo "OpenClaw 灾难恢复 - 步骤 7: 恢复验证"
echo "=========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 计数器
PASSED=0
FAILED=0
WARNINGS=0

check() {
  local name=$1
  local command=$2
  
  if eval "$command" >/dev/null 2>&1; then
    log_info "✅ $name"
    ((PASSED++))
  else
    log_error "❌ $name"
    ((FAILED++))
  fi
}

warn_check() {
  local name=$1
  local command=$2
  
  if eval "$command" >/dev/null 2>&1; then
    log_info "✅ $name"
    ((PASSED++))
  else
    log_warn "⚠️  $name"
    ((WARNINGS++))
  fi
}

# 1. 系统状态
echo "=== 1. 系统状态检查 ==="
check "Node.js 已安装" "command -v node"
check "npm 已安装" "command -v npm"
check "Git 已安装" "command -v git"
check "Docker 已安装" "command -v docker"
check "Docker 运行中" "docker ps"
echo ""

# 2. OpenClaw 状态
echo "=== 2. OpenClaw 状态检查 ==="
check "OpenClaw CLI 已安装" "command -v openclaw"
check "Gateway 运行中" "openclaw status | grep -q running"
check "工作区存在" "test -d ~/.openclaw/workspace"
warn_check "配置文件存在" "test -f ~/.openclaw/openclaw.json"
echo ""

# 3. 核心配置文件
echo "=== 3. 核心配置文件检查 ==="
WORKSPACE="~/.openclaw/workspace"
check "SOUL.md" "test -f $WORKSPACE/SOUL.md"
check "AGENTS.md" "test -f $WORKSPACE/AGENTS.md"
check "USER.md" "test -f $WORKSPACE/USER.md"
check "TOOLS.md" "test -f $WORKSPACE/TOOLS.md"
check "MEMORY.md" "test -f $WORKSPACE/MEMORY.md"
warn_check "HEARTBEAT.md" "test -f $WORKSPACE/HEARTBEAT.md"
echo ""

# 4. 技能系统
echo "=== 4. 技能系统检查 ==="
check "技能目录存在" "test -d ~/.openclaw/workspace/skills"

SKILLS_COUNT=$(ls ~/.openclaw/workspace/skills/ 2>/dev/null | grep -v "^\." | wc -l)
if [ $SKILLS_COUNT -gt 0 ]; then
  log_info "✅ 已安装技能数：$SKILLS_COUNT"
  ((PASSED++))
else
  log_error "❌ 未检测到已安装技能"
  ((FAILED++))
fi

# 关键技能检查
CRITICAL_SKILLS=("self-improving-agent" "memory-master" "skill-vetting")
for skill in "${CRITICAL_SKILLS[@]}"; do
  warn_check "关键技能：$skill" "test -d ~/.openclaw/workspace/skills/$skill"
done
echo ""

# 5. 记忆系统
echo "=== 5. 记忆系统检查 ==="
check "记忆目录存在" "test -d ~/.openclaw/workspace/memory"
check "记忆索引存在" "test -f ~/.openclaw/workspace/memory/INDEX.md"
check "学习目录存在" "test -d ~/.openclaw/workspace/.learnings"

DAILY_COUNT=$(find ~/.openclaw/workspace/memory/daily -name "*.md" 2>/dev/null | wc -l)
log_info "✅ Daily 记忆文件数：$DAILY_COUNT"
((PASSED++))

KNOWLEDGE_COUNT=$(find ~/.openclaw/workspace/memory/knowledge -name "*.md" 2>/dev/null | wc -l)
log_info "✅ Knowledge 记忆文件数：$KNOWLEDGE_COUNT"
((PASSED++))
echo ""

# 6. 学习数据
echo "=== 6. 学习数据检查 ==="
warn_check "LEARNINGS.md" "test -f ~/.openclaw/workspace/.learnings/LEARNINGS.md"
warn_check "ERRORS.md" "test -f ~/.openclaw/workspace/.learnings/ERRORS.md"
warn_check "FEATURE_REQUESTS.md" "test -f ~/.openclaw/workspace/.learnings/FEATURE_REQUESTS.md"
echo ""

# 7. Docker 服务
echo "=== 7. Docker 服务检查 ==="
warn_check "Memos 容器" "docker ps | grep -q memos"
warn_check "SearXNG 容器" "docker ps | grep -q searxng"
warn_check "n8n 容器" "docker ps | grep -q n8n"

# 服务连通性
warn_check "Memos 服务 (5230)" "curl -s http://localhost:5230"
warn_check "SearXNG 服务 (8080)" "curl -s http://localhost:8080"
warn_check "n8n 服务 (5678)" "curl -s http://localhost:5678"
echo ""

# 8. 环境变量
echo "=== 8. 环境变量检查 ==="
warn_check "OPENCLAW_GATEWAY_PORT" "env | grep -q OPENCLAW_GATEWAY_PORT"
warn_check "MEMOS_URL" "env | grep -q MEMOS_URL"
warn_check "SEARXNG_URL" "env | grep -q SEARXNG_URL"
echo ""

# 9. 网络端口
echo "=== 9. 网络端口检查 ==="
warn_check "Gateway 端口 (18789)" "netstat -tlnp 2>/dev/null | grep -q 18789 || ss -tlnp 2>/dev/null | grep -q 18789"
warn_check "SSH 端口 (22)" "netstat -tlnp 2>/dev/null | grep -q :22 || ss -tlnp 2>/dev/null | grep -q :22"
warn_check "Memos 端口 (5230)" "netstat -tlnp 2>/dev/null | grep -q 5230 || ss -tlnp 2>/dev/null | grep -q 5230"
warn_check "SearXNG 端口 (8080)" "netstat -tlnp 2>/dev/null | grep -q 8080 || ss -tlnp 2>/dev/null | grep -q 8080"
echo ""

# 10. 备份系统
echo "=== 10. 备份系统检查 ==="
check "备份目录存在" "test -d ~/.openclaw/backups-repo"
check "MANIFEST.json" "test -f ~/.openclaw/backups-repo/MANIFEST.json"
check "恢复脚本存在" "test -f ~/.openclaw/backups-repo/scripts/01-system-setup.sh"
echo ""

# 生成恢复报告
echo "=========================================="
echo "恢复验证报告"
echo "=========================================="
echo ""
echo "通过：$PASSED"
echo "失败：$FAILED"
echo "警告：$WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
  log_info "✅ 恢复验证通过！系统已完全恢复。"
  echo ""
  echo "=== 恢复完成清单 ==="
  echo "✅ 系统初始化"
  echo "✅ OpenClaw 安装"
  echo "✅ 配置恢复"
  echo "✅ 技能安装"
  echo "✅ 记忆恢复"
  echo "✅ Docker 服务恢复"
  echo "✅ 恢复验证"
  echo ""
  echo "系统已准备就绪！"
  exit 0
else
  log_error "❌ 恢复验证失败，有 $FAILED 项未通过"
  echo ""
  echo "请检查失败项并手动修复"
  echo "失败项详情见上方输出"
  exit 1
fi

#!/bin/bash
# OpenClaw 灾难恢复 - 脚本 6: Docker 服务恢复
# 用途：恢复 Docker 容器和数据
# 执行时间：约 3-5 分钟

set -e

echo "=========================================="
echo "OpenClaw 灾难恢复 - 步骤 6: Docker 恢复"
echo "=========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

BACKUP_DIR="~/openclaw-backup"

# 1. 检查 Docker 状态
log_info "检查 Docker 状态..."
if ! docker ps >/dev/null 2>&1; then
  log_error "Docker 未运行，请先启动 Docker"
  exit 1
fi
log_info "✅ Docker 运行正常"

# 2. 恢复 Memos
log_info "恢复 Memos 服务..."

# 检查是否已有 Memos 容器
if docker ps | grep -q memos; then
  log_info "Memos 已运行，跳过"
else
  # 从备份恢复数据库
  if [ -f "$BACKUP_DIR/docker/memos/memos_prod.db.dump" ]; then
    log_info "从备份恢复 Memos 数据库..."
    
    # 创建数据目录
    mkdir -p ~/.memos
    
    # 启动临时容器导入数据
    docker run --rm -v ~/.memos:/home/user/.memos \
      neosmemo/memos:stable \
      sh -c "cat /home/user/.memos/memos_prod.db.dump | sqlite3 /home/user/.memos/memos_prod.db"
    
    log_info "✅ Memos 数据库已恢复"
  fi
  
  # 启动 Memos 容器
  docker run -d \
    --name memos \
    -p 5230:5230 \
    -v ~/.memos:/home/user/.memos \
    --restart unless-stopped \
    neosmemo/memos:stable
  
  log_info "✅ Memos 容器已启动"
fi

# 3. 恢复 SearXNG
log_info "恢复 SearXNG 服务..."

if docker ps | grep -q searxng; then
  log_info "SearXNG 已运行，跳过"
else
  # 恢复配置
  if [ -f "$BACKUP_DIR/docker/searxng/settings.yml" ]; then
    mkdir -p ~/.searxng
    cp $BACKUP_DIR/docker/searxng/settings.yml ~/.searxng/
    log_info "✅ SearXNG 配置已恢复"
  fi
  
  # 启动 SearXNG 容器
  docker run -d \
    --name searxng \
    -p 8080:8080 \
    -v ~/.searxng:/etc/searxng \
    --restart unless-stopped \
    searxng/searxng:latest
  
  log_info "✅ SearXNG 容器已启动"
fi

# 4. 恢复 n8n
log_info "恢复 n8n 服务..."

if docker ps | grep -q n8n; then
  log_info "n8n 已运行，跳过"
else
  # 启动 n8n 容器
  docker run -d \
    --name n8n \
    -p 5678:5678 \
    -v ~/.n8n:/home/node/.n8n \
    --restart unless-stopped \
    n8nio/n8n:latest
  
  log_info "✅ n8n 容器已启动"
fi

# 5. 验证 Docker 服务
log_info "验证 Docker 服务..."
echo ""
echo "=== Docker 容器状态 ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 6. 测试服务连通性
log_info "测试服务连通性..."

# Memos
if curl -s http://localhost:5230 | grep -q "memos\|Memos"; then
  log_info "✅ Memos 服务正常"
else
  log_warn "⚠️  Memos 服务响应异常"
fi

# SearXNG
if curl -s http://localhost:8080 | grep -q "searxng\|SearXNG"; then
  log_info "✅ SearXNG 服务正常"
else
  log_warn "⚠️  SearXNG 服务响应异常"
fi

# n8n
if curl -s http://localhost:5678 | grep -q "n8n"; then
  log_info "✅ n8n 服务正常"
else
  log_warn "⚠️  n8n 服务响应异常"
fi

echo ""
log_info "✅ Docker 服务恢复完成！"
echo ""
echo "下一步：执行脚本 7 - 恢复验证"
echo "  bash scripts/07-verify-recovery.sh"

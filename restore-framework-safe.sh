#!/bin/bash
# =============================================================================
# OpenClaw 框架基线恢复脚本 v1.0
# 
# 用途：安全恢复框架基线配置（不影响系统配置）
# 特点：独立运行，不影响现有完整备份策略
# 创建：2026-03-25
# =============================================================================

set -euo pipefail

#=========== 配置区 ===========
MASTER_DIR="/root/.openclaw/workspace/agents/master"
WORKSPACE_ROOT="/root/.openclaw/workspace"
OPENCLAW_HOME="/root/.openclaw"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

#=========== 使用帮助 ===========
usage() {
    echo "用法：$0 <framework_bundle_path>"
    echo ""
    echo "参数:"
    echo "  framework_bundle_path  框架备份目录路径"
    echo ""
    echo "示例:"
    echo "  $0 /root/.openclaw/backups-unified/framework_bak_20260325_120000"
    echo ""
    echo "可用框架备份:"
    ls -1d /root/.openclaw/backups-unified/framework_bak_* 2>/dev/null | tail -5 || echo "  (无)"
    exit 1
}

#=========== 参数检查 ===========
if [ $# -ne 1 ]; then
    usage
fi

FRAMEWORK_BUNDLE="$1"

if [ ! -d "$FRAMEWORK_BUNDLE" ]; then
    log_error "框架备份目录不存在：$FRAMEWORK_BUNDLE"
    usage
fi

if [ ! -f "$FRAMEWORK_BUNDLE/architecture.tar.gz" ]; then
    log_error "架构备份文件不存在"
    exit 1
fi

#=========== 安全确认 ===========
echo ""
echo "=========================================="
echo "   OpenClaw 框架基线恢复工具 v1.0"
echo "=========================================="
echo ""
log_warn "⚠️  警告：这将覆盖当前框架配置"
echo ""
echo "备份源：$FRAMEWORK_BUNDLE"
echo ""
echo "将恢复的内容:"
echo "  ✓ Agent 架构配置 (AGENTS.md, SOUL.md 等)"
echo "  ✓ 工作流程模板 (memory/config/)"
echo "  ✓ Skills (如果包含)"
echo ""
echo "不会修改的内容:"
echo "  ✓ openclaw.json (系统配置)"
echo "  ✓ memory/daily/ (每日日志)"
echo "  ✓ memory/short_term/ (短期记忆)"
echo "  ✓ Agent 独立配置 (agent.json, models.json)"
echo ""
read -p "是否已备份当前状态？(y/n): " confirm_backup
if [ "$confirm_backup" != "y" ]; then
    echo ""
    log_info "创建自动备份..."
    BACKUP_POINT="/tmp/framework_pre_restore_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_POINT"
    cp -r "$MASTER_DIR/AGENTS.md" "$BACKUP_POINT/" 2>/dev/null || true
    cp -r "$MASTER_DIR/SOUL.md" "$BACKUP_POINT/" 2>/dev/null || true
    cp -r "$MASTER_DIR/TOOLS.md" "$BACKUP_POINT/" 2>/dev/null || true
    cp -r "$OPENCLAW_HOME/openclaw.json" "$BACKUP_POINT/" 2>/dev/null || true
    log_info "✓ 回滚点已创建：$BACKUP_POINT"
fi

echo ""
read -p "是否继续恢复？(y/n): " confirm
if [ "$confirm" != "y" ]; then
    log_error "已取消恢复"
    exit 1
fi

#=========== 恢复流程 ===========
echo ""
log_step "开始恢复框架基线..."

# 1. 停止 Gateway
log_step "停止 Gateway..."
if systemctl --user is-active openclaw-gateway >/dev/null 2>&1; then
    systemctl --user stop openclaw-gateway
    log_info "✓ Gateway 已停止"
else
    log_warn "⚠ Gateway 未运行"
fi

# 2. 创建回滚点
BACKUP_POINT="/tmp/framework_pre_restore_$(date +%Y%m%d_%H%M%S)"
log_step "创建回滚点：$BACKUP_POINT"
mkdir -p "$BACKUP_POINT"
cp -r "$MASTER_DIR/AGENTS.md" "$BACKUP_POINT/" 2>/dev/null || true
cp -r "$MASTER_DIR/SOUL.md" "$BACKUP_POINT/" 2>/dev/null || true
cp -r "$MASTER_DIR/TOOLS.md" "$BACKUP_POINT/" 2>/dev/null || true
cp -r "$MASTER_DIR/USER.md" "$BACKUP_POINT/" 2>/dev/null || true
cp -r "$MASTER_DIR/HEARTBEAT.md" "$BACKUP_POINT/" 2>/dev/null || true
cp -r "$OPENCLAW_HOME/openclaw.json" "$BACKUP_POINT/" 2>/dev/null || true
log_info "✓ 回滚点已创建"

# 3. 恢复架构配置
log_step "恢复架构配置..."
if [ -f "$FRAMEWORK_BUNDLE/architecture.tar.gz" ]; then
    tar -xzf "$FRAMEWORK_BUNDLE/architecture.tar.gz" \
        -C "$WORKSPACE_ROOT/agents/"
    log_info "✓ 架构配置已恢复"
else
    log_warn "⚠ 架构备份文件不存在，跳过"
fi

# 4. 恢复工作流程
log_step "恢复工作流程..."
if [ -f "$FRAMEWORK_BUNDLE/workflows.tar.gz" ]; then
    mkdir -p "$MASTER_DIR/memory"
    tar -xzf "$FRAMEWORK_BUNDLE/workflows.tar.gz" \
        -C "$MASTER_DIR/memory/"
    log_info "✓ 工作流程已恢复"
else
    log_warn "⚠ 工作流程备份文件不存在，跳过"
fi

# 5. 恢复 Skills
log_step "恢复 Skills..."
if [ -f "$FRAMEWORK_BUNDLE/skills.tar.gz" ]; then
    tar -xzf "$FRAMEWORK_BUNDLE/skills.tar.gz" \
        -C "$MASTER_DIR/"
    log_info "✓ Skills 已恢复"
else
    log_info "ℹ️  无 Skills 备份，跳过"
fi

# 6. 保留系统配置
log_step "验证系统配置..."
if [ -f "$OPENCLAW_HOME/openclaw.json" ]; then
    log_info "✓ openclaw.json 保持不变"
else
    log_warn "⚠ openclaw.json 不存在，可能需要重新配置"
fi

# 7. 修复权限
log_step "修复权限..."
chown -R root:root "$MASTER_DIR" 2>/dev/null || true
chmod -R 755 "$MASTER_DIR" 2>/dev/null || true
log_info "✓ 权限已修复"

# 8. 启动 Gateway
log_step "启动 Gateway..."
systemctl --user start openclaw-gateway
sleep 3

if systemctl --user is-active openclaw-gateway >/dev/null 2>&1; then
    log_info "✓ Gateway 运行正常"
else
    log_error "❌ Gateway 启动失败！"
    echo ""
    log_warn "🔄 准备回滚..."
    
    # 回滚操作
    cp "$BACKUP_POINT/AGENTS.md" "$MASTER_DIR/" 2>/dev/null || true
    cp "$BACKUP_POINT/SOUL.md" "$MASTER_DIR/" 2>/dev/null || true
    cp "$BACKUP_POINT/TOOLS.md" "$MASTER_DIR/" 2>/dev/null || true
    cp "$BACKUP_POINT/openclaw.json" "$OPENCLAW_HOME/" 2>/dev/null || true
    
    systemctl --user start openclaw-gateway
    
    if systemctl --user is-active openclaw-gateway >/dev/null 2>&1; then
        log_info "✓ 已回滚到恢复前状态"
    else
        log_error "❌ 回滚失败！请手动检查配置"
    fi
    
    exit 1
fi

# 9. 验证功能
log_step "验证系统功能..."
echo ""
echo "恢复完成检查清单:"
echo "  [ ] Gateway 服务运行正常"
echo "  [ ] 飞书消息可以正常发送/接收"
echo "  [ ] Agent 配置完整"
echo "  [ ] 工作流程正常加载"
echo ""
log_info "请手动验证上述项目"

# 10. 显示摘要
echo ""
echo "=========================================="
echo "   框架基线恢复完成！"
echo "=========================================="
echo ""
log_info "恢复内容:"
echo "  ✓ Agent 架构配置"
echo "  ✓ 工作流程模板"
echo "  ✓ Skills (如包含)"
echo ""
log_info "保留内容:"
echo "  ✓ openclaw.json (系统配置)"
echo "  ✓ 记忆数据 (daily, short_term)"
echo "  ✓ Agent 独立配置"
echo ""
log_info "回滚点：$BACKUP_POINT"
echo ""
log_info "后续步骤:"
echo "  1. 配置新赛道角色 (编辑 AGENTS.md)"
echo "  2. 发送测试消息验证"
echo "  3. 开始新赛道工作"
echo ""
echo "=========================================="

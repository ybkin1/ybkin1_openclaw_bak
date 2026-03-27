#!/bin/bash
# =============================================================================
# OpenClaw 架构改进合并脚本 v1.0
# 
# 用途：将架构改进合并到框架基线
# 特点：独立运行，不影响现有完整备份策略
# 创建：2026-03-25
# =============================================================================

set -euo pipefail

#=========== 配置区 ===========
FRAMEWORK_LATEST="/root/.openclaw/backups-unified/framework_latest"
BACKUP_ROOT="/root/.openclaw/backups-unified"

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
    echo "用法：$0 <improvements_dir>"
    echo ""
    echo "参数:"
    echo "  improvements_dir  改进提取目录（包含 patch 文件和配置）"
    echo ""
    echo "示例:"
    echo "  $0 /tmp/framework_improvements_12345"
    echo ""
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

IMPROVEMENTS_DIR="$1"

if [ ! -d "$IMPROVEMENTS_DIR" ]; then
    log_error "改进目录不存在：$IMPROVEMENTS_DIR"
    exit 1
fi

#=========== 安全确认 ===========
echo ""
echo "=========================================="
echo "   OpenClaw 架构改进合并工具 v1.0"
echo "=========================================="
echo ""
log_warn "⚠️  警告：这将更新框架基线"
echo ""
echo "改进来源：$IMPROVEMENTS_DIR"
echo "目标基线：$FRAMEWORK_LATEST"
echo ""

read -p "是否已审查改进内容？(y/n): " confirm_review
if [ "$confirm_review" != "y" ]; then
    log_info "请先审查改进报告："
    echo "  cat $IMPROVEMENTS_DIR/improvements_report.md"
    exit 1
fi

echo ""
read -p "是否继续合并？(y/n): " confirm
if [ "$confirm" != "y" ]; then
    log_error "已取消合并"
    exit 1
fi

#=========== 合并流程 ===========
echo ""
log_step "开始合并架构改进..."

# 1. 创建基线备份（回滚点）
BACKUP_POINT="$BACKUP_ROOT/framework_latest_backup_$(date +%Y%m%d_%H%M%S)"
log_step "创建基线备份：$BACKUP_POINT"
if [ -d "$FRAMEWORK_LATEST" ]; then
    cp -r "$FRAMEWORK_LATEST" "$BACKUP_POINT"
    log_info "✓ 基线备份已创建"
else
    log_warn "⚠ 基线不存在，将创建新基线"
    mkdir -p "$FRAMEWORK_LATEST"
fi

# 2. 审查并合并架构改进
log_step "合并架构配置..."
if [ -f "$IMPROVEMENTS_DIR/arch_diff.patch" ] && [ -s "$IMPROVEMENTS_DIR/arch_diff.patch" ]; then
    echo "差异文件：$IMPROVEMENTS_DIR/arch_diff.patch"
    echo ""
    echo "预览变更（前 20 行）:"
    head -20 "$IMPROVEMENTS_DIR/arch_diff.patch"
    echo ""
    
    read -p "是否应用架构变更？(y/n): " apply_arch
    if [ "$apply_arch" = "y" ]; then
        # 手动应用变更（需要用户确认）
        log_info "请手动审查并应用变更："
        echo "  cd /root/.openclaw/workspace/agents/master"
        echo "  patch -p1 < $IMPROVEMENTS_DIR/arch_diff.patch"
        echo ""
        log_info "应用后执行框架备份更新基线"
    else
        log_info "跳过架构变更"
    fi
else
    log_info "无架构变更"
fi

# 3. 合并记忆结构改进
log_step "合并记忆结构..."
if [ -f "$IMPROVEMENTS_DIR/memory_config_diff.patch" ] && [ -s "$IMPROVEMENTS_DIR/memory_config_diff.patch" ]; then
    echo "差异文件：$IMPROVEMENTS_DIR/memory_config_diff.patch"
    echo ""
    
    read -p "是否应用记忆结构变更？(y/n): " apply_mem
    if [ "$apply_mem" = "y" ]; then
        log_info "请手动审查并应用变更："
        echo "  cd /root/.openclaw/workspace/agents/master/memory"
        echo "  patch -p1 < $IMPROVEMENTS_DIR/memory_config_diff.patch"
        echo ""
        log_info "应用后执行框架备份更新基线"
    else
        log_info "跳过记忆结构变更"
    fi
else
    log_info "无记忆结构变更"
fi

# 4. 复制新配置模板
log_step "更新配置模板..."
if [ -d "$IMPROVEMENTS_DIR/config_current" ]; then
    read -p "是否更新配置模板？(y/n): " apply_config
    if [ "$apply_config" = "y" ]; then
        # 备份当前配置
        if [ -d "/root/.openclaw/workspace/agents/master/memory/config" ]; then
            cp -r "/root/.openclaw/workspace/agents/master/memory/config" \
                "/tmp/config_backup_$(date +%Y%m%d_%H%M%S)"
        fi
        
        # 更新配置
        cp -r "$IMPROVEMENTS_DIR/config_current/"* \
            "/root/.openclaw/workspace/agents/master/memory/config/" 2>/dev/null || true
        log_info "✓ 配置模板已更新"
    else
        log_info "跳过配置模板更新"
    fi
else
    log_info "无新配置模板"
fi

# 5. 执行框架备份（更新基线）
log_step "更新框架基线..."
echo ""
read -p "是否执行框架备份以更新基线？(y/n): " run_backup
if [ "$run_backup" = "y" ]; then
    if [ -x "$BACKUP_ROOT/backup-framework.sh" ]; then
        bash "$BACKUP_ROOT/backup-framework.sh"
        
        # 更新 framework_latest 软链接
        local latest_backup=$(ls -1d "$BACKUP_ROOT/framework_bak_"* 2>/dev/null | sort | tail -1)
        if [ -n "$latest_backup" ] && [ -d "$latest_backup" ]; then
            rm -rf "$FRAMEWORK_LATEST"
            ln -sf "$latest_backup" "$FRAMEWORK_LATEST"
            log_info "✓ 框架基线已更新：$FRAMEWORK_LATEST"
        fi
    else
        log_error "备份脚本不存在或不可执行"
    fi
else
    log_info "跳过基线更新"
fi

#=========== 显示摘要 ===========
show_summary() {
    echo ""
    echo "=========================================="
    echo "   架构改进合并完成！"
    echo "=========================================="
    echo ""
    log_info "回滚点：$BACKUP_POINT"
    echo ""
    
    if [ -d "$FRAMEWORK_LATEST" ]; then
        log_info "框架基线：$FRAMEWORK_LATEST"
        echo ""
        log_info "基线内容:"
        ls -lh "$FRAMEWORK_LATEST/"*.tar.gz 2>/dev/null | while read line; do
            echo "  $line"
        done
    fi
    
    echo ""
    log_info "后续步骤:"
    echo "  1. 验证框架基线：openclaw doctor"
    echo "  2. 测试赛道切换：bash restore-framework-safe.sh <framework_bak>"
    echo "  3. 清理临时文件：rm -rf $IMPROVEMENTS_DIR"
    echo ""
    echo "=========================================="
}

#=========== 主流程 ===========
main() {
    check_prerequisites
    merge_improvements
    show_summary
    
    log_info "✅ 所有操作完成！"
}

# 执行主流程
main "$@"

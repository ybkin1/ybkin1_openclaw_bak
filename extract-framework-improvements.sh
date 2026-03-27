#!/bin/bash
# =============================================================================
# OpenClaw 架构改进提取脚本 v1.0
# 
# 用途：从赛道备份中提取架构改进，用于更新框架基线
# 特点：独立运行，不影响现有完整备份策略
# 创建：2026-03-25
# =============================================================================

set -euo pipefail

#=========== 配置区 ===========
MASTER_DIR="/root/.openclaw/workspace/agents/master"
FRAMEWORK_LATEST="/root/.openclaw/backups-unified/framework_latest"
WORK_DIR="/tmp/framework_improvements_$$"

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
    echo "用法：$0 <domain_name>"
    echo ""
    echo "参数:"
    echo "  domain_name  赛道名称 (如：server-ops, media, stock)"
    echo ""
    echo "示例:"
    echo "  $0 server-ops"
    echo ""
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

DOMAIN="$1"

#=========== 检查 ===========
check_prerequisites() {
    log_step "检查前置条件..."
    
    if [ ! -d "$MASTER_DIR" ]; then
        log_error "Master 目录不存在"
        exit 1
    fi
    
    if [ ! -d "$FRAMEWORK_LATEST" ]; then
        log_warn "⚠️  框架基线不存在，将创建新的基线"
        log_info "提示：先执行 backup-framework.sh 创建基线"
        # 不退出，继续执行
    fi
    
    mkdir -p "$WORK_DIR"
    log_info "✓ 前置检查通过"
}

#=========== 提取改进 ===========
extract_improvements() {
    log_step "从 '$DOMAIN' 赛道提取架构改进..."
    
    # 1. 比较架构差异
    log_info "📊 比较架构配置差异..."
    if [ -d "$FRAMEWORK_LATEST" ] && [ -f "$FRAMEWORK_LATEST/architecture.tar.gz" ]; then
        # 解压基线架构用于比较
        mkdir -p "$WORK_DIR/framework_arch"
        tar -xzf "$FRAMEWORK_LATEST/architecture.tar.gz" -C "$WORK_DIR/framework_arch" 2>/dev/null || true
        
        # 生成差异
        diff -ruN \
            "$WORK_DIR/framework_arch/agents/master/" \
            "$MASTER_DIR/" \
            --exclude='memory' \
            --exclude='*.lock' \
            > "$WORK_DIR/arch_diff.patch" 2>/dev/null || true
        
        local arch_lines=$(wc -l < "$WORK_DIR/arch_diff.patch" || echo "0")
        log_info "  架构差异：$arch_lines 行"
    else
        log_info "  无基线对比，将创建完整架构备份"
        touch "$WORK_DIR/arch_diff.patch"
    fi
    
    # 2. 比较记忆结构差异（仅 config/）
    log_info "📊 比较记忆结构差异..."
    if [ -d "$FRAMEWORK_LATEST" ] && [ -f "$FRAMEWORK_LATEST/workflows.tar.gz" ]; then
        mkdir -p "$WORK_DIR/framework_workflows"
        tar -xzf "$FRAMEWORK_LATEST/workflows.tar.gz" -C "$WORK_DIR/framework_workflows" 2>/dev/null || true
        
        if [ -d "$MASTER_DIR/memory/config" ]; then
            diff -ruN \
                "$WORK_DIR/framework_workflows/config/" \
                "$MASTER_DIR/memory/config/" \
                > "$WORK_DIR/memory_config_diff.patch" 2>/dev/null || true
            
            local mem_lines=$(wc -l < "$WORK_DIR/memory_config_diff.patch" || echo "0")
            log_info "  记忆结构差异：$mem_lines 行"
        else
            log_warn "  memory/config 不存在"
            touch "$WORK_DIR/memory_config_diff.patch"
        fi
    else
        log_info "  无基线对比"
        touch "$WORK_DIR/memory_config_diff.patch"
    fi
    
    # 3. 提取新增的配置模板
    log_info "📋 提取新增配置模板..."
    if [ -d "$MASTER_DIR/memory/config" ]; then
        cp -r "$MASTER_DIR/memory/config/" "$WORK_DIR/config_current/"
        log_info "✓ 配置模板已复制"
    fi
    
    # 4. 生成改进报告
    log_info "📄 生成改进报告..."
    cat > "$WORK_DIR/improvements_report.md" << REPORT
# 架构改进报告

**来源赛道**: $DOMAIN  
**提取时间**: $(date -Iseconds)  
**工作目录**: $WORK_DIR

## 发现的改进

### 1. 架构配置变更

**差异文件**: arch_diff.patch  
**变更行数**: $(wc -l < "$WORK_DIR/arch_diff.patch") 行

主要变更:
$(grep -E "^\+[^+]" "$WORK_DIR/arch_diff.patch" 2>/dev/null | head -20 || echo "无显著变更")

### 2. 记忆结构变更

**差异文件**: memory_config_diff.patch  
**变更行数**: $(wc -l < "$WORK_DIR/memory_config_diff.patch") 行

主要变更:
$(grep -E "^\+[^+]" "$WORK_DIR/memory_config_diff.patch" 2>/dev/null | head -20 || echo "无显著变更")

### 3. 新增配置模板

**位置**: $WORK_DIR/config_current/

文件列表:
$(ls -1 "$WORK_DIR/config_current/" 2>/dev/null || echo "无")

## 建议操作

1. **审查差异文件**
   ```bash
   # 查看架构差异
   cat $WORK_DIR/arch_diff.patch
   
   # 查看记忆结构差异
   cat $WORK_DIR/memory_config_diff.patch
   ```

2. **确认改进内容**
   - 确认哪些改进应该合并到框架基线
   - 排除赛道特定的配置

3. **合并到框架基线**
   ```bash
   # 使用合并脚本
   bash /root/.openclaw/backups-unified/merge-to-framework.sh $WORK_DIR/
   ```

4. **验证合并结果**
   ```bash
   # 执行框架备份
   bash /root/.openclaw/backups-unified/backup-framework.sh
   
   # 验证新基线
   openclaw doctor
   ```

## 注意事项

- ⚠️ 仔细审查差异，避免将赛道特定数据混入框架
- ⚠️ 确保改进是通用的，适用于所有赛道
- ⚠️ 合并前创建当前基线的备份
REPORT
    
    log_info "✓ 改进报告已生成"
}

#=========== 显示摘要 ===========
show_summary() {
    echo ""
    echo "=========================================="
    echo "   架构改进提取完成！"
    echo "=========================================="
    echo ""
    log_info "工作目录：$WORK_DIR"
    echo ""
    log_info "生成的文件:"
    ls -lh "$WORK_DIR/"*.patch "$WORK_DIR/"*.md 2>/dev/null | while read line; do
        echo "  $line"
    done
    echo ""
    log_info "后续步骤:"
    echo "  1. 审查改进报告：cat $WORK_DIR/improvements_report.md"
    echo "  2. 查看差异：cat $WORK_DIR/arch_diff.patch"
    echo "  3. 合并到基线：bash /root/.openclaw/backups-unified/merge-to-framework.sh $WORK_DIR/"
    echo ""
    echo "=========================================="
}

#=========== 清理 ===========
cleanup() {
    # 不自动清理，保留供用户审查
    log_info "工作目录已保留供审查：$WORK_DIR"
    log_info "清理命令：rm -rf $WORK_DIR"
}

#=========== 主流程 ===========
main() {
    echo ""
    echo "=========================================="
    echo "   OpenClaw 架构改进提取工具 v1.0"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    extract_improvements
    show_summary
    cleanup
    
    log_info "✅ 所有操作完成！"
}

# 执行主流程
main "$@"

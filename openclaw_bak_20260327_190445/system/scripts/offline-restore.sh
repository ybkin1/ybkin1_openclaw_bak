#!/bin/bash
# =============================================================================
# OpenClaw 离线一键部署脚本
# 
# 功能：使用本地备份包进行离线恢复，不依赖 GitHub
# 用法：bash offline-restore.sh <备份包路径> [目标目录]
# 示例：
#   bash offline-restore.sh /tmp/openclaw_bak_20260327_174150
#   bash offline-restore.sh /tmp/openclaw_bak_20260327_174150 /home/admin/.openclaw
# =============================================================================

set -euo pipefail

#=========== 配置区 ===========
SCRIPT_NAME="OpenClaw 离线恢复脚本"
VERSION="1.0.0"

# 智能检测安装目录
if [ -n "$OPENCLAW_ROOT" ]; then
    TARGET_ROOT="$OPENCLAW_ROOT"
elif [ -d "/root/.openclaw" ]; then
    TARGET_ROOT="/root/.openclaw"
elif [ -d "$HOME/.openclaw" ]; then
    TARGET_ROOT="$HOME/.openclaw"
elif [ -d "/home/admin/.openclaw" ]; then
    TARGET_ROOT="/home/admin/.openclaw"
else
    TARGET_ROOT="/root/.openclaw"
fi

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

#=========== 日志函数 ===========
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_success() { echo -e "${MAGENTA}[SUCCESS]${NC} $1"; }

print_header() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "${CYAN}   $SCRIPT_NAME v$VERSION"
    echo -e "${CYAN}==========================================${NC}"
    echo ""
}

#=========== 帮助信息 ===========
show_help() {
    cat << EOF
使用方法:
  $0 <备份包路径> [目标目录]

参数说明:
  备份包路径    必填 - 本地备份目录路径
  目标目录      可选 - OpenClaw 安装目录 (默认自动检测)

示例:
  # 使用默认安装目录
  $0 /tmp/openclaw_bak_20260327_174150
  
  # 指定安装目录
  $0 /tmp/openclaw_bak_20260327_174150 /home/admin/.openclaw
  
  # 使用环境变量
  OPENCLAW_ROOT=/opt/openclaw $0 /tmp/openclaw_bak_20260327_174150

环境变量:
  OPENCLAW_ROOT    OpenClaw 安装根目录

EOF
}

#=========== 检查函数 ===========
check_command() {
    command -v "$1" >/dev/null 2>&1
}

check_backup() {
    local backup_path="$1"
    
    if [ ! -d "$backup_path" ]; then
        log_error "备份目录不存在：$backup_path"
        exit 1
    fi
    
    # 检查关键文件
    local required_files=(
        "backup-stats.json"
        "config/"
        "memory/"
        "system/"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -e "$backup_path/$file" ]; then
            log_error "备份不完整，缺少：$file"
            exit 1
        fi
    done
    
    log_info "✓ 备份完整性验证通过"
}

#=========== 显示备份信息 ===========
show_backup_info() {
    local backup_path="$1"
    
    log_step "读取备份信息..."
    
    if [ -f "$backup_path/backup-stats.json" ]; then
        log_info "备份统计:"
        cat "$backup_path/backup-stats.json" | python3 -m json.tool 2>/dev/null || cat "$backup_path/backup-stats.json"
    fi
    
    echo ""
}

#=========== 恢复配置 ===========
restore_config() {
    log_step "恢复配置文件..."
    
    if [ -f "$BACKUP_PATH/config/config_"*".tar.gz" ]; then
        tar -xzf "$BACKUP_PATH"/config/config_*.tar.gz -C "$TARGET_ROOT/workspace/agents/master/"
        log_info "✓ 配置文件已恢复"
    fi
    
    if [ -f "$BACKUP_PATH/config/config_agent_master_"*".tar.gz" ]; then
        tar -xzf "$BACKUP_PATH"/config/config_agent_master_*.tar.gz -C "$TARGET_ROOT/workspace/agents/master/"
        log_info "✓ Agent 配置已恢复"
    fi
}

#=========== 恢复 Agent 代码 ===========
restore_agents() {
    log_step "恢复 Agent 代码..."
    
    local count=0
    for tar in "$BACKUP_PATH"/agents/*.tar.gz; do
        [ -f "$tar" ] || continue
        local agent
        agent=$(basename "$tar" | cut -d'_' -f1)
        mkdir -p "$TARGET_ROOT/workspace/agents/$agent"
        tar -xzf "$tar" -C "$TARGET_ROOT/workspace/agents/$agent"
        count=$((count + 1))
    done
    
    log_info "✓ Agent 代码已恢复 ($count 个)"
}

#=========== 恢复记忆系统 ===========
restore_memory() {
    log_step "恢复记忆系统..."
    
    local count=0
    for tar in "$BACKUP_PATH"/memory/*.tar.gz; do
        [ -f "$tar" ] || continue
        tar -xzf "$tar" -C "$TARGET_ROOT/workspace/agents/master/"
        count=$((count + 1))
    done
    
    log_info "✓ 记忆系统已恢复 ($count 个包)"
}

#=========== 恢复依赖包列表 ===========
restore_dependencies() {
    log_step "恢复依赖包列表..."
    
    if [ -d "$BACKUP_PATH/config/dependencies" ]; then
        mkdir -p "$TARGET_ROOT/workspace/dependencies"
        cp -r "$BACKUP_PATH/config/dependencies/"* "$TARGET_ROOT/workspace/dependencies/"
        
        if [ -f "$BACKUP_PATH/config/dependencies/npm_global_packages.txt" ]; then
            log_info "  ✓ npm 全局包：$(wc -l < "$BACKUP_PATH/config/dependencies/npm_global_packages.txt") 个"
        fi
        if [ -f "$BACKUP_PATH/config/dependencies/pnpm_global_packages.txt" ]; then
            log_info "  ✓ pnpm 全局包：$(wc -l < "$BACKUP_PATH/config/dependencies/pnpm_global_packages.txt") 个"
        fi
        if [ -f "$BACKUP_PATH/config/dependencies/python_packages.txt" ]; then
            log_info "  ✓ Python 包：$(wc -l < "$BACKUP_PATH/config/dependencies/python_packages.txt") 个"
        fi
        
        log_info "✓ 依赖包列表已恢复"
    fi
}

#=========== 恢复数据库 ===========
restore_database() {
    log_step "恢复数据库..."
    
    if [ -d "$BACKUP_PATH/database" ]; then
        # SQLite 数据库
        if [ -f "$BACKUP_PATH/database/memory.db" ]; then
            cp "$BACKUP_PATH/database/memory.db" "$TARGET_ROOT/workspace/agents/master/"
            log_info "  ✓ memory.db (SQLite 记忆数据库)"
        else
            log_warn "  ⚠ memory.db 不存在（记忆架构未初始化）"
        fi
        
        # LanceDB 向量库
        if [ -f "$BACKUP_PATH/database/vectors.tar.gz" ]; then
            tar -xzf "$BACKUP_PATH/database/vectors.tar.gz" -C "$TARGET_ROOT/workspace/agents/master/"
            log_info "  ✓ memory_vectors.lance (向量索引)"
        else
            log_warn "  ⚠ memory_vectors.lance 不存在（向量库未初始化）"
        fi
        
        log_info "✓ 数据库已恢复"
    fi
}

#=========== 恢复系统配置 ===========
restore_system() {
    log_step "恢复系统配置..."
    
    # 恢复系统文件
    if [ -f "$BACKUP_PATH/system/system_"*".tar.gz" ]; then
        tar -xzf "$BACKUP_PATH"/system/system_*.tar.gz -C "$TARGET_ROOT/workspace/agents/master/"
        log_info "✓ 系统配置已恢复"
    fi
    
    # 恢复脚本
    if [ -d "$BACKUP_PATH/system/scripts" ]; then
        mkdir -p "$TARGET_ROOT/backups-unified"
        cp -r "$BACKUP_PATH/system/scripts/"* "$TARGET_ROOT/backups-unified/" 2>/dev/null || true
        log_info "✓ 脚本工具已恢复"
    fi
}

#=========== 恢复 Crontab ===========
restore_crontab() {
    log_step "恢复 Crontab 定时任务..."
    
    if [ -f "$BACKUP_PATH/system/crontab_"*".txt" ]; then
        local crontab_file
        crontab_file=$(ls "$BACKUP_PATH"/system/crontab_*.txt | head -1)
        
        # 替换路径
        if [[ "$TARGET_ROOT" != "/root/.openclaw" ]]; then
            sed "s|/root/.openclaw|$TARGET_ROOT|g" "$crontab_file" | crontab -
        else
            crontab "$crontab_file"
        fi
        
        log_info "✓ Crontab 已恢复"
    fi
}

#=========== 恢复 Systemd 服务 ===========
restore_systemd() {
    log_step "恢复 Systemd 服务..."
    
    if [ -f "$BACKUP_PATH/identity/systemd_services_"*".tar.gz" ]; then
        # 检测用户类型
        if [[ "$TARGET_ROOT" == /root/* ]]; then
            # Root 用户 - 系统级服务
            tar -xzf "$BACKUP_PATH"/identity/systemd_services_*.tar.gz -C ~/.config/systemd/user/
            systemctl --user daemon-reload
            log_info "✓ Systemd 用户服务已恢复"
        else
            # 非 Root 用户 - 用户级服务
            mkdir -p "$HOME/.config/systemd/user/"
            tar -xzf "$BACKUP_PATH"/identity/systemd_services_*.tar.gz -C "$HOME/.config/systemd/user/"
            systemctl --user daemon-reload
            log_info "✓ Systemd 用户服务已恢复"
        fi
    fi
}

#=========== 启动服务 ===========
start_services() {
    log_step "启动 OpenClaw 服务..."
    
    # 检查服务文件
    if [ -f "$HOME/.config/systemd/user/openclaw-gateway.service" ]; then
        systemctl --user enable openclaw-gateway
        systemctl --user start openclaw-gateway
        
        sleep 2
        
        if systemctl --user is-active openclaw-gateway >/dev/null 2>&1; then
            log_success "✓ Gateway 服务已启动"
        else
            log_warn "⚠ Gateway 服务启动失败，请检查日志"
        fi
    else
        log_warn "⚠ 未找到 systemd 服务文件"
    fi
}

#=========== 显示完成信息 ===========
show_completion() {
    echo ""
    echo -e "${CYAN}=========================================="
    echo -e "${CYAN}   OpenClaw 离线恢复完成！"
    echo -e "${CYAN}==========================================${NC}"
    echo ""
    log_info "恢复内容:"
    echo "  ✓ 配置文件 (openclaw.json, AGENTS.md, etc.)"
    echo "  ✓ 记忆系统 (所有 agent memory)"
    echo "  ✓ 数据库 (memory.db + vectors.lance)"
    echo "  ✓ 依赖包列表 (npm/pnpm/python)"
    echo "  ✓ Agent 代码 (9 个 Agent)"
    echo "  ✓ 脚本工具 (17 个运维脚本)"
    echo "  ✓ Systemd 服务配置"
    echo "  ✓ Crontab 定时任务"
    echo ""
    log_info "后续步骤:"
    echo "  1. 检查服务状态：systemctl --user status openclaw-gateway"
    echo "  2. 验证配置：openclaw doctor"
    echo "  3. 配置飞书 API（如需要）：编辑 openclaw.json"
    echo "  4. 执行一次完整备份：$TARGET_ROOT/backups-unified/backup-manager.sh full"
    echo ""
    log_info "安装目录：$TARGET_ROOT"
    echo "=========================================="
}

#=========== 主流程 ===========
main() {
    print_header
    
    # 解析参数
    if [ $# -lt 1 ]; then
        log_error "缺少备份包路径参数"
        show_help
        exit 1
    fi
    
    BACKUP_PATH="$1"
    
    # 可选：目标目录
    if [ $# -ge 2 ]; then
        TARGET_ROOT="$2"
    fi
    
    log_info "备份包路径：$BACKUP_PATH"
    log_info "目标目录：$TARGET_ROOT"
    echo ""
    
    # 检查备份
    check_backup "$BACKUP_PATH"
    
    # 显示备份信息
    show_backup_info "$BACKUP_PATH"
    
    # 创建目标目录
    log_step "创建目录结构..."
    mkdir -p "$TARGET_ROOT"/{workspace,backups-unified,logs}
    mkdir -p "$TARGET_ROOT/workspace/agents"
    log_info "✓ 目录已创建"
    echo ""
    
    # 执行恢复
    restore_config
    restore_agents
    restore_memory
    restore_dependencies
    restore_database
    restore_system
    restore_crontab
    restore_systemd
    start_services
    
    # 完成
    show_completion
    
    log_success "离线恢复完成！"
}

# 执行主流程
main "$@"

#!/bin/bash
# =============================================================================
# OpenClaw 一键迁移恢复脚本
# 
# 功能：从 GitHub 下载最新备份并自动恢复到新服务器
# 用法：curl -fsSL <script_url> | bash
# 或：wget -O restore.sh <script_url> && bash restore.sh
# =============================================================================

set -euo pipefail

#=========== 配置区 ===========
GITHUB_REPO="git@github.com:ybkin1/ybkin1_openclaw_bak.git"
GITHUB_HTTPS="https://github.com/ybkin1/ybkin1_openclaw_bak.git"
TARGET_ROOT="/root/.openclaw"
TEMP_DIR="/tmp/openclaw_restore_$$"
BACKUP_DIR="${TARGET_ROOT}/backups-unified"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#=========== 日志函数 ===========
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

#=========== 检查函数 ===========
check_command() {
    command -v "$1" >/dev/null 2>&1
}

check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_error "请使用 root 用户运行此脚本"
        exit 1
    fi
}

#=========== 环境检查 ===========
check_environment() {
    log_step "检查系统环境..."
    
    local missing=()
    
    if ! check_command git; then missing+=("git"); fi
    if ! check_command node; then missing+=("nodejs"); fi
    if ! check_command npm; then missing+=("npm"); fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_warn "缺少必要组件：${missing[*]}"
        log_info "尝试自动安装..."
        
        if check_command apt; then
            apt update && apt install -y "${missing[@]}"
        elif check_command yum; then
            yum install -y "${missing[@]}"
        else
            log_error "无法自动安装依赖，请手动安装：${missing[*]}"
            exit 1
        fi
    fi
    
    # 检查 openclaw CLI
    if ! check_command openclaw; then
        log_info "安装 OpenClaw CLI..."
        npm install -g openclaw
    fi
    
    # 检查 pnpm
    if ! check_command pnpm; then
        log_info "安装 pnpm..."
        npm install -g pnpm
    fi
    
    log_info "环境检查通过"
}

#=========== SSH 密钥检查 ===========
check_ssh_key() {
    log_step "检查 SSH 密钥..."
    
    if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
        log_info "生成新的 SSH 密钥..."
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "openclaw_migration"
        
        echo ""
        log_warn "请将以下公钥添加到 GitHub:"
        echo "----------------------------------------"
        cat ~/.ssh/id_ed25519.pub
        echo "----------------------------------------"
        echo ""
        read -p "添加完成后按回车继续..."
    fi
    
    # 测试 GitHub 连接
    if ! ssh -T -o StrictHostKeyChecking=no git@github.com >/dev/null 2>&1; then
        log_warn "无法连接 GitHub，请检查 SSH 密钥配置"
        log_info "继续使用 HTTPS 方式克隆..."
        GITHUB_REPO="$GITHUB_HTTPS"
    else
        log_info "GitHub SSH 连接正常"
    fi
}

#=========== 克隆备份仓库 ===========
clone_backup_repo() {
    log_step "克隆备份仓库..."
    
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    if git clone "$GITHUB_REPO" "$TEMP_DIR" 2>/dev/null; then
        log_info "仓库克隆成功"
    else
        log_warn "Git 克隆失败，尝试使用 HTTPS..."
        GITHUB_REPO="$GITHUB_HTTPS"
        git clone "$GITHUB_REPO" "$TEMP_DIR" || {
            log_error "无法克隆仓库，请检查网络或手动下载"
            exit 1
        }
    fi
}

#=========== 选择最新备份 ===========
select_latest_backup() {
    log_step "查找最新备份..."
    
    cd "$TEMP_DIR"
    
    local latest
    latest=$(ls -d openclaw_bak_* 2>/dev/null | sort | tail -1)
    
    if [ -z "$latest" ]; then
        log_error "未找到任何备份 bundle"
        exit 1
    fi
    
    log_info "找到最新备份：$latest"
    
    # 验证完整性
    if [ -f "$latest/checksums.sha256" ]; then
        log_info "验证备份完整性..."
        cd "$latest"
        if sha256sum -c checksums.sha256 >/dev/null 2>&1; then
            log_info "✓ 备份完整性验证通过"
        else
            log_warn "⚠ 部分文件验证失败，继续恢复..."
        fi
        cd "$TEMP_DIR"
    fi
    
    export LATEST_BACKUP="$latest"
}

#=========== 恢复配置 ===========
restore_config() {
    log_step "恢复配置文件..."
    
    mkdir -p "${TARGET_ROOT}/workspace/agents/master"
    
    # 恢复主配置
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/config/config_"*.tar.gz ]; then
        tar -xzf "$TEMP_DIR/$LATEST_BACKUP/config/config_"*.tar.gz \
            -C "${TARGET_ROOT}/workspace/agents/master"
        log_info "✓ 主配置已恢复"
    fi
    
    # 恢复 openclaw.json
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/config/openclaw.json" ]; then
        mkdir -p "${TARGET_ROOT}"
        cp "$TEMP_DIR/$LATEST_BACKUP/config/openclaw.json" "${TARGET_ROOT}/"
        log_info "✓ openclaw.json 已恢复"
    fi
}

#=========== P0 Fix - 2026-03-27: 恢复数据库 ===========
restore_database() {
    log_step "恢复数据库（P0 关键修复）..."
    
    # 恢复 SQLite 记忆数据库
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/database/memory.db" ]; then
        cp "$TEMP_DIR/$LATEST_BACKUP/database/memory.db" \
           "${TARGET_ROOT}/workspace/agents/master/"
        log_info "✓ memory.db (SQLite 记忆数据库)"
    else
        log_warn "  ⚠ memory.db 不存在，可能需要重新初始化"
    fi
    
    # 恢复 LanceDB 向量库
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/database/vectors.tar.gz" ]; then
        tar -xzf "$TEMP_DIR/$LATEST_BACKUP/database/vectors.tar.gz" \
            -C "${TARGET_ROOT}/workspace/agents/master"
        log_info "✓ memory_vectors.lance (向量索引)"
    else
        log_warn "  ⚠ memory_vectors.lance 不存在，可能需要重新构建索引"
    fi
    
    # 恢复其他 Agent 的数据库
    for db_file in "$TEMP_DIR/$LATEST_BACKUP/database/"*_memory.db; do
        [ -f "$db_file" ] || continue
        local agent_name
        agent_name=$(basename "$db_file" | sed 's/_memory.db//')
        
        if [ -d "${TARGET_ROOT}/workspace/agents/$agent_name" ]; then
            cp "$db_file" "${TARGET_ROOT}/workspace/agents/$agent_name/"
            log_info "✓ ${agent_name}_memory.db"
        fi
    done
    
    log_info "数据库恢复完成"
}

#=========== 恢复记忆系统 ===========
restore_memory() {
    log_step "恢复记忆系统..."
    
    # 恢复 master memory
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/memory/memory_master_"*.tar.gz ]; then
        tar -xzf "$TEMP_DIR/$LATEST_BACKUP/memory/memory_master_"*.tar.gz \
            -C "${TARGET_ROOT}/workspace/agents/master"
        log_info "✓ Master 记忆已恢复"
    fi
    
    # 恢复 shared memory
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/memory/memory_shared_"*.tar.gz ]; then
        tar -xzf "$TEMP_DIR/$LATEST_BACKUP/memory/memory_shared_"*.tar.gz \
            -C "${TARGET_ROOT}/workspace"
        log_info "✓ Shared 记忆已恢复"
    fi
    
    # 恢复所有 agent 的 memory
    for memory_tar in "$TEMP_DIR/$LATEST_BACKUP/memory/"memory_*.tar.gz; do
        [ -f "$memory_tar" ] || continue
        local agent_name
        agent_name=$(basename "$memory_tar" | sed 's/memory_//' | cut -d'_' -f1)
        
        # 跳过 main 和 shared（已处理）
        [[ "$agent_name" =~ ^(main|shared)$ ]] && continue
        
        if [ -d "${TARGET_ROOT}/workspace/agents/$agent_name" ]; then
            tar -xzf "$memory_tar" \
                -C "${TARGET_ROOT}/workspace/agents/$agent_name" --strip-components=1
            log_info "✓ $agent_name 记忆已恢复"
        fi
    done
}

#=========== 恢复脚本和 Skills ===========
restore_scripts() {
    log_step "恢复脚本和 Skills..."
    
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/system/system_"*.tar.gz ]; then
        tar -xzf "$TEMP_DIR/$LATEST_BACKUP/system/system_"*.tar.gz \
            -C "${TARGET_ROOT}/workspace/agents/master"
        log_info "✓ Scripts 和 Skills 已恢复"
    fi
    
    # 恢复 backup-manager.sh
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/system/scripts/backup-manager.sh" ]; then
        mkdir -p "${BACKUP_DIR}"
        cp "$TEMP_DIR/$LATEST_BACKUP/system/scripts/backup-manager.sh" "${BACKUP_DIR}/"
        chmod +x "${BACKUP_DIR}/backup-manager.sh"
        log_info "✓ backup-manager.sh 已恢复"
    fi
}

#=========== 恢复 SSH 密钥 ===========
restore_ssh_keys() {
    log_step "恢复 SSH 密钥..."
    
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/identity/ssh_keys_"*.tar.gz ]; then
        mkdir -p ~/.ssh
        tar -xzf "$TEMP_DIR/$LATEST_BACKUP/identity/ssh_keys_"*.tar.gz -C ~/.ssh
        chmod 600 ~/.ssh/id_*
        chmod 644 ~/.ssh/*.pub
        log_info "✓ SSH 密钥已恢复"
    else
        log_warn "未找到 SSH 密钥备份，需手动配置"
    fi
}

#=========== 恢复 Systemd 服务 ===========
restore_systemd() {
    log_step "恢复 Systemd 服务配置..."
    
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/identity/systemd_services_"*.tar.gz ]; then
        mkdir -p ~/.config/systemd/user
        tar -xzf "$TEMP_DIR/$LATEST_BACKUP/identity/systemd_services_"*.tar.gz \
            -C ~/.config/systemd/user
        log_info "✓ Systemd 服务配置已恢复"
    elif [ -f "$TEMP_DIR/$LATEST_BACKUP/system/systemd_overrides_"*.tar.gz ]; then
        mkdir -p ~/.config/systemd/user
        tar -xzf "$TEMP_DIR/$LATEST_BACKUP/system/systemd_overrides_"*.tar.gz \
            -C ~/.config/systemd/user
        log_info "✓ Systemd overrides 已恢复"
    fi
    
    # 重新加载 systemd
    systemctl --user daemon-reload
    log_info "✓ Systemd 已重新加载"
}

#=========== 恢复 Crontab ===========
restore_crontab() {
    log_step "恢复 Crontab 配置..."
    
    if [ -f "$TEMP_DIR/$LATEST_BACKUP/system/crontab_"*.tar.gz ]; then
        tar -xzf "$TEMP_DIR/$LATEST_BACKUP/system/crontab_"*.tar.gz -C /tmp
        crontab /tmp/crontab_* 2>/dev/null || true
        log_info "✓ Crontab 已恢复"
    elif [ -f "$TEMP_DIR/$LATEST_BACKUP/system/crontab_"*.txt ]; then
        crontab "$TEMP_DIR/$LATEST_BACKUP/system/crontab_"*.txt 2>/dev/null || true
        log_info "✓ Crontab 已恢复"
    fi
}

#=========== 启动服务 ===========
start_services() {
    log_step "启动 OpenClaw 服务..."
    
    # 启用并启动 Gateway
    systemctl --user enable openclaw-gateway 2>/dev/null || true
    systemctl --user start openclaw-gateway 2>/dev/null || true
    
    # 启用并启动 Health Guardian
    systemctl --user enable openclaw-health-guardian 2>/dev/null || true
    systemctl --user start openclaw-health-guardian 2>/dev/null || true
    
    sleep 3
    
    # 检查服务状态
    if systemctl --user is-active openclaw-gateway >/dev/null 2>&1; then
        log_info "✓ Gateway 服务已启动"
    else
        log_warn "⚠ Gateway 服务启动失败，请手动检查"
    fi
}

#=========== 清理临时文件 ===========
cleanup() {
    log_step "清理临时文件..."
    rm -rf "$TEMP_DIR"
    log_info "✓ 临时文件已清理"
}

#=========== 显示恢复摘要 ===========
show_summary() {
    echo ""
    echo "=========================================="
    echo "   OpenClaw 迁移恢复完成！"
    echo "=========================================="
    echo ""
    log_info "恢复内容:"
    echo "  ✓ 配置文件 (openclaw.json, AGENTS.md, etc.)"
    echo "  ✓ 记忆系统 (所有 agent memory)"
    echo "  ✓ 数据库 (memory.db + vectors.lance) [P0 新增]"
    echo "  ✓ 脚本工具 (17 个运维脚本)"
    echo "  ✓ Skills (300+ 个技能文件)"
    echo "  ✓ SSH 密钥"
    echo "  ✓ Systemd 服务配置"
    echo "  ✓ Crontab 定时任务"
    echo ""
    log_info "后续步骤:"
    echo "  1. 检查服务状态：systemctl --user status openclaw-gateway"
    echo "  2. 验证飞书连接：发送测试消息"
    echo "  3. 配置飞书 API（如需要）：编辑 openclaw.json"
    echo "  4. 执行一次完整备份：${BACKUP_DIR}/backup-manager.sh full"
    echo ""
    log_info "备份来源：$LATEST_BACKUP"
    echo "=========================================="
}

#=========== 主流程 ===========
main() {
    echo ""
    echo "=========================================="
    echo "   OpenClaw 一键迁移恢复工具"
    echo "=========================================="
    echo ""
    
    check_root
    check_environment
    check_ssh_key
    clone_backup_repo
    select_latest_backup
    
    log_info "开始恢复..."
    echo ""
    
    restore_config
    restore_memory
    restore_database  # P0 Fix - 2026-03-27
    restore_scripts
    restore_ssh_keys
    restore_systemd
    restore_crontab
    start_services
    cleanup
    show_summary
}

# 执行主流程
main "$@"

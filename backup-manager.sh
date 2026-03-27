#!/bin/bash
# Unified Backup Manager v2.0 - Bundle-based retention
# Single backup: openclaw_bak_<timestamp>/
# Keep latest 4 bundles, auto-delete older ones

set -euo pipefail

BACKUP_ROOT="/root/.openclaw/backups-unified"
WORKSPACE_ROOT="/root/.openclaw/workspace"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUNDLE_NAME="openclaw_bak_$TIMESTAMP"
BUNDLE_DIR="$BACKUP_ROOT/$BUNDLE_NAME"
PUSH_TO_GITHUB=false

# P1 Security Fix - 2026-03-25: 分级保留策略
# - 每日备份：保留 7 份
# - 每周备份：保留 4 份（每月第一个 bundle 标记为 weekly）
# - 每月备份：保留 12 份（永久归档关键配置）
RETAIN_DAILY=7
RETAIN_WEEKLY=4
RETAIN_MONTHLY=12

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# P2 Security Fix - 2026-03-25: 日志轮转 + 增量备份优化
# P3 Security Fix - 2026-03-25: 备份统计报告
LOG_DIR="${BACKUP_ROOT}/logs"
LOG_FILE="${LOG_DIR}/backup.log"
LOG_MAX_SIZE=10485760  # 10MB
LOG_KEEP_COUNT=5

# 统计报告配置
REPORT_FILE="${LOG_DIR}/backup-stats.json"
STATS_HISTORY="${BACKUP_ROOT}/.stats_history"

# 变更检测缓存文件
CACHE_FILE="${BACKUP_ROOT}/.backup_cache.json"

# 计算文件/目录的 checksum
calc_checksum() {
    local path="$1"
    if [ -d "$path" ]; then
        find "$path" -type f -exec sha256sum {} \; 2>/dev/null | sha256sum | cut -d' ' -f1
    elif [ -f "$path" ]; then
        sha256sum "$path" | cut -d' ' -f1
    else
        echo ""
    fi
}

# 检查是否有变更（增量备份优化）
has_changes() {
    local source_path="$1"
    local cache_key="$2"
    
    # 如果缓存不存在，认为有变更
    [ -f "$CACHE_FILE" ] || return 0
    
    local current_checksum
    current_checksum=$(calc_checksum "$source_path")
    [ -z "$current_checksum" ] && return 0
    
    local cached_checksum
    cached_checksum=$(jq -r ".\"$cache_key\" // \"\"" "$CACHE_FILE" 2>/dev/null)
    
    [ "$current_checksum" != "$cached_checksum" ] && return 0 || return 1
}

# 更新缓存
update_cache() {
    local source_path="$1"
    local cache_key="$2"
    
    local checksum
    checksum=$(calc_checksum "$source_path")
    [ -z "$checksum" ] && return 1
    
    # 初始化或更新缓存文件
    if [ -f "$CACHE_FILE" ]; then
        jq ".\"$cache_key\" = \"$checksum\"" "$CACHE_FILE" > "${CACHE_FILE}.tmp" && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
    else
        echo "{\"$cache_key\": \"$checksum\"}" > "$CACHE_FILE"
    fi
}

# 保存缓存到备份中（用于恢复）
save_cache_to_backup() {
    if [ -f "$CACHE_FILE" ]; then
        cp "$CACHE_FILE" "$BUNDLE_DIR/config/.backup_cache.json"
        log_info "备份缓存已保存"
    fi
}

# 智能备份单个 agent（带变更检测）
backup_agent_smart() {
    local agent="$1"
    local source_path
    local cache_key
    local output_file
    
    if [ "$agent" = "main" ]; then
        source_path="$WORKSPACE_ROOT/main"
        cache_key="agent_main"
        output_file="$BUNDLE_DIR/agents/main_$TIMESTAMP.tar.gz"
    else
        source_path="$WORKSPACE_ROOT/agents/$agent"
        cache_key="agent_$agent"
        output_file="$BUNDLE_DIR/agents/${agent}_$TIMESTAMP.tar.gz"
    fi
    
    # 检查是否有变更
    if ! has_changes "$source_path" "$cache_key"; then
        log_info "⊘ 跳过 $agent (无变更)"
        return 0
    fi
    
    log_info "备份 $agent (检测到变更)"
    tar -czf "$output_file" -C "$(dirname "$source_path")" "$(basename "$source_path")"
    update_cache "$source_path" "$cache_key"
}

rotate_backup_log() {
    mkdir -p "$LOG_DIR"
    [ -f "$LOG_FILE" ] || return 0
    
    local size
    size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    
    if [ "$size" -gt "$LOG_MAX_SIZE" ]; then
        log_info "备份日志达到 $((size / 1024 / 1024))MB，执行轮转"
        
        # 删除最旧的日志
        ls -t "${LOG_FILE}".*.gz 2>/dev/null | tail -n +${LOG_KEEP_COUNT} | xargs rm -f 2>/dev/null || true
        
        # 压缩当前日志
        gzip -c "$LOG_FILE" > "${LOG_FILE}.$(date +%Y%m%d%H%M%S).gz"
        
        # 清空当前日志（保留文件）
        > "$LOG_FILE"
        
        log_info "日志轮转完成"
    fi
}

# =============================================================================
# PHASE: Backup Statistics Report (P3 Security Fix - 2026-03-25)
# =============================================================================

# 生成单次备份统计
generate_backup_stats() {
    local bundle="$1"
    local stats_file="$2"
    
    log_info "生成备份统计报告..."
    
    local total_size=0
    local file_count=0
    local agents_size=0
    local memory_size=0
    local config_size=0
    local system_size=0
    
    # 计算各分类大小
    if [ -d "$bundle/agents" ]; then
        agents_size=$(du -sb "$bundle/agents" 2>/dev/null | cut -f1)
    fi
    
    if [ -d "$bundle/memory" ]; then
        memory_size=$(du -sb "$bundle/memory" 2>/dev/null | cut -f1)
    fi
    
    if [ -d "$bundle/config" ]; then
        config_size=$(du -sb "$bundle/config" 2>/dev/null | cut -f1)
    fi
    
    if [ -d "$bundle/system" ]; then
        system_size=$(du -sb "$bundle/system" 2>/dev/null | cut -f1)
    fi
    
    total_size=$((agents_size + memory_size + config_size + system_size))
    file_count=$(find "$bundle" -type f | wc -l)
    
    # 生成 JSON 统计
    cat > "$stats_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "bundle": "$(basename "$bundle")",
    "total_size_bytes": $total_size,
    "total_size_human": "$(numfmt --to=iec-i --suffix=B $total_size 2>/dev/null || echo "${total_size}B")",
    "file_count": $file_count,
    "breakdown": {
        "agents": {"bytes": $agents_size, "human": "$(numfmt --to=iec-i --suffix=B $agents_size 2>/dev/null || echo "${agents_size}B")"},
        "memory": {"bytes": $memory_size, "human": "$(numfmt --to=iec-i --suffix=B $memory_size 2>/dev/null || echo "${memory_size}B")"},
        "config": {"bytes": $config_size, "human": "$(numfmt --to=iec-i --suffix=B $config_size 2>/dev/null || echo "${config_size}B")"},
        "system": {"bytes": $system_size, "human": "$(numfmt --to=iec-i --suffix=B $system_size 2>/dev/null || echo "${system_size}B")"}
    }
}
EOF
    
    log_info "统计报告已生成：$stats_file"
}

# 生成历史趋势报告
generate_trend_report() {
    local output_file="${LOG_DIR}/backup-trend-report.txt"
    
    log_info "生成备份趋势报告..."
    
    # 获取所有 bundle 的统计
    local bundles=($(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "openclaw_bak_*" | sort -r))
    
    {
        echo "=========================================="
        echo "   备份系统趋势报告"
        echo "   生成时间：$(date '+%Y-%m-%d %H:%M:%S')"
        echo "=========================================="
        echo ""
        echo "最近备份统计:"
        echo "------------------------------------------"
        printf "%-25s %12s %8s\n" "备份名称" "大小" "文件数"
        echo "------------------------------------------"
        
        local count=0
        for bundle in "${bundles[@]}"; do
            [ $count -ge 10 ] && break  # 只显示最近 10 个
            
            local bundle_name=$(basename "$bundle")
            local total_size=$(du -sb "$bundle" 2>/dev/null | cut -f1)
            local size_human=$(numfmt --to=iec-i --suffix=B $total_size 2>/dev/null || echo "${total_size}B")
            local file_count=$(find "$bundle" -type f | wc -l)
            
            printf "%-25s %12s %8d\n" "$bundle_name" "$size_human" "$file_count"
            count=$((count + 1))
        done
        
        echo "------------------------------------------"
        echo ""
        
        # 计算总大小
        local grand_total=0
        for bundle in "${bundles[@]}"; do
            local size=$(du -sb "$bundle" 2>/dev/null | cut -f1)
            grand_total=$((grand_total + size))
        done
        
        echo "存储使用汇总:"
        echo "  备份总数：${#bundles[@]}"
        echo "  总占用空间：$(numfmt --to=iec-i --suffix=B $grand_total 2>/dev/null || echo "${grand_total}B")"
        echo "  平均每个备份：$(numfmt --to=iec-i --suffix=B $((grand_total / (${#bundles[@]} + 1))) 2>/dev/null || echo "N/A")"
        echo ""
        
        # 分类统计（最新备份）
        if [ ${#bundles[@]} -gt 0 ]; then
            local latest="${bundles[0]}"
            echo "最新备份分类占比:"
            
            local agents_size=$(du -sb "$latest/agents" 2>/dev/null | cut -f1 || echo 0)
            local memory_size=$(du -sb "$latest/memory" 2>/dev/null | cut -f1 || echo 0)
            local config_size=$(du -sb "$latest/config" 2>/dev/null | cut -f1 || echo 0)
            local system_size=$(du -sb "$latest/system" 2>/dev/null | cut -f1 || echo 0)
            local total=$((agents_size + memory_size + config_size + system_size))
            
            if [ $total -gt 0 ]; then
                local agents_pct=$((agents_size * 100 / total))
                local memory_pct=$((memory_size * 100 / total))
                local config_pct=$((config_size * 100 / total))
                local system_pct=$((system_size * 100 / total))
                
                printf "  %-10s %8s (%3d%%)\n" "Agents:" "$(numfmt --to=iec-i --suffix=B $agents_size 2>/dev/null)" $agents_pct
                printf "  %-10s %8s (%3d%%)\n" "Memory:" "$(numfmt --to=iec-i --suffix=B $memory_size 2>/dev/null)" $memory_pct
                printf "  %-10s %8s (%3d%%)\n" "Config:" "$(numfmt --to=iec-i --suffix=B $config_size 2>/dev/null)" $config_pct
                printf "  %-10s %8s (%3d%%)\n" "System:" "$(numfmt --to=iec-i --suffix=B $system_size 2>/dev/null)" $system_pct
            fi
        fi
        
        echo ""
        echo "=========================================="
        
    } > "$output_file"
    
    log_info "趋势报告已生成：$output_file"
}

# 保存统计历史
save_stats_history() {
    local stats_file="$1"
    
    mkdir -p "$(dirname "$STATS_HISTORY")"
    
    # 追加到历史文件
    if [ -f "$stats_file" ]; then
        echo "---" >> "$STATS_HISTORY"
        cat "$stats_file" >> "$STATS_HISTORY"
    fi
}

# Create bundle directory structure
mkdir -p "$BUNDLE_DIR"/{agents,memory,config,system}

# Parse arguments
BACKUP_TYPE="${1:-full}"
for arg in "$@"; do
    [ "$arg" = "--push" ] && PUSH_TO_GITHUB=true
done

log_info "Starting unified backup - $BUNDLE_NAME (type: $BACKUP_TYPE)"

# =============================================================================
# PHASE: Graded Retention Policy (P1 Security Fix - 2026-03-25)
# =============================================================================

# 判断备份是否为每月第一个（用于标记为 monthly）
is_monthly_backup() {
    local bundle_name="$1"
    # 提取日期部分：openclaw_bak_20260301_033001 → 20260301
    local date_part=$(echo "$bundle_name" | sed 's/openclaw_bak_//' | cut -d'_' -f1)
    local day=$(echo "$date_part" | cut -c7-8)
    
    # 每月的 1-7 日执行的备份标记为 monthly candidate
    [ "$day" -le 7 ] && return 0 || return 1
}

# 判断备份是否为每周第一个（用于标记为 weekly）
is_weekly_backup() {
    local bundle_name="$1"
    local date_part=$(echo "$bundle_name" | sed 's/openclaw_bak_//' | cut -d'_' -f1)
    local year=${date_part:0:4}
    local month=${date_part:4:2}
    local day=${date_part:6:2}
    
    # 使用 date 命令计算星期几（1=周一，7=周日）
    local weekday=$(date -d "$year-$month-$day" +%u 2>/dev/null || echo "1")
    
    # 周一的备份作为 weekly candidate
    [ "$weekday" = "1" ] && return 0 || return 1
}

# 分级清理策略
cleanup_graduated() {
    log_info "执行分级保留策略清理..."
    log_info "保留策略：每日${RETAIN_DAILY}份 + 每周${RETAIN_WEEKLY}份 + 每月${RETAIN_MONTHLY}份"
    
    # 获取所有 bundle，按时间排序
    local bundles=($(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "openclaw_bak_*" | sort))
    local total=${#bundles[@]}
    
    if [ "$total" -le "$RETAIN_DAILY" ]; then
        log_info "当前备份数量 ($total) ≤ 每日保留数 ($RETAIN_DAILY)，无需清理"
        return 0
    fi
    
    # 分类备份
    local -a daily_bundles=()
    local -a weekly_bundles=()
    local -a monthly_bundles=()
    local -a to_delete=()
    
    for bundle in "${bundles[@]}"; do
        bundle_name=$(basename "$bundle")
        
        if is_monthly_backup "$bundle_name"; then
            monthly_bundles+=("$bundle")
        elif is_weekly_backup "$bundle_name"; then
            weekly_bundles+=("$bundle")
        else
            daily_bundles+=("$bundle")
        fi
    done
    
    log_info "备份分类：每日${#daily_bundles[@]}份，每周${#weekly_bundles[@]}份，每月${#monthly_bundles[@]}份"
    
    # 清理超出的每日备份（保留最新的 RETAIN_DAILY 份）
    if [ ${#daily_bundles[@]} -gt "$RETAIN_DAILY" ]; then
        local to_remove=$((${#daily_bundles[@]} - RETAIN_DAILY))
        log_info "清理 ${to_remove} 份超期的每日备份"
        for ((i=0; i<to_remove; i++)); do
            to_delete+=("${daily_bundles[$i]}")
        done
    fi
    
    # 清理超出每周备份（保留最新的 RETAIN_WEEKLY 份）
    if [ ${#weekly_bundles[@]} -gt "$RETAIN_WEEKLY" ]; then
        local to_remove=$((${#weekly_bundles[@]} - RETAIN_WEEKLY))
        log_info "清理 ${to_remove} 份超期的每周备份"
        for ((i=0; i<to_remove; i++)); do
            to_delete+=("${weekly_bundles[$i]}")
        done
    fi
    
    # 清理超出每月备份（保留最新的 RETAIN_MONTHLY 份）
    if [ ${#monthly_bundles[@]} -gt "$RETAIN_MONTHLY" ]; then
        local to_remove=$((${#monthly_bundles[@]} - RETAIN_MONTHLY))
        log_info "清理 ${to_remove} 份超期的每月备份"
        for ((i=0; i<to_remove; i++)); do
            to_delete+=("${monthly_bundles[$i]}")
        done
    fi
    
    # 执行删除
    if [ ${#to_delete[@]} -gt 0 ]; then
        log_info "共删除 ${#to_delete[@]} 份备份"
        for bundle in "${to_delete[@]}"; do
            log_info "删除：$(basename "$bundle")"
            rm -rf "$bundle"
        done
    else
        log_info "无需清理，所有备份均在保留策略内"
    fi
}

# 兼容旧函数（保留但标记为废弃）
cleanup_old_bundles() {
    log_warn "cleanup_old_bundles 已废弃，使用 cleanup_graduated 替代"
    cleanup_graduated
}

# Discover all agent workspaces
discover_agents() {
    local agents=()
    
    # Check workspace/agents/ directory (primary location)
    if [ -d "$WORKSPACE_ROOT/agents" ]; then
        for agent_dir in "$WORKSPACE_ROOT/agents"/*/; do
            agent_name=$(basename "$agent_dir")
            # Skip 'master' since we'll add 'main' (symlink to master)
            if [ "$agent_name" != "master" ] && [ -f "$agent_dir/AGENTS.md" ]; then
                agents+=("$agent_name")
            fi
        done
    fi
    
    # Always include main (symlink to agents/master)
    if [ -d "$WORKSPACE_ROOT/main" ] && [ -f "$WORKSPACE_ROOT/main/AGENTS.md" ]; then
        agents+=("main")
    fi
    
    echo "${agents[@]}"
}

# =============================================================================
# PHASE: Identity & Credentials Backup (P4 Security Fix - 2026-03-25)
# =============================================================================
# Backup identity, credentials, extensions config, SSH keys, and systemd services
# This enables complete migration to new servers

# P0 Fix - 2026-03-27: 备份数据库（记忆架构核心数据）
backup_database() {
    log_info "备份数据库（P0 关键修复）..."
    mkdir -p "$BUNDLE_DIR/database"
    
    local db_count=0
    
    # 1. SQLite 记忆数据库
    if [ -f "$WORKSPACE_ROOT/agents/master/memory.db" ]; then
        cp "$WORKSPACE_ROOT/agents/master/memory.db" "$BUNDLE_DIR/database/"
        log_info "  ✓ memory.db (SQLite 记忆数据库)"
        db_count=$((db_count + 1))
    else
        log_warn "  ⚠ memory.db 不存在（记忆架构未初始化）"
    fi
    
    # 2. LanceDB 向量库
    if [ -d "$WORKSPACE_ROOT/agents/master/memory_vectors.lance" ]; then
        tar -czf "$BUNDLE_DIR/database/vectors.tar.gz" \
            -C "$WORKSPACE_ROOT/agents/master" memory_vectors.lance
        log_info "  ✓ memory_vectors.lance (向量索引)"
        db_count=$((db_count + 1))
    else
        log_warn "  ⚠ memory_vectors.lance 不存在（向量库未初始化）"
    fi
    
    # 3. 其他 Agent 的数据库（如果存在）
    for agent_dir in "$WORKSPACE_ROOT/agents"/*/; do
        agent_name=$(basename "$agent_dir")
        if [ -f "$agent_dir/memory.db" ]; then
            cp "$agent_dir/memory.db" "$BUNDLE_DIR/database/${agent_name}_memory.db"
            log_info "  ✓ ${agent_name}_memory.db"
            db_count=$((db_count + 1))
        fi
    done
    
    if [ $db_count -eq 0 ]; then
        log_warn "  ⚠ 未找到任何数据库文件（记忆架构尚未初始化）"
        log_info "  → 数据库目录已创建，初始化后将自动备份"
    else
        log_info "  ✓ 共备份 $db_count 个数据库文件"
    fi
}

# P1 Fix - 2026-03-27: 备份依赖包列表（用于新服务器环境重建）
backup_dependencies() {
    log_info "备份依赖包列表（P1 优化）..."
    mkdir -p "$BUNDLE_DIR/config/dependencies"
    
    # 1. Node.js 全局包
    if command -v npm &> /dev/null; then
        npm list -g --depth=0 > "$BUNDLE_DIR/config/dependencies/npm_global_packages.txt" 2>/dev/null || true
        log_info "  ✓ npm 全局包列表"
    fi
    
    # 2. pnpm 全局包
    if command -v pnpm &> /dev/null; then
        pnpm list -g --depth=0 > "$BUNDLE_DIR/config/dependencies/pnpm_global_packages.txt" 2>/dev/null || true
        log_info "  ✓ pnpm 全局包列表"
    fi
    
    # 3. Python 包
    if command -v pip3 &> /dev/null; then
        pip3 list --format=freeze > "$BUNDLE_DIR/config/dependencies/python_packages.txt" 2>/dev/null || true
        log_info "  ✓ Python 包列表"
    fi
    
    # 4. OpenClaw CLI 版本
    if command -v openclaw &> /dev/null; then
        openclaw --version > "$BUNDLE_DIR/config/dependencies/openclaw_version.txt" 2>/dev/null || true
        log_info "  ✓ OpenClaw CLI 版本"
    fi
    
    # 5. Node.js 版本
    if command -v node &> /dev/null; then
        node --version > "$BUNDLE_DIR/config/dependencies/node_version.txt"
        log_info "  ✓ Node.js 版本"
    fi
    
    # 6. pnpm 版本
    if command -v pnpm &> /dev/null; then
        pnpm --version > "$BUNDLE_DIR/config/dependencies/pnpm_version.txt"
        log_info "  ✓ pnpm 版本"
    fi
    
    log_info "依赖包备份完成"
}

backup_identity() {
    log_info "备份身份认证和扩展配置..."
    mkdir -p "$BUNDLE_DIR/identity"
    
    # 1. Identity files (device ID + auth keys)
    if [ -d "/root/.openclaw/identity" ]; then
        tar -czf "$BUNDLE_DIR/identity/identity_$TIMESTAMP.tar.gz" \
            -C /root/.openclaw identity/
        log_info "✓ identity/ 已备份"
    else
        log_warn "⚠ identity/ 目录不存在"
    fi
    
    # 2. Credentials (Feishu pairing, allowFrom, etc.)
    if [ -d "/root/.openclaw/credentials" ]; then
        tar -czf "$BUNDLE_DIR/identity/credentials_$TIMESTAMP.tar.gz" \
            -C /root/.openclaw credentials/
        log_info "✓ credentials/ 已备份"
    else
        log_warn "⚠ credentials/ 目录不存在"
    fi
    
    # 3. Extensions configuration (exclude node_modules to save space)
    if [ -d "/root/.openclaw/extensions" ]; then
        tar -czf "$BUNDLE_DIR/identity/extensions_$TIMESTAMP.tar.gz" \
            -C /root/.openclaw \
            --exclude='extensions/*/node_modules' \
            --exclude='extensions/.openclaw-install-backups' \
            extensions/
        log_info "✓ extensions/ 已备份（不含 node_modules）"
    else
        log_warn "⚠ extensions/ 目录不存在"
    fi
    
    # 4. SSH keys (for GitHub push)
    if [ -f "/root/.ssh/id_ed25519" ]; then
        tar -czf "$BUNDLE_DIR/identity/ssh_keys_$TIMESTAMP.tar.gz" \
            -C /root/.ssh \
            id_ed25519 id_ed25519.pub \
            id_ed25519_openclaw_backup id_ed25519_openclaw_backup.pub 2>/dev/null || \
        tar -czf "$BUNDLE_DIR/identity/ssh_keys_$TIMESTAMP.tar.gz" \
            -C /root/.ssh id_ed25519 id_ed25519.pub
        log_info "✓ SSH 密钥已备份"
    else
        log_warn "⚠ 未找到 SSH 密钥 /root/.ssh/id_ed25519"
    fi
    
    # 5. Systemd service files (complete .service files, not just overrides)
    if [ -d "$HOME/.config/systemd/user" ]; then
        cd "$HOME/.config/systemd/user"
        find . -name "openclaw-*.service" -print0 | \
            tar -czf "$BUNDLE_DIR/identity/systemd_services_$TIMESTAMP.tar.gz" \
            --null -T - 2>/dev/null || true
        if [ -f "$BUNDLE_DIR/identity/systemd_services_$TIMESTAMP.tar.gz" ]; then
            log_info "✓ systemd 服务文件已备份"
        else
            log_warn "⚠ 未找到 systemd 服务文件"
        fi
        cd - > /dev/null
    fi
}

case $BACKUP_TYPE in
    full)
        # Backup all agents into bundle (with incremental optimization - P2 Fix)
        AGENTS=($(discover_agents))
        for agent in "${AGENTS[@]}"; do
            backup_agent_smart "$agent"
        done
        
        # Backup memory system (main + shared + all agents' private memory)
        if [ -d "$WORKSPACE_ROOT/main/memory" ]; then
            tar -czf "$BUNDLE_DIR/memory/memory_main_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT/main" memory/
        fi
        
        if [ -d "$WORKSPACE_ROOT/memory" ]; then
            tar -czf "$BUNDLE_DIR/memory/memory_shared_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT" memory/
        fi
        
        # Backup all agents' private memory
        for agent_dir in "$WORKSPACE_ROOT/agents"/*/; do
            agent_name=$(basename "$agent_dir")
            if [ -d "$agent_dir/memory" ]; then
                tar -czf "$BUNDLE_DIR/memory/memory_${agent_name}_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT/agents" "$agent_name/memory/"
            fi
        done
        
        # Backup configurations
        if [ -d "$WORKSPACE_ROOT/main" ]; then
            tar -czf "$BUNDLE_DIR/config/config_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/main" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md USER.md TOOLS.md \
                -C /root/.openclaw openclaw.json exec-approvals.json 2>/dev/null || true
        fi
        
        # Backup master agent's config (if separate)
        if [ -d "$WORKSPACE_ROOT/agents/master" ]; then
            tar -czf "$BUNDLE_DIR/config/config_agent_master_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/agents/master" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md USER.md TOOLS.md 2>/dev/null || true
        fi
        
        # P4 Security Fix - 2026-03-25: Backup identity & credentials (for complete migration)
        backup_identity
        
        # P0 Fix - 2026-03-27: Backup database (memory architecture core data)
        backup_database
        
        # P1 Fix - 2026-03-27: Backup dependencies (for environment reconstruction)
        backup_dependencies
        
        # Backup system-wide (skills, scripts, crontab, systemd overrides, backup-manager.sh, migration scripts)
        mkdir -p "$BUNDLE_DIR/system/scripts"
        mkdir -p "$BUNDLE_DIR/migration"
        
        # Copy backup-manager.sh to system/scripts (ensures latest version is backed up)
        cp "$0" "$BUNDLE_DIR/system/scripts/backup-manager.sh"
        chmod +x "$BUNDLE_DIR/system/scripts/backup-manager.sh"
        
        # Copy migration scripts to migration/ (ensures one-click restore is available)
        if [ -f "$BACKUP_ROOT/restore-from-github.sh" ]; then
            cp "$BACKUP_ROOT/restore-from-github.sh" "$BUNDLE_DIR/migration/"
            chmod +x "$BUNDLE_DIR/migration/restore-from-github.sh"
            log_info "✓ 迁移恢复脚本已备份"
        fi
        
        if [ -f "$BACKUP_ROOT/MIGRATION-README.md" ]; then
            cp "$BACKUP_ROOT/MIGRATION-README.md" "$BUNDLE_DIR/migration/"
            log_info "✓ 迁移指南已备份"
        fi
        
        if [ -f "$BACKUP_ROOT/RESTORE.md" ]; then
            cp "$BACKUP_ROOT/RESTORE.md" "$BUNDLE_DIR/migration/"
            log_info "✓ 恢复文档已备份"
        fi
        
        if [ -d "$WORKSPACE_ROOT/agents/master" ]; then
            tar -czf "$BUNDLE_DIR/system/system_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/agents/master" skills/ scripts/ \
                -C "$BUNDLE_DIR/system" scripts/backup-manager.sh 2>/dev/null || true
        fi
        
        # Backup migration scripts as separate archive
        if [ -d "$BUNDLE_DIR/migration" ] && [ "$(ls -A "$BUNDLE_DIR/migration" 2>/dev/null)" ]; then
            tar -czf "$BUNDLE_DIR/migration/migration_scripts_$TIMESTAMP.tar.gz" \
                -C "$BUNDLE_DIR/migration" . 2>/dev/null || true
            log_info "✓ 迁移工具包已打包"
        fi
        # Backup crontab (multiple methods for compatibility)
        if [ -f "/var/spool/cron/crontabs/$(whoami)" ]; then
            tar -czf "$BUNDLE_DIR/system/crontab_$TIMESTAMP.tar.gz" \
                -C "/var/spool/cron/crontabs" "$(whoami)" 2>/dev/null || true
        elif command -v crontab &>/dev/null; then
            # Fallback: use crontab -l to export
            crontab -l > "$BUNDLE_DIR/system/crontab_$TIMESTAMP.txt" 2>/dev/null || true
            if [ -f "$BUNDLE_DIR/system/crontab_$TIMESTAMP.txt" ]; then
                tar -czf "$BUNDLE_DIR/system/crontab_$TIMESTAMP.tar.gz" \
                    -C "$BUNDLE_DIR/system" "crontab_$TIMESTAMP.txt" 2>/dev/null || true
            fi
        fi
        # Backup systemd overrides
        if [ -d "$HOME/.config/systemd/user" ]; then
            tar -czf "$BUNDLE_DIR/system/systemd_overrides_$TIMESTAMP.tar.gz" \
                -C "$HOME/.config/systemd/user" . 2>/dev/null || true
        fi
        ;;
        
    agents)
        AGENTS=($(discover_agents))
        for agent in "${AGENTS[@]}"; do
            log_info "Backing up agent: $agent"
            if [ "$agent" = "main" ]; then
                tar -czf "$BUNDLE_DIR/agents/main_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT" main/
            else
                tar -czf "$BUNDLE_DIR/agents/${agent}_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT" "agents/$agent/"
            fi
        done
        ;;
        
    memory)
        if [ -d "$WORKSPACE_ROOT/main/memory" ]; then
            tar -czf "$BUNDLE_DIR/memory/memory_main_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT/main" memory/
        fi
        if [ -d "$WORKSPACE_ROOT/memory" ]; then
            tar -czf "$BUNDLE_DIR/memory/memory_shared_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT" memory/
        fi
        for agent_dir in "$WORKSPACE_ROOT/agents"/*/; do
            agent_name=$(basename "$agent_dir")
            if [ -d "$agent_dir/memory" ]; then
                tar -czf "$BUNDLE_DIR/memory/memory_${agent_name}_$TIMESTAMP.tar.gz" -C "$WORKSPACE_ROOT/agents" "$agent_name/memory/"
            fi
        done
        ;;
        
    config)
        if [ -d "$WORKSPACE_ROOT/main" ]; then
            tar -czf "$BUNDLE_DIR/config/config_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/main" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md USER.md TOOLS.md \
                -C /root/.openclaw openclaw.json exec-approvals.json 2>/dev/null || true
        fi
        if [ -d "$WORKSPACE_ROOT/agents/master" ]; then
            tar -czf "$BUNDLE_DIR/config/config_agent_master_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/agents/master" AGENTS.md SOUL.md MEMORY.md HEARTBEAT.md USER.md TOOLS.md 2>/dev/null || true
        fi
        ;;

    system)
        # Backup system-wide with latest backup-manager.sh and migration scripts
        mkdir -p "$BUNDLE_DIR/system/scripts"
        mkdir -p "$BUNDLE_DIR/migration"
        
        cp "$0" "$BUNDLE_DIR/system/scripts/backup-manager.sh"
        chmod +x "$BUNDLE_DIR/system/scripts/backup-manager.sh"
        
        # Copy migration scripts
        if [ -f "$BACKUP_ROOT/restore-from-github.sh" ]; then
            cp "$BACKUP_ROOT/restore-from-github.sh" "$BUNDLE_DIR/migration/"
            chmod +x "$BUNDLE_DIR/migration/restore-from-github.sh"
        fi
        if [ -f "$BACKUP_ROOT/MIGRATION-README.md" ]; then
            cp "$BACKUP_ROOT/MIGRATION-README.md" "$BUNDLE_DIR/migration/"
        fi
        if [ -f "$BACKUP_ROOT/RESTORE.md" ]; then
            cp "$BACKUP_ROOT/RESTORE.md" "$BUNDLE_DIR/migration/"
        fi
        
        if [ -d "$WORKSPACE_ROOT/agents/master" ]; then
            tar -czf "$BUNDLE_DIR/system/system_$TIMESTAMP.tar.gz" \
                -C "$WORKSPACE_ROOT/agents/master" skills/ scripts/ \
                -C "$BUNDLE_DIR/system" scripts/backup-manager.sh 2>/dev/null || true
        fi
        
        # Backup migration scripts
        if [ -d "$BUNDLE_DIR/migration" ] && [ "$(ls -A "$BUNDLE_DIR/migration" 2>/dev/null)" ]; then
            tar -czf "$BUNDLE_DIR/migration/migration_scripts_$TIMESTAMP.tar.gz" \
                -C "$BUNDLE_DIR/migration" . 2>/dev/null || true
        fi
        
        # Backup crontab (multiple methods for compatibility)
        if [ -f "/var/spool/cron/crontabs/$(whoami)" ]; then
            tar -czf "$BUNDLE_DIR/system/crontab_$TIMESTAMP.tar.gz" \
                -C "/var/spool/cron/crontabs" "$(whoami)" 2>/dev/null || true
        elif command -v crontab &>/dev/null; then
            crontab -l > "$BUNDLE_DIR/system/crontab_$TIMESTAMP.txt" 2>/dev/null || true
            if [ -f "$BUNDLE_DIR/system/crontab_$TIMESTAMP.txt" ]; then
                tar -czf "$BUNDLE_DIR/system/crontab_$TIMESTAMP.tar.gz" \
                    -C "$BUNDLE_DIR/system" "crontab_$TIMESTAMP.txt" 2>/dev/null || true
            fi
        fi
        if [ -d "$HOME/.config/systemd/user" ]; then
            tar -czf "$BUNDLE_DIR/system/systemd_overrides_$TIMESTAMP.tar.gz" \
                -C "$HOME/.config/systemd/user" . 2>/dev/null || true
        fi
        ;;
        
    *)
        log_warn "Unknown backup type: $BACKUP_TYPE. Using 'full'."
        ;;
esac

# Cleanup old bundles using graduated retention policy (P1 Fix)
cleanup_graduated

# =============================================================================
# PHASE: Backup Integrity Verification (P0 Security Fix - 2026-03-25)
# =============================================================================
verify_backup_integrity() {
    log_info "Verifying backup integrity..."
    local errors=0
    
    # Verify all tar.gz files in bundle
    for archive in "$BUNDLE_DIR"/*/*.tar.gz; do
        if [ -f "$archive" ]; then
            if tar -tzf "$archive" > /dev/null 2>&1; then
                log_info "✓ $(basename "$archive") - OK"
            else
                log_warn "✗ $(basename "$archive") - CORRUPTED"
                errors=$((errors + 1))
            fi
        fi
    done
    
    # Verify backup-manager.sh copy
    if [ -f "$BUNDLE_DIR/config/backup-manager.sh" ]; then
        if diff -q "$0" "$BUNDLE_DIR/config/backup-manager.sh" > /dev/null 2>&1; then
            log_info "✓ backup-manager.sh - OK (identical)"
        else
            log_warn "✗ backup-manager.sh - MISMATCH"
            errors=$((errors + 1))
        fi
    fi
    
    # Generate checksum manifest
    # Save change detection cache (P2 Fix)
    save_cache_to_backup
    
    # Generate backup statistics (P3 Fix)
    local stats_file="$BUNDLE_DIR/backup-stats.json"
    generate_backup_stats "$BUNDLE_DIR" "$stats_file"
    save_stats_history "$stats_file"
    
    log_info "Generating checksum manifest..."
    (cd "$BUNDLE_DIR" && find . -type f -name "*.tar.gz" -exec sha256sum {} \; > checksums.sha256)
    
    if [ "$errors" -gt 0 ]; then
        log_warn "Backup verification FAILED: $errors corrupted file(s)"
        return 1
    else
        log_info "Backup verification PASSED: All files intact"
        return 0
    fi
}

# Run verification
if ! verify_backup_integrity; then
    log_warn "Backup integrity check failed - sending alert"
    # Alert will be handled by health-guardian monitoring
fi

# =============================================================================

# Backup the backup-manager.sh itself (critical for recovery)
# Copy to bundle's config directory so it's versioned alongside other configs
cp "$0" "$BUNDLE_DIR/config/backup-manager.sh" 2>/dev/null || true

# GitHub sync if requested
if [ "$PUSH_TO_GITHUB" = true ]; then
    cd "$BACKUP_ROOT"
    
    # Initialize git if needed
    if [ ! -d ".git" ]; then
        log_info "Initializing Git repository..."
        git init
        git remote add origin git@github.com:ybkin1/ybkin1_openclaw_bak.git 2>/dev/null || true
    fi
    
    # Add all backup files (including the new bundle directory)
    git add openclaw_bak_*/ 2>/dev/null || true
    
    # Also add any loose tar.gz for backward compatibility
    git add agents/*.tar.gz memory/*.tar.gz config/*.tar.gz system/*.tar.gz 2>/dev/null || true
    
    if ! git diff --cached --quiet; then
        git commit -m "📦 Backup bundle: $BUNDLE_NAME (graded retention: ${RETAIN_DAILY}d/${RETAIN_WEEKLY}w/${RETAIN_MONTHLY}m)"
        
        # Push to GitHub with SSH key
        if GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519_openclaw_backup -o IdentitiesOnly=yes" git push origin main 2>&1; then
            log_info "✓ GitHub sync successful"
        else
            log_info "⚠ GitHub push failed (network or SSH key issue)"
        fi
    else
        log_info "✓ No new backups, skipping push"
    fi
fi

# Rotate backup log (P2 Fix)
rotate_backup_log

# Generate trend report (P3 Fix)
generate_trend_report

log_info "Unified backup completed! Bundle: $BUNDLE_DIR (graded retention: ${RETAIN_DAILY}d/${RETAIN_WEEKLY}w/${RETAIN_MONTHLY}m)"

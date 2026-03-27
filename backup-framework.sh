#!/bin/bash
# =============================================================================
# OpenClaw 框架基线备份脚本 v1.0
# 
# 用途：备份框架层配置（不包含系统配置和赛道数据）
# 特点：独立运行，不影响现有完整备份策略
# 创建：2026-03-25
# =============================================================================

set -euo pipefail

#=========== 配置区 ===========
BACKUP_ROOT="/root/.openclaw/backups-unified"
MASTER_DIR="/root/.openclaw/workspace/agents/master"
WORKSPACE_ROOT="/root/.openclaw/workspace"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FRAMEWORK_BUNDLE="$BACKUP_ROOT/framework_bak_$TIMESTAMP"

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

#=========== 安全检查 ===========
check_prerequisites() {
    log_step "检查前置条件..."
    
    if [ ! -d "$MASTER_DIR" ]; then
        log_error "Master 目录不存在：$MASTER_DIR"
        exit 1
    fi
    
    if [ ! -f "$MASTER_DIR/AGENTS.md" ]; then
        log_error "AGENTS.md 不存在"
        exit 1
    fi
    
    log_info "前置检查通过"
}

#=========== 创建框架备份 ===========
create_framework_backup() {
    log_step "创建框架基线备份..."
    log_info "目标目录：$FRAMEWORK_BUNDLE"
    
    mkdir -p "$FRAMEWORK_BUNDLE"
    
    # 1. 备份 Agent 架构（排除敏感配置和记忆）
    log_info "📐 备份架构配置..."
    tar -czf "$FRAMEWORK_BUNDLE/architecture.tar.gz" \
        -C "$WORKSPACE_ROOT/agents" \
        master/AGENTS.md \
        master/SOUL.md \
        master/TOOLS.md \
        master/USER.md \
        master/HEARTBEAT.md \
        master/IDENTITY.md \
        master/scripts/ \
        master/docs/ \
        --exclude='*/memory' \
        --exclude='*/agent.json' \
        --exclude='*/models.json' \
        --exclude='*/.openclaw' \
        2>/dev/null || true
    
    if [ -f "$FRAMEWORK_BUNDLE/architecture.tar.gz" ]; then
        local arch_size=$(du -h "$FRAMEWORK_BUNDLE/architecture.tar.gz" | cut -f1)
        log_info "✓ 架构已备份 ($arch_size)"
    fi
    
    # 2. 备份工作流程（仅配置模板，排除日常数据）
    log_info "📋 备份工作流程..."
    if [ -d "$MASTER_DIR/memory/config" ]; then
        tar -czf "$FRAMEWORK_BUNDLE/workflows.tar.gz" \
            -C "$MASTER_DIR/memory" \
            config/ \
            --exclude='daily' \
            --exclude='short_term' \
            --exclude='tasks' \
            2>/dev/null || true
        
        if [ -f "$FRAMEWORK_BUNDLE/workflows.tar.gz" ]; then
            local wf_size=$(du -h "$FRAMEWORK_BUNDLE/workflows.tar.gz" | cut -f1)
            log_info "✓ 工作流程已备份 ($wf_size)"
        fi
    fi
    
    # 3. 备份规范文档
    log_info "📜 备份规范文档..."
    if [ -f "$MASTER_DIR/AGENTS.md" ]; then
        cp "$MASTER_DIR/AGENTS.md" "$FRAMEWORK_BUNDLE/rules.md"
        log_info "✓ 规范已备份"
    fi
    
    if [ -f "$MASTER_DIR/architecture_overview.md" ]; then
        cp "$MASTER_DIR/architecture_overview.md" "$FRAMEWORK_BUNDLE/"
        log_info "✓ 架构概览已备份"
    fi
    
    # 4. 备份 skills（如果存在）
    log_info "🛠️  备份 skills..."
    if [ -d "$MASTER_DIR/skills" ]; then
        tar -czf "$FRAMEWORK_BUNDLE/skills.tar.gz" \
            -C "$MASTER_DIR" \
            skills/ \
            2>/dev/null || true
        
        if [ -f "$FRAMEWORK_BUNDLE/skills.tar.gz" ]; then
            local skills_size=$(du -h "$FRAMEWORK_BUNDLE/skills.tar.gz" | cut -f1)
            log_info "✓ Skills 已备份 ($skills_size)"
        fi
    fi
    
    # 5. 创建排除清单（重要！）
    cat > "$FRAMEWORK_BUNDLE/EXCLUSIONS.md" << 'EOF'
# 框架基线排除清单

以下文件**未**包含在框架基线中，恢复时需手动配置：

## 系统配置（不备份）
- ❌ openclaw.json (Gateway 配置)
- ❌ .gateway_token (认证 token)
- ❌ exec-approvals.json (执行审批)

## Agent 独立配置（不备份）
- ❌ */agent.json (Agent 模型配置)
- ❌ */models.json (Provider 配置)
- ❌ */.openclaw/ (Agent 运行时配置)

## 记忆内容（不备份）
- ❌ memory/daily/ (每日日志)
- ❌ memory/short_term/ (短期记忆)
- ❌ memory/*/tasks/ (任务数据)
- ❌ memory/archive/ (归档记忆)

## 外部数据（不备份）
- ❌ 数据库文件
- ❌ 临时缓存
- ❌ SSH keys
- ❌ Device auth

## 原因说明

框架基线的目的是保存**架构配置**和**工作流程**，不包含：
1. **系统配置**：每台服务器的 Gateway 配置可能不同（端口、网络等）
2. **赛道数据**：领域相关的记忆和数据应单独备份
3. **敏感信息**：认证 token、SSH keys 等应通过安全渠道传输

恢复时，这些内容会：
- 系统配置 → 保留目标服务器的现有配置
- 赛道数据 → 从赛道备份中恢复
- 敏感信息 → 手动配置或从安全存储恢复
EOF
    
    log_info "✓ 排除清单已创建"
    
    # 6. 创建恢复指南
    cat > "$FRAMEWORK_BUNDLE/RESTORE-INSTRUCTIONS.md" << 'EOF'
# 框架基线恢复指南

## ⚠️ 重要提示

框架基线**不包含**系统配置（如 openclaw.json），恢复后需要手动配置。

## 恢复前准备

1. **备份当前状态**（重要！）
   ```bash
   cp -r /root/.openclaw/workspace/agents/master /tmp/agents_backup_$(date +%Y%m%d_%H%M%S)
   cp /root/.openclaw/openclaw.json /root/.openclaw/openclaw.json.backup
   ```

2. **停止 Gateway**
   ```bash
   systemctl --user stop openclaw-gateway
   ```

3. **确认框架备份目录**
   ```bash
   ls -la /root/.openclaw/backups-unified/framework_bak_*/
   ```

## 恢复步骤

### 步骤 1: 恢复架构配置

```bash
# 解压架构备份
tar -xzf architecture.tar.gz -C /root/.openclaw/workspace/agents/
```

### 步骤 2: 恢复工作流程

```bash
# 解压工作流程
tar -xzf workflows.tar.gz -C /root/.openclaw/workspace/agents/master/memory/
```

### 步骤 3: 恢复 Skills（如有）

```bash
# 解压 skills
tar -xzf skills.tar.gz -C /root/.openclaw/workspace/agents/master/
```

### 步骤 4: 保留系统配置

```bash
# 确认 openclaw.json 未被覆盖
cat /root/.openclaw/openclaw.json | jq '.gateway.port'
```

### 步骤 5: 启动 Gateway

```bash
# 启动服务
systemctl --user start openclaw-gateway

# 检查状态
systemctl --user status openclaw-gateway
```

### 步骤 6: 验证功能

```bash
# 运行诊断
openclaw doctor

# 发送测试消息
# 检查飞书连接
```

## 回滚步骤

如果恢复后出现问题：

```bash
# 1. 停止 Gateway
systemctl --user stop openclaw-gateway

# 2. 恢复备份
cp -r /tmp/agents_backup_*/ /root/.openclaw/workspace/agents/master
cp /root/.openclaw/openclaw.json.backup /root/.openclaw/openclaw.json

# 3. 重启 Gateway
systemctl --user start openclaw-gateway
```

## 常见问题

### Q: Gateway 启动失败
**A**: 检查 openclaw.json 是否被意外修改，恢复备份的 openclaw.json

### Q: 记忆丢失
**A**: 框架基线不包含记忆内容，需从赛道备份恢复

### Q: Skills 不可用
**A**: 确认 skills.tar.gz 已正确解压到 master/skills/
EOF
    
    log_info "✓ 恢复指南已创建"
    
    # 7. 生成 manifest
    cat > "$FRAMEWORK_BUNDLE/manifest.json" << MANIFEST
{
    "type": "framework",
    "version": "1.0",
    "created": "$(date -Iseconds)",
    "components": ["architecture", "workflows", "rules"],
    "excluded": ["openclaw.json", "agent.json", "models.json", "memory/daily", "memory/short_term"],
    "safety_level": "high",
    "restore_time": "15-20 minutes",
    "purpose": "Domain switching and architecture versioning"
}
MANIFEST
    
    log_info "✓ Manifest 已生成"
}

#=========== 生成统计报告 ===========
generate_stats() {
    log_step "生成备份统计..."
    
    local total_size=$(du -sh "$FRAMEWORK_BUNDLE" | cut -f1)
    local file_count=$(find "$FRAMEWORK_BUNDLE" -type f | wc -l)
    
    echo ""
    echo "=========================================="
    echo "   框架基线备份统计"
    echo "=========================================="
    echo "备份目录：$FRAMEWORK_BUNDLE"
    echo "总大小：$total_size"
    echo "文件数：$file_count"
    echo ""
    echo "组件详情:"
    ls -lh "$FRAMEWORK_BUNDLE"/*.tar.gz 2>/dev/null | while read line; do
        echo "  $line"
    done
    echo "=========================================="
    echo ""
    
    log_info "框架基线备份完成！"
    log_info "📄 查看排除清单：$FRAMEWORK_BUNDLE/EXCLUSIONS.md"
    log_info "📖 恢复指南：$FRAMEWORK_BUNDLE/RESTORE-INSTRUCTIONS.md"
}

#=========== 主流程 ===========
main() {
    echo ""
    echo "=========================================="
    echo "   OpenClaw 框架基线备份工具 v1.0"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    create_framework_backup
    generate_stats
    
    echo ""
    log_info "✅ 所有操作完成！"
    echo ""
}

# 执行主流程
main "$@"

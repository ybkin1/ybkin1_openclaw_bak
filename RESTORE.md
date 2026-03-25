# 🔄 OpenClaw 备份恢复指南

**版本**: 1.0 (2026-03-25 创建)  
**适用备份**: `openclaw_bak_<timestamp>/` bundle 结构

---

## 📋 恢复前检查

### 1. 确认可用备份
```bash
# 列出所有备份 bundle
ls -lht /root/.openclaw/backups-unified/openclaw_bak_*/

# 查看最新备份
latest=$(ls -d /root/.openclaw/backups-unified/openclaw_bak_* | sort | tail -1)
echo "最新备份：$latest"

# 验证备份完整性
cd "$latest"
sha256sum -c checksums.sha256
```

### 2. 停止相关服务
```bash
# 停止 Gateway
systemctl --user stop openclaw-gateway

# 停止 Health Guardian
systemctl --user stop openclaw-health-guardian 2>/dev/null || true

# 停止 Assistant Agent
pkill -f task-listener.sh 2>/dev/null || true
```

---

## 🔧 恢复步骤

### 场景 A: 完整系统恢复（灾难恢复）

**适用情况**: 系统崩溃、数据丢失、迁移到新服务器

```bash
#!/bin/bash
# 完整恢复脚本

set -euo pipefail

BACKUP_BUNDLE="${1:-/root/.openclaw/backups-unified/openclaw_bak_*/}"
TARGET_ROOT="/root/.openclaw"

echo "⚠️  警告：这将覆盖现有数据！"
echo "备份源：$BACKUP_BUNDLE"
read -p "确认继续？(yes/no): " confirm
[ "$confirm" = "yes" ] || exit 1

# 1. 备份当前状态（以防万一）
if [ -d "$TARGET_ROOT" ]; then
    echo "备份当前状态..."
    mv "$TARGET_ROOT" "${TARGET_ROOT}.pre_restore.$(date +%Y%m%d_%H%M%S)"
fi

# 2. 创建目录结构
mkdir -p "$TARGET_ROOT"/{workspace,backups-unified,logs}

# 3. 恢复 agents
echo "恢复 agents..."
for agent_tar in "$BACKUP_BUNDLE/agents/"*.tar.gz; do
    [ -f "$agent_tar" ] || continue
    agent_name=$(basename "$agent_tar" | cut -d'_' -f1)
    echo "  → $agent_name"
    
    if [ "$agent_name" = "main" ]; then
        tar -xzf "$agent_tar" -C "$TARGET_ROOT/workspace"
    else
        mkdir -p "$TARGET_ROOT/workspace/agents/$agent_name"
        tar -xzf "$agent_tar" -C "$TARGET_ROOT/workspace/agents/$agent_name" --strip-components=1
    fi
done

# 4. 恢复 memory
echo "恢复 memory..."
# main memory
if [ -f "$BACKUP_BUNDLE/memory/memory_main_"*.tar.gz ]; then
    tar -xzf "$BACKUP_BUNDLE/memory/memory_main_"*.tar.gz -C "$TARGET_ROOT/workspace/main"
fi

# shared memory
if [ -f "$BACKUP_BUNDLE/memory/memory_shared_"*.tar.gz ]; then
    tar -xzf "$BACKUP_BUNDLE/memory/memory_shared_"*.tar.gz -C "$TARGET_ROOT/workspace"
fi

# agent memory
for memory_tar in "$BACKUP_BUNDLE/memory/"memory_*.tar.gz; do
    [ -f "$memory_tar" ] || continue
    agent_name=$(basename "$memory_tar" | sed 's/memory_//' | cut -d'_' -f1)
    
    # 跳过 main 和 shared（已处理）
    [[ "$agent_name" =~ ^(main|shared)$ ]] && continue
    
    echo "  → $agent_name memory"
    mkdir -p "$TARGET_ROOT/workspace/agents/$agent_name"
    tar -xzf "$memory_tar" -C "$TARGET_ROOT/workspace/agents/$agent_name" --strip-components=1
done

# 5. 恢复配置
echo "恢复配置..."
if [ -f "$BACKUP_BUNDLE/config/config_"*.tar.gz ]; then
    # 恢复主配置
    tar -xzf "$BACKUP_BUNDLE/config/config_"*.tar.gz -C "$TARGET_ROOT/workspace/main"
    
    # 恢复 openclaw.json
    if [ -f "$BACKUP_BUNDLE/config/openclaw.json" ]; then
        cp "$BACKUP_BUNDLE/config/openclaw.json" "$TARGET_ROOT/"
    fi
fi

# 6. 恢复系统配置
echo "恢复系统配置..."
if [ -f "$BACKUP_BUNDLE/system/system_"*.tar.gz ]; then
    tar -xzf "$BACKUP_BUNDLE/system/system_"*.tar.gz -C "$TARGET_ROOT/workspace/agents/master"
fi

if [ -f "$BACKUP_BUNDLE/system/systemd_overrides_"*.tar.gz ]; then
    tar -xzf "$BACKUP_BUNDLE/system/systemd_overrides_"*.tar.gz -C "$HOME/.config/systemd/user"
fi

if [ -f "$BACKUP_BUNDLE/system/crontab_"*.tar.gz ]; then
    tar -xzf "$BACKUP_BUNDLE/system/crontab_"*.tar.gz -C "/var/spool/cron/crontabs"
fi

# 7. 修复权限
echo "修复权限..."
chown -R root:root "$TARGET_ROOT"
chmod 755 "$TARGET_ROOT/backups-unified/backup-manager.sh"

# 8. 重新加载 systemd
systemctl --user daemon-reload

echo "✅ 恢复完成！"
echo ""
echo "下一步:"
echo "1. 检查配置：cat $TARGET_ROOT/openclaw.json | jq ."
echo "2. 启动服务：systemctl --user start openclaw-gateway"
echo "3. 验证状态：systemctl --user status openclaw-gateway"
```

---

### 场景 B: 部分恢复（单个文件/配置）

**适用情况**: 误删文件、配置错误、回滚特定更改

```bash
# 1. 查看备份内容
BACKUP="/root/.openclaw/backups-unified/openclaw_bak_20260325_033001"

# 列出 agents
tar -tzf "$BACKUP/agents/master_"*.tar.gz | head -20

# 列出 memory
tar -tzf "$BACKUP/memory/memory_master_"*.tar.gz | head -20

# 2. 提取单个文件
# 恢复单个 agent 配置
tar -xzf "$BACKUP/agents/master_"*.tar.gz -C /root/.openclaw/workspace/agents/master AGENTS.md

# 恢复 memory 文件
tar -xzf "$BACKUP/memory/memory_master_"*.tar.gz -C /root/.openclaw/workspace/agents/master memory/daily/2026-03-24.md

# 3. 恢复 openclaw.json
tar -xzf "$BACKUP/config/config_"*.tar.gz -C /root/.openclaw openclaw.json
```

---

### 场景 C: 从 GitHub 恢复（本地备份丢失）

**适用情况**: 服务器完全丢失，需要从 GitHub 拉取备份

```bash
# 1. 克隆备份仓库
git clone git@github.com:ybkin1/ybkin1_openclaw_bak.git /tmp/openclaw_restore

# 2. 选择要恢复的 bundle
cd /tmp/openclaw_restore
ls -d openclaw_bak_*/

# 3. 使用场景 A 的脚本恢复
# （修改 BACKUP_BUNDLE 路径为 /tmp/openclaw_restore/openclaw_bak_<timestamp>/）
```

---

## ✅ 恢复后验证

### 1. 基础验证
```bash
# 检查 Gateway 状态
systemctl --user status openclaw-gateway

# 检查端口监听
netstat -tlnp | grep 18789

# 检查配置有效性
openclaw doctor
```

### 2. 功能验证
```bash
# 发送测试消息（通过飞书）
# 检查 agent 状态
sessions_list

# 检查记忆系统
ls -la /root/.openclaw/workspace/agents/master/memory/
```

### 3. 备份系统验证
```bash
# 手动触发一次备份
/root/.openclaw/backups-unified/backup-manager.sh full

# 验证新生成的备份
cd /root/.openclaw/backups-unified/openclaw_bak_*/
sha256sum -c checksums.sha256
```

---

## 🕐 恢复时间目标 (RTO)

| 恢复场景 | 预计时间 | 说明 |
|----------|----------|------|
| **单个文件恢复** | < 5 分钟 | 场景 B |
| **完整系统恢复** | 15-30 分钟 | 场景 A |
| **GitHub 恢复** | 30-60 分钟 | 场景 C（含网络时间） |

---

## 📊 恢复时间记录

| 日期 | 场景 | 实际用时 | 备注 |
|------|------|----------|------|
| 2026-03-25 | 部分恢复演练 | < 2 分钟 | 首次 P1 修复演练，测试 config + memory 恢复 |
| 2026-03-25 | P3 统计报告验证 | < 1 分钟 | 验证 backup-stats.json + trend report |
| - | - | - | 待完整恢复演练 |

---

## 🧪 恢复演练计划

**频率**: 每月一次  
**下次演练**: 2026-04-25

**演练步骤**:
1. 选择一个非生产时段（建议周六凌晨）
2. 在测试环境或临时目录执行完整恢复
3. 记录实际用时和问题
4. 更新本文档
5. 清理测试数据

## ✅ 演练历史

### 2026-03-25 - P1 修复演练（部分恢复）

**目标**: 验证备份可恢复性和 checksum 验证

**执行内容**:
1. ✅ 创建测试目录 `/tmp/openclaw_restore_test`
2. ✅ 恢复 config 备份（AGENTS.md, openclaw.json, MEMORY.md 等 8 个文件）
3. ✅ 恢复 memory 备份（master/memory/ 目录结构）
4. ✅ 验证 checksums.sha256（26 个 archive 全部 OK）
5. ✅ 清理测试数据

**结果**: 
- 配置恢复：< 10 秒
- Memory 恢复：< 10 秒
-Checksum 验证：< 5 秒
- **总用时**: < 2 分钟

**问题**: 无

**改进项**: 
- 下次演练需测试完整系统恢复（场景 A）
- 需测试 systemd 服务恢复后的启动验证

---

## ⚠️ 注意事项

1. **恢复前务必备份当前状态** - 即使当前数据有问题，也可能包含备份后新增的重要数据
2. **检查备份完整性** - 使用 `sha256sum -c checksums.sha256` 验证
3. **停止相关服务** - 避免恢复过程中文件被修改
4. **权限修复** - 恢复后检查文件权限是否正确
5. **配置验证** - 使用 `openclaw doctor` 验证配置有效性

---

## 🆘 故障排查

### 问题：恢复后 Gateway 无法启动
```bash
# 检查日志
journalctl --user -u openclaw-gateway -n 100

# 验证配置
openclaw doctor --repair

# 检查端口占用
lsof -i :18789
```

### 问题：memory 文件丢失
```bash
# 检查恢复路径是否正确
ls -la /root/.openclaw/workspace/agents/master/memory/

# 手动提取
tar -xzf openclaw_bak_*/memory/memory_master_*.tar.gz -C /root/.openclaw/workspace/agents/master
```

### 问题：systemd 服务未恢复
```bash
# 重新加载 systemd
systemctl --user daemon-reload

# 重新启用服务
systemctl --user enable openclaw-gateway
```

---

## 📞 紧急联系

如果恢复过程中遇到无法解决的问题：
1. 记录完整错误信息到 `/root/.openclaw/logs/restore_error_$(date +%Y%m%d_%H%M%S).log`
2. 尝试从另一个备份 bundle 恢复
3. 联系系统管理员

---

**最后更新**: 2026-03-25  
**维护者**: Master Agent (喵小白)  
**状态**: ✅ 待首次演练验证

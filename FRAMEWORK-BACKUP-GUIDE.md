# 🏗️ OpenClaw 框架基线备份系统使用指南

**版本**: 1.0 (2026-03-25 创建)  
**状态**: ✅ 生产就绪

---

## 📋 概述

框架基线备份系统用于保存 OpenClaw 的**架构配置**和**工作流程**，不包含系统配置和赛道数据。

### 用途

1. **赛道切换** - 快速回退到框架基线，配置新赛道
2. **架构版本管理** - 保存架构改进的历史版本
3. **灾难恢复** - 恢复架构配置（不含数据）

### 与完整备份的区别

| 特性 | 完整备份 | 框架基线备份 |
|------|---------|------------|
| **包含 openclaw.json** | ✅ | ❌ |
| **包含赛道记忆** | ✅ | ❌ |
| **包含 SSH keys** | ✅ | ❌ |
| **备份大小** | ~5MB | ~400KB |
| **恢复时间** | 10-15 分钟 | 15-20 分钟 |
| **用途** | 完整迁移 | 赛道切换 |

---

## 🛠️ 工具脚本

### 1. backup-framework.sh - 创建框架基线

**用途**: 备份当前架构配置到框架基线

```bash
# 执行备份
/root/.openclaw/backups-unified/backup-framework.sh

# 输出示例:
# ✓ 架构已备份 (60K)
# ✓ 工作流程已备份 (40K)
# ✓ Skills 已备份 (272K)
# 框架基线备份完成！
```

**备份内容**:
- `architecture.tar.gz` - Agent 架构配置
- `workflows.tar.gz` - 工作流程模板
- `skills.tar.gz` - Skills（如有）
- `EXCLUSIONS.md` - 排除清单
- `RESTORE-INSTRUCTIONS.md` - 恢复指南
- `manifest.json` - 版本信息

**备份位置**:
```
/root/.openclaw/backups-unified/framework_bak_YYYYMMDD_HHMMSS/
```

---

### 2. restore-framework-safe.sh - 恢复框架基线

**用途**: 安全恢复框架基线配置

```bash
# 查看可用基线
ls -1d /root/.openclaw/backups-unified/framework_bak_*

# 恢复指定基线
/root/.openclaw/backups-unified/restore-framework-safe.sh \
    /root/.openclaw/backups-unified/framework_bak_20260325_203341/

# 或使用软链接（最新基线）
/root/.openclaw/backups-unified/restore-framework-safe.sh \
    /root/.openclaw/backups-unified/framework_latest/
```

**恢复流程**:
1. 停止 Gateway
2. 创建回滚点
3. 恢复架构配置
4. 恢复工作流程
5. 保留 openclaw.json 不变
6. 启动 Gateway
7. 验证功能

**恢复后**:
- ✅ AGENTS.md, SOUL.md 等已恢复
- ✅ 工作流程模板已恢复
- ✅ openclaw.json 保持不变
- ✅ 记忆数据保持不变

---

### 3. extract-framework-improvements.sh - 提取架构改进

**用途**: 从赛道工作中提取架构改进

```bash
# 提取改进
/root/.openclaw/backups-unified/extract-framework-improvements.sh server-ops

# 输出:
# 📊 比较架构配置差异...
# 📊 比较记忆结构差异...
# 📄 生成改进报告...
# 工作目录：/tmp/framework_improvements_12345
```

**生成文件**:
- `arch_diff.patch` - 架构差异
- `memory_config_diff.patch` - 记忆结构差异
- `improvements_report.md` - 改进报告
- `config_current/` - 当前配置模板

---

### 4. merge-to-framework.sh - 合并改进到基线

**用途**: 将架构改进合并到框架基线

```bash
# 合并改进
/root/.openclaw/backups-unified/merge-to-framework.sh \
    /tmp/framework_improvements_12345/

# 流程:
# 1. 创建基线备份（回滚点）
# 2. 审查并合并架构改进
# 3. 更新配置模板
# 4. 执行框架备份更新基线
```

---

## 📖 使用场景

### 场景 1: 创建初始框架基线

```bash
# 1. 完善当前架构配置
# 编辑 AGENTS.md, SOUL.md, memory/config/ 等

# 2. 创建框架基线
/root/.openclaw/backups-unified/backup-framework.sh

# 3. 创建软链接
cd /root/.openclaw/backups-unified
ln -sf framework_bak_20260325_203341 framework_latest

# 4. 推送到 GitHub（可选）
git add framework_bak_*/
git commit -m "🏗️ Framework baseline v1.0"
git push
```

---

### 场景 2: 切换到新赛道

```bash
# 1. 备份当前赛道（完整备份）
/root/.openclaw/backups-unified/backup-manager.sh full --label server-ops-final

# 2. 恢复框架基线
/root/.openclaw/backups-unified/restore-framework-safe.sh framework_latest/

# 3. 配置新赛道角色
# 编辑 AGENTS.md, 定义新角色

# 4. 开始新赛道工作
```

---

### 场景 3: 提取架构改进

```bash
# 假设在运维工作中改进了记忆结构

# 1. 提取改进
/root/.openclaw/backups-unified/extract-framework-improvements.sh server-ops

# 2. 审查改进报告
cat /tmp/framework_improvements_12345/improvements_report.md

# 3. 查看差异
cat /tmp/framework_improvements_12345/arch_diff.patch

# 4. 合并到基线
/root/.openclaw/backups-unified/merge-to-framework.sh \
    /tmp/framework_improvements_12345/
```

---

### 场景 4: 完整迁移 + 赛道切换

```bash
# 新服务器迁移（使用完整备份）
curl -fsSL https://raw.githubusercontent.com/ybkin1/ybkin1_openclaw_bak/main/restore-from-github.sh | bash

# 切换到新赛道（使用框架基线）
/root/.openclaw/backups-unified/restore-framework-safe.sh framework_latest/
```

---

## 🔐 安全保证

### 不会影响的内容

框架基线备份和恢复**不会修改**:

- ❌ `openclaw.json` (Gateway 配置)
- ❌ `memory/daily/` (每日日志)
- ❌ `memory/short_term/` (短期记忆)
- ❌ `*/agent.json` (Agent 模型配置)
- ❌ `*/models.json` (Provider 配置)
- ❌ SSH keys 和认证信息

### 回滚机制

每次恢复前自动创建回滚点:
```
/tmp/framework_pre_restore_YYYYMMDD_HHMMSS/
```

如需回滚:
```bash
cp /tmp/framework_pre_restore_*/AGENTS.md /root/.openclaw/workspace/agents/master/
cp /tmp/framework_pre_restore_*/openclaw.json /root/.openclaw/
systemctl --user restart openclaw-gateway
```

---

## 📊 备份策略集成

### 完整备份体系

```
备份体系:
├── 完整备份 (backup-manager.sh)
│   ├── 每日自动执行 (03:30)
│   ├── 包含所有配置和数据
│   └── 用于完整迁移
│
└── 框架基线备份 (backup-framework.sh)
    ├── 手动执行（赛道切换前）
    ├── 仅包含架构配置
    └── 用于赛道切换
```

### 备份频率建议

| 备份类型 | 频率 | 时间 |
|----------|------|------|
| **完整备份** | 每日自动 | 03:30 |
| **框架基线** | 赛道切换前 | 手动 |
| **架构改进提取** | 架构优化后 | 手动 |

---

## ⚠️ 注意事项

### 1. 框架基线不包含 openclaw.json

**原因**: 每台服务器的 Gateway 配置可能不同（端口、网络等）

**解决**: 恢复框架基线后，保留目标服务器的 openclaw.json

---

### 2. 赛道数据需单独备份

**原因**: 框架基线排除赛道特定数据

**解决**: 切换赛道前执行完整备份:
```bash
backup-manager.sh full --label <domain>-final
```

---

### 3. 架构改进需手动合并

**原因**: 自动合并可能引入赛道特定配置

**解决**: 使用 extract 和 merge 脚本，手动审查改进

---

### 4. 恢复后验证功能

**必须验证**:
- [ ] Gateway 服务运行正常
- [ ] 飞书消息可以正常发送/接收
- [ ] Agent 配置完整
- [ ] 工作流程正常加载

---

## 📞 故障排查

### Q1: Gateway 启动失败

**可能原因**: openclaw.json 被意外修改

**解决**:
```bash
# 恢复 openclaw.json
cp /tmp/framework_pre_restore_*/openclaw.json /root/.openclaw/
systemctl --user restart openclaw-gateway
```

---

### Q2: 记忆丢失

**可能原因**: 误删除 memory 目录

**解决**:
```bash
# 从完整备份恢复记忆
tar -xzf openclaw_bak_*/memory/memory_master_*.tar.gz \
    -C /root/.openclaw/workspace/agents/master/
```

---

### Q3: Skills 不可用

**可能原因**: skills.tar.gz 未正确解压

**解决**:
```bash
# 重新解压 skills
tar -xzf framework_bak_*/skills.tar.gz \
    -C /root/.openclaw/workspace/agents/master/
```

---

## 📚 相关文档

- `EXCLUSIONS.md` - 框架基线排除清单
- `RESTORE-INSTRUCTIONS.md` - 详细恢复指南
- `MIGRATION-README.md` - 一键迁移指南
- `RESTORE.md` - 完整恢复指南

---

**最后更新**: 2026-03-25  
**维护者**: Master Agent  
**状态**: ✅ 生产就绪

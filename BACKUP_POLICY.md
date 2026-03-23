# 备份管理规范

**版本**: 2.0  
**生效日期**: 2026-03-17  
**负责人**: backup agent

---

## 备份目录结构

```
/root/.openclaw/backups-unified/
├── config/                     # 配置文件备份
│   └── openclaw/
│       └── openclaw.json.{date}
│
├── memory/                     # 记忆文件备份
│   └── MEMORY.md.{date}
│
├── system/                     # 系统配置备份
│   └── crontab.{date}
│
├── agents/                     # Agent 配置备份
│   └── {agent_id}/{date}/
│
├── logs/                       # 备份日志
│   └── backup.log
│
└── migration/                  # 历史备份迁移 (一次性)
    └── 2026-03-17/             # 迁移日期
        └── ...                 # 从其他目录迁移的备份
```

---

## 备份策略

### 配置文件
- **频率**: 每次修改前自动备份
- **保留**: 最近 10 个版本
- **位置**: `backups-unified/config/`

### 记忆文件
- **频率**: 每日自动备份
- **保留**: 最近 30 天
- **位置**: `backups-unified/memory/`

### 系统配置
- **频率**: 每周日备份
- **保留**: 最近 4 周
- **位置**: `backups-unified/system/`

### Agent 配置
- **频率**: 每次修改前备份
- **保留**: 最近 5 个版本
- **位置**: `backups-unified/agents/`

---

## 清理规则

### 已清理目录
- [x] `/root/.openclaw/backups-repo/` - 已迁移到 backups-unified
- [x] `/root/.openclaw/workspace-main/` - 已删除

### 待清理目录
- [ ] `/root/.openclaw/extensions/.openclaw-install-backups/` - npm 安装备份，保留
- [ ] `/root/.openclaw/workspace/*.bak` - 迁移后删除
- [ ] `/root/.openclaw/openclaw.json.bak*` - 迁移后删除

---

## 备份脚本

### 主备份脚本
- **位置**: `/root/.openclaw/backups-unified/backup-manager.sh`
- **执行**: 每日 03:00 (cron)
- **日志**: `/root/.openclaw/backups-unified/logs/backup.log`

### 系统级服务脚本（纳入备份范围）

| 脚本 | 位置 | 备份方式 |
|------|------|----------|
| Health Guardian | `workspace/agents/master/health-guardian/` | 随 agent 备份 |
| OOM 配置 | `~/.config/systemd/user/openclaw-gateway.service.d/override.conf` | 随 system 备份 |
| Arch Guardian | `workspace/agents/master/guardian3.0/` | 随 agent 备份（已禁用） |

### 手动备份
```bash
/root/.openclaw/backups-unified/backup-manager.sh --manual
```

---

## 恢复流程

1. **定位备份**: 在 `backups-unified/` 中找到对应日期的备份
2. **验证完整性**: 检查备份文件完整性
3. **执行恢复**: 使用备份管理器恢复
4. **验证恢复**: 确认系统正常运行

---

## 监控与告警

- **备份失败**: 立即通知 master agent
- **磁盘空间**: 低于 20% 时告警
- **备份过期**: 定期清理过期备份

---

## 实施状态

| 项目 | 状态 | 完成度 |
|------|------|--------|
| 目录结构 | ✅ 已创建 | 100% |
| 备份策略 | ✅ 已定义 | 100% |
| 历史迁移 | 🟡 进行中 | 50% |
| 清理规则 | 🟡 进行中 | 50% |
| 自动化 | ✅ 已配置 | 100% |

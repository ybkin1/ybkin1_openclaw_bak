# HEARTBEAT.md - 定期检查任务

## 每日检查 (每 6 小时)

- [ ] 检查 Memos 服务状态 (`docker ps --filter name=memos`)
- [ ] 检查是否有紧急邮件/消息
- [ ] 检查日历事件 (未来 24 小时)

## 每周检查 (每周一)

- [ ] 整理 memory/ 目录，更新 MEMORY.md
- [ ] 审查 .learnings/ 中的待处理项目
- [ ] 检查 skills 更新 (`clawhub list`)
- [ ] Token 使用报告

## 每月检查 (每月 1 日)

- [ ] 系统安全更新检查
- [ ] Docker 容器清理
- [ ] 归档旧记忆文件

---

## 🔄 自动任务 (Cron)

以下任务已配置为自动执行，无需手动干预：

| 任务 | 时间 | 脚本 | 日志 |
|------|------|------|------|
| 每日备份 | 02:00 | `scripts/daily-backup.sh` | `logs/daily-backup.log` |
| GitHub 推送 | 03:00 | `scripts/push-core-files.sh` | `logs/github-push.log` |
| 每周完整备份 | 周日 04:00 | `tar` 打包 | `logs/weekly-backup.log` |

---

## ⚠️ MEMORY.md 编辑规范

**重要**: 修改 MEMORY.md 前必须先备份！

```bash
# 方式 1: 使用编辑脚本 (推荐)
./scripts/edit-memory.sh edit "[修改内容]"

# 方式 2: 手动备份后编辑
./scripts/edit-memory.sh backup
# 然后编辑 MEMORY.md
```

**禁止**: 直接修改 MEMORY.md 而不备份

---

## 📊 心跳状态

状态追踪文件：`memory/heartbeat-state.json`

下次审查：根据心跳间隔 (30 分钟)

---

## 📅 Cron 配置状态

```bash
# 查看当前 cron 配置
crontab -l

# 编辑 cron
crontab -e
```

配置位置：`config/github-backup.md`

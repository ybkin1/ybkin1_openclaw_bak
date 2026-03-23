# 功能请求日志

## [FEAT-20260304-001] Tavily API 集成

**Logged**: 2026-03-04T22:45:00+08:00
**Priority**: medium
**Status**: pending
**Area**: infra

### Requested Capability
配置 Tavily API key 以启用 AI 优化搜索

### User Context
- SearXNG 已部署但搜索结果较原始
- Tavily 提供 AI 优化的精选结果
- 适合复杂查询和研究任务

### Complexity Estimate
simple

### Suggested Implementation
1. 用户访问 https://app.tavily.com 注册
2. 获取免费 API key（1000 次/月）
3. 添加到 ~/.bashrc 或 gateway 配置

### Metadata
- Frequency: first_time
- Related Features: searxng, web_search

---

## [FEAT-20260304-002] 定期备份自动化

**Logged**: 2026-03-04T23:12:00+08:00
**Priority**: high
**Status**: ✅ **completed** (2026-03-09)
**Area**: infra

### Requested Capability
自动备份 memory、.learnings、配置文件

### Implementation
- ✅ cron 已配置：每天 1:30/3:00/12:00 自动备份
- ✅ 备份类型：memory/config/full
- ✅ GitHub 同步：自动推送到 ybkin1/openclaw_git
- ✅ 日志：/var/log/openclaw-backup.log

### Metadata
- Frequency: recurring
- Related Features: memory-master, self-improvement

---

## [FEAT-20260304-003] Token 使用监控

**Logged**: 2026-03-04T23:12:00+08:00
**Priority**: medium
**Status**: pending
**Area**: config

### Requested Capability
监控和报告 token 使用情况

### User Context
- 使用本地模型（免费）
- 但仍需监控使用量
- 优化长任务减少浪费

### Complexity Estimate
simple

### Suggested Implementation
使用 token-budget-monitor skill：
1. 配置 config.json 设置限额
2. cron 任务跟踪使用情况
3. 超限前发送通知

### Metadata
- Frequency: recurring
- Related Features: token-budget-monitor

---

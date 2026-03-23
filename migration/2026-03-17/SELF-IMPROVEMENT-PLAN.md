# 🚀 自我提升方案

_版本：1.0 | 创建日期：2026-03-04 | 最后更新：2026-03-04_

---

## 📊 目标

| 目标 | 当前状态 | 目标状态 |
|------|----------|----------|
| 对话效率 | 每次从零开始 | 利用记忆减少 50% 上下文 |
| Token 消耗 | ~680k/会话 | 降低至 ~300k/会话 |
| 错误重复率 | 未追踪 | 降低 80% |
| 任务完成时间 | 未优化 | 缩短 40% |

---

## 🛠️ 已安装的核心 Skills

| Skill | 用途 | 状态 |
|-------|------|------|
| self-improving-agent | 记录学习与错误 | ✅ 已安装 |
| memory-hygiene | 记忆清理与维护 | ✅ 已安装 |
| memory-master | 记忆管理 | ✅ 已安装 |
| token-budget-monitor | Token 预算监控 | ✅ 已安装 |
| openclaw-agent-optimize | 代理优化 | ✅ 已安装 |
| skill-vetting | 技能安全扫描 | ✅ 已安装 |

---

## 📁 目录结构

```
/root/.openclaw/workspace/
├── MEMORY.md                    # 长期记忆 (跨会话)
├── HEARTBEAT.md                 # 定期检查任务
├── SELF-IMPROVEMENT-PLAN.md     # 本方案
├── memory/
│   └── YYYY-MM-DD.md            # 每日会话日志
└── .learnings/
    ├── LEARNINGS.md             # 学习日志
    ├── ERRORS.md                # 错误日志
    └── FEATURE_REQUESTS.md      # 功能请求
```

---

## 🔧 配置步骤

### 步骤 1: 记忆系统设置 ✅

```bash
# 已创建目录
mkdir -p ~/.openclaw/workspace/memory
mkdir -p ~/.openclaw/workspace/.learnings

# 已创建文件
touch ~/.openclaw/workspace/MEMORY.md
touch ~/.openclaw/workspace/memory/$(date +%Y-%m-%d).md
touch ~/.openclaw/workspace/.learnings/{LEARNINGS.md,ERRORS.md,FEATURE_REQUESTS.md}
```

### 步骤 2: HEARTBEAT 配置 ✅

已在 `HEARTBEAT.md` 中配置：
- 每日检查：服务状态、邮件、日历
- 每周检查：记忆整理、learnings 审查、skills 更新
- 每月检查：系统更新、Docker 清理、记忆归档

### 步骤 3: Self-Improvement 工作流

**触发条件**（自动记录到 .learnings/）：

| 情况 | 记录到 | 示例 |
|------|--------|------|
| 命令失败 | ERRORS.md | Docker 命令报错 |
| 用户纠正 | LEARNINGS.md (correction) | "不对，应该是..." |
| 发现更好方法 | LEARNINGS.md (best_practice) | 优化后的安装流程 |
| 知识过时 | LEARNINGS.md (knowledge_gap) | 镜像标签变更 |
| 功能请求 | FEATURE_REQUESTS.md | 用户想要新功能 |

**记录格式**：
```markdown
## [LRN-YYYYMMDD-XXX] category

**Logged**: ISO-8601 timestamp
**Priority**: low | medium | high | critical
**Status**: pending
**Area**: infra | config | workflow | tools

### Summary
一句话描述

### Details
完整上下文

### Suggested Action
具体改进步骤

### Metadata
- Source: conversation | error | user_feedback
- Tags: tag1, tag2
- Pattern-Key: stable.identifier
```

### 步骤 4: Token 优化策略

#### 4.1 减少上下文消耗

| 策略 | 预期节省 | 实施方法 |
|------|----------|----------|
| 使用 MEMORY.md | 30-40% | 会话开始前读取，避免重复解释 |
| 使用 daily notes | 20% | 仅加载最近 2 天的详细日志 |
| 压缩长输出 | 10% | 表格代替长段落，使用摘要 |
| 后台任务 | 15% | 长任务用 subagent，主会话继续 |

#### 4.2 clawhub 限流优化

```bash
# 批量安装脚本 (避免限流)
#!/bin/bash
skills=("skill-a" "skill-b" "skill-c")
for skill in "${skills[@]}"; do
    echo "Installing $skill..."
    clawhub install "$skill" --force
    sleep 45  # 等待 45 秒避免限流
done
```

#### 4.3 使用 token-budget-monitor

```bash
# 查看当前会话 token 使用
openclaw skill-run token-budget-monitor status

# 设置预算告警
export TOKEN_BUDGET_DAILY=1000000  # 1M tokens/天
```

### 步骤 5: 子代理使用规范

**何时使用子代理**：

| 场景 | 模式 | 示例 |
|------|------|------|
| 长时间等待 | `mode=run` | clawhub 安装、大文件下载 |
| 独立任务 | `mode=session` | 代码审查、文档生成 |
| 并行任务 | `mode=run` | 多个 API 调用 |

**使用示例**：
```bash
# 后台安装 skill
openclaw sessions_spawn \
  --runtime subagent \
  --mode run \
  --task "clawhub install example-skill --force" \
  --label "install-skill"
```

---

## 📈 监控指标

### 每日追踪

| 指标 | 目标值 | 当前值 |
|------|--------|--------|
| 会话 Token 消耗 | <500k | ~680k |
| 记忆命中率 | >60% | 待追踪 |
| 错误重复率 | <10% | 待追踪 |
| 任务完成时间 | -20% | 基准 |

### 每周审查

```bash
# 检查 learnings 数量
grep -c "^## \[" ~/.openclaw/workspace/.learnings/*.md

# 检查已解决项目
grep -c "Status\*\*: resolved" ~/.openclaw/workspace/.learnings/*.md

# 检查记忆文件大小
du -h ~/.openclaw/workspace/memory/*.md
```

---

## 🔄 持续改进循环

```
┌─────────────────┐
│  会话中记录     │
│  (learnings/)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  每日整理       │
│  (memory/)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  每周提炼       │
│  (MEMORY.md)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  更新行为       │
│  (SOUL.md)      │
└─────────────────┘
```

---

## ⚠️ 注意事项

1. **MEMORY.md 仅在主会话加载** - 群聊/共享会话不加载，避免信息泄露
2. **定期清理** - 使用 memory-hygiene 技能清理过期记忆
3. **敏感信息** - 不要记录 API keys、密码等敏感数据
4. **适度记录** - 避免过度记录导致 token 浪费

---

## 📚 参考文档

- [self-improving-agent SKILL.md](./skills/self-improving-agent/SKILL.md)
- [AGENTS.md](./AGENTS.md) - 工作流规范
- [TOOLS.md](./TOOLS.md) - 工具使用指南

---

_此方案本身也会持续改进。每次发现优化机会时，记录到 .learnings/ 并更新本方案。_

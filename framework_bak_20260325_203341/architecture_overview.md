# OpenClaw Agent 架构完整文档

**生成时间**: 2026-03-24
**版本**: v2.0 (Unified Backup + gstack 集成)
**维护者**: Master Agent (喵小白)

---

## 📋 目录

1. [架构总览](#架构总览)
2. [Agent 详细清单](#agent-详细清单)
3. [核心配置系统](#核心配置系统)
4. [工具链](#工具链)
5. [备份系统](#备份系统)
6. [安全配置](#安全配置)
7. [目录结构](#目录结构)
8. [配置文件索引](#配置文件索引)

---

## 架构总览

```
┌─────────────────────────────────────────────────────────────┐
│                      主控层 (master)                        │
│  职责: 全局协调、任务路由、用户直连、战略决策               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      执行层 (assistant → branches)         │
├─────────────────────────────────────────────────────────────┤
│  analysis          数据分析、报告生成                        │
│  backup            备份管理、存储维护                       │
│  monitoring        系统监控、告警处理                       │
│  server-maintenance 服务器维护、故障排除                   │
│  customer-service  客户服务、问题解答                      │
│  database-manager  数据库管理、数据操作                     │
│  file-processor    文件处理、格式转换                      │
│  memory-manager    记忆管理、知识检索                       │
└─────────────────────────────────────────────────────────────┘
```

**架构原则**:
- Master 可调用所有 agent
- Assistant 根据主控命令调用分支 agent
- 分支 agent 需要跨部门能力时调用其他 agent
- 未经用户同意不得修改架构

---

## Agent 详细清单

### 1. Master (老板)

| 属性 | 值 |
|------|-----|
| **Agent ID** | master |
| **职责** | 主控、全局协调、用户直连 |
| **模型配置** | primary: `openrouter/stepfun/step-3.5-flash:free`<br>fallbacks: `qwencode/qwen3.5-plus` |
| **配置文件** | ✅ WORKFLOW.md<br>✅ CAPABILITIES.md |
| **位置** | `/root/.openclaw/workspace/agents/master/` |

---

### 2. Assistant (秘书)

| 属性 | 值 |
|------|-----|
| **Agent ID** | assistant |
| **职责** | 任务接收、分支调用、进度跟踪 |
| **模型配置** | primary: `qwencode/qwen3.5-plus`<br>fallbacks: `qwencode/qwen3-max` |
| **配置文件** | ✅ WORKFLOW.md<br>✅ CAPABILITIES.md |
| **位置** | `/root/.openclaw/workspace/agents/assistant/` |

---

### 3. Analysis (分析部门)

| 属性 | 值 |
|------|-----|
| **Agent ID** | analysis |
| **职责** | 数据分析、报告生成 |
| **模型配置** | primary: `openrouter/stepfun/step-3.5-flash:free` |
| **配置文件** | ✅ WORKFLOW.md<br>✅ CAPABILITIES.md |
| **位置** | `/root/.openclaw/workspace/agents/analysis/` |

---

### 4. Backup (备份部门)

| 属性 | 值 |
|------|-----|
| **Agent ID** | backup |
| **职责** | 备份管理、存储维护 |
| **模型配置** | primary: `qwencode/qwen3.5-plus`<br>fallback: `qwencode/qwen3-coder-plus` |
| **配置文件** | ✅ WORKFLOW.md<br>✅ CAPABILITIES.md |
| **位置** | `/root/.openclaw/workspace/agents/backup/` |

---

### 5. Monitoring (监控部门)

| 属性 | 值 |
|------|-----|
| **Agent ID** | monitoring |
| **职责** | 系统监控、告警处理 |
| **模型配置** | primary: `qwencode/qwen3.5-plus`<br>fallback: `qwencode/qwen3-coder-plus` |
| **配置文件** | ✅ WORKFLOW.md<br>✅ CAPABILITIES.md |
| **位置** | `/root/.openclaw/workspace/agents/monitoring/` |

---

### 6. Server-Maintenance (运维部门)

| 属性 | 值 |
|------|-----|
| **Agent ID** | server-maintenance |
| **职责** | 服务器维护、故障排除 |
| **模型配置** | primary: `openrouter/stepfun/step-3.5-flash:free` |
| **配置文件** | ✅ WORKFLOW.md<br>✅ CAPABILITIES.md |
| **位置** | `/root/.openclaw/workspace/agents/server-maintenance/` |

---

### 7. Customer-Service (客服部门)

| 属性 | 值 |
|------|-----|
| **Agent ID** | customer-service |
| **职责** | 客户服务、问题解答 |
| **模型配置** | primary: `openrouter/stepfun/step-3.5-flash:free` |
| **配置文件** | ✅ WORKFLOW.md<br>✅ CAPABILITIES.md |
| **位置** | `/root/.openclaw/workspace/agents/customer-service/` |

---

### 8. Database-Manager (数据部门)

| 属性 | 值 |
|------|-----|
| **Agent ID** | database-manager |
| **职责** | 数据库管理、数据操作 |
| **模型配置** | primary: `openrouter/stepfun/step-3.5-flash:free` |
| **配置文件** | ✅ WORKFLOW.md<br>✅ CAPABILITIES.md |
| **位置** | `/root/.openclaw/workspace/agents/database-manager/` |

---

### 9. File-Processor (文档部门)

| 属性 | 值 |
|------|-----|
| **Agent ID** | file-processor |
| **职责** | 文件处理、格式转换 |
| **模型配置** | primary: `openrouter/stepfun/step-3.5-flash:free` |
| **配置文件** | ✅ WORKFLOW.md<br>✅ CAPABILITIES.md |
| **位置** | `/root/.openclaw/workspace/agents/file-processor/` |

---

### 10. Memory-Manager (记忆部门)

| 属性 | 值 |
|------|-----|
| **Agent ID** | memory-manager |
| **职责** | 记忆管理、知识检索 |
| **模型配置** | primary: `openrouter/stepfun/step-3.5-flash:free` |
| **配置文件** | ✅ WORKFLOW.md<br>✅ CAPABILITIES.md |
| **位置** | `/root/.openclaw/workspace/agents/memory-manager/` |

---

## 核心配置系统

### 通用能力框架（七大维度）

每个 agent 都具备完整的能力矩阵：

| 维度 | 来源 | 核心能力 |
|------|------|----------|
| **思考哲学** | gstack Builder Ethos | Boil the Lake、Search Before Building、Build for Yourself |
| **工作流程** | gstack 26 技能方法 | 需求理解、架构设计、审查验证、安全防护、回顾改进 |
| **任务管理** | GSD-2 | 三级分解、状态机驱动、超时监督、成本追踪、崩溃恢复 |
| **质量保障** | gstack + GSD-2 | 自我验证、边缘情况猎杀、错误处理 |
| **资源优化** | DeerFlow 2.0 | 按需加载、并行处理、跨会话持久化 |
| **协作能力** | 三大项目 | 清晰沟通、主动汇报、请求协助 |
| **持续改进** | 三大项目 | 经验沉淀、错误学习、自我优化 |

**强制自检清单**（每个任务必须回答）:

```
□ 思考哲学：是否在做完整的事？是否先搜索了已有方案？
□ 工作流程：是否理解需求？是否设计路径？是否验证结果？
□ 任务管理：是否分解任务？是否记录状态？是否监控时间？
□ 质量保障：是否验证结果？是否处理边缘情况？
□ 资源优化：是否按需加载？是否持久化状态？
□ 协作能力：是否清晰汇报？是否主动同步？
□ 持续改进：是否沉淀经验？是否记录错误？
```

---

### gstack 技能集成（26 个技能）

#### 战略层（仅 master 可调用）
- `/office-hours` - YC 风格需求理解
- `/plan-ceo-review` - CEO 模式产品思考

#### 设计层（master, assistant 可调用）
- `/plan-eng-review` - 技术架构设计
- `/plan-design-review` - 设计评审
- `/autoplan` - 自动化规划流程

#### 执行层（分析部门可调用）
- `/review` - 代码审查
- `/qa` - 测试
- `/browse` - 浏览器操作
- `/investigate` - 调试
- `/benchmark` - 性能基线

#### 安全层（监控部门可调用）
- `/cso` - 安全审计
- `/careful` - 危险操作警告
- `/freeze` - 编辑锁定
- `/guard` - 完整安全模式

#### 发布层（运维部门可调用）
- `/ship` - 发布
- `/land-and-deploy` - 部署

#### 反馈层（记忆部门可调用）
- `/retro` - 回顾总结

**强制工作流程**:
```
Think → Plan → Build → Review → Test → Ship → Reflect
```

---

### 任务处理流程（四阶段）

#### 阶段 1: 任务接收与梳理
- 分析用户真实意图和核心需求
- 识别相关 skills 和依赖关系
- 生成结构化任务描述
- **不调用助手 agent**

#### 阶段 2: 需求对齐与规格确认
- 生成规格说明书和实现需求
- 预估任务时间周期
- 分解详细执行步骤
- **必须经过用户确认**

#### 阶段 3: 任务执行与进度汇报
- **汇报频率**: 每过预估总时间的 1/3 主动汇报
- **汇报内容**: 当前状态、已完成步骤、下一步计划、风险预警
- **异常处理**: 遇到问题立即暂停，等待用户确认

#### 阶段 4: 成长记录与规则更新
- 流程优化记录到 `memory/config/`
- 系统改进记录到 `SOUL.md` 和 `MEMORY.md`

---

### 思考原则（强制遵循）

遵循 `memory/config/agent-thinking-principles.md`:

1. **第一性原理**: 从问题本质出发，不假设用户意图明确
2. **目标澄清优先**: 目标不清时立即停顿，不猜测
3. **最短路径优先**: 不止步于可行，追求最优
4. **主动沟通改进**: 发现次优路径必须指出并建议

---

## 工具链

### 核心服务

| 服务 | 路径 | 功能 | 状态 |
|------|------|------|------|
| OpenClaw Gateway | systemd: `openclaw-gateway` | 消息路由 (端口 18789) | ✅ |
| Health Guardian | `health-guardian/scripts/health_guardian.sh` | 健康监控 + 自动修复 | ✅ |
| OOM Protection | `~/.config/systemd/user/openclaw-gateway.service.d/override.conf` | oom_score_adj = -500 | ✅ |

---

### Master 工具脚本（16 个）

| 脚本 | 路径 | 功能 |
|------|------|------|
| task-classifier.sh | `master/scripts/` | 任务复杂度分类 |
| task-router.sh | `master/scripts/` | 任务自动路由 |
| get-assistant-results.sh | `master/scripts/` | 获取助手处理结果 |
| daily-heartbeat.sh | `master/scripts/` | 每日心跳检查 |
| task-scheduler.sh | `master/scripts/` | 任务调度 |
| agent-capability-check.sh | `master/scripts/` | 能力检查 |
| filter-sensitive.sh | `master/scripts/` | 敏感信息过滤 |
| message-deduplication.sh | `master/scripts/` | 消息去重 |
| task-list-manager.sh | `master/scripts/` | 任务列表管理 |
| task-router-enhanced.sh | `master/scripts/` | 增强版任务路由 |
| aggregate-results.sh | `master/scripts/` | 结果聚合 |
| task-router.legacy.sh | `master/scripts/` | 旧版任务路由（保留） |
| master-executor.sh | `master/scripts/` | master 执行器 |
| maintain-symlinks.sh | `master/scripts/` | 符号链接维护 |
| collaboration-aggregator.sh | `master/scripts/` | 协作聚合 |
| task-scheduler.sh | `master/scripts/` | 任务调度（已列出） |

---

### Assistant 工具脚本（3 个）

| 脚本 | 路径 | 功能 |
|------|------|------|
| task-listener.sh | `assistant/scripts/` | 守护进程监听任务 |
| task-scan-once.sh | `assistant/scripts/` | 手动触发扫描 |
| start.sh | `assistant/scripts/` | 启动服务 |

---

## 备份系统

### Backup Manager v2.0

**脚本位置**: `/root/.openclaw/backups-unified/backup-manager.sh`

**Bundle 结构**:
```
openclaw_bak_<timestamp>/
├── agents/              (10 × tar.gz)
├── memory/              (12 × tar.gz)
├── config/              (2 × tar.gz + backup-manager.sh)
└── system/              (2 × tar.gz → skills + scripts)
```

**保留策略**: 自动保留最新 4 个 bundle，删除更早的

**GitHub 同步**: `--push` 参数自动推送 `ybkin1/ybkin1_openclaw_bak`

**定时任务**: crontab `30 3 * * * backup-manager.sh full --push`

**验证结果**:
- ✅ 本地保留 4 个完整 bundle（最新：20260324_192752）
- ✅ 自动清理旧 bundle
- ✅ GitHub 同步成功
- ✅ system 层包含 master/scripts/ 全部 16 个脚本
- ✅ backup-manager.sh 自包含（复制到 bundle/config/）

---

## 安全配置

### 安全组件状态

| 组件 | 状态 | 说明 |
|------|------|------|
| firewalld | ✅ 运行中 | 端口规则已配置 |
| sshguard | ✅ 运行中 | 自动封禁 SSH 攻击者 |
| OOM 保护 | ✅ 已配置 | `oom_score_adj = -500` |
| Health Guardian | ✅ 运行中 | Gateway 健康监控 |
| 消息队列 | ✅ 已配置 | debounceMs: 5000ms |
| 架构保护 | ✅ 已记录 | 禁止未经同意修改 agent |

---

## 目录结构

```
/root/.openclaw/
├── openclaw.json                    # 全局配置
├── backups-unified/                 # 统一备份目录
│   ├── backup-manager.sh
│   ├── logs/
│   └── openclaw_bak_*/
└── workspace/
    └── agents/
        ├── master/                  # 主控 Agent (11)
        │   ├── .openclaw/agent.json
        │   ├── AGENT.md
        │   ├── AGENTS.md → ../../../AGENTS.md (symlink)
        │   ├── WORKFLOW.md
        │   ├── CAPABILITIES.md
        │   ├── SOUL.md
        │   ├── USER.md
        │   ├── TOOLS.md → ../../../TOOLS.md (symlink)
        │   ├── HEARTBEAT.md
        │   ├── MEMORY.md → ../../../MEMORY.md (symlink) [read-only]
        │   ├── scripts/             # 16 个工具脚本
        │   ├── skills/              # 技能目录
        │   │   ├── feishu-doc-manager/
        │   │   ├── find-skill/
        │   │   ├── pdf-toolkit-pro/
        │   │   ├── word-docx/
        │   │   └── ...
        │   ├── health-guardian/      # 健康守护
        │   │   └── scripts/health_guardian.sh
        │   ├── memory/              # 记忆系统
        │   │   ├── master/
        │   │   │   ├── long_term/
        │   │   │   ├── short_term/
        │   │   │   └── tasks/
        │   │   └── shared/
        │   └── docs/
        ├── assistant/               # 助手 Agent
        │   ├── .openclaw/agent.json
        │   ├── AGENT.md
        │   ├── AGENT_RULES.md
        │   ├── WORKFLOW.md
        │   ├── CAPABILITIES.md
        │   ├── scripts/
        │   ├── memory/assistant/
        │   └── logs/
        ├── analysis/                # 分析部门
        │   ├── .openclaw/agent.json
        │   ├── WORKFLOW.md
        │   ├── CAPABILITIES.md
        │   └── memory/analysis/
        ├── backup/                  # 备份部门
        │   ├── .openclaw/agent.json
        │   ├── WORKFLOW.md
        │   ├── CAPABILITIES.md
        │   └── memory/backup/
        ├── monitoring/              # 监控部门
        │   ├── .openclaw/agent.json
        │   ├── WORKFLOW.md
        │   ├── CAPABILITIES.md
        │   └── memory/monitoring/
        ├── server-maintenance/      # 运维部门
        │   ├── .openclaw/agent.json
        │   ├── WORKFLOW.md
        │   ├── CAPABILITIES.md
        │   └── memory/server-maintenance/
        ├── customer-service/        # 客服部门
        │   ├── .openclaw/agent.json
        │   ├── WORKFLOW.md
        │   ├── CAPABILITIES.md
        │   └── memory/customer-service/
        ├── database-manager/        # 数据部门
        │   ├── .openclaw/agent.json
        │   ├── WORKFLOW.md
        │   ├── CAPABILITIES.md
        │   └── memory/database-manager/
        ├── file-processor/          # 文档部门
        │   ├── .openclaw/agent.json
        │   ├── WORKFLOW.md
        │   ├── CAPABILITIES.md
        │   └── memory/file-processor/
        └── memory-manager/          # 记忆部门
            ├── .openclaw/agent.json
            ├── WORKFLOW.md
            ├── CAPABILITIES.md
            └── memory/memory-manager/
```

---

## 配置文件索引

| 文件 | 路径 | 用途 |
|------|------|------|
| MEMORY.md | `/root/.openclaw/workspace/agents/master/MEMORY.md` | 长期记忆、规则、变更记录 |
| AGENTS.md | `/root/.openclaw/workspace/agents/master/AGENTS.md` | 系统规则、工作流、工具 |
| TOOLS.md | `/root/.openclaw/workspace/agents/master/TOOLS.md` | 本地工具、命令、配置 |
| SOUL.md | `/root/.openclaw/workspace/agents/master/SOUL.md` | 身份、语气、行为准则 |
| USER.md | `/root/.openclaw/workspace/agents/master/USER.md` | 用户画像 |
| HEARTBEAT.md | `/root/.openclaw/workspace/agents/master/HEARTBEAT.md` | 心跳任务、自动检查 |
| openclaw.json | `/root/.openclaw/openclaw.json` | OpenClaw 全局配置 |
| backup-manager.sh | `/root/.openclaw/backups-unified/backup-manager.sh` | 统一备份脚本 |

---

## 消息队列配置

**配置位置**: `channels.feishu.accounts.default`

```json
{
  "debounceMs": 5000,
  "messageQueue": {
    "enabled": true,
    "mergeDelayMs": 5000,
    "maxBatchSize": 10,
    "description": "连续消息合并：5 秒内连续发送的消息合并为一条处理"
  }
}
```

**效果**:
- 5 秒内连续发送的消息合并为一条处理
- 超过 5 秒没发下一条，才开始处理
- 最多合并 10 条消息

---

## 统计摘要

- **Agent 总数**: 11 个 (1 主控 + 10 分支)
- **功能部门**: 8 个 (分析、备份、监控、运维、客服、数据、文档、记忆)
- **技能集成**: gstack 26 个技能 + DeerFlow 2.0 + GSD-2 方法论
- **模型配置**: 10/11 agent 有独立 agent.json
- **工作流文件**: 10/10 agent 有 WORKFLOW.md
- **能力文件**: 10/10 agent 有 CAPABILITIES.md
- **备份 bundle**: 4 个 (保留策略)
- **自包含工具**: 16 个 master/scripts/ 脚本 + backup-manager.sh

---

**文档版本**: v2.0 (2026-03-24)
**维护者**: Master Agent (喵小白)

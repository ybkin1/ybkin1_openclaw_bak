# 工具配置

_最后更新：2026-03-05_

---

## 🔑 API 密钥管理

**安全提醒**: 本文件仅记录密钥名称和用途，**不存储明文密钥**。
密钥存储在环境变量或密钥管理器中。

### 已配置的密钥

| 服务 | 环境变量 | 用途 | 状态 |
|------|----------|------|------|
| 通义千问 | `QWEN_API_KEY` | 模型推理 | ✅ 已配置 |
| Memos | `MEMOS_TOKEN` | 笔记 API | ⏳ 待首次登录获取 |
| Brave Search | `BRAVE_API_KEY` | 网络搜索 | ❌ 未配置 |
| Tavily | `TAVILY_API_KEY` | AI 搜索 | ❌ 未配置 |

### 密钥获取方式

#### 通义千问
- 平台：https://dashscope.console.aliyun.com/
- 已配置，无需操作

#### Memos Token
- 登录：http://43.166.175.41:5230
- 获取：首次登录后在设置中生成
- 存储：待添加到密钥管理器

#### Brave Search API
- 平台：https://brave.com/search/api/
- 状态：需要配置以启用 web_search 功能

#### Tavily API
- 平台：https://app.tavily.com
- 状态：已安装技能，待配置

---

## 🛠️ 已安装工具

### OpenClaw 核心技能
| 技能 | 用途 | 状态 |
|------|------|------|
| self-improving-agent | 自我改进系统 | ✅ 活跃 |
| memory-master | 记忆管理 | ✅ 活跃 |
| memory-hygiene | 记忆清理 | ✅ 可用 |
| token-budget-monitor | Token 预算监控 | ✅ 可用 |
| openclaw-agent-optimize | 代理优化 | ✅ 可用 |
| skill-vetting | 技能安全扫描 | ✅ 可用 |
| superpowers | 超级工作流 | ✅ 可用 |
| planning-with-files | 文件规划 | ✅ 可用 |

### 外部服务集成
| 技能 | 服务 | 状态 |
|------|------|------|
| memos | Memos 笔记 | ✅ 已部署 |
| github | GitHub CLI | ✅ 可用 |
| gog | Google Workspace | ⏳ 待配置 |
| notion | Notion API | ⏳ 待配置 |
| obsidian | Obsidian | ⏳ 待配置 |
| moltbook | AI 社交网络 | ✅ 可用 |

### 工具类技能
| 技能 | 用途 | 状态 |
|------|------|------|
| nano-pdf | PDF 编辑 | ✅ 可用 |
| summarize | 内容摘要 | ✅ 可用 |
| weather | 天气查询 | ✅ 可用 |
| agent-browser | 浏览器自动化 | ✅ 可用 |
| tavily-search | AI 搜索 | ⏳ 待配置 API |
| cron-retry | Cron 重试 | ✅ 可用 |

### 云服务
| 技能 | 服务 | 状态 |
|------|------|------|
| tencentcloud-lighthouse | 腾讯云轻量 | ✅ 可用 |

---

## 📦 钉钉机器人配置

### 应用信息
- **名称**: tx-OCBot
- **clientId**: `ding6aolfnqejqw53o2q`
- **agentId**: `4304294525`

### 权限
- 企业内机器人发送消息 ✅
- 文件下载权限 ✅

### 限制
- 单聊消息：约 100 条/分钟
- 文本消息最大：4000 字符

---

## 🔄 配置变更日志

| 日期 | 变更 | 影响 |
|------|------|------|
| 2026-03-05 | qmd 安装尝试 | npm 包为空，需找替代方案 |
| 2026-03-05 | thinking 模式开启 | 回复速度略降，质量提升 |

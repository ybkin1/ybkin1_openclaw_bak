# 技能清单

_最后更新：2026-03-05_

---

## 🧠 核心技能

### 记忆与学习
| 技能 | 用途 | 文档 |
|------|------|------|
| memory-master | 记忆管理，自动学习 | `memory-master/SKILL.md` |
| memory-hygiene | 记忆清理和优化 | `memory-hygiene/SKILL.md` |
| self-improving-agent | 错误记录和自我改进 | `self-improving-agent/SKILL.md` |
| token-budget-monitor | Token 预算监控 | `token-budget-monitor/SKILL.md` |

### 工作流
| 技能 | 用途 | 文档 |
|------|------|------|
| superpowers | TDD 驱动的开发工作流 | `superpowers/SKILL.md` |
| planning-with-files | 复杂任务规划 | `planning-with-files/SKILL.md` |
| openclaw-agent-optimize | OpenClaw 优化审计 | `openclaw-agent-optimize/SKILL.md` |

### 技能管理
| 技能 | 用途 | 文档 |
|------|------|------|
| skill-creator | 创建新技能 | `skill-creator/SKILL.md` |
| skill-vetting | 技能安全扫描 | `skill-vetting/SKILL.md` |
| find-skills | 技能发现 | `find-skills/SKILL.md` |
| clawhub | ClawHub 技能市场 | `clawhub/SKILL.md` |

---

## 🔧 工具类技能

### 内容处理
| 技能 | 用途 | 状态 |
|------|------|------|
| summarize | 内容摘要 (URL/PDF/音频) | ✅ 可用 |
| nano-pdf | PDF 编辑 | ✅ 可用 |
| tts | 文本转语音 | ✅ 可用 |

### 网络与搜索
| 技能 | 用途 | 状态 |
|------|------|------|
| web_search | Brave 搜索 | ⏳ 待配置 API |
| tavily-search | AI 优化搜索 | ⏳ 待配置 API |
| searxng | 本地元搜索 | ⏳ 待部署 |
| agent-browser | 浏览器自动化 | ✅ 可用 |

### 实用工具
| 技能 | 用途 | 状态 |
|------|------|------|
| weather | 天气查询 | ✅ 可用 |
| cron-retry | Cron 失败重试 | ✅ 可用 |
| healthcheck | 安全检查 | ✅ 可用 |

---

## 🌐 服务集成

### 笔记与文档
| 技能 | 服务 | 状态 |
|------|------|------|
| memos | Memos 自托管笔记 | ✅ 已部署 |
| notion | Notion | ⏳ 待配置 API |
| obsidian | Obsidian 本地笔记 | ⏳ 待配置 |
| notebooklm | Google NotebookLM | ⏳ 待配置 |
| feishu-* | 飞书文档/云盘/权限 | ⏳ 待配置 |

### 代码与版本控制
| 技能 | 服务 | 状态 |
|------|------|------|
| github | GitHub CLI | ✅ 可用 |

### 云服务
| 技能 | 服务 | 状态 |
|------|------|------|
| tencentcloud-lighthouse | 腾讯云轻量 | ✅ 可用 |
| gog | Google Workspace | ⏳ 待配置 |

### 社交与通讯
| 技能 | 服务 | 状态 |
|------|------|------|
| moltbook | AI 社交网络 | ✅ 可用 |
| qqbot | QQ 机器人 | ✅ 已安装 |
| ddingtalk | 钉钉机器人 | ✅ 已配置 |
| dingtalk | 钉钉 (旧版) | ⚠️ 有错误 |
| wecom | 企业微信 | ✅ 已安装 |

---

## 📦 技能安装指南

### 从 ClawHub 安装
```bash
clawhub install <skill-name>
# 或
openclaw skills install <skill-name>
```

### 从 npm 安装
```bash
openclaw plugins install @package/name
```

### 本地开发
```bash
# 技能位于 ~/.openclaw/workspace/skills/
# 每个技能包含 SKILL.md 和使用代码
```

---

## ⚠️ 已知问题

| 技能 | 问题 | 解决方案 |
|------|------|----------|
| dingtalk | 缺少 `dingtalk-stream` 依赖 | 使用 ddingtalk (Stream 模式) |
| web_search | 缺少 Brave API 密钥 | 需配置 `BRAVE_API_KEY` |
| tavily-search | 缺少 Tavily API 密钥 | 需配置 `TAVILY_API_KEY` |

---

## 📝 技能使用笔记

### 记忆系统最佳实践
1. 日常对话 → `memory/daily/YYYY-MM-DD.md`
2. 项目跟踪 → `memory/projects/<name>.md`
3. 配置信息 → `memory/config/<category>.md`
4. 知识积累 → `memory/knowledge/<topic>.md`
5. 重要决策 → `memory/decisions/YYYY-MM-DD-topic.md`

### 定期维护
- 每 7 天审查 daily/ 目录
- 每月审查 knowledge/ 目录
- 每季度审查 decisions/ 目录

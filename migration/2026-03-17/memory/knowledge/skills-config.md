# 技能配置与使用指南

_最后更新：2026-03-05 | 技能总数：28_

---

## 📊 技能分类总览

| 类别 | 数量 | 技能列表 |
|------|------|----------|
| 🧠 **记忆与学习** | 6 | memory-master, memory-hygiene, self-improving-agent, self-evolving-skill, skill-creator, skill-vetting |
| ⚡ **工作流优化** | 5 | superpowers, planning-with-files, openclaw-agent-optimize, token-budget-monitor, cron-retry |
| 🌐 **网络与搜索** | 4 | searxng, tavily-search, tavily-Search, agent-browser |
| 📝 **内容处理** | 3 | summarize, nano-pdf, tts |
| 📋 **笔记与文档** | 5 | memos, notion, obsidian, notebooklm, feishu-* |
| 💼 **云服务** | 2 | tencentcloud-lighthouse, gog |
| 🔧 **开发工具** | 2 | github, moltbook |
| 🎯 **实用工具** | 1 | weather |

---

## 🧠 记忆与学习系统

### 1. memory-master ⭐ 核心技能

**用途**: 分层记忆管理，自动索引

**配置状态**: ✅ 已启用

**使用场景**:
- 每次会话自动加载 `memory/daily/YYYY-MM-DD.md`
- 修改记忆时自动更新索引
- 主动回忆相关记忆（当上下文缺失时）

**触发条件**:
```
- 会话开始时自动加载
- 用户说"记住..."时
- 发现记忆不足时主动学习
```

**示例**:
```markdown
# 写入日常记忆
文件：memory/daily/2026-03-05.md

## 2026-03-05 技能配置
- 因：需要系统化管理 28 个技能
- 改：创建技能配置文档，分类整理
- 待：配置定期审查任务
```

---

### 2. memory-hygiene

**用途**: 记忆清理和优化

**配置状态**: ⏳ 待配置

**使用场景**:
- 每 7 天审查 daily/ 目录
- 每月审查 knowledge/ 目录
- 清理过期/重复记忆

**触发条件**:
```
- 每周 heartbeat 时
- 发现记忆检索变慢时
- 用户说"清理记忆"时
```

**命令**:
```bash
# 审计记忆
memory_recall query="*" limit=50

# 清理过期记忆
# 手动删除 memory/archive/ 中 90 天前的文件
```

---

### 3. self-improving-agent ⭐ 核心技能

**用途**: 错误记录和自我改进

**配置状态**: ✅ 已启用

**使用场景**:
- 命令/操作失败时记录到 `.learnings/ERRORS.md`
- 用户纠正时记录到 `.learnings/LEARNINGS.md`
- 发现更好的方法时更新最佳实践

**触发条件**:
```
- 任何错误发生后
- 用户说"不对，应该是..."时
- 发现更优解决方案时
```

**示例**:
```markdown
# .learnings/ERRORS.md
## 2026-03-05 GitHub 推送失败
- 错误：`fatal: could not read Username`
- 原因：Git 凭证未嵌入 URL
- 解决：使用 `https://user:token@github.com/...` 格式
```

---

### 4. self-evolving-skill-1-0-2

**用途**: 技能自动进化系统

**配置状态**: ⏳ 待配置 MCP 适配器

**使用场景**:
- 技能使用模式学习
- 自动优化技能参数
- 技能间协同优化

**触发条件**:
```
- 技能使用 10 次后自动分析
- 每周审查技能效果
```

---

### 5. skill-creator

**用途**: 创建新技能

**配置状态**: ✅ 可用

**使用场景**:
- 需要新功能的技能时
- 扩展现有技能时
- 标准化工作流程时

**触发条件**:
```
- 用户说"创建一个技能来..."时
- 发现重复工作模式时
```

**命令**:
```bash
cd ~/.openclaw/workspace/skills
mkdir my-new-skill
# 使用模板创建 SKILL.md
```

---

### 6. skill-vetting

**用途**: 技能安全扫描

**配置状态**: ✅ 可用

**使用场景**:
- 安装新技能前
- 审查第三方代码时
- 评估技能价值时

**触发条件**:
```
- 安装技能前必须运行
- 定期审查已安装技能
```

**命令**:
```bash
cd /tmp
curl -L -o skill.zip "https://clawhub.ai/api/v1/download?slug=SKILL_NAME"
mkdir skill-inspect && cd skill-inspect
unzip -q ../skill.zip
python3 ~/.openclaw/workspace/skills/skill-vetting/scripts/scan.py .
```

---

## ⚡ 工作流优化

### 7. superpowers ⭐ 核心技能

**用途**: TDD 驱动的软件开发工作流

**配置状态**: ✅ 已启用

**使用场景**:
- 开发新功能/应用
- 调试 bug 或测试失败
- 用户说"让我们构建..."时

**触发条件**:
```
- 任何代码开发任务
- 需要系统设计时
- 复杂功能实现
```

**流程**:
```
1. Brainstorming → 探索需求，提出方案
2. Writing Plans → 编写设计文档
3. Subagent Development → 子代理执行
4. Code Review → 代码审查
5. Finish Branch → 完成分支
```

**示例**:
```markdown
# 用户说："帮我创建一个 API 客户端"
# 触发 superpowers 流程

## Phase 1: Brainstorming
- 探索项目上下文
- 提问澄清问题
- 提出 2-3 个方案
- 编写设计文档 → docs/plans/2026-03-05-api-client-design.md
```

---

### 8. planning-with-files ⭐ 核心技能

**用途**: 复杂任务规划（Manus 风格）

**配置状态**: ✅ 已启用

**使用场景**:
- 复杂多步骤任务
- 研究项目
- 任何需要 >5 次工具调用的任务

**触发条件**:
```
- 任务复杂度 > 5 步
- 需要长期跟踪的项目
- 用户说"帮我规划..."时
```

**文件结构**:
```
task_plan.md      # 任务计划
findings.md       # 发现记录
progress.md       # 进度追踪
```

**示例**:
```markdown
# task_plan.md
## 任务：部署 Kronos 金融预测模型

### 阶段 1: 环境准备
- [x] 安装 Python 3.10+
- [x] 安装依赖 `pip install -r requirements.txt`
- [ ] 下载预训练模型

### 阶段 2: 模型测试
- [ ] 运行示例代码
- [ ] 验证预测结果

### 阶段 3: 生产部署
- [ ] 配置 API 服务
- [ ] 设置监控
```

---

### 9. openclaw-agent-optimize

**用途**: OpenClaw 代理优化审计

**配置状态**: ✅ 可用

**使用场景**:
- 优化成本/模型路由
- 减少上下文膨胀
- 提高可靠性

**触发条件**:
```
- 每月审查一次
- 发现 token 使用过高时
- 响应速度变慢时
```

**命令**:
```
# 完整审计（不修改）
"Audit my OpenClaw setup for cost, reliability, and context bloat."

# 上下文优化
"My OpenClaw context is bloating. Identify top offenders and propose fixes."

# 模型路由优化
"Propose a model routing plan for coding, notifications, and research."
```

---

### 10. token-budget-monitor

**用途**: Token 预算监控

**配置状态**: ⏳ 待配置

**使用场景**:
- 追踪 cron job token 使用
- 预算超支告警
- 模型推荐

**触发条件**:
```
- 每日 cron 执行后
- 预算达到 80% 时告警
- 每周生成使用报告
```

**命令**:
```bash
cd ~/.openclaw/workspace/skills/token-budget-monitor
node track-usage.js status      # 查看当前使用
node track-usage.js check daily-tweet  # 检查特定任务
node track-usage.js alert       # 超支告警
node track-usage.js recommend   # 模型推荐
```

---

### 11. cron-retry

**用途**: Cron 失败自动重试

**配置状态**: ⏳ 待配置

**使用场景**:
- 网络错误导致 cron 失败
- 连接恢复后自动重试
- 与 heartbeat 集成

**触发条件**:
```
- cron 任务失败时
- 网络恢复时
```

---

## 🌐 网络与搜索

### 12. searxng ⭐ 已部署

**用途**: 本地隐私搜索引擎

**配置状态**: ✅ 已部署 (端口 8080)

**使用场景**:
- 需要联网搜索时
- 隐私敏感查询
- 多引擎聚合搜索

**触发条件**:
```
- 用户问实时信息时
- 需要最新数据时
- 搜索多个来源时
```

**命令**:
```bash
cd ~/.openclaw/workspace/skills/searxng/scripts
python3 searxng.py "查询关键词"
```

**API**:
```
http://localhost:8080/search?q=查询词&format=json
```

---

### 13. tavily-search / tavily-Search

**用途**: AI 优化搜索

**配置状态**: ⏳ 待配置 API Key

**使用场景**:
- 需要高质量搜索结果
- AI 友好的摘要
- 研究性查询

**触发条件**:
```
- 需要深度研究时
- searxng 结果不足时
- 用户明确要求时
```

**待办**:
```bash
# 获取 API Key
访问 https://app.tavily.com 注册

# 配置环境变量
export TAVILY_API_KEY="your-api-key"
```

---

### 14. agent-browser

**用途**: 浏览器自动化

**配置状态**: ✅ 可用

**使用场景**:
- 需要访问网页内容
- 自动化网页操作
- 截图/快照

**触发条件**:
```
- 用户说"查看这个网页..."时
- 需要网页截图时
- 自动化测试时
```

**命令**:
```bash
# 使用 browser 工具
browser action=navigate targetUrl="https://example.com"
browser action=snapshot
```

---

## 📝 内容处理

### 15. summarize

**用途**: 内容摘要（URL/PDF/音频/YouTube）

**配置状态**: ✅ 可用

**使用场景**:
- 长文章摘要
- PDF 文档总结
- 视频内容提取
- 音频转录

**触发条件**:
```
- 用户提供长 URL 时
- 需要快速了解内容时
- 处理文档时
```

**命令**:
```bash
summarize <url>
summarize <pdf-file>
summarize <youtube-url>
```

---

### 16. nano-pdf

**用途**: PDF 编辑

**配置状态**: ✅ 可用

**使用场景**:
- PDF 内容修改
- PDF 合并/拆分
- PDF 转其他格式

**触发条件**:
```
- 用户需要编辑 PDF 时
- 处理 PDF 文档时
```

---

### 17. tts

**用途**: 文本转语音

**配置状态**: ✅ 可用

**使用场景**:
- 语音回复消息
- 故事讲述
- 无障碍支持

**触发条件**:
```
- 用户请求语音回复时
- 发送故事/长内容时
- 需要语音消息时
```

**命令**:
```
tts text="要转换的文本" [channel="telegram"]
```

---

## 📋 笔记与文档

### 18. memos ⭐ 已部署

**用途**: Memos 自托管笔记

**配置状态**: ✅ 已部署 (端口 5230)

**使用场景**:
- 快速记录想法
- 分享笔记链接
- 个人知识库

**触发条件**:
```
- 用户说"记下来..."时
- 需要保存片段时
- 分享笔记时
```

**待办**:
```bash
# 首次登录获取 Token
访问 http://43.166.175.41:5230

# 配置环境变量
export MEMOS_TOKEN="your-token"
```

---

### 19. notion

**用途**: Notion API 集成

**配置状态**: ⏳ 待配置 API Key

**使用场景**:
- 创建/更新 Notion 页面
- 数据库管理
- 团队协作

**触发条件**:
```
- 用户要求更新 Notion 时
- 团队文档管理时
```

**待办**:
```bash
# 获取 Integration Token
访问 https://www.notion.so/my-integrations

# 配置环境变量
export NOTION_TOKEN="secret_xxx"
```

---

### 20. obsidian

**用途**: Obsidian 本地笔记

**配置状态**: ⏳ 待配置

**使用场景**:
- 本地 Markdown 笔记
- 知识图谱
- 双向链接

**触发条件**:
```
- 用户要求更新 Obsidian 时
- 管理本地笔记时
```

---

### 21. tiangong-notebooklm-cli

**用途**: Google NotebookLM CLI

**配置状态**: ⏳ 待配置

**使用场景**:
- 研究笔记管理
- 文档对话
- 知识整理

**触发条件**:
```
- 研究项目时
- 需要文档对话时
```

---

### 22. feishu-* (feishu-doc, feishu-drive, feishu-perm, feishu-wiki)

**用途**: 飞书集成

**配置状态**: ⏳ 待配置

**使用场景**:
- 飞书文档编辑
- 飞书云盘管理
- 权限管理
- 知识库导航

**触发条件**:
```
- 用户提到飞书时
- 需要协作文档时
```

---

## 💼 云服务

### 23. tencentcloud-lighthouse-skill ⭐ 已配置

**用途**: 腾讯云轻量服务器管理

**配置状态**: ✅ 可用

**使用场景**:
- 查询实例状态
- 监控告警
- 防火墙配置
- 快照管理
- 远程命令执行

**触发条件**:
```
- 用户询问服务器状态时
- 需要管理腾讯云时
- 服务器故障诊断时
```

**命令**:
```bash
cd ~/.openclaw/workspace/skills/tencentcloud-lighthouse-skill/scripts
./setup.sh  # 初始化配置
```

---

### 24. gog

**用途**: Google Workspace CLI

**配置状态**: ⏳ 待配置

**使用场景**:
- Gmail 管理
- Google Calendar
- Google Drive
- Google Sheets/Docs

**触发条件**:
```
- 用户要求管理 Google 服务时
- 需要日历/邮件操作时
```

---

## 🔧 开发工具

### 25. github ⭐ 已配置

**用途**: GitHub CLI 集成

**配置状态**: ✅ 已配置

**使用场景**:
- Issue 管理
- PR 操作
- CI/CD 运行
- 高级查询

**触发条件**:
```
- 用户提到 GitHub 时
- 需要管理仓库时
- 查看 CI 状态时
```

**命令**:
```bash
gh issue list
gh pr create
gh run list
gh api /user
```

---

### 26. moltbook

**用途**: AI 社交网络

**配置状态**: ✅ 可用

**使用场景**:
- AI 代理发帖
- 评论互动
- 创建社区

**触发条件**:
```
- 用户要求在 MoltBook 发帖时
- AI 代理社交时
```

---

## 🎯 实用工具

### 27. weather

**用途**: 天气查询

**配置状态**: ✅ 可用

**使用场景**:
- 查询当前天气
- 天气预报
- 出行建议

**触发条件**:
```
- 用户问天气时
- 需要天气信息时
```

**命令**:
```bash
weather <城市名>
weather beijing
```

---

## 📦 其他技能

### 28. find-skills

**用途**: 技能发现

**配置状态**: ✅ 可用

**使用场景**:
- 用户问"有技能可以..."时
- 寻找特定功能时
- 扩展能力时

**触发条件**:
```
- 用户寻找新技能时
- 需要特定功能时
```

---

## 🔄 技能使用决策树

```
用户请求
├─ 需要记忆/学习？
│  ├─ 写入记忆 → memory-master
│  ├─ 清理记忆 → memory-hygiene
│  └─ 记录错误 → self-improving-agent
│
├─ 需要开发代码？
│  ├─ 复杂项目 → superpowers + planning-with-files
│  └─ 简单修改 → 直接 edit
│
├─ 需要搜索信息？
│  ├─ 本地搜索 → searxng
│  ├─ 深度研究 → tavily-search (需 API)
│  └─ 网页内容 → agent-browser
│
├─ 需要处理内容？
│  ├─ 摘要 → summarize
│  ├─ PDF → nano-pdf
│  └─ 语音 → tts
│
├─ 需要笔记/文档？
│  ├─ 快速记录 → memos
│  ├─ 团队协作 → notion/feishu
│  └─ 本地笔记 → obsidian
│
├─ 需要云服务？
│  ├─ 腾讯云 → tencentcloud-lighthouse
│  └─ Google → gog (需配置)
│
├─ 需要开发工具？
│  ├─ GitHub → github
│  └─ AI 社交 → moltbook
│
└─ 实用工具？
   ├─ 天气 → weather
   └─ 找技能 → find-skills
```

---

## ⚠️ 待配置技能清单

| 技能 | 优先级 | 待办事项 |
|------|--------|----------|
| tavily-search | 中 | 获取 API Key |
| token-budget-monitor | 高 | 配置 cron 集成 |
| cron-retry | 中 | 配置 heartbeat 集成 |
| notion | 低 | 获取 Integration Token |
| obsidian | 低 | 配置 vault 路径 |
| notebooklm | 低 | 配置认证 |
| gog | 低 | 配置 Google OAuth |
| memos | 中 | 首次登录获取 Token |
| memory-hygiene | 中 | 配置定期审查 |

---

## 📅 技能审查计划

| 周期 | 任务 | 技能 |
|------|------|------|
| 每日 | 错误记录 | self-improving-agent |
| 每周 | 记忆清理 | memory-hygiene |
| 每月 | 优化审计 | openclaw-agent-optimize |
| 每月 | 技能审查 | skill-vetting |
| 每季 | 预算审查 | token-budget-monitor |

---

## 🎯 快速激活命令

```bash
# 技能配置审查
cd ~/.openclaw/workspace/skills
ls -la */SKILL.md | wc -l

# 测试技能
weather beijing
gh --version

# 查看技能状态
clawhub list
```

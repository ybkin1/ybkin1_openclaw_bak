# Webnovel Writer 深度学习笔记

> 📚 基于 GitHub: lingfengQAQ/webnovel-writer 的学习总结  
> 📅 2026-03-08 | ⭐ 1023 Stars | 🍴 222 Forks  
> 📄 协议：GPL v3

---

## 🎯 项目定位

**Webnovel Writer** = 基于 Claude Code 的长篇网文辅助创作系统

**核心目标**: 解决 AI 写作中的两大痛点
- ❌ **遗忘问题**: 写后面忘前面，角色/设定不一致
- ❌ **幻觉问题**: AI 凭空编造设定，前后矛盾

**支持规模**: 200 万字量级连载创作

---

## 🏗️ 系统架构

### 核心理念：防幻觉三定律

| 定律 | 说明 | 执行方式 |
|------|------|---------|
| **大纲即法律** | 遵循大纲，不擅自发挥 | Context Agent 强制加载章节大纲 |
| **设定即物理** | 遵守设定，不自相矛盾 | Consistency Checker 实时校验 |
| **发明需识别** | 新实体必须入库管理 | Data Agent 自动提取并消歧 |

---

### Strand Weave 节奏系统

网文叙事的三条线索（类似编织）：

| Strand | 含义 | 理想占比 | 说明 |
|--------|------|---------|------|
| **Quest** | 主线剧情 | 60% | 推动核心冲突 |
| **Fire** | 感情线 | 20% | 人物关系发展 |
| **Constellation** | 世界观扩展 | 20% | 背景/势力/设定 |

**节奏红线**:
- ⚠️ Quest 连续不超过 5 章（避免审美疲劳）
- ⚠️ Fire 断档不超过 10 章（避免感情线断裂）
- ⚠️ Constellation 断档不超过 15 章（避免世界观模糊）

---

### 双 Agent 架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Claude Code                           │
├─────────────────────────────────────────────────────────────┤
│  Skills (7 个): init / plan / write / review / query / ... │
├─────────────────────────────────────────────────────────────┤
│  Agents (8 个): Context / Data / 多维 Checker               │
├─────────────────────────────────────────────────────────────┤
│  Data Layer: state.json / index.db / vectors.db            │
└─────────────────────────────────────────────────────────────┘
```

#### Context Agent（读）
- **职责**: 在写作前构建"创作任务书"
- **输入**: 本章编号、项目根目录
- **输出**: 本章上下文、约束和追读力策略
- **关键**: 强制加载章节大纲，确保"大纲即法律"

#### Data Agent（写）
- **职责**: 从正文提取实体与状态变化
- **更新**: `state.json`、`index.db`、`vectors.db`
- **保证**: 数据链闭环，新实体自动入库

---

### 六维并行审查系统

每章写完后，6 个 Checker 并行审查：

| Checker | 检查重点 | 关键指标 |
|---------|---------|---------|
| **High-point Checker** | 爽点密度与质量 | 爽点间隔、爽点类型分布 |
| **Consistency Checker** | 设定一致性 | 战力/地点/时间线冲突 |
| **Pacing Checker** | Strand 比例与断档 | Quest/Fire/Constellation 占比 |
| **OOC Checker** | 人物行为是否偏离人设 | 角色言行一致性 |
| **Continuity Checker** | 场景与叙事连贯性 | 场景切换、情绪连贯 |
| **Reader-pull Checker** | 钩子强度、期待管理 | 追读力、未闭合问题 |

---

## 📋 核心命令详解

### 1. `/webnovel-init` - 项目初始化

**用途**: 深度初始化小说项目，生成交互式收集完整创作信息

**产出**:
```
PROJECT_ROOT/
├── .webnovel/
│   ├── state.json          # 项目状态（进度、主角状态、strand_tracker）
│   ├── index.db            # 实体索引（角色/势力/地点/伏笔）
│   └── .webnovel-current-project  # 当前项目指针
├── 设定集/
│   ├── 角色设定.md
│   ├── 世界观设定.md
│   └── 力量体系.md
└── 大纲/
    ├── 总纲.md
    └── 第 X 卷 - 时间线.md
```

**交互流程**（Deep 模式）:
```
Step 0: 预检与上下文加载
Step 1: 故事核与商业定位（书名/题材/目标规模/一句话故事）
Step 2: 角色骨架与关系冲突（主角欲望/缺陷/反派分层）
Step 3: 金手指与兑现机制（类型/代价/成长节奏）
Step 4: 世界观与力量体系（规则/势力/等级）
Step 5: 创意约束与卖点（反套路/差异化/商业化）
Step 6: 一致性复述与最终确认
```

---

### 2. `/webnovel-plan [卷号]` - 卷级规划

**用途**: 生成卷级规划与节拍

**示例**:
```bash
/webnovel-plan 1        # 规划第 1 卷
/webnovel-plan 2-3      # 规划第 2-3 卷
```

**输出**:
- 卷纲（本卷核心冲突/主要事件/角色弧光）
- 章纲列表（每章一句话概要）
- 时间线（关键事件时间节点）
- Strand 分布预测

---

### 3. `/webnovel-write [章号]` - 章节创作

**用途**: 执行完整章节创作流水线

**流程**:
```
上下文加载 → 草稿生成 → 六维审查 → 数据落盘
     ↓            ↓           ↓           ↓
Context Agent  写作 Agent  6 Checker  Data Agent
```

**示例**:
```bash
/webnovel-write 1       # 写第 1 章
/webnovel-write 45      # 写第 45 章
```

**模式**:
- 标准模式：全流程（推荐）
- 快速模式：`--fast`（跳过部分审查）
- 极简模式：`--minimal`（仅生成草稿）

---

### 4. `/webnovel-review [范围]` - 质量审查

**用途**: 对历史章节做多维质量审查

**示例**:
```bash
/webnovel-review 1-5    # 审查第 1-5 章
/webnovel-review 45     # 审查第 45 章
```

**输出**:
- 六维评分雷达图
- 问题清单（按严重程度排序）
- 修改建议

---

### 5. `/webnovel-query [关键词]` - 信息查询

**用途**: 查询角色、伏笔、节奏、状态等运行时信息

**示例**:
```bash
/webnovel-query 萧炎          # 查询角色信息
/webnovel-query 伏笔          # 查询未闭合伏笔
/webnovel-query 紧急          # 查询紧急待处理问题
```

---

### 6. `/webnovel-resume` - 任务恢复

**用途**: 任务中断后自动识别断点并恢复

**示例**:
```bash
/webnovel-resume
```

**场景**:
- Claude Code 会话意外断开
- 写作任务执行到一半被中断
- 需要切换到其他项目后再回来

---

### 7. `/webnovel-dashboard` - 可视化面板（v5.5 新增）

**用途**: 启动只读可视化面板

**功能**:
- 项目状态总览
- 实体图谱可视化
- 章节/大纲浏览
- 追读力实时查看

**特点**:
- 只读面板，不直接修改数据
- 支持实时刷新
- 预构建前端，无需本地 npm build

---

## 🔧 RAG 检索系统

### 架构

```
查询 → QueryRouter(auto) → vector / bm25 / hybrid / graph_hybrid
                     └→ RRF 融合 + Rerank → Top-K
```

### 默认模型配置

| 类型 | 模型 | 提供商 |
|------|------|--------|
| Embedding | `Qwen/Qwen3-Embedding-8B` | ModelScope |
| Reranker | `jina-reranker-v3` | Jina AI |

### 环境变量配置（`.env`）

```bash
# Embedding 配置
EMBED_BASE_URL=https://api-inference.modelscope.cn/v1
EMBED_MODEL=Qwen/Qwen3-Embedding-8B
EMBED_API_KEY=your_embed_api_key

# Reranker 配置
RERANK_BASE_URL=https://api.jina.ai/v1
RERANK_MODEL=jina-reranker-v3
RERANK_API_KEY=your_rerank_api_key
```

**重要说明**:
- 未配置 Embedding Key 时，语义检索会回退到 BM25（纯关键词）
- 推荐每本书单独配置 `${PROJECT_ROOT}/.env`，避免多项目串配置

---

## 📚 题材模板系统

### 内置 37+ 题材模板

#### 玄幻修仙类
- 修仙 | 系统流 | 高武 | 西幻 | 无限流 | 末世 | 科幻

#### 都市现代类
- 都市异能 | 都市日常 | 都市脑洞 | 现实题材 | 黑暗题材 | 电竞 | 直播文

#### 言情类
- 古言 | 宫斗宅斗 | 青春甜宠 | 豪门总裁 | 职场婚恋 | 民国言情 | 幻想言情 | 现言脑洞 | 女频悬疑 | 狗血言情 | 替身文 | 多子多福 | 种田 | 年代

#### 特殊题材
- 规则怪谈 | 悬疑脑洞 | 悬疑灵异 | 历史古代 | 历史脑洞 | 游戏体育 | 抗战谍战 | 知乎短篇 | 克苏鲁

---

### 复合题材规则

支持 `题材 A+ 题材 B` 组合（最多 2 个）

**建议**:
- 主辅比例 7:3
- 主线遵循主题材逻辑
- 副题材提供钩子/规则/爽点

**示例**:
- `都市脑洞 + 规则怪谈`
- `修仙 + 系统流`
- `豪门总裁 + 替身文`

---

## 🎯 追读力系统（v5.3 新增）

网文核心指标：让读者愿意追更下一章

### 核心概念

| 概念 | 说明 |
|------|------|
| **Hook** | 章末钩子，吸引读者继续 |
| **Cool-point** | 爽点，读者获得快感的地方 |
| **微兑现** | 小承诺的即时满足 |
| **债务追踪** | 未闭合问题/伏笔的累积 |

### 追读力设计策略

1. **每章必须有钩子**（类型：悬念/情感/冲突/信息）
2. **爽点密度控制**（3-5 章一个中爽点，10-15 章一个大爽点）
3. **债务管理**（未闭合问题不超过 5 个，避免读者疲劳）
4. **微兑现节奏**（每章至少 1 个小满足）

---

## 🛠️ 安装与配置

### 1. 安装插件（官方 Marketplace）

```bash
claude plugin marketplace add lingfengQAQ/webnovel-writer --scope user
claude plugin install webnovel-writer@webnovel-writer-marketplace --scope user
```

**作用域说明**:
- `--scope user`: 全局生效（推荐）
- `--scope project`: 仅当前项目生效

---

### 2. 安装 Python 依赖

```bash
cd /root/.openclaw/workspace/webnovel-writer
python -m pip install -r requirements.txt
```

**依赖说明**:
- 核心写作链路
- Dashboard 可视化
- RAG 检索组件

---

### 3. 初始化项目

在 Claude Code 中执行：
```bash
/webnovel-init
```

**产物**:
- 在当前 Workspace 下创建项目目录
- 写入 `.webnovel-current-project` 指针文件

---

### 4. 配置 RAG 环境

进入项目目录：
```bash
cd 斗破苍穹  # 示例书名
cp .env.example .env
vim .env      # 编辑 API Key
```

---

## 📊 版本更新历史

| 版本 | 关键更新 |
|------|---------|
| **v5.5.0** (当前) | 只读可视化 Dashboard、实时刷新、预构建前端分发 |
| **v5.4.4** | 官方 Plugin Marketplace 安装机制、统一 CLI 调用 |
| **v5.4.3** | 智能 RAG 上下文辅助（auto/graph_hybrid 回退 BM25） |
| **v5.3** | 追读力系统（Hook / Cool-point / 微兑现 / 债务追踪） |

---

## 💡 核心设计洞察

### 1. 分阶段隔离 vs 单一巨型提示词

Webnovel Writer 采用**分阶段隔离**策略：
- `/webnovel-init` 只负责初始化
- `/webnovel-plan` 只负责规划
- `/webnovel-write` 只负责写作
- `/webnovel-review` 只负责审查

**优势**:
- 每个阶段上下文清晰
- 错误容易定位和修复
- 可以单独优化某个环节

---

### 2. 文档化决策 vs 依赖聊天记录

所有关键决策写入文件：
- `state.json`: 项目状态
- `index.db`: 实体索引
- `大纲/`: 各级大纲
- `设定集/`: 世界观设定

**优势**:
- 不依赖 Claude 会话历史
- 可以跨会话继续
- 便于版本管理和回滚

---

### 3. 小步迭代 vs 一次性完美

写作流程设计：
```
写 1 章 → 审查 1 章 → 修改 → 数据落盘 → 写下一章
```

而不是：
```
一次性写 10 章 → 统一审查 → 发现前面有问题要全部重写
```

---

### 4. 验证优先 vs 盲目信任

六维审查系统强制验证：
- 设定一致性检查
- 时间线连续性检查
- 角色行为 OOC 检查
- 爽点密度检查

**原则**: 不相信 AI 的输出，必须经过验证

---

## 🎓 学习路线建议

### 第 1 天：安装与上手
1. 克隆项目
2. 安装依赖
3. 运行 `/webnovel-init` 创建示例项目

### 第 2-3 天：理解架构
1. 阅读 `docs/architecture.md`
2. 理解双 Agent 和六维审查
3. 手动执行一次完整流程

### 第 4-7 天：实战创作
1. 规划一部短篇小说（10-20 章）
2. 使用 `/webnovel-plan` 生成大纲
3. 使用 `/webnovel-write` 逐章创作
4. 使用 `/webnovel-review` 审查质量

### 第 2 周：深度定制
1. 修改题材模板
2. 调整审查规则
3. 自定义 Agent 行为

---

## 📂 项目结构总览

```
webnovel-writer/
├── README.md                    # 快速开始指南
├── docs/                        # 详细文档
│   ├── architecture.md          # 系统架构
│   ├── commands.md              # 命令详解
│   ├── rag-and-config.md        # RAG 配置
│   ├── genres.md                # 题材模板
│   └── operations.md            # 运维手册
├── webnovel-writer/             # 核心代码
│   ├── skills/                  # 7 个技能
│   │   ├── webnovel-init/
│   │   ├── webnovel-plan/
│   │   ├── webnovel-write/
│   │   ├── webnovel-review/
│   │   ├── webnovel-query/
│   │   ├── webnovel-resume/
│   │   └── webnovel-dashboard/
│   ├── agents/                  # 8 个 Agent
│   │   ├── context-agent.md
│   │   ├── data-agent.md
│   │   ├── consistency-checker.md
│   │   ├── continuity-checker.md
│   │   ├── high-point-checker.md
│   │   ├── ooc-checker.md
│   │   ├── pacing-checker.md
│   │   └── reader-pull-checker.md
│   ├── scripts/                 # Python 脚本
│   │   └── webnovel.py         # 主入口
│   ├── templates/               # 模板文件
│   │   ├── genres/             # 题材模板
│   │   └── golden-finger-templates.md
│   ├── references/              # 参考资料
│   │   ├── genre-tropes.md
│   │   ├── worldbuilding/
│   │   └── creativity/
│   └── dashboard/               # 可视化面板
├── requirements.txt             # Python 依赖
└── LICENSE                      # GPL v3
```

---

## 🔗 相关资源

### 本地学习路径
```bash
# 已克隆到工作区
/root/.openclaw/workspace/webnovel-writer/

# 核心文档
cat docs/architecture.md      # 系统架构
cat docs/commands.md          # 命令详解
cat docs/rag-and-config.md    # RAG 配置
```

### 在线资源
- GitHub: https://github.com/lingfengQAQ/webnovel-writer
- 灵感来源：https://linux.do/t/topic/1397944/49

---

## 🚀 下一步行动

1. **安装依赖**: `pip install -r requirements.txt`
2. **配置 API Key**: 创建 `.env` 文件
3. **初始化项目**: 在 Claude Code 中运行 `/webnovel-init`
4. **创作第一部作品**: 从短篇小说开始实践

---

> ✨ **核心理念**: Webnovel Writer 不是"一键生成小说"的魔法工具，而是**结构化创作系统**。它通过防幻觉机制、数据闭环和六维审查，帮助作者在 AI 辅助下保持创作一致性和质量。

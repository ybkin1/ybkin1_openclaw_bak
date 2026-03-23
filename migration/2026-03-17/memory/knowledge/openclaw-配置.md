# OpenClaw 配置指南

## 记忆系统架构

```
~/.openclaw/workspace/
├── MEMORY.md              # 长期记忆（主会话）
├── memory/
│   ├── daily/             # 每日记录（因 - 改-待格式）
│   │   └── YYYY-MM-DD.md
│   ├── knowledge/         # 知识库
│   │   └── *.md
│   ├── daily-index.md     # 每日记忆索引
│   └── knowledge-index.md # 知识索引
├── .learnings/
│   ├── LEARNINGS.md       # 学习日志
│   ├── ERRORS.md          # 错误日志
│   └── FEATURE_REQUESTS.md
└── backups/               # 定期备份
```

## 记忆写入规则

### 何时写入
- ✅ 讨论达成结论
- ✅ 做出决策
- ✅ 分配任务
- ✅ 学到新知识
- ✅ 技能完成/出错（自动）

### 写入格式
```markdown
## [YYYY-MM-DD] 主题
- 因：原因/背景
- 改：做了什么、改了什么
- 待：待办/后续
```

## 记忆读取规则

### 启发式召回
1. 用户提到过去的事情 → 读 daily-index 定位
2. 上下文缺失 → 搜索 knowledge-index
3. 知识不存在 → 网络搜索学习 → 写入知识库

### 避免 token 浪费
- ❌ 不加载整个 memory 目录
- ✅ 只读取相关文件
- ✅ 用索引快速定位

## 知识库维护

### 何时更新
- 学到新技能/工具
- 解决新类型问题
- 配置变更

### 索引格式
```markdown
# 知识库索引

- 关键字 1
- 关键字 2
```

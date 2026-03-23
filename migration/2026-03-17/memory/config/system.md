# 系统配置

_最后更新：2026-03-05_

---

## 🖥️ 服务器信息

### 基本信息
| 项目 | 值 |
|------|-----|
| 公网 IP | 43.166.175.41 |
| 系统 | OpenCloudOS 9.4 |
| 位置 | 腾讯云轻量应用服务器 |
| 时区 | GMT+8 (中国) |

### 服务状态
| 服务 | 端口 | 状态 | 备注 |
|------|------|------|------|
| OpenClaw Gateway | 18789-18792 | ✅ 运行中 | 主服务 |
| Docker | - | ✅ 运行中 | 容器管理 |
| Memos | 5230 | ✅ 运行中 | 笔记服务 |

### 环境变量
```bash
# Memos
MEMOS_URL="http://localhost:5230"
# MEMOS_TOKEN - 首次登录后生成，存储在密钥管理器

# OpenClaw
OPENCLAW_WORKSPACE="/root/.openclaw/workspace"
```

---

## 🔧 OpenClaw 配置

### 模型配置
- **默认模型**: `qwencode/qwen3.5-plus`
- **Thinking 模式**: `on` (2026-03-05 开启)
- **最大并发**: 4
- **子代理并发**: 8

### 渠道配置
- **钉钉 (ddingtalk)**: ✅ 已启用
  - RobotCode: `ding6aolfnqejqw53o2q`
  - dmPolicy: `open`
  - groupPolicy: `open` ⚠️ 建议改为 `allowlist`

### 配置文件位置
- 主配置：`~/.openclaw/openclaw.json`
- 工作区：`~/.openclaw/workspace/`
- 会话：`~/.openclaw/agents/main/sessions/sessions.json`

---

## 📝 变更日志

| 日期 | 变更 | 原因 |
|------|------|------|
| 2026-03-05 | 开启 thinking 模式 | 需要模型深度思考回答问题 |
| 2026-03-05 | 建立分层记忆系统 | 优化记忆管理结构 |
| 2026-03-04 | Memos 部署完成 | 使用 `:stable` 标签 |

# Tavily API 配置指南

## 获取免费 API Key

1. 访问 https://app.tavily.com
2. 使用 Google/GitHub 账号登录
3. 在 Dashboard 复制 API Key（格式：`tvly-xxxxx`）

## 免费额度

- **每月 1000 次搜索** 免费
- 无需信用卡

## 配置方法

### 方法 1：添加到 ~/.bashrc（推荐）
```bash
export TAVILY_API_KEY="tvly-你的 key"
source ~/.bashrc
```

### 方法 2：添加到 Gateway 环境
编辑 `~/.openclaw/gateway/config.json`：
```json
{
  "env": {
    "TAVILY_API_KEY": "tvly-你的 key"
  }
}
```

## 测试
```bash
cd /root/.openclaw/workspace/skills/tavily-Search
node scripts/search.mjs "test query"
```

# 学习日志

## [LRN-20260304-001] clawhub 限流处理

**Logged**: 2026-03-04T16:47:00+08:00
**Priority**: medium
**Status**: resolved
**Area**: infra

### Summary
clawhub API 有速率限制，安装 skills 时需要等待间隔

### Details
- 连续安装技能时会遇到 `Rate limit exceeded` 错误
- 需要等待 30-90 秒才能重试
- 使用后台任务 (`sleep XX && clawhub install`) 可以避免阻塞会话

### Suggested Action
批量安装技能时：
1. 每个技能之间等待 30 秒
2. 使用后台 exec 任务
3. 用 process poll 检查进度

### Metadata
- Source: conversation
- Tags: clawhub, rate-limit, installation
- Pattern-Key: clawhub.rate-limit

---

## [LRN-20260304-002] skill-vetting 扫描结果解读

**Logged**: 2026-03-04T17:48:00+08:00
**Priority**: medium
**Status**: resolved
**Area**: security

### Summary
skill-vetting 的 CRITICAL 警告多为误报，需人工复核

### Details
- 文档中提到"AI"、"reviewer"等词会触发提示注入检测
- 官方/半官方 skills 风险较低
- skill-vetting 自身的 80 个警告是教学示例，正常

### Suggested Action
1. 对标记为 CRITICAL 的 skills 进行人工代码审查
2. 检查是否有真实的风险代码（eval、base64、网络调用）
3. 考虑更新文档描述以避免误报

### Metadata
- Source: conversation
- Tags: security, vetting, false-positive
- Pattern-Key: vetting.false-positives

---

## [LRN-20260304-003] SearXNG JSON API 配置

**Logged**: 2026-03-04T22:31:00+08:00
**Priority**: high
**Status**: resolved
**Area**: infra

### Summary
SearXNG 默认不启用 JSON API，需要手动配置

### Details
- 默认配置 `formats: [html]` 只允许 HTML
- 需要在 settings.yml 中添加 `json` 到 formats
- 还需要设置 `secret_key` 否则容器会循环重启

### Solution
```yaml
search:
  formats:
    - html
    - json
    - csv
    - rss

server:
  secret_key: "随机生成的 32 位字符串"
```

### Metadata
- Source: error
- Tags: searxng, docker, configuration
- Pattern-Key: searxng.json-api

---

## [LRN-20260304-004] Python 依赖安装

**Logged**: 2026-03-04T22:30:00+08:00
**Priority**: medium
**Status**: resolved
**Area**: infra

### Summary
OpenCloudOS 9.4 没有 pip3，需要手动安装

### Details
- `pip3: command not found`
- `dnf install -y python3-pip` 可以安装
- python3-httpx 包有依赖冲突，需要用 pip 安装

### Solution
```bash
dnf install -y python3-pip --skip-broken
pip3 install httpx rich --break-system-packages
```

### Metadata
- Source: error
- Tags: python, pip, opencloudos
- Pattern-Key: python.missing-pip

---

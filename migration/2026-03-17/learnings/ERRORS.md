# 错误日志

## [ERR-20260304-001] SearXNG 容器循环重启

**Logged**: 2026-03-04T22:27:00+08:00
**Priority**: high
**Status**: resolved
**Area**: infra

### Summary
SearXNG 容器启动后持续重启，日志显示 secret_key 未配置

### Error
```
ERROR:searx.webapp: server.secret_key is not changed. Please use something else instead of ultrasecretkey.
[ERROR] Unexpected exit from worker-1
[INFO] Shutting down granian
```

### Context
- 使用默认配置启动 searxng 容器
- 容器持续重启，无法正常服务

### Suggested Fix
在 settings.yml 中设置唯一的 secret_key：
```yaml
server:
  secret_key: "x7Kp9mN2vQ4wR8tY3uL6sJ1hF5dA0cE"
```

### Metadata
- Reproducible: yes
- Related Files: ~/.searxng/settings.yml

---

## [ERR-20260304-002] SearXNG 403 Forbidden

**Logged**: 2026-03-04T22:28:00+08:00
**Priority**: high
**Status**: resolved
**Area**: infra

### Summary
SearXNG API 返回 403，JSON 格式未启用

### Error
```json
{"code":5,"message":"Not Found","details":[]}
```

### Context
- 访问 `http://localhost:8080/search?q=test&format=json`
- 返回 403 Forbidden

### Suggested Fix
在 settings.yml 中启用 JSON 格式：
```yaml
search:
  formats:
    - html
    - json
    - csv
    - rss
```

### Metadata
- Reproducible: yes
- Related Files: ~/.searxng/settings.yml

---

## [ERR-20260304-003] Memos latest 镜像不存在

**Logged**: 2026-03-04T17:54:00+08:00
**Priority**: medium
**Status**: resolved
**Area**: infra

### Summary
`neosmemo/memos:latest` 镜像不存在，需改用 stable 标签

### Error
```
Error response from daemon: manifest for neosmemo/memos:latest not found
```

### Context
- 尝试拉取 `neosmemo/memos:latest`
- 镜像仓库已移除 latest 标签

### Suggested Fix
使用 `stable` 标签：
```bash
docker pull neosmemo/memos:stable
docker run ... neosmemo/memos:stable
```

### Metadata
- Reproducible: yes
- Related Files: -

---

# Docker 部署指南

## 已部署服务

| 服务 | 端口 | 容器名 | 数据卷 |
|------|------|--------|--------|
| Memos | 5230 | memos | ~/.memos |
| SearXNG | 8080 | searxng | ~/.searxng |

## 常用命令

```bash
# 查看运行状态
docker ps

# 查看日志
docker logs <container>

# 重启
docker restart <container>

# 停止
docker stop <container>

# 删除
docker rm <container>

# 查看端口
docker port <container>
```

## Memos 配置
```bash
docker run -d --name memos -p 5230:5230 \
  -v ~/.memos:/var/opt/memos \
  --restart always \
  neosmemo/memos:stable
```

## SearXNG 配置
```bash
docker run -d --name searxng -p 8080:8080 \
  -v ~/.searxng:/etc/searxng:ro \
  --restart always \
  -e "SEARXNG_BASE_URL=http://localhost:8080/" \
  searxng/searxng:latest
```

## 安全组配置
- Memos: 5230/TCP
- SearXNG: 8080/TCP
- SSH: 22/TCP

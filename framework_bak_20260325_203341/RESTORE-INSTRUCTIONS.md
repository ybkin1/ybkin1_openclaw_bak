# 框架基线恢复指南

## ⚠️ 重要提示

框架基线**不包含**系统配置（如 openclaw.json），恢复后需要手动配置。

## 恢复前准备

1. **备份当前状态**（重要！）
   ```bash
   cp -r /root/.openclaw/workspace/agents/master /tmp/agents_backup_$(date +%Y%m%d_%H%M%S)
   cp /root/.openclaw/openclaw.json /root/.openclaw/openclaw.json.backup
   ```

2. **停止 Gateway**
   ```bash
   systemctl --user stop openclaw-gateway
   ```

3. **确认框架备份目录**
   ```bash
   ls -la /root/.openclaw/backups-unified/framework_bak_*/
   ```

## 恢复步骤

### 步骤 1: 恢复架构配置

```bash
# 解压架构备份
tar -xzf architecture.tar.gz -C /root/.openclaw/workspace/agents/
```

### 步骤 2: 恢复工作流程

```bash
# 解压工作流程
tar -xzf workflows.tar.gz -C /root/.openclaw/workspace/agents/master/memory/
```

### 步骤 3: 恢复 Skills（如有）

```bash
# 解压 skills
tar -xzf skills.tar.gz -C /root/.openclaw/workspace/agents/master/
```

### 步骤 4: 保留系统配置

```bash
# 确认 openclaw.json 未被覆盖
cat /root/.openclaw/openclaw.json | jq '.gateway.port'
```

### 步骤 5: 启动 Gateway

```bash
# 启动服务
systemctl --user start openclaw-gateway

# 检查状态
systemctl --user status openclaw-gateway
```

### 步骤 6: 验证功能

```bash
# 运行诊断
openclaw doctor

# 发送测试消息
# 检查飞书连接
```

## 回滚步骤

如果恢复后出现问题：

```bash
# 1. 停止 Gateway
systemctl --user stop openclaw-gateway

# 2. 恢复备份
cp -r /tmp/agents_backup_*/ /root/.openclaw/workspace/agents/master
cp /root/.openclaw/openclaw.json.backup /root/.openclaw/openclaw.json

# 3. 重启 Gateway
systemctl --user start openclaw-gateway
```

## 常见问题

### Q: Gateway 启动失败
**A**: 检查 openclaw.json 是否被意外修改，恢复备份的 openclaw.json

### Q: 记忆丢失
**A**: 框架基线不包含记忆内容，需从赛道备份恢复

### Q: Skills 不可用
**A**: 确认 skills.tar.gz 已正确解压到 master/skills/

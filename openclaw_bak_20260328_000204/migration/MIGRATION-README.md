# 🚀 OpenClaw 一键迁移指南

**版本**: 2.0 (2026-03-25 更新)  
**重要**: 恢复脚本已纳入自动备份，每次备份都会包含最新版本

---

## 📦 恢复脚本位置

| 来源 | 位置 | 说明 |
|------|------|------|
| **GitHub** | `restore-from-github.sh` | 根目录下，可直接访问 |
| **备份中** | `migration/migration_scripts_*.tar.gz` | 每次备份自动包含 |
| **本地** | `/root/.openclaw/backups-unified/restore-from-github.sh` | 源文件 |

---

## 快速开始（3 步完成迁移）

### 方式 A: 从 GitHub 下载（推荐）

```bash
# 方法 1: 直接执行
curl -fsSL https://raw.githubusercontent.com/ybkin1/ybkin1_openclaw_bak/main/restore-from-github.sh | bash

# 方法 2: 下载后执行
wget -O restore.sh https://raw.githubusercontent.com/ybkin1/ybkin1_openclaw_bak/main/restore-from-github.sh
bash restore.sh
```

### 方式 B: 从备份恢复（无需网络）

```bash
# 1. 下载最新备份 bundle
# 2. 解压迁移工具包
tar -xzf migration/migration_scripts_*.tar.gz -C /tmp

# 3. 执行恢复脚本
bash /tmp/restore-from-github.sh
```

### 步骤 2: 按提示操作

脚本会自动：
1. ✅ 检查并安装必要依赖（Node.js, pnpm, git）
2. ✅ 生成 SSH 密钥（如需要）
3. ✅ 克隆 GitHub 备份仓库
4. ✅ 选择最新备份
5. ✅ 验证备份完整性
6. ✅ 恢复所有配置和数据
7. ✅ 启动 OpenClaw 服务

### 步骤 3: 验证恢复

```bash
# 检查服务状态
systemctl --user status openclaw-gateway

# 查看日志
journalctl --user -u openclaw-gateway -n 50

# 发送测试消息验证飞书连接
```

---

## 📦 恢复内容清单

| 类别 | 内容 | 状态 |
|------|------|------|
| **配置文件** | openclaw.json, AGENTS.md, SOUL.md, MEMORY.md 等 | ✅ |
| **所有 Agent** | 10 个 agent 的 workspace | ✅ |
| **记忆系统** | 所有短期/长期记忆 | ✅ |
| **运维脚本** | 17 个 master scripts | ✅ |
| **Skills** | 300+ 个技能文件 | ✅ |
| **定时任务** | crontab 配置 | ✅ |
| **Systemd 服务** | Gateway + Health Guardian | ✅ |
| **SSH 密钥** | GitHub SSH Key | ✅ |

---

## 🔧 手动恢复（备选方案）

如果自动脚本失败，可以手动执行：

### 1. 准备环境

```bash
# 安装基础依赖
apt update && apt install -y nodejs npm git
npm install -g pnpm openclaw

# 生成 SSH 密钥（如需要）
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
# 将公钥添加到 GitHub
cat ~/.ssh/id_ed25519.pub
```

### 2. 下载备份

```bash
# 克隆备份仓库
git clone git@github.com:ybkin1/ybkin1_openclaw_bak.git /tmp/openclaw_restore
cd /tmp/openclaw_restore

# 选择最新备份
latest=$(ls -d openclaw_bak_* | sort | tail -1)
echo "使用备份：$latest"
```

### 3. 恢复配置

```bash
# 恢复主配置
mkdir -p /root/.openclaw/workspace/agents/master
tar -xzf $latest/config/config_*.tar.gz -C /root/.openclaw/workspace/agents/master

# 恢复 openclaw.json
cp $latest/config/openclaw.json /root/.openclaw/

# 恢复记忆系统
tar -xzf $latest/memory/memory_master_*.tar.gz -C /root/.openclaw/workspace/agents/master

# 恢复脚本
tar -xzf $latest/system/system_*.tar.gz -C /root/.openclaw/workspace/agents/master

# 恢复 SSH 密钥（如有）
tar -xzf $latest/identity/ssh_keys_*.tar.gz -C ~/.ssh
chmod 600 ~/.ssh/id_*

# 恢复 systemd 服务
tar -xzf $latest/identity/systemd_services_*.tar.gz -C ~/.config/systemd/user
systemctl --user daemon-reload
```

### 4. 启动服务

```bash
# 启动 Gateway
systemctl --user enable openclaw-gateway
systemctl --user start openclaw-gateway

# 检查状态
systemctl --user status openclaw-gateway
```

---

## ⚠️ 常见问题

### Q1: SSH 密钥验证失败

**症状**: `Permission denied (publickey)`

**解决**:
```bash
# 重新生成 SSH 密钥
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# 将公钥添加到 GitHub
# 访问：https://github.com/settings/keys
cat ~/.ssh/id_ed25519.pub
```

---

### Q2: 无法连接 GitHub

**症状**: `Could not resolve hostname github.com`

**解决**:
```bash
# 检查网络
ping github.com

# 使用 HTTPS 代替 SSH
git clone https://github.com/ybkin1/ybkin1_openclaw_bak.git
```

---

### Q3: Gateway 启动失败

**症状**: `Failed to start openclaw-gateway.service`

**解决**:
```bash
# 查看日志
journalctl --user -u openclaw-gateway -n 100

# 检查配置
openclaw doctor

# 重新安装 OpenClaw
npm install -g openclaw --force
```

---

### Q4: 飞书连接失败

**症状**: 无法发送/接收消息

**解决**:
```bash
# 检查 openclaw.json 中的飞书配置
cat /root/.openclaw/openclaw.json | jq '.channels.feishu'

# 手动配置飞书 API 密钥
# 编辑 /root/.openclaw/openclaw.json
# 填入正确的 app_id 和 app_secret
```

---

## 📊 恢复验证清单

恢复完成后，请检查以下项目：

- [ ] Gateway 服务运行正常
- [ ] 飞书消息可以正常发送/接收
- [ ] 所有 agent 配置完整
- [ ] 记忆系统正常加载
- [ ] 定时任务（crontab）已恢复
- [ ] Health Guardian 服务运行正常
- [ ] 可以执行备份命令

```bash
# 执行验证命令
systemctl --user status openclaw-gateway
systemctl --user status openclaw-health-guardian
crontab -l
/root/.openclaw/backups-unified/backup-manager.sh full
```

---

## 📞 获取帮助

如果恢复过程中遇到问题：

1. **查看日志**: `journalctl --user -u openclaw-gateway -n 100`
2. **检查配置**: `openclaw doctor`
3. **查看文档**: `RESTORE.md`（完整恢复指南）
4. **联系支持**: 提供错误日志和系统信息

---

**最后更新**: 2026-03-25  
**脚本版本**: 1.0  
**适用备份**: `openclaw_bak_20260325_160920` 及更新版本

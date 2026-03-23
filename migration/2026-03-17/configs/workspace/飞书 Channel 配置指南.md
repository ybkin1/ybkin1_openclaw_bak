# 📱 飞书 Channel 配置指南

**服务器**: 43.166.175.41  
**配置日期**: 2026-03-06  
**状态**: 扩展已安装，待配置

---

## ✅ 当前状态

飞书扩展已安装在 OpenClaw 中：
- 路径：`/root/.local/share/pnpm/global/5/.pnpm/openclaw@2026.3.2/.../extensions/feishu/`
- 状态：已加载，未配置 credentials

---

## 🔧 配置步骤

### 第一步：在飞书开放平台创建应用

1. **访问飞书开放平台**
   - 国内版：https://open.feishu.cn/app
   - 国际版 (Lark)：https://open.larksuite.com/app

2. **创建企业应用**
   - 点击「创建应用」
   - 填写应用名称（如：OpenClaw Bot）
   - 选择应用图标
   - 点击「创建」

3. **获取应用凭证**
   - 进入应用管理页面
   - 点击「凭证与基础信息」
   - 记录：
     - **App ID** (cli_xxxxxxxxxxxxx)
     - **App Secret** (点击「获取」后查看)

4. **配置应用权限**
   - 点击「权限管理」
   - 添加以下权限：
     ```
     发送消息
     读取用户信息
     事件订阅
     机器人相关
     ```
   - 点击「申请权限」

5. **配置事件订阅**
   - 点击「事件订阅」
   - 启用事件订阅
   - 记录 **Verification Token**（用于验证 webhook）
   - 订阅以下事件：
     ```
     接收消息
     消息已读
     机器人进入群组
     ```

6. **配置机器人能力**
   - 点击「机器人」
   - 启用机器人
   - 配置机器人名称和头像
   - 启用「接收消息」能力

---

### 第二步：在 OpenClaw 中配置飞书

**方式 1：使用配置向导（推荐）**

```bash
openclaw onboard
```

按照向导提示输入：
- App ID
- App Secret
- Verification Token（可选，webhook 模式需要）

**方式 2：手动编辑配置文件**

编辑 `~/.openclaw/config.json`：

```json
{
  "channels": {
    "feishu": {
      "enabled": true,
      "appId": "cli_xxxxxxxxxxxxx",
      "appSecret": "你的 App Secret",
      "verificationToken": "你的 Verification Token（可选）",
      "domain": "feishu",
      "connectionMode": "websocket",
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist"
    }
  }
}
```

**方式 3：使用 CLI 命令**

```bash
openclaw channels add --channel feishu \
  --app-id "cli_xxxxxxxxxxxxx" \
  --app-secret "你的 App Secret"
```

---

### 第三步：启动网关并验证

```bash
# 重启网关
openclaw gateway restart

# 查看状态
openclaw gateway status

# 查看日志
openclaw logs --follow
```

**成功的标志**：
- 网关状态显示 `feishu: connected`
- 日志中没有认证错误

---

### 第四步：配对飞书账号

1. **在飞书中找到机器人**
   - 给机器人发送任意消息

2. **批准配对**
   - OpenClaw 会自动回复配对确认消息
   - 或者在 CLI 中批准：
     ```bash
     openclaw approvals list
     openclaw approvals approve <id>
     ```

3. **测试对话**
   - 在飞书中给机器人发消息
   - 应该能收到回复

---

## 🔍 故障排除

### 问题 1: 网关启动失败
**检查日志**：
```bash
openclaw logs | tail -50
```

**常见原因**：
- App ID 或 App Secret 错误
- 网络连接问题
- 飞书应用权限未正确配置

### 问题 2: 收不到消息
**检查**：
1. 飞书应用中是否启用了「接收消息」
2. 事件订阅是否正确配置
3. 机器人是否已添加到聊天

### 问题 3: 无法发送消息
**检查**：
1. 飞书应用是否有「发送消息」权限
2. 机器人是否已配对
3. 网关是否正常运行

---

## 📊 配置项说明

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `enabled` | 是否启用飞书 channel | true |
| `appId` | 飞书应用 ID | 必填 |
| `appSecret` | 飞书应用密钥 | 必填 |
| `verificationToken` | 事件订阅验证令牌 | 可选 |
| `domain` | 飞书域名 (feishu/lark) | feishu |
| `connectionMode` | 连接模式 (websocket/webhook) | websocket |
| `dmPolicy` | 私聊策略 (open/pairing/allowlist) | pairing |
| `groupPolicy` | 群聊策略 (open/allowlist/disabled) | allowlist |
| `requireMention` | 群聊是否需要 @机器人 | true |

---

## 🔐 安全建议

1. **保护 App Secret**
   - 不要提交到代码仓库
   - 使用环境变量或加密存储

2. **限制访问范围**
   - 使用 `dmPolicy: "pairing"` 要求配对
   - 使用 `groupPolicy: "allowlist"` 限制群聊

3. **定期审查权限**
   - 检查飞书应用的权限列表
   - 移除不需要的权限

---

## 📞 需要帮助？

如果配置过程中遇到问题：
1. 查看日志：`openclaw logs --follow`
2. 检查状态：`openclaw gateway status`
3. 查看文档：https://docs.openclaw.ai/channels/feishu

---

**配置完成日期**: 待配置  
**下次审查**: 配置完成后记录

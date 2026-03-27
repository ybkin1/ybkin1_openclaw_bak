# 框架基线排除清单

以下文件**未**包含在框架基线中，恢复时需手动配置：

## 系统配置（不备份）
- ❌ openclaw.json (Gateway 配置)
- ❌ .gateway_token (认证 token)
- ❌ exec-approvals.json (执行审批)

## Agent 独立配置（不备份）
- ❌ */agent.json (Agent 模型配置)
- ❌ */models.json (Provider 配置)
- ❌ */.openclaw/ (Agent 运行时配置)

## 记忆内容（不备份）
- ❌ memory/daily/ (每日日志)
- ❌ memory/short_term/ (短期记忆)
- ❌ memory/*/tasks/ (任务数据)
- ❌ memory/archive/ (归档记忆)

## 外部数据（不备份）
- ❌ 数据库文件
- ❌ 临时缓存
- ❌ SSH keys
- ❌ Device auth

## 原因说明

框架基线的目的是保存**架构配置**和**工作流程**，不包含：
1. **系统配置**：每台服务器的 Gateway 配置可能不同（端口、网络等）
2. **赛道数据**：领域相关的记忆和数据应单独备份
3. **敏感信息**：认证 token、SSH keys 等应通过安全渠道传输

恢复时，这些内容会：
- 系统配置 → 保留目标服务器的现有配置
- 赛道数据 → 从赛道备份中恢复
- 敏感信息 → 手动配置或从安全存储恢复

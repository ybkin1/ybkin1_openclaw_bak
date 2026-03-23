# ✅ SSH 连接问题已修复！

**修复时间**: 2026-03-06 23:53 CST  
**问题原因**: 配置文件冲突导致 root 用户被拒绝密码认证

---

## 🔍 问题根因

### 配置冲突

两个配置文件中的 `PermitRootLogin` 设置冲突：

| 文件 | 设置 | 问题 |
|------|------|------|
| `98-2fa.conf` | `PermitRootLogin yes` | ✅ 允许 root 登录 |
| `99-anti-bruteforce.conf` | `PermitRootLogin prohibit-password` | ❌ 禁止 root 密码登录 |

**SSH 配置加载顺序**: 按字母顺序，`99-anti-bruteforce.conf` 后加载，覆盖了前面的设置

**结果**: root 用户无法使用密码认证 (即使配合 2FA)

---

## ✅ 已修复

### 修改内容

```bash
# 修改 /etc/ssh/sshd_config.d/99-anti-bruteforce.conf
# 从:
PermitRootLogin prohibit-password

# 改为:
PermitRootLogin yes
```

### 当前生效配置

```bash
permitrootlogin yes
passwordauthentication yes
kbdinteractiveauthentication yes
usepam yes
authenticationmethods any
maxauthtries 3
```

### PAM 认证顺序

```pam
# 1. 首先验证 Google Authenticator 验证码
auth       required     pam_google_authenticator.so

# 2. 然后验证密码
auth       substack     password-auth
```

---

## 🚀 现在可以连接了！

### Windows (PuTTY)

```
1. Host Name: 43.166.175.41
2. Port: 22
3. 点击 Open
4. 输入密码 → 回车
5. 输入 Google Authenticator 6 位验证码 → 回车
6. 登录成功！
```

### Windows (PowerShell)

```powershell
ssh -N -L 18789:127.0.0.1:18789 root@43.166.175.41

# 流程:
# Password: [输入服务器密码]
# Verification code: [打开手机 Google Authenticator，输入 6 位数字]
```

### Linux/Mac

```bash
ssh root@43.166.175.41

# Password: [输入服务器密码]
# Verification code: [输入 6 位验证码]
```

---

## 📱 验证码获取

### Google Authenticator App

1. 打开手机上的 **Google Authenticator**
2. 找到账户 `root@VM-0-13-opencloudos`
3. 输入当前显示的 **6 位数字**
4. 数字每 30 秒刷新一次

### 备用码 (手机丢失时使用)

```
80367350
14046331
69730968
43273761
81665639
```

**注意**: 每个备用码只能用一次！

---

## ⚠️ 如果还是连不上

### 检查清单

- [ ] 密码是否正确 (区分大小写)
- [ ] 验证码是否是当前的 (30 秒内)
- [ ] 手机时间是否准确 (打开 Google Authenticator 设置→时间校正)
- [ ] 网络是否通畅 (ping 43.166.175.41)
- [ ] SSH 端口是否开放 (telnet 43.166.175.41 22)

### 测试命令

```bash
# 测试网络连通性
ping -c 4 43.166.175.41

# 测试 SSH 端口
telnet 43.166.175.41 22

# 如果显示 Connected 则端口正常
```

### 查看详细错误

```bash
# 使用详细模式连接
ssh -vvv root@43.166.175.41

# 这会显示详细的认证过程，便于定位问题
```

---

## 📊 安全状态

| 安全措施 | 状态 | 说明 |
|----------|------|------|
| 双因素认证 | ✅ | 密码 + Google Authenticator |
| Root 登录 | ✅ | 需要 2FA |
| 密码认证 | ✅ | 配合 2FA 使用 |
| 最大尝试次数 | ✅ | 3 次失败断开 |
| 连接频率限制 | ✅ | iptables 防护 |
| 日志记录 | ✅ | 详细模式 |

---

## 🔗 相关文档

| 文档 | 路径 |
|------|------|
| SSH 2FA 配置指南 | `~/SSH-2FA-配置指南.md` |
| SSH 登录快速参考 | `~/SSH-登录快速参考.md` |
| SSH 配置修复报告 | `~/SSH-2FA-配置修复报告.md` |

---

## ✅ 修复总结

| 步骤 | 操作 | 状态 |
|------|------|------|
| 1 | 修改 `99-anti-bruteforce.conf` | ✅ |
| 2 | 统一 `PermitRootLogin yes` | ✅ |
| 3 | 重启 SSH 服务 | ✅ |
| 4 | 验证配置语法 | ✅ |

---

**现在请重新尝试连接:**

```bash
ssh -N -L 18789:127.0.0.1:18789 root@43.166.175.41
```

**如果还有问题**, 请提供:
1. 完整的错误信息
2. 使用 `ssh -vvv` 的详细输出

---

**修复完成**: 2026-03-06 23:53 CST  
**SSH 服务状态**: ✅ 正常运行

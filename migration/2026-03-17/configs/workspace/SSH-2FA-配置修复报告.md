# 🔐 SSH 2FA 配置修复报告

**修复时间**: 2026-03-06 23:41 CST  
**问题**: 密码和验证码正确但 SSH 连接被关闭

---

## 🔍 问题诊断

### 日志分析

从 SSH 日志中发现关键错误：

```
Mar 06 23:34:25 sshd(pam_google_authenticator)[1363579]: 
  Dummy password supplied by PAM. Did OpenSSH 'PermitRootLogin <anything but yes>' 
  or some other config block this login?
```

**根本原因**: PAM 配置顺序错误

---

## ❌ 原配置问题

### 原 `/etc/pam.d/sshd` 配置

```pam
#%PAM-1.0
auth       substack     password-auth     ← 先验证密码
auth       include      postlogin
...
auth required pam_google_authenticator.so nullok  ← 最后才验证 2FA (位置错误!)
account required pam_google_authenticator.so
```

**问题**:
1. Google Authenticator 放在了密码认证之后
2. `password-auth` 子栈可能已经拒绝了登录
3. 2FA 验证实际上没有被正确执行

---

## ✅ 修复方案

### 新 `/etc/pam.d/sshd` 配置

```pam
#%PAM-1.0
# Google Authenticator 2FA - 必须放在最前面！
auth       required     pam_google_authenticator.so

# 标准密码认证
auth       substack     password-auth
auth       include      postlogin

account    required     pam_sepermit.so
account    required     pam_nologin.so
account    include      password-auth
account    required     pam_google_authenticator.so  ← 账户验证也需要

password   include      password-auth

session    required     pam_selinux.so close
session    required     pam_loginuid.so
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    optional     pam_motd.so
session    include      password-auth
session    include      postlogin
```

**关键改动**:
1. ✅ `pam_google_authenticator.so` 放在 `auth` 栈的最前面
2. ✅ 先验证 2FA 验证码，再验证密码
3. ✅ `account` 栈也添加了 2FA 验证

---

## 🔧 SSH 配置状态

### 当前生效配置

```bash
# /etc/ssh/sshd_config.d/98-2fa.conf
ChallengeResponseAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
PermitRootLogin yes
PasswordAuthentication yes
```

### 验证结果

```bash
$ /usr/sbin/sshd -t
SSH 配置语法检查通过 ✓

$ systemctl status sshd
Active: active (running) ✓
```

---

## 📱 正确的登录流程

### Windows (PuTTY)

1. **打开 PuTTY**
   - Host Name: `43.166.175.41`
   - Port: `22`
   - Connection type: `SSH`

2. **点击 Open**

3. **输入密码**
   ```
   root@43.166.175.41's password:
   [输入服务器密码，不显示，正常]
   ```

4. **输入验证码**
   ```
   Verification code:
   [打开手机 Google Authenticator，输入 6 位数字]
   ```

5. **登录成功**

---

### Linux/Mac (命令行)

```bash
ssh root@43.166.175.41

# 流程:
# 1. 输入密码 → 回车
# 2. 输入验证码 → 回车
# 3. 登录成功
```

---

### Windows (PowerShell/OpenSSH)

```powershell
ssh root@43.166.175.41

# 流程同上
```

---

## 🔑 紧急备用码

如果手机丢了或验证码不对，使用备用码登录：

```
80367350
14046331
69730968
43273761
81665639
```

**注意**: 每个备用码只能用一次！

---

## ⚠️ 常见问题排查

### 问题 1: "Verification code 错误"

**原因**: 手机时间不同步

**解决**:
1. 打开 Google Authenticator App
2. 设置 → 时间校正 → 立即同步

### 问题 2: "Permission denied"

**原因**: 密码或验证码错误

**解决**:
1. 确认密码正确（区分大小写）
2. 确认验证码是当前 30 秒内的
3. 使用备用码尝试

### 问题 3: "Connection closed"

**原因**: 可能是 iptables 或配置问题

**解决**:
```bash
# 检查 SSH 服务
systemctl status sshd

# 检查配置
/usr/sbin/sshd -t

# 重启 SSH
systemctl restart sshd
```

---

## 📊 安全状态

| 安全措施 | 状态 |
|----------|------|
| 双因素认证 (2FA) | ✅ 已启用 |
| 密码认证 | ✅ 已启用 (配合 2FA) |
| Root 登录 | ✅ 允许 (需 2FA) |
| 连接频率限制 | ✅ 60 秒最多 4 次 |
| 最大尝试次数 | ✅ 3 次失败断开 |
| iptables 防护 | ✅ 已配置 |

---

## 🔗 相关文件

| 文件 | 用途 |
|------|------|
| `/etc/pam.d/sshd` | PAM 认证配置 (已修复) |
| `/root/.google_authenticator` | 2FA 密钥 |
| `/etc/ssh/sshd_config.d/98-2fa.conf` | SSH 2FA 配置 |
| `/etc/ssh/sshd_config.d/99-anti-bruteforce.conf` | 防爆破配置 |

---

## ✅ 验证步骤

现在可以重新尝试连接：

```bash
# 从 Windows PowerShell 或 Linux/Mac
ssh root@43.166.175.41

# 输入密码 → 回车
# 输入 Google Authenticator 6 位验证码 → 回车
```

**如果还有问题**, 请提供:
1. 完整的错误信息
2. 使用的 SSH 客户端 (PuTTY/PowerShell/其他)
3. 是从哪个网络连接的 (家庭/公司/移动数据)

---

**修复完成时间**: 2026-03-06 23:41 CST  
**SSH 服务状态**: ✅ 正常运行

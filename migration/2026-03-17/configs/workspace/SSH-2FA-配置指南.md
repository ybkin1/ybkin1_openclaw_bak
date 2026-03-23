# 🔐 SSH 安全访问配置指南

**服务器**: 43.166.175.41  
**配置日期**: 2026-03-06  
**安全级别**: 双因素认证 (2FA)

---

## 📋 认证方式

本次配置采用 **双因素认证 (2FA)**，登录需要同时满足：
1. **服务器密码** - 只有你知道
2. **Google Authenticator 验证码** - 只有你的手机能生成（6 位动态码，30 秒刷新）

**优势**：
- ✅ 任何设备都能登录（电脑、手机、平板）
- ✅ 不需要配置 SSH 密钥
- ✅ 即使密码泄露，黑客没有你的手机也登不上
- ✅ 即使手机丢了，还有备用码可以应急

---

## 📱 第一步：配置手机验证码

### 1. 安装 Google Authenticator App

| 平台 | 下载 |
|------|------|
| iOS | [App Store - Google Authenticator](https://apps.apple.com/app/google-authenticator/id388497605) |
| Android | [Google Play](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2) |
| 安卓备用 | [Microsoft Authenticator](https://apps.microsoft.com/detail/9nblggh0347x) |

### 2. 扫描二维码

**二维码 URL**（复制到浏览器查看）：
```
https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&chl=otpauth://totp/root@VM-0-13-opencloudos%3Fsecret%3DMS3OG2QZSJVNPGIDSJAYQRX6YM%26issuer%3DVM-0-13-opencloudos
```

**或手动输入密钥**：
```
账户名：root@VM-0-13-opencloudos
密钥：MS3OG2QZSJVNPGIDSJAYQRX6YM
```

### 3. 保存紧急备用码 ⚠️

**重要！** 把这些代码保存在安全的地方（密码管理器/打印），手机丢失时用来登录：

```
80367350
14046331
69730968
43273761
81665639
```

每个备用码只能用一次！

---

## 💻 第二步：配置 SSH 客户端（可选）

### Linux/Mac 配置（方便记忆主机名）

编辑 `~/.ssh/config`：
```bash
Host server-43
    HostName 43.166.175.41
    User root
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### Windows 用户

直接用 PuTTY 或 PowerShell，不需要额外配置。

---

## 🚀 第三步：测试登录

```bash
# 连接服务器
ssh root@43.166.175.41

# 或如果配置了 config
ssh server-43
```

**登录流程**：
1. 输入密码：`root@43.166.175.41's password:`
   - 输入服务器密码（不显示，正常）
2. 输入验证码：`Verification code:`
   - 打开手机上的 Google Authenticator
   - 输入当前 6 位数字（30 秒刷新）
3. 登录成功！

**Windows (PuTTY)**:
1. Host Name: `43.166.175.41`
2. Port: `22`
3. 点击 Open
4. 输入密码
5. 输入验证码

---

## 📲 多设备配置

如果你想在多个设备（手机 + 平板 + 备用手机）上都能生成验证码：

**方法 1：导出二维码**
1. 在主手机上用 Google Authenticator 导出账号
2. 其他设备扫描二维码

**方法 2：同一密钥导入多个设备**
1. 每个设备都手动输入密钥：`MS3OG2QZSJVNPGIDSJAYQRX6YM`
2. 所有设备会生成相同的验证码

---

## ⚠️ 故障排除

### 问题 1: "Permission denied (publickey,keyboard-interactive)"
**原因**: 私钥权限不对  
**解决**: `chmod 600 ~/.ssh/id_ed25519`

### 问题 2: 验证码错误
**原因**: 手机时间不同步  
**解决**: 
- 打开 Google Authenticator → 设置 → 时间校正
- 或手动同步手机时间

### 问题 3: 手机丢了怎么办？
**解决**: 使用紧急备用码登录，然后重新配置 2FA
```bash
# 登录时使用备用码代替验证码
# 登录后删除旧配置：rm /root/.google_authenticator
# 重新运行：google-authenticator
```

### 问题 4: 被锁在外面了！
**解决**: 
1. 联系服务器提供商通过控制台访问
2. 或临时禁用 2FA（修改 SSH 配置）

---

## 🔧 临时禁用 2FA（紧急情况）

如果遇到问题需要临时禁用 2FA：

```bash
# 1. 通过控制台或现有会话登录
# 2. 编辑 SSH 配置
vi /etc/ssh/sshd_config.d/98-2fa.conf

# 3. 注释掉这行
# AuthenticationMethods publickey,keyboard-interactive

# 4. 重启 SSH
systemctl restart sshd

# 5. 问题解决后记得重新启用！
```

---

## 📊 安全配置清单

| 配置项 | 状态 | 说明 |
|--------|------|------|
| 双因素认证 | ✅ | 密码 + Google Authenticator |
| 密码登录 | ✅ | 需要密码 + 验证码 |
| SSH 密钥 | ⭕ | 可选，有密钥可跳过密码 |
| Root 登录 | ✅ | 需要 2FA |
| 连接频率限制 | ✅ | 60 秒最多 4 次 |
| 最大尝试次数 | ✅ | 3 次失败断开 |
| 空闲超时 | ✅ | 180 秒无响应断开 |
| 日志记录 | ✅ | 详细模式 |
| iptables 防护 | ✅ | 自动拦截暴力破解 |

---

## 📞 需要帮助？

如果配置过程中遇到问题，提供以下信息：
1. 客户端操作系统
2. SSH 客户端版本 (`ssh -V`)
3. 完整错误信息
4. 已经尝试过的解决方法

---

**配置完成日期**: 2026-03-06  
**下次审查**: 2026-06-06（每季度审查一次）

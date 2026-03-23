# 文档处理技能配置

_最后更新：2026-03-05_

---

## 📄 已安装的文档技能

| 技能 | 用途 | 状态 | 安装方式 |
|------|------|------|----------|
| **nano-pdf** | PDF 编辑 | ✅ 已安装 | `pip install nano-pdf` |
| **summarize** | 内容摘要 | ✅ 已安装 | 二进制文件 |
| **agent-browser** | 网页内容提取 | ✅ 可用 | 内置技能 |

---

## 🔧 nano-pdf 配置

### 安装状态

```bash
which nano-pdf
# 输出：/usr/local/bin/nano-pdf

nano-pdf --version
# 输出：0.2.1
```

### 使用示例

```bash
# 编辑 PDF 第 1 页
nano-pdf edit document.pdf 1 "将标题改为'Q3 结果'并修复副标题中的拼写错误"

# 编辑 PDF 第 5 页
nano-pdf edit report.pdf 5 "添加公司 Logo 到右上角"

# 批量处理
for page in 1 2 3; do
  nano-pdf edit deck.pdf $page "统一字体为 Arial"
done
```

### 注意事项

- ⚠️ 页码从 0 或 1 开始（取决于版本），如果结果偏移请重试另一个
- ✅ 始终在发送前检查输出的 PDF
- 📝 支持自然语言指令

### API 密钥配置

nano-pdf 使用 Google GenAI，需要配置：

```bash
export GOOGLE_API_KEY="your-api-key"
# 或
export GOOGLE_GENERATIVE_AI_API_KEY="your-api-key"
```

**获取密钥**: https://makersuite.google.com/app/apikey

---

## 📝 summarize 配置

### 安装状态

```bash
which summarize
# 输出：/usr/local/bin/summarize
```

### 使用示例

```bash
# 总结网页
summarize "https://example.com/article"

# 总结 PDF 文件
summarize "/path/to/document.pdf"

# 总结 YouTube 视频
summarize "https://youtu.be/dQw4w9WgXcQ" --youtube auto

# 指定模型
summarize "https://example.com" --model google/gemini-2-flash-preview

# 指定长度
summarize "https://example.com" --length short
summarize "https://example.com" --length medium
summarize "https://example.com" --length long

# JSON 输出（机器可读）
summarize "https://example.com" --json

# 仅提取内容（不总结）
summarize "https://example.com" --extract-only
```

### API 密钥配置

根据选择的模型配置对应的 API 密钥：

```bash
# Google (默认)
export GEMINI_API_KEY="your-key"
# 或
export GOOGLE_GENERATIVE_AI_API_KEY="your-key"
# 或
export GOOGLE_API_KEY="your-key"

# OpenAI
export OPENAI_API_KEY="your-key"

# Anthropic
export ANTHROPIC_API_KEY="your-key"

# xAI
export XAI_API_KEY="your-key"
```

**默认模型**: `google/gemini-2-flash-preview`

### 配置文件

可选配置文件：`~/.summarize/config.json`

```json
{
  "model": "google/gemini-2-flash-preview",
  "length": "medium"
}
```

### 高级选项

| 参数 | 说明 | 示例 |
|------|------|------|
| `--length` | 摘要长度 | `short\|medium\|long\|xl\|xxl\|<chars>` |
| `--max-output-tokens` | 最大输出 token 数 | `--max-output-tokens 500` |
| `--extract-only` | 仅提取内容（不总结） | 仅 URL 有效 |
| `--json` | JSON 格式输出 | 机器可读 |
| `--firecrawl` | Firecrawl 回退提取 | `auto\|off\|always` |
| `--youtube` | YouTube 提取 | `auto` (需要 Apify Token) |

### 可选服务

```bash
# Firecrawl (用于被阻止的网站)
export FIRECRAWL_API_KEY="your-key"

# Apify (YouTube 回退)
export APIFY_API_TOKEN="your-token"
```

---

## 🌐 agent-browser 配置

### 使用示例

```bash
# 导航到网页
browser action=navigate targetUrl="https://example.com"

# 获取快照
browser action=snapshot

# 截图
browser action=screenshot

# 点击元素
browser action=act ref="e12" kind="click"

# 输入文本
browser action=act ref="e15" kind="type" text="搜索内容"
```

### 触发条件

- 用户说"查看这个网页..."时
- 需要网页截图时
- 自动化网页操作时

---

## 📊 技能选择决策树

```
用户请求处理文档
├─ PDF 编辑/修改？
│  └─ nano-pdf ✅
│
├─ 内容摘要？
│  ├─ URL/网页 → summarize ✅
│  ├─ PDF 文件 → summarize ✅
│  ├─ YouTube 视频 → summarize ✅
│  └─ 音频文件 → summarize ✅
│
├─ 网页内容提取？
│  ├─ 简单页面 → summarize --extract-only ✅
│  └─ 复杂交互 → agent-browser ✅
│
└─ 格式转换？
   ├─ PDF → Markdown → summarize + nano-pdf
   └─ 网页 → Markdown → summarize --extract-only
```

---

## 🎯 使用场景示例

### 场景 1: 快速了解长文章

```bash
# 用户："帮我总结一下这篇文章"
summarize "https://example.com/long-article" --length medium
```

### 场景 2: PDF 报告修改

```bash
# 用户："把这份 PDF 第 3 页的标题改一下"
nano-pdf edit report.pdf 3 "将标题改为'2026 年第一季度财务报告'"
```

### 场景 3: YouTube 视频摘要

```bash
# 用户："这个视频讲了什么？"
summarize "https://youtu.be/video-id" --youtube auto
```

### 场景 4: 网页内容提取

```bash
# 用户："保存这个网页的内容"
summarize "https://example.com" --extract-only > content.md
```

### 场景 5: 批量处理 PDF

```bash
# 用户："统一所有 PDF 的字体"
for pdf in *.pdf; do
  nano-pdf edit "$pdf" 1 "使用 Arial 字体，12 号"
done
```

---

## ⚠️ 待办事项

- [ ] 配置 Google API Key (nano-pdf 和 summarize)
- [ ] 测试 nano-pdf 实际功能
- [ ] 测试 summarize 各种模型
- [ ] 配置 Firecrawl API (可选，用于被阻止的网站)
- [ ] 配置 Apify Token (可选，用于 YouTube 提取)

---

## 📚 相关文档

- nano-pdf PyPI: https://pypi.org/project/nano-pdf/
- summarize GitHub: https://github.com/steipete/summarize
- Google AI Studio: https://makersuite.google.com/app/apikey

---

## 🔍 快速测试

```bash
# 测试 nano-pdf
nano-pdf --help

# 测试 summarize
summarize --help

# 测试 summarize (示例 URL)
summarize "https://example.com" --length short
```

#!/bin/bash
# 核心文件推送到 GitHub 脚本
# 用法：./push-core-files.sh [git 仓库 URL] [提交信息]

set -e

WORKSPACE="${HOME}/.openclaw/workspace"
CORE_FILES=(
    "SOUL.md"
    "MEMORY.md"
    "AGENTS.md"
    "USER.md"
)

# 检查参数
GIT_REPO="${1:-}"
COMMIT_MSG="${2:-chore: daily backup of core files}"

if [ -z "${GIT_REPO}" ]; then
    echo "❌ 请提供 Git 仓库 URL"
    echo "用法：$0 <git-repo-url> [commit-message]"
    exit 1
fi

cd "${WORKSPACE}"

# 检查文件是否存在
MISSING_FILES=()
for file in "${CORE_FILES[@]}"; do
    if [ ! -f "${file}" ]; then
        MISSING_FILES+=("${file}")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "⚠️ 以下文件不存在："
    for file in "${MISSING_FILES[@]}"; do
        echo "   - ${file}"
    done
    echo "继续推送存在的文件..."
fi

# 初始化 git (如果未初始化)
if [ ! -d ".git" ]; then
    echo "📦 初始化 Git 仓库..."
    git init
    git config user.email "agent@openclaw.local"
    git config user.name "OpenClaw Agent"
fi

# 检查远程仓库
if ! git remote | grep -q origin; then
    echo "🔗 添加远程仓库..."
    git remote add origin "${GIT_REPO}"
fi

# 添加文件
echo "📝 添加核心文件..."
for file in "${CORE_FILES[@]}"; do
    if [ -f "${file}" ]; then
        git add "${file}"
        echo "   ✅ ${file}"
    fi
done

# 检查是否有变更
if git diff --cached --quiet; then
    echo "✨ 没有变更，跳过推送"
    exit 0
fi

# 提交
echo "💾 提交变更..."
git commit -m "${COMMIT_MSG} ($(date +%Y-%m-%d))"

# 推送
echo "🚀 推送到 GitHub..."
git push origin master || git push origin main

echo "✅ 推送完成"

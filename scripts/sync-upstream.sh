#!/bin/bash
# 上游同步脚本 - 从 appdev/siyuan-unlock 同步更新
# 用法: ./scripts/sync-upstream.sh

set -e  # 遇到错误立即退出

echo "🔄 开始同步上游 appdev/siyuan-unlock..."
echo ""

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ 错误：当前目录不是 Git 仓库"
    exit 1
fi

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  警告：检测到未提交的更改"
    git status --short
    echo ""
    read -p "是否暂存这些更改并继续？(y/N): " stash_confirm
    if [ "$stash_confirm" = "y" ]; then
        git stash push -m "Auto-stash before upstream sync"
        echo "✅ 更改已暂存"
    else
        echo "❌ 同步已取消，请先提交或暂存更改"
        exit 1
    fi
fi

# 1. 拉取上游更新
echo "📥 拉取上游更新..."
if ! git fetch upstream; then
    echo "❌ 错误：拉取上游失败"
    echo "请检查 upstream 远程仓库配置："
    git remote -v
    exit 1
fi
echo "✅ 上游更新已拉取"
echo ""

# 2. 查看变更摘要
echo "📊 上游变更摘要:"
git log HEAD..upstream/master --oneline --graph --max-count=10
echo ""

# 3. 检查补丁文件是否有变更
echo "🔍 检查补丁文件变更:"
if git diff HEAD..upstream/master --quiet -- patches/; then
    echo "✅ 补丁文件无变更"
else
    echo "⚠️  补丁文件有变更，详情如下："
    git diff HEAD..upstream/master --stat -- patches/
    echo ""
    echo "变更详情："
    git diff HEAD..upstream/master -- patches/
fi
echo ""

# 4. 用户确认
read -p "是否继续合并？(y/N): " confirm
if [ "$confirm" != "y" ]; then
    echo "❌ 同步已取消"
    exit 0
fi

# 5. 合并上游更新
echo ""
echo "🔀 合并上游更新..."
if git merge upstream/master --no-edit; then
    echo "✅ 合并成功"
else
    echo "⚠️  检测到合并冲突，请手动解决："
    echo ""
    git status
    echo ""
    echo "解决冲突后运行："
    echo "  git add ."
    echo "  git commit"
    echo "  cd app && bash ../scripts/apply-patches.sh"
    echo "  cd app && pnpm run tsc"
    exit 1
fi
echo ""

# 6. 应用补丁（确保补丁生效）
echo "🔧 应用补丁..."
if [ -f "scripts/apply-patches.sh" ]; then
    cd app
    if bash ../scripts/apply-patches.sh; then
        echo "✅ 补丁应用成功"
    else
        echo "⚠️  补丁应用失败，请检查补丁文件"
        cd ..
        exit 1
    fi
    cd ..
else
    echo "⚠️  警告：未找到 scripts/apply-patches.sh"
fi
echo ""

# 7. 安装依赖（如果 package.json 有变更）
if git diff HEAD@{1} HEAD --quiet -- app/package.json; then
    echo "✅ package.json 无变更，跳过依赖安装"
else
    echo "📦 检测到 package.json 变更，安装依赖..."
    cd app
    if pnpm install; then
        echo "✅ 依赖安装成功"
    else
        echo "❌ 依赖安装失败"
        cd ..
        exit 1
    fi
    cd ..
fi
echo ""

# 8. 测试密码锁插件兼容性
echo "🧪 测试密码锁插件兼容性..."
cd app
if pnpm run tsc; then
    echo "✅ TypeScript 类型检查通过"
else
    echo "❌ TypeScript 类型检查失败"
    echo "密码锁插件可能需要调整以兼容新版本"
    cd ..
    exit 1
fi
cd ..
echo ""

# 9. 恢复暂存的更改（如果有）
if git stash list | grep -q "Auto-stash before upstream sync"; then
    echo "📦 恢复之前暂存的更改..."
    if git stash pop; then
        echo "✅ 更改已恢复"
    else
        echo "⚠️  恢复暂存更改时出现冲突，请手动解决"
    fi
    echo ""
fi

# 10. 完成
echo "✅ 上游同步完成！"
echo ""
echo "📝 下一步建议："
echo "  1. 运行完整测试: cd app && pnpm run dev"
echo "  2. 手动测试密码锁功能是否正常工作"
echo "  3. 检查是否需要更新版本号: app/package.json"
echo "  4. 推送更新: git push origin master"
echo ""

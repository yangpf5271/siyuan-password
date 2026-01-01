# Patches - 补丁文件说明

本目录包含从上游项目 `appdev/siyuan-unlock` 继承的补丁文件。

## 核心原则

⚠️ **重要**：所有补丁文件必须与上游 `appdev/siyuan-unlock` 保持 100% 一致。

**禁止操作**：
- ❌ 修改现有补丁文件
- ❌ 删除上游补丁
- ❌ 在补丁中添加密码锁相关代码

**密码锁功能**应作为独立插件实现（`app/src/plugins/password-lock/`），而非补丁方式。

## 补丁列表

### siyuan/ - 核心补丁

#### default-config.patch
**用途**：修改默认配置

**主要变更**：
- 云同步提供商：SiYuan → S3
- 默认语言：en_US → zh_CN
- 隐藏 VIP 显示标识
- 默认生成冲突文档
- 关闭按钮行为：最小化到托盘

**来源**：appdev/siyuan-unlock

**应用位置**：
- `kernel/conf/sync.go` - 云同步配置
- `kernel/conf/account.go` - 账户配置
- `kernel/conf/appearance.go` - 外观配置

**具体修改**：
```go
// sync.go
- Provider: ProviderSiYuan  → Provider: ProviderS3
- GenerateConflictDoc: false → GenerateConflictDoc: true

// account.go
- DisplayTitle: true  → DisplayTitle: false
- DisplayVIP: true    → DisplayVIP: false

// appearance.go
- Lang: "en_US"            → Lang: "zh_CN"
- CloseButtonBehavior: 0   → CloseButtonBehavior: 1
```

#### disable-update.patch
**用途**：禁用自动更新检查

**主要变更**：
- 注释掉 `checkUpdate()` API 函数体
- 强制 `DownloadInstallPkg = false`（禁止自动下载安装包）
- 禁用打开帮助文档时的自动更新检查

**来源**：appdev/siyuan-unlock

**应用位置**：
- `kernel/api/system.go` - 检查更新 API
- `kernel/model/updater.go` - 更新器模型
- `kernel/conf/system.go` - 系统配置
- `kernel/model/mount.go` - 挂载模型

**具体修改**：
```go
// api/system.go - 禁用检查更新 API
func checkUpdate(c *gin.Context) {
-   ret := gulu.Ret.NewResult()
-   defer c.JSON(http.StatusOK, ret)
-   arg, ok := util.JsonArg(c, ret)
-   if !ok { return }
-   showMsg := arg["showMsg"].(bool)
-   model.CheckUpdate(showMsg)
+   return  // 直接返回，不执行任何逻辑
}

// model/updater.go - 强制禁用下载
if !Conf.System.DownloadInstallPkg {
    return true
+} else {
+   Conf.System.DownloadInstallPkg = false
+   Conf.Save()
+   return true
}

// conf/system.go - 默认配置
- DownloadInstallPkg: true
+ DownloadInstallPkg: false

// model/mount.go - 禁用帮助文档打开时的自动检查
- time.Sleep(time.Second * 10)
- CheckUpdate(true)
+ // 注释掉自动检查
```

#### mock-vip-user.patch
**用途**：模拟 VIP 用户（解锁订阅限制）

**主要变更**：
- 重写 `getCloudUser()` 函数，返回模拟的 VIP 用户数据
- 设置永久 VIP 状态（`UserSiYuanProExpireTime: -1`）
- 模拟订阅类型和一次性支付状态

**来源**：appdev/siyuan-unlock

**应用位置**：
- `kernel/api/setting.go` - 用户设置 API

**具体修改**：
```go
// 保留原函数为 getCloudUserOrigin()
func getCloudUserOrigin(c *gin.Context) {
    // 原逻辑保持不变
}

// 新增模拟函数
func getCloudUser(c *gin.Context) {
    ret := gulu.Ret.NewResult()
    defer c.JSON(http.StatusOK, ret)

    if !model.IsAdminRoleContext(c) {
        return
    }

    // 构造模拟 VIP 用户
    user := &conf.User{
        UserId: "0",
        UserName: "_",
        UserAvatarURL: "data:image/gif;base64,...",
        UserCreateTime: "29991231 00:00:00",
        UserSiYuanProExpireTime: -1,  // 永久 VIP
        UserToken: "token",
        UserTokenExpireTime: "32503593600",  // 超长过期时间
        UserSiYuanSubscriptionType: 1,       // 订阅类型
        UserSiYuanOneTimePayStatus: 1,       // 一次性支付状态
    }

    model.Conf.User = user
    data, _ := gulu.JSON.MarshalJSON(user)
    model.Conf.UserData = util.AESEncrypt(string(data))
    model.Conf.Save()

    ret.Data = user
}
```

**效果**：
- ✅ 云同步功能无限制
- ✅ 导出功能无限制
- ✅ 所有 VIP 功能解锁

### siyuan-android/ - Android 平台补丁

#### debug-build.patch
**用途**：Android 调试构建修复

**来源**：appdev/siyuan-unlock

**说明**：修复 Android 平台的调试构建相关问题。

### siyuan-ios/ - iOS 平台补丁

#### build-failed.patch
**用途**：iOS 构建失败修复

**来源**：appdev/siyuan-unlock

**说明**：修复 iOS 平台的构建失败问题。

## 应用补丁

### 手动应用（开发环境）
```bash
cd app && bash ../scripts/apply-patches.sh
```

或者：
```bash
cd app && pnpm run apply-patches
```

### Docker 构建自动应用
Docker 构建过程会自动应用所有补丁（参见 `.github/workflows/release-docker.yml`）：
```yaml
- name: clone origin and apply patches
  run: |
    git clone --branch ${{ github.event.inputs.version }} --depth=1 https://github.com/siyuan-note/siyuan.git
    cd siyuan

    git apply patches/siyuan/disable-update.patch
    git apply patches/siyuan/default-config.patch
    git apply patches/siyuan/mock-vip-user.patch
```

## 上游同步

### 自动同步（推荐）
使用项目提供的自动化脚本：
```bash
./scripts/sync-upstream.sh
```

**同步流程**：
1. 拉取 `appdev/siyuan-unlock` 的最新更新
2. 合并更新到本地（补丁文件会自动覆盖）
3. 重新应用所有补丁
4. 运行 TypeScript 类型检查验证兼容性

### 手动同步
如果自动化脚本不可用：
```bash
# 1. 拉取上游更新
git fetch upstream
git merge upstream/master

# 2. 如果补丁文件有冲突，直接使用上游版本
git checkout --theirs patches/

# 3. 重新应用补丁
cd app && bash ../scripts/apply-patches.sh

# 4. 测试兼容性
cd app && pnpm run tsc
```

### 同步策略

**补丁文件处理**：
- ✅ **直接覆盖**：补丁文件冲突时，使用上游版本
- ✅ **不修改**：本项目永远不修改补丁文件
- ✅ **自动合并**：Git 可以安全地合并补丁文件

**验证检查**：
```bash
# 检查补丁文件是否与上游一致
git diff upstream/master -- patches/

# 应该输出空（无差异）
```

## 补丁来源追踪

**上游仓库**：https://github.com/appdev/siyuan-unlock

**补丁目录**：https://github.com/appdev/siyuan-unlock/tree/master/patches

**变更历史**：
- 查看上游补丁的提交历史
- 了解补丁的演进过程
- 追踪特定补丁的修改原因

## 常见问题

### Q: 为什么不能修改补丁文件？

**A**: 保持与上游 100% 一致是为了：
- ✅ 减少同步冲突（补丁文件可以直接合并）
- ✅ 简化维护（不需要手动解决补丁冲突）
- ✅ 功能完整性（完全继承上游的解锁功能）

### Q: 密码锁功能应该如何实现？

**A**: 密码锁功能必须作为**独立插件**实现：
- 📁 位置：`app/src/plugins/password-lock/`
- 🔌 方式：继承 `Plugin` 基类
- 🎯 优势：与上游同步零冲突

### Q: 补丁应用失败怎么办？

**A**: 按以下步骤排查：
1. 确认是否从官方 SiYuan 仓库克隆了源代码
2. 检查补丁文件是否完整（未被修改）
3. 确认 Git 版本 >= 2.0
4. 尝试手动应用补丁：
   ```bash
   cd siyuan
   git apply --check ../patches/siyuan/default-config.patch
   git apply --check ../patches/siyuan/disable-update.patch
   git apply --check ../patches/siyuan/mock-vip-user.patch
   ```

### Q: 上游更新后补丁还能用吗？

**A**: 大部分情况下可以，但需要注意：
- ✅ **相同版本**：补丁完全兼容
- ⚠️ **跨版本**：可能需要上游更新补丁
- 🔄 **验证方法**：应用补丁后运行 `pnpm run tsc` 检查

### Q: 如何验证补丁是否正确应用？

**A**: 使用以下方法验证：
```bash
# 1. 检查 VIP 状态（应该显示永久 VIP）
# 启动应用后查看设置 -> 账号 -> VIP 状态

# 2. 检查自动更新（应该禁用）
# 设置 -> 关于 -> 不应该有"检查更新"按钮

# 3. 检查默认语言（应该是中文）
# 首次启动时界面应显示中文

# 4. 检查云同步提供商（应该是 S3）
# 设置 -> 云端 -> 提供商应该是 S3
```

## 安全说明

**补丁安全性**：
- ✅ 所有补丁来自可信上游 `appdev/siyuan-unlock`
- ✅ 补丁仅修改配置和功能限制，不涉及数据安全
- ✅ 模拟 VIP 用户数据存储在本地，不上传到服务器

**使用风险**：
- ⚠️ 使用修改版软件可能违反官方服务条款
- ⚠️ 建议仅在个人学习和测试环境中使用
- ⚠️ 生产环境建议使用官方版本并购买正版授权

## 许可证

本补丁文件继承自 `appdev/siyuan-unlock` 项目，遵循 AGPL-3.0 许可证。

**原始项目**：[siyuan-note/siyuan](https://github.com/siyuan-note/siyuan)
**上游项目**：[appdev/siyuan-unlock](https://github.com/appdev/siyuan-unlock)
**当前项目**：[yangpf5271/siyuan-password](https://github.com/yangpf5271/siyuan-password)

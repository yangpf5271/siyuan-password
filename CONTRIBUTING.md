# 贡献指南

感谢您对 SiYuan Password 项目的关注！本文档将帮助您了解如何为项目做出贡献。

## 项目原则

### 核心原则

1. **补丁文件保持一致**：`patches/siyuan/` 下的所有补丁文件必须与上游 `appdev/siyuan-unlock` 保持一致
2. **插件化开发**：密码锁功能作为独立插件实现，位于 `app/src/plugins/password-lock/`
3. **代码质量**：遵循 TypeScript/ESLint 规范，保持代码可维护性

## 可以贡献的内容

### ✅ 欢迎的贡献

- **密码锁功能改进**
  - Bug 修复
  - 性能优化
  - 新功能建议和实现
  - UI/UX 改进

- **文档改进**
  - README.md 完善
  - CLAUDE.md 技术文档补充
  - 设计文档更新
  - 代码注释改进

- **测试用例**
  - 单元测试
  - 集成测试
  - 边缘用例测试
  - 安全性测试

- **国际化**
  - 多语言翻译
  - 本地化支持

### ❌ 不接受的贡献

- **补丁文件修改**：保持与上游一致原则，不接受对 `patches/siyuan/` 的修改
- **核心代码直接修改**：除非通过插件 API 无法实现的功能

## 提交 PR 流程

### 1. Fork 项目

在 GitHub 上 Fork [yangpf5271/siyuan-password](https://github.com/yangpf5271/siyuan-password)

### 2. 克隆到本地

```bash
git clone https://github.com/YOUR_USERNAME/siyuan-password.git
cd siyuan-password

# 添加上游仓库
git remote add upstream https://github.com/yangpf5271/siyuan-password.git
```

### 3. 创建功能分支

```bash
# 从 master 创建新分支
git checkout -b feature/my-feature

# 或者修复 Bug
git checkout -b fix/my-bug
```

**分支命名规范**：
- `feature/功能名` - 新功能开发
- `fix/bug名` - Bug 修复
- `docs/文档名` - 文档改进
- `test/测试名` - 测试用例添加
- `refactor/重构名` - 代码重构

### 4. 开发和测试

```bash
# 安装依赖
cd app && pnpm install

# 开发模式
pnpm run dev

# TypeScript 类型检查
pnpm run tsc

# 代码风格检查
pnpm run lint

# 运行测试（如果有）
pnpm run test
```

### 5. 提交代码

```bash
# 添加更改
git add .

# 提交（遵循 Conventional Commits 规范）
git commit -m "feat: add password strength indicator"
```

**提交信息规范**：
- `feat:` - 新功能
- `fix:` - Bug 修复
- `docs:` - 文档更新
- `style:` - 代码格式（不影响功能）
- `refactor:` - 代码重构
- `test:` - 测试用例
- `chore:` - 构建/工具配置

### 6. 推送到 Fork

```bash
git push origin feature/my-feature
```

### 7. 创建 Pull Request

1. 在 GitHub 上访问您的 Fork
2. 点击 "New Pull Request"
3. 选择 base: `yangpf5271/siyuan-password:master` ← compare: `YOUR_USERNAME/siyuan-password:feature/my-feature`
4. 填写 PR 标题和描述

**PR 描述模板**：
```markdown
## 变更类型
- [ ] 新功能
- [ ] Bug 修复
- [ ] 文档更新
- [ ] 代码重构
- [ ] 测试用例

## 变更说明
简要描述本次 PR 的目的和变更内容。

## 测试情况
- [ ] 通过 TypeScript 类型检查 (`pnpm run tsc`)
- [ ] 通过代码风格检查 (`pnpm run lint`)
- [ ] 手动测试通过
- [ ] 添加了测试用例

## 相关 Issue
Closes #issue_number

## 截图（如果有 UI 变更）
（附上截图）
```

## 代码规范

### TypeScript 规范

```typescript
// ✅ 好的示例
interface PasswordLock {
    id: string;
    boxId: string;
    docId?: string;
    passwordHash: string;
    createdAt: number;
}

class PasswordManager {
    private locks: Map<string, PasswordLock>;

    async verifyPassword(lockId: string, password: string): Promise<boolean> {
        // 实现逻辑
    }
}

// ❌ 避免的示例
var locks = {};  // 使用 const/let，不使用 var
function verify(id, pwd) { }  // 缺少类型定义
```

### 文件组织

```
app/src/plugins/password-lock/
├── index.ts              # 插件入口，导出 PasswordLockPlugin 类
├── core/                 # 核心逻辑
├── interceptors/         # 拦截器
├── handlers/             # 事件处理器
├── ui/                   # UI 组件
└── utils/                # 工具函数
```

### 命名规范

- **类名**：PascalCase（如 `PasswordManager`）
- **函数/方法**：camelCase（如 `verifyPassword`）
- **常量**：UPPER_SNAKE_CASE（如 `MAX_RETRY_ATTEMPTS`）
- **私有成员**：以 `_` 或使用 TypeScript `private`（如 `private _locks`）

### 注释规范

```typescript
/**
 * 密码管理器
 * 负责密码的加密、验证和存储
 */
class PasswordManager {
    /**
     * 验证密码
     * @param lockId - 密码锁 ID
     * @param password - 用户输入的密码
     * @returns 验证结果，true 表示密码正确
     */
    async verifyPassword(lockId: string, password: string): Promise<boolean> {
        // 实现逻辑
    }
}
```

## 测试规范

### 单元测试

```typescript
// tests/PasswordManager.test.ts
import { PasswordManager } from '../src/plugins/password-lock/core/PasswordManager';

describe('PasswordManager', () => {
    let manager: PasswordManager;

    beforeEach(() => {
        manager = new PasswordManager();
    });

    it('should hash password correctly', async () => {
        const password = 'test123';
        const hash = await manager.hashPassword(password);
        expect(hash).toBeDefined();
        expect(hash).not.toBe(password);
    });

    it('should verify correct password', async () => {
        const password = 'test123';
        const hash = await manager.hashPassword(password);
        const result = await manager.verifyPasswordHash(password, hash);
        expect(result).toBe(true);
    });
});
```

## 常见问题

### Q: 我想修改补丁文件，可以吗？

**A**: 不可以。补丁文件必须与上游 `appdev/siyuan-unlock` 保持一致。如果您需要添加功能，请通过插件系统实现。

### Q: 我的功能需要修改核心代码怎么办？

**A**: 首先尝试通过插件 API 实现。如果确实需要修改核心代码：
1. 在 Issue 中详细说明原因
2. 讨论是否可以通过扩展插件 API 来实现
3. 如果确实必要，可以考虑在插件中使用 Hook 机制

### Q: 如何同步上游更新？

**A**: 项目已提供自动化脚本：
```bash
./scripts/sync-upstream.sh
```

### Q: 我的 PR 需要多久才能被审查？

**A**: 通常在 1-3 天内会进行初步审查。复杂的功能可能需要更长时间。

## 联系方式

- **Issues**: [GitHub Issues](https://github.com/yangpf5271/siyuan-password/issues)
- **讨论**: [GitHub Discussions](https://github.com/yangpf5271/siyuan-password/discussions)

## 行为准则

参与本项目即表示您同意遵守以下行为准则：

- 尊重所有贡献者
- 建设性地提出批评和建议
- 专注于对项目最有利的事情
- 对其他社区成员表现出同理心

感谢您的贡献！🎉

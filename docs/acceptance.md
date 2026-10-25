# 人工验收

四阶段代码均已提供。自动测试不能替代真实 Unity 工程、Konsole 按键和实际 GPU/引擎项目验证。
按以下顺序试用，反馈时附：工程类型、复现步骤、`:messages`、`:checkhealth workbench`；敏感路径/代码先脱敏。

## 1. 编辑与语言基线

- [ ] 启动无错误，字体图标正常；无字体时 `icons=false` 可用。
- [ ] `Ctrl+p` 找文件，`<leader>fg` 搜索，文件树不改变 cwd。
- [ ] 输入时补全，不默认预选；未选择候选时 Enter 正常换行。
- [ ] C++、Rust、C# 分别验证 `gd`、`grr`、F2、hover、code action。
- [ ] 保存不触发格式化；`Shift+Alt+F` / `<leader>cf` 手动工作；`=` 仍是缩进。
- [ ] 缺工具、缺 parser 时有合理提示/降级，不导致整体配置失败。

## 2. 构建、调试、测试

- [ ] 实际 CMake presets 能 configure/build/target/CTest；编译数据库路径正确。
- [ ] 临时制造编译错误，quickfix 可跳到真实文件；任务支持停止、重跑。
- [ ] Cargo build/check/test/clippy；features / target 与 rust-analyzer 保持一致。
- [ ] C/C++ 与 Rust 的本机 Debug 程序能断点、单步、查看局部变量、条件断点、日志断点、监视。
- [ ] 带空格的路径、多个 argv、cwd、环境变量按工程设置生效。
- [ ] 本地 attach 如失败，先检查 ptrace/SELinux，不自动放宽系统权限。
- [ ] Unity 不出现 DAP/test runner 或自动 dotnet build。

## 3. 大工程与辅助语言

- [ ] Unity 6.3 生成 solution 后，跨程序集导航/补全可用；`:Roslyn target` 可切 solution。
- [ ] Unity `Library/Temp`、Rust `target` 等不进入普通搜索；显式全文件入口可查被忽略内容。
- [ ] 大文件不触发高成本 LSP/Treesitter/行内差异；窗口仍能流畅移动。
- [ ] Linux 内核/Godot 使用其真实编译数据库，诊断没有大面积错误 include。
- [ ] Vulkan/交叉编译切换数据库和工具链后导航正确；不要同时混用不兼容目标数据库。
- [ ] GLSL 文件高亮/导航、显式 shader 编译任务符合工程的 stage/宏/profile。

## 4. 开关、AI 和多项目

- [ ] 点击状态栏 `Git`：差异标记消失、Git 输出关闭；重启仍保持关闭；再开启可恢复。
- [ ] Git 关闭时继续正常编辑、搜索、构建；Git 快捷入口仅提示关闭。
- [ ] 默认没有 AI 进程；未选 provider 不会隐式安装 Agent 或登录。
- [ ] 当前工程明确授权后才启动 Agent/行内 AI；拒绝授权保持关闭。
- [ ] 切换未授权商业工程时，行内 AI 不附着。
- [ ] `Quiet` / `<leader>uQ` 一键关闭两个总开关，停止受管理 Agent 和行内服务；不是仅隐藏 UI。
- [ ] 再开启 AI 需要重新授权；重启后 AI 仍默认关闭。
- [ ] Agent 布局保留编辑区，终端可退出输入模式；编辑内容由你检查后接受或回退。

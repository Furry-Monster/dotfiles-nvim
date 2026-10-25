# 验证记录

日期：2026-10-25。仅记录当前机器的验收基线，不把机器路径写死到通用配置。

## 已通过

- Lua 语法与核心插件加载、clangd 自动附着和手动格式化。
- 保存不格式化、`=` 不被覆盖、声明式工程设置的基本类型检查。
- CMake configure/build/test presets，包含空格的工程路径，编译数据库和语言服务重启。
- 构建报错解析为正确的 quickfix 文件/行号，任务取消与独立输出。
- Rust 语言服务初始化、Cargo build/test/clippy、edition 2024 的 rustfmt。
- Roslyn 实际 `.csproj` 加载、语义符号查询、C# 手动格式化、非 daemon 启动。
- 实际 lldb-dap 启动本机 Debug 程序、命中断点、求值局部变量、终止会话。
- Git source 解除/重新附着，关闭后拒绝查询。
- AI 授权/拒绝/撤销、独立终端布局与 Quiet 关停；使用 `cat` 模拟 Agent，不连接实际 AI 服务。

`tests/integration.lua` 中故意运行失败的编译器风格输出，测试日志中的该条 `FAILURE` 是预期断言，不是配置故障。

## 仍需你的人工验收

- Unity 6.3 LTS 的真实 solution、程序集与生成代码、重命名和引用准确度。
- Godot、内核和实际引擎的大仓库性能及真实交叉编译工具链。
- Konsole / KDE 快捷键、Nerd Font、窗口布局与个人操作习惯。
- 实际 Rust 调试类型展示、复杂 C++ 容器与优化构建的调试表现。
- 实际 AI 供应商认证、行内建议与商业项目合规策略；默认未选择供应商。

## 本机基线

| 工具 | 版本 |
| --- | --- |
| Neovim | 0.12.5 |
| clangd / clang-format | 22.1.8 |
| CMake | 4.3.0 |
| Rust / rust-analyzer | 1.99.1 |
| tree-sitter CLI | 0.26.11 |
| .NET SDK | 8.0.131 + **10.0.112（用户手动安装）** |
| LuaLS / StyLua | 3.19.2 / 2.6.0 |
| Roslyn | 5.13.0-1.26519.8，Mason 扩展源非 nightly 包 |
| neocmakelsp | 0.11.2 |
| glsl_analyzer | 1.7.1 |
| bash-language-server / shfmt | 5.8.1 / 3.14.1 |
| json-lsp / yaml-language-server | vscode-langservers-extracted 4.10.0 / 2.0.0 |
| Taplo / typescript-language-server | 0.10.0 / 6.0.2 |

22 个默认插件的实际提交由 `lazy-lock.json` 记录；可选 Copilot 插件仅在本机明确启用后安装。
Mason 的版本来自各包 `mason-receipt.json`，不在 lazy 锁文件中。更新工具应独立验收。

没有修改 shell 启动文件或持久 PATH。测试中的 XDG_STATE_HOME 仅对单次测试进程生效。
Rust 补装了 rust-analyzer / rust-src，Clippy 原本已安装。SDK 不由配置自动安装。

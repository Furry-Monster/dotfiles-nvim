# 外部工具的来源与环境边界

Neovim 插件由 lazy.nvim 声明式管理。语言服务器、编译器、格式化器与系统工具不是插件，
其安装方式需要你指定；配置不调用 dnf、rpm，不添加软件仓库，不更改 shell 或系统 PATH。
不通过旧 Mason 数据目录寻找可执行文件，也不为 PowerShell 拼接旧管理器安装路径。
如果以后决定重新引入工具管理器，需要明确安装与配置，不复用未声明的遗留状态。

## 工具来源约定

| 能力 | 依赖来源 |
| --- | --- |
| C/C++ | 用户准备的 GCC/Clang、clangd、clang-format、GDB/LLDB、CMake/Ninja/Make |
| Rust | 原生 rustup 或发行版工具链；rust-analyzer/rustfmt/Clippy/rust-src 应与项目工具链匹配 |
| C# / Unity 编辑 | .NET SDK/运行时与独立的 Roslyn 服务器；安装方式由用户指定 |
| Bash 编辑 | 用户明确安装并放入 PATH 的 bash-language-server、shfmt |
| CMake 编辑 | 用户明确安装的 neocmakelsp，与构建工具 cmake 分开 |
| GLSL 编辑 | 用户明确安装的 glsl_analyzer，与着色器编译工具分开 |
| Lua 格式化 | 用户明确安装并放入 PATH 的 stylua |
| PowerShell | 仅使用显式 POWERSHELL_ES_BUNDLE 与可见的 pwsh，不推测工具管理器路径 |

删除旧工具后，缺失的可选 LSP 不启动。格式化器没有可执行文件时使用可用的 LSP 兜底或报告缺失，
不会下载软件来弥补。基础编辑、文件侧栏与项目策略不依赖这些可选工具。
旧目录中还有未被当前配置启用的 JSON/YAML/TypeScript/Lua/TOML 工具，删除它们不会隐式启用替代工具。

Rust 子进程保留 RUSTUP_AUTO_INSTALL=0，避免打开项目时触发 rustup 隐式安装。
交叉编译 targets、nightly 和系统链接器仍由你指定，编辑器不更改默认工具链。
Tree-sitter parser 是插件管理的数据，缺少时回退基础语法；安装通过你主动执行 TSInstall 完成。

## Roslyn 的原生安装选项

官方 NuGet 提供独立的 roslyn-language-server .NET 工具。可审核的固定版本安装命令为：

```sh
dotnet tool install --global roslyn-language-server --version 5.13.0-1.26514.10 --source https://api.nuget.org/v3/index.json
```

这是用户级安装：Linux/macOS 默认写入 ~/.dotnet/tools，Windows 写入 %USERPROFILE%\\.dotnet\\tools，
并使用 .NET/NuGet 用户缓存；不替换系统 SDK，不需要 sudo，不涉及 Nobara 的 dnf/rpm。
命令仅供你批准或手动执行，本配置不会在启动时运行它。
将工具目录加入用户 PATH，配置通过可执行文件命令启动 Roslyn，不推测安装目录。
Linux/bash 可在你使用的 shell 启动文件中加入下面一行，再重新启动终端与 Neovim：

```sh
export PATH="$HOME/.dotnet/tools:$PATH"
```

Windows 则将 `%USERPROFILE%\.dotnet\tools` 加入用户 Path。
迁移时在新环境准备同名命令即可；`languages.csharp.cmd` 可覆盖启动命令与参数。
没有原生 Roslyn 时 C# LSP 保持禁用，不退回旧服务器。

参考：[Roslyn NuGet 工具包](https://www.nuget.org/packages/roslyn-language-server)、
[dotnet tool 安装与目录](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-tool-install)。

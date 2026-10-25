# Neovim：C/C++ / Vulkan 与 Rust 编辑工作流

面向 Linux + Windows，重型工具放在 tmux。Neovim 负责编辑、查找、CMake 操作和按需 CPU 调试。
使用 Neovim 0.12+；插件统一由 **lazy.nvim** 管理，版本记录在 `lazy-lock.json`。
默认主题为 Catppuccin Mocha，配置位于 `lua/plugins/theme.lua`。
分层设计与项目工作流见 [架构说明](docs/architecture.md)。通用 Rust 语言工作流见 [Rust 配置说明](docs/rust.md)，包含 Cargo、交叉编译参数和宿主机调试。
C# 语言与仅编辑的 Unity 工作流见 [C# / Unity 说明](docs/csharp-unity.md)。

## 插件与工具

打开 `nvim` 后由 lazy.nvim 安装缺少的插件。`:Lazy` 查看插件，`:Lazy restore` 恢复锁定版本，
`:Lazy update` 主动更新。没有自动检查更新，没有项目 Lua 配置自动执行。

迁移时复制整个配置目录（含 `lazy-lock.json`）到目标机器的 Neovim 配置目录即可。
插件及其依赖全部在 `lua/plugins/` 声明，由 lazy.nvim 在首次启动时下载，
不需要复制本机插件目录或逐个手动安装。插件路径使用 Neovim 的 `stdpath`，不绑定用户名或操作系统。
目标环境需提供 Neovim、Git 和网络访问；字体与编译器等系统依赖由你选择安装方式，
配置不会自动安装系统软件或修改终端字体。图标插件尚未锁定时，首次安装会更新锁文件。

插件包括 nvim-lspconfig、blink.cmp、conform.nvim、telescope.nvim（依赖 plenary）、
nvim-treesitter、nvim-dap、cmake-tools.nvim、which-key.nvim、nvim-tree.lua、nvim-web-devicons、quicker.nvim。
文件侧栏在左侧，状态栏、诊断和调试变量面板使用内置功能。

外部工具通过 PATH 或明确配置的命令查找，不修改 PATH，不复用旧工具管理器目录。
插件由 lazy.nvim 管理，语言工具与系统工具的安装由你指定；详见 [外部工具说明](docs/tools.md)。

| 用途 | 工具 |
| --- | --- |
| 构建 | CMake >= 3.21、Ninja 或 Make、GCC/G++ 或 Clang/Clang++ |
| C/C++ 编辑 | clangd、clang-format；clangd 内启用 clang-tidy 检查 |
| 查找 | ripgrep（`rg`） |
| CPU 调试 | lldb-dap 或 GDB >= 14（含 Python / DAP 支持） |
| Bash 编辑 | bash-language-server、shfmt；shellcheck 提供额外诊断 |
| CMake 编辑 | neocmakelsp |
| GLSL 编辑 | glsl_analyzer |
| Vulkan 工具 | Vulkan SDK / 开发包、glslangValidator 或 glslc、spirv-val |
| PowerShell | pwsh、PowerShell Editor Services |

运行 `:WorkflowHealth`（`:checkhealth core vim.lsp`）查看注册模块、工具路径、缺失工具与 LSP 状态。
缺少可选语言工具时，对应 LSP 不启动；LSP 是否附着需在对应项目的源文件中检查。
安装系统编译器、Vulkan SDK、PowerShell 等仍使用各平台包管理器。

以 `:WorkflowHealth` 的当前检查结果为准；不因旧目录中曾存在工具，就把它视为当前配置的依赖来源。

PowerShell：安装 `pwsh`，从官方 PowerShellEditorServices 发布页解压 bundle，
将环境变量 `POWERSHELL_ES_BUNDLE` 指向包含 `PowerShellEditorServices/Start-EditorServices.ps1`
的目录，再启动 Neovim。
未配置这些工具时，`.ps1/.psm1/.psd1` 仍有文件类型和基础语法支持。

Tree-sitter 使用新版 main 分支 API。需要高亮时执行：

```vim
:TSInstall c cpp cmake bash lua json glsl powershell
```

安装 parser 需要 tree-sitter CLI >= 0.26.1、C 编译器、curl、tar。缺少 parser 时回退到 Vim 语法高亮。
注释可用 Neovim 自带的 `gcc`（行）和可视模式 `gc`；不额外安装注释插件。

## 从没有 Presets 的项目开始

Presets 是保存在项目里的命名构建方案。例如 `gcc-debug` 记录 GCC、Ninja、Debug 及输出目录，
在 Neovim 和 tmux 终端中都可以使用。示例只是模板，不会自动改动你的项目。

1. 将 `examples/CMakePresets.json` 复制到项目顶层（与主 `CMakeLists.txt` 同级）。
2. 在项目目录启动 `nvim`，执行 `:CMakeSelectConfigurePreset`，先选 `gcc-debug` 或 `clang-debug`。
3. 执行 `:CMakeGenerate`。它生成编译数据库，并复制到项目顶层供 clangd 读取。
4. 执行 `:CMakeSelectBuildPreset`，选择同名 preset，再执行 `:CMakeBuild`。
5. 如需运行或调试，先 `:CMakeSelectLaunchTarget`，再 `:CMakeRun` 或 `:CMakeDebug`。
6. CTest 使用 `:CMakeSelectTestPreset` 选择同名 preset，`:CMakeRunTest` 执行。

**先 configure，再打开 C++ 文件**可让 clangd 直接读取正确的 include、宏和编译选项。
切换 preset 并重新 generate 后，如诊断未刷新，执行 `:lsp restart clangd`。
复制动作会更新项目顶层的 `compile_commands.json`；如果项目已有独立管理的编译数据库，
将 `lua/builders/cmake.lua` 中 `action = 'copy'` 改为 `'none'`，在项目 `.clangd` 中指定数据库目录。

示例提供 GCC/Clang 的 Debug、RelWithDebInfo，以及 Linux 的 GCC + Make。
每个 preset 使用独立的 `build/<preset名称>` 目录，切换工具链不共用 CMakeCache。
没有 Presets 的项目也可使用 `:CMakeSelectKit`、`:CMakeSelectBuildType`，然后 generate/build。

tmux 中执行相同构建：

```sh
cmake --preset gcc-debug
cmake --build --preset gcc-debug --parallel
ctest --preset gcc-debug
```

项目 `.gitignore` 建议加入 `build/`、`compile_commands.json`、`CMakeUserPresets.json`。
团队共享配置提交 `CMakePresets.json`；本机 SDK 路径放到不提交的 `CMakeUserPresets.json`。
示例 `.clang-format` 和 `.clang-tidy` 可按项目需求复制；已有风格配置优先，不会全局强加 C++ 标准。

## Vulkan / 图形程序

GLSL 常规阶段和光追阶段后缀都映射为 `glsl`，使用 glsl_analyzer 补全和导航。
`<leader>cf` 通过 clang-format 格式化 C/C++/GLSL。
着色器的 Vulkan 目标版本、宏、include 路径和 SPIR-V 生成应放在项目 CMake 规则中，
再从 tmux 构建，例如 `glslangValidator -V shader.vert -o shader.vert.spv`；编辑器的 GLSL
诊断不能替代实际着色器编译。HLSL/Slang 暂未加入，后续可按项目需要扩展。

Vulkan 头文件/链接库由项目通过 `find_package(Vulkan REQUIRED)` 与 `Vulkan::Vulkan` 管理；
clangd 从编译数据库读取这些路径，无需编辑器硬编码 SDK 目录。

图形程序常依赖资源目录、启动参数和环境变量：用 `:CMakeTargetSettings` 调整所选目标的
`working_directory`、`args`、`env`，运行和调试共用这些设置。
例如将 `working_directory` 设为项目资源目录的绝对路径，`args = { "--scene", "assets/demo.json" }`，
`env = { VK_INSTANCE_LAYERS = "VK_LAYER_KHRONOS_validation" }`（需要已安装该层）。
默认工作目录为构建目录。也可用 `:CMakeLaunchArgs` 单独设置参数。

`:CMakeDebug` 默认优先 LLDB，`:DebugAdapter gdb` / `:DebugAdapter lldb` 切换本次会话的
原生调试器。`F5` 与 `<leader>cd` 统一调用当前项目的调试动作；Cargo 提供本机产物选择，CMake 调试所选目标。
使用 Debug 或 RelWithDebInfo 构建；资源路径与环境由目标设置管理。
GDB/LLDB 负责 CPU 断点、栈和变量；RenderDoc 等 GPU 帧调试工具在 tmux/外部运行。

## Windows 注意事项

配置放在 `%LOCALAPPDATA%/nvim`；插件和语言工具在 Windows 单独安装。
推荐 Ninja，避免 Windows Make 变体的差异。GCC 使用 MSYS2 UCRT64/MinGW-w64；Clang 可使用
MSYS2 CLANG64 工具链。用对应环境的 PATH 启动 Neovim，并确保 CMake、Ninja、编译器、调试器
及依赖库属于兼容工具链。原生 LLVM/MSVC ABI 需要 Developer 环境和相应 SDK，不能直接混用 MinGW 库。
Presets 指定的编译器名称在 Windows 同样从 PATH 解析，必要时在 UserPresets 中设本机绝对路径。

`lldb-dap.exe` 必须可执行；GDB 需要支持 DAP。Windows 未做本机实测，Linux 下已验证的结果见下方。
Bash 脚本需要 Git Bash/MSYS2 Bash，PowerShell 脚本通过 `pwsh -NoProfile -File` 运行。
没有改写 Windows 默认 shell 及其命令参数。tmux 可在 Linux/WSL 中使用。

## 常用按键

`<leader>` 为空格。按下空格约 300 毫秒后显示快捷键菜单，组合键等待时间为 1000 毫秒。
`<leader>cf` 显式格式化，保存不自动格式化。
补全：`Ctrl-Space` 打开、`Ctrl-n/p` 选择、`Ctrl-y` 确认、`Ctrl-e` 关闭；`Tab` 保留正常缩进。

| 按键 | 功能 |
| --- | --- |
| `<leader>w` / `<leader>e` | 保存 / 切换左侧文件侧栏 |
| `Ctrl+h/j/k/l` / `Ctrl+方向键` | 向左/下/上/右切换窗口焦点（普通及终端模式） |
| `<leader>ff` / `fg` / `fb` | 文件 / 全文搜索 / buffer |
| `<leader>fs` / `fS` | 当前文件 / 工作区符号 |
| `gd` / `gD` / `gr` / `gi` / `K` | 定义 / 声明 / 引用 / 实现 / 文档 |
| `<leader>cr` / `ca` / `cs` / `ch` | 重命名 / 代码操作 / 头源切换 / 内联提示 |
| `[d` / `]d` / `<leader>xd` / `xx` | 诊断跳转 / 当前诊断 / 诊断列表 |
| `<leader>cp` / `cP` / `cg` / `cb` | 配置 preset / 构建 preset / configure / build |
| `<leader>ct` / `cl` | 构建目标 / 启动目标 |
| `<leader>cR` / `cd` / `cT` / `cx` | 运行 / 调试 / CTest / 停止构建 |
| `<leader>q` / `[q` / `]q` | 构建输出 / 错误跳转 |
| `F5` / `F10` / `F11` / `F12` | 项目调试或继续 / 单步越过 / 进入 / 跳出 |
| `<leader>db` / `dB` / `dq` | 断点 / 条件断点 / 结束调试 |
| `<leader>dv` / `df` / `dr` | 检查变量 / 调用栈 / 调试 REPL |
| `<leader>tt` / `ts` | 项目终端 / 运行当前 Bash 或 PowerShell 脚本 |
| 终端中 `Esc Esc` | 回到普通模式 |

脚本从项目根目录运行；需要额外参数或特殊环境时，在 tmux 中运行即可。
文件侧栏中 `h` / 左箭头关闭目录或返回父目录，`l` / 右箭头打开文件或目录，
`j/k` 与上下箭头移动，`g?` 查看侧栏快捷键。编辑区普通方向键保持默认光标移动。
侧栏启用 Nerd Font 文件、文件夹及 Git 图标，常用开发文件图标使用 Catppuccin Mocha 配色。
终端需使用 Nerd Font（当前 nvim-web-devicons 要求 Nerd Font >= 3.3）。
语言、构建后端、项目工作流分别位于 `lua/languages/`、`lua/builders/`、`lua/workflows/`，公共设施位于 `lua/core/`。注册入口是 `lua/config/modules.lua`。

Quickfix 使用 quicker.nvim 排版，背景、文件名、行号、分隔线和选中行采用 Mocha 配色，
错误/警告类型使用 Nerd Font 图标和主题诊断颜色；原有文件侧栏图标保持不变。
`<leader>q` 打开列表，`Enter` 跳转，`q` 关闭，`>` 展开前后两行代码，`<` 收起上下文。
`[q` / `]q` 及 `Ctrl+h/j/k/l`、`Ctrl+方向键` 仍可使用。未启用 Quickfix 批量编辑和自动写入功能。
构建日志中未被解析成错误位置的行仍会显示，只有带诊断类型的条目才显示错误/警告图标。
该插件由 lazy.nvim 在启动时自动安装，打开 Quickfix 时加载；无需手动安装或额外系统依赖。

参考：[Neovim LSP](https://neovim.io/doc/user/lsp)、
[CMake Presets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)、
[CMake Tools](https://github.com/Civitasv/cmake-tools.nvim)、
[PowerShell Editor Services](https://github.com/PowerShell/PowerShellEditorServices/releases)。

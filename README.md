# Native Workbench

面向 Nobara Linux 的 Neovim 开发配置：C/C++ / Vulkan、Rust、Unity C# 为主，原生编辑优先。
从零维护，不继承任何发行版。要求 **Neovim ≥ 0.12 稳定版**。

## 开始使用

1. 在 Konsole 配置中选择已安装的 Nerd Font。没有字体时，在本机设置里关闭 `icons`。
2. 启动 `nvim`，插件由 lazy.nvim 管理；`:Lazy` 查看安装状态。
3. `:checkhealth workbench` 检查工具路径、缺失项和来源冲突。
4. 从工程目录启动 `nvim`，或直接打开源码。`Ctrl+p` 找文件，空格后等待提示查看快捷键。
5. 需要工程专属参数时，参考 `examples/*.nvim.json`，复制成工程根目录的 `.nvim.json`，执行 `:ProjectTrust`。

**保存不会格式化、整理 import 或自动修复。** `Shift+Alt+F` / `<leader>cf` 手动格式化；选区模式格式化所选行。
`=` / `gg=G` 保留 Vim 缩进语义，不等于外部格式化。

### 一键关闭集成

状态栏有三个可点击按钮，也有命令和按键：

| 按钮 | 命令 | 按键 | 行为 |
| --- | --- | --- | --- |
| `AI:OFF/ON` | `:AIToggle` / `:AIDisable` | `<leader>ua` | AI 总开关 |
| `Git:OFF/ON` | `:GitToggle` / `:GitDisable` | `<leader>ug` | Git 总开关 |
| `Quiet` | `:IntegrationsOff` | `<leader>uQ` | 立即关闭所有受管理 AI/Git 集成 |

- AI **每次启动默认关闭**。开启需明确授权当前工程，仅本会话生效；总开关关闭时撤销全部项目授权、停止行内服务和受管理 Agent 终端。
  总开关开启但当前工程未授权时显示 `AI:BLOCK`。
- Git 开关跨重启保存于 `stdpath('state')/workbench-features.json`。关闭时解除 diff/index 监听、移除行内差异、关闭 Git 视图、取消自有查询和受管理 lazygit 终端；快捷入口拒绝运行。
- 文件树始终不启动 Git 后台扫描，状态栏不额外轮询分支；搜索使用 ripgrep，不依赖 `git ls-files`。
- “关闭”不卸载插件、不修改仓库、不禁止用户手动运行 shell 命令；`:Lazy` 手动更新插件仍会调用 Git。外部独立启动的 Agent/Git 进程不受此开关控制。

## 工具安装与来源

不修改系统 shell 配置，不调用 sudo，不自动更新编译器。Mason 只在 **Neovim 进程内**将自己的 bin 目录追加到 PATH。
项目 `env` 只传给相应任务/已配置的语言服务或调试进程，不写回系统环境。

| 来源（唯一约定） | 工具 |
| --- | --- |
| 系统 / Nobara 软件源 | Neovim、Git ≥ 2.38、ripgrep、C/C++ 编译器、clangd、clang-format、CMake、Ninja/Make、LLDB / lldb-dap、curl、tar、tree-sitter CLI ≥ 0.26.1、剪贴板工具、.NET SDK |
| rustup | cargo、rustc、rust-analyzer、rustfmt、Clippy、rust-src，以及项目声明的工具链 |
| Mason 官方源 | lua-language-server、StyLua、bash-language-server、shfmt、json-lsp、yaml-language-server、Taplo、neocmakelsp、glsl_analyzer、typescript-language-server |
| Mason 扩展源 | **roslyn**：`Crashdummyy/mason-registry`，非 `roslyn-nightly`；提供 VS Code 使用的 Roslyn 分发包 |
| 工程本地依赖 | Prettier（`node_modules/.bin`）、工程脚本、just / nu 等工程自选工具 |
| lazy.nvim / Treesitter | 编辑器插件 / 对应语法解析器；不是编译器管理器 |

本机路径等覆盖放在 `lua/local.lua`（已被 Git 忽略），样例：`examples/local.lua`。
不要同时在 Mason 中安装 clangd、rust-analyzer、clang-format、rustfmt 或第二套 C# 语言服务。

### 显式初始化命令

以下会联网并写入 Neovim 数据目录；**不在每次启动执行**：

```bash
nvim --headless -l scripts/install-tools.lua
nvim --headless -l scripts/install-parsers.lua
```

当前 Roslyn 需要 **.NET 10 SDK（含相应 runtime）**，由你手动安装；配置不提供自动安装大型 SDK 的脚本。
可保留现有 .NET 8，单独安装 .NET 10，并在 `lua/local.lua` 指定 `dotnet_host = "/绝对路径/dotnet"`。
只有指定独立 host 时，Roslyn 子进程才设置相应 `DOTNET_ROOT`；不会修改用户终端或其他工程的环境。
未安装时清晰提示并跳过 C# 服务，其他语言不受影响。安装完成后重启 Neovim。

工具脚本会安装上表 Mason 工具。Mason 的 Node/Python 工具使用其隔离目录，但仍需要可用的 Node/npm 等宿主依赖。
失败检查 `:MasonLog`；不要为装低频工具强行更换系统 Python/.NET。
单独安装可用 `:MasonInstall <包名>`；Roslyn 使用 `:MasonInstall roslyn`，**不是** `roslyn-language-server`，不要双装。

语法解析器也可用 `:ParsersInstall` 或 `:TSInstall <language>`。PS1、just、nu 按需安装 `powershell`、`just`、`nu`。
缺解析器时回退普通语法，不导致启动失败。ShaderLab/JSONC 等不承诺存在专用解析器；没有时同样降级。

## 工程与语言

### C/C++、Vulkan、内核

- clangd 处理补全、诊断、导航和轻量重构；clang-format 是唯一默认 C/C++ 格式化器。
- 优先让工程生成 `compile_commands.json`。CMake 推荐 `CMakePresets.json`，示例见 `examples/CMakePresets.json`。
- `:CMakeConfigure`、`:CMakeBuild`、`:CMakeTarget`、`:CTest` 使用 CMake 自己列出的 presets，支持 include、继承与用户 preset。
- 若未使用 preset，默认构建目录 `build/debug`；首次 configure 优先 Ninja，不覆盖已有 cache 的 generator。
- **preset 和 clangd 编译数据库目录是独立选择**：使用 `.nvim.json` 的 `build_dir` 或 `:BuildDirectory` 指定真实目录，再 `:LspRestart`。
  不解析/复制 CMake 的宏，也不偷偷创建覆盖根目录的编译数据库软链接。
- `--parallel` 由原生工具决定默认并行度，需要限制时使用 preset、工程任务或工程环境变量。
- Vulkan SDK、跨平台宏、sysroot 和工具链路径由 CMake/toolchain 文件负责，不全局硬塞 include。
- 交叉编译时，`query_drivers` 是本机显式白名单，见 `examples/local.lua`；不要填写 `*`。
- `.clangd`、`.clang-format`、`.clang-tidy` 归项目管理。内核用对应源码树的编译数据库生成流程，不套 CMake。
- clang-tidy 由 clangd 接入，实际检查集合遵循工程规则；独立静态分析可定义成手动任务。

### Rust

- 使用标准 Cargo + rustup + rust-analyzer；尊重 `rust-toolchain.toml`，不强制 nightly。
- 自动检查为 `cargo check`；Clippy 仅显式运行。默认不打开全部 features。
- `:Cargo build/check/test/clippy/run` 或 `<leader>bb` / `<leader>tt`。
- `:CargoArgs` 输入 JSON argv，调整本会话 Cargo 任务参数；复杂测试过滤写成独立项目任务。
- `.nvim.json` 的 `rust.target` / `rust.features` / `rust.all_features` 配置语言服务；`cargo_args` 配置任务。
  两者需自行保持一致，修改语言服务设置后 `:LspRestart`。
- rustfmt 使用工程 edition 与配置；不在保存时执行。

### Unity 6.3 LTS / C#

- 唯一语言服务为 Roslyn；不启用 OmniSharp，不安装完整 Unity IDE 工作流。
- 在 Unity 的 External Tools / IDE 集成中启用工程文件生成，重新生成 `.sln` / `.csproj`；程序集引用必须有效。
- 首次打开等待 solution 加载；多个 solution 使用 `:Roslyn target`。
- 提供编辑、补全、定义/引用、重命名和服务器可用的代码操作。后台诊断限打开文件，避免对大 solution 持续全量分析。
- 格式化交给 Roslyn，不自动整理 using。禁用测试 CodeLens；**没有 Unity 调试、测试或自动 dotnet build**。
- 非 daemon 模式启动 Roslyn，退出编辑器不留下长期驻留 daemon。
- 不保证场景、Prefab、序列化引用分析达到 Rider 水平；真实 Unity 工程需要人工验证。

### 辅助语言与 Shader

- Lua、Shell、JSON/YAML、TOML、CMake、TS/JS：工具存在时启用对应 LSP；缺工具不启动失败进程。
- CMake 采用 neocmakelsp（避免本机 Python 版本限制）；手动格式化仅在其提供相应能力时开放。
- GLSL：glsl_analyzer + `:ShaderCheck`（当前使用已保存文件和 `glslangValidator` 默认语义）。
  `.glsl` 无法推断 stage，或 Vulkan/SPIR-V 验证需要 `-V`、include、宏时，请写显式工程任务。
- HLSL、ShaderLab：文件类型与可用语法高亮；DXC 的 profile、entry、宏由工程任务提供，不猜测。
- XML / Markdown：基础语法与编辑；Markdown 格式化按需安装工程本地 Prettier。
- PowerShell、just、nushell 暂不强装语言服务。需要时扩展 `languages/auxiliary.lua`，明确安装来源。

## 构建、任务、调试

### 任务

`<leader>bb` 根据当前工程选择 CMake/Cargo；Unity 提示回到 Editor。其他任务：`:Task`、`:OverseerRun`、`:OverseerShell`。

- 流式输出、停止、重跑与任务列表由 Overseer 管理；编译错误进入 quickfix。
- `<leader>br` 重跑当前工程最近任务；`<leader>bs` 停止由本配置创建的当前工程任务。
- 外部模板任务使用 Overseer 面板自带的重跑/停止操作；`:TaskRepeat` 不接管所有第三方任务。
- 同名同目录任务运行中拒绝重复启动，不自动中止已有构建。
- 项目任务 `cmd` 为 argv 数组，不隐式经过 shell。确需 shell 时显式使用 `["bash", "-lc", "..."]` 并审查内容。
- 任务固定启动时的路径和环境，不因切换窗口/cwd 漂移。
- quickfix 为编辑器共享列表，并发构建可能切换正在显示的列表，完整输出保留在各自任务里。

### 本地原生调试

F5 选择 Launch 或 Attach；C/C++ 和 Rust 使用系统 `lldb-dap`，不自动构建。
支持断点、条件断点、日志断点、单步、栈、作用域、监视、求值与 REPL；参数用 `:lua require('config.debug').arguments()` 或 `<leader>da`。

- 可执行文件、cwd、参数、环境可在可信 `.nvim.json` 中指定；Launch 仍允许确认/修改程序路径。
- Rust 加载活动工具链提供的 LLDB 类型展示脚本；工具链缺脚本则跳过。
- 需构建带调试信息的本机程序；优化、剥离符号会影响体验。
- Attach 受 Linux ptrace / SELinux / 权限限制；配置不修改系统安全策略。
- 交叉编译的非本机程序不能直接用本机 Launch 调试。不预装远程调试或所有 GDB adapter。
- 退出调试后保留 UI 便于查看输出，`<leader>du` 手动关闭。

## AI：可选而非编辑前提

默认无 AI 进程、无行内建议，不自动选择供应商或登录。

本机设置示例：

```lua
return {
    ai = {
        agent = { "codex" }, -- 或自行安装的其他 CLI，argv，不是 shell 命令串
        copilot = false, -- 需要 GitHub Copilot 时显式改 true，再重启安装可选插件
        copilot_server = "", -- 手动安装的 Copilot 原生语言服务可执行路径
    },
}
```

- `<leader>aa` / `:AIAgent`：授权后在独立标签页打开“编辑区 + Agent 终端”；从编辑区可再打开任务面板和 Git diff。
- `<leader>ai` / `:AIInlineToggle`：行内建议独立开关。开启后 `:Copilot auth` 登录，`Alt+l` 接受建议。
- AI 总开关只是许可，不自动启动两类功能。关闭行内建议不停止 Agent；关闭总开关会同时停止两者。
- Copilot 的原生语言服务需自行安装并填写 `ai.copilot_server`，配置不会隐式下载大型服务；CLI 安装、账号、订阅与凭据也由用户管理。
- 无自动发送选区、无自动提交、无自动放宽 Agent 审批策略。CLI 的修改权限、命令审批由该工具自身设置决定。
- 工程授权按实际根目录区分，并非操作系统沙箱；忽略规则不能代替保密要求。商业项目必须先确认组织政策。
- 行内 AI 默认不附着 `.env*`、常见私钥/证书文件和 `.git` 内部文件；这不是对 Agent CLI 的沙箱限制，也无法识别所有敏感内容。
- 关闭会停止受管理终端任务，不是仅隐藏页面；已经传出的上下文无法撤回。独立后台化/脱离终端的进程仍需在外部管理。

## 配置扩展与安全边界

```text
lua/config/       编辑器行为与各功能的少量适配代码
lua/plugins/      插件声明、按键和接入选项
lua/languages/    语言专属设置
lua/project/      工程根目录、声明式设置与信任入口
lua/workbench/    :checkhealth workbench
examples/         本机/工程设置和 CMake Presets 样例
tests/            无界面冒烟测试
scripts/          显式依赖初始化脚本
```

遵守 `.editorconfig`；项目工具规则优先。基础配置禁用 `exrc` 和 modeline，不自动执行项目 Lua。
`.nvim.json` 每个会话需 `:ProjectTrust` 显式加载；Neovim 按文件内容记录信任，文件变化会重新询问。
拒绝授权不会影响普通编辑；`:ProjectForget` 移除本会话设置，永久信任管理见 `:help :trust`。
JSON 也可能指定会执行的任务/编译器参数，必须审查。语言服务、Cargo build scripts/proc macros 本身仍可能执行工程代码，未知仓库不等于安全沙箱。
当前实现不会自动恢复会话、构建或运行测试。

## 更新与回归

- 提交 `lazy-lock.json`；常规启动不检查更新，不追 nightly。
- 更新前提交当前配置；手动 `:Lazy update`，验收失败用已提交锁文件配合 `:Lazy restore`。
- Treesitter 插件、解析器、query 一组更新；`:TSUpdate` 后重开文件验证，不混用旧 API。
- Mason 工具不由 lazy 锁定；更新前记录版本，不无条件升级 SDK/编译器。
- 不要在存放敏感临时内容的目录运行批量测试；测试 fixture 写到 `/tmp/opencode`。

自动冒烟测试会**仅对该进程**设置临时状态目录，避免改动日常 Git 开关：

```bash
XDG_STATE_HOME=/tmp/opencode/nvim-smoke-state nvim --headless -l tests/smoke.lua
```

真实工具集成测试（临时 CMake/Cargo/.NET 工程、LLDB、假 Agent；不连接 AI 服务）：

```bash
XDG_STATE_HOME=/tmp/opencode/nvim-integration-state nvim --headless -l tests/integration.lua
```

测试调用已安装的工具与 `dotnet restore`，可能产生工具自己的常规缓存；不会安装 SDK。
本轮实测范围和版本记录见 [docs/verification.md](docs/verification.md)。

手动验收顺序和快捷键表见 [docs/acceptance.md](docs/acceptance.md)、[docs/keymaps.md](docs/keymaps.md)。

# 配置结构检查与完善方向

检查日期：2026-10-25。本次以工作区配置、已安装插件源码和 Neovim 0.12.5 的实际运行结果为依据。

## 结构与职责

现有语言、构建后端、项目工作流分层值得保留。添加语言通常只需要新增语言模块，
再在 `lua/config/modules.lua` 注册，不应把语言特例堆进 `init.lua`。

```text
init.lua                  启动顺序
lua/config/
  options.lua             编辑器选项与基础文件类型
  autocmds.lua            通用自动命令、文件类型缩进
  keymaps.lua             通用按键与健康检查入口
  navigation.lua          编辑区、终端、侧栏共用的窗口导航
  lazy.lua                插件管理器引导
  modules.lua             语言、构建后端、工作流注册表
lua/plugins/
  editor.lua              which-key、Telescope
  coding.lua              补全、LSP、格式化、Tree-sitter
  build.lua               DAP、CMake Tools
  files/icons/quickfix/theme.lua  各界面插件
lua/core/                 项目上下文、任务、终端、LSP、格式化、语法与调试设施
lua/languages/            各语言的工具、服务与编辑行为
lua/builders/             CMake、Cargo、自定义命令与输出解析
lua/workflows/            default、engine、kernel、unity 的动作策略
```

插件声明负责加载时机和依赖；具体行为仍由 core、languages、builders 实现。
项目配置来自 `.nvim/project.json`，不会自动执行项目中的 Lua 配置。

## 本次已完成

- 将原 `plugins/init.lua` 的声明分为 editor、coding、build 三组，保留原有插件及加载条件。
- 将公共自动命令从 options 拆出；公共编辑、LSP、Tree-sitter、C++、Rust 自动命令使用可清理的分组，重复 setup 不再堆积回调。
- 项目终端和任务终端共用 `core.tasks.terminal()`，统一启动及错误处理入口。
- 修复 Cargo run 忽略 `run.cwd`：使用指定目录启动，并通过绝对 `--manifest-path` 定位项目。
- 项目 JSON 解析错误包含文件路径，并拒绝数组、null 等非对象顶层配置。
- clangd 附着回调增加客户端不存在时的保护。
- README 去除失效的 docs 链接，使用当前模块链接，并内嵌最小 CMake Presets 示例。

## 优先完善的方向

| 优先级 | 方向 | 现状与下一步 |
| --- | --- | --- |
| P1 | 着色器语言支持 | `languages/shader.lua` 将 GLSL、HLSL、Slang 全部交给 clangd，模块自身已有能力限制警告。应按语言独立验证诊断、跳转和补全，再决定服务；先保留文件类型与高亮，不以成功附着判断分析正确。 |
| P1 | 项目配置校验 | 当前只补齐 JSON 顶层检查，Cargo 有部分字段校验。建议统一校验 `tasks`、`run`、`build`、`external`、语言配置的字段类型，并报告具体字段路径。 |
| P1 | 补全实际需要的工具 | 本机健康检查未找到 lua-language-server、shellcheck；只有需要 PowerShell 编辑时才需补齐 pwsh 和 Editor Services。安装由用户手动完成，优先已有系统仓库的全局包。 |
| P2 | 测量后调整懒加载 | nvim-lspconfig 依赖 blink.cmp，因此 blink 虽声明 InsertEnter，仍可能被依赖提前加载；DAP、CMake Tools 当前也启动加载。先用 `:Lazy profile` 测量，再调整命令、按键和文件类型触发，避免破坏首文件 LSP 或现有构建命令。 |
| P2 | Cargo 项目探测成本 | `cargo_project.root()` 会同步调用 `cargo locate-project`，最多等待 3 秒；项目上下文查询会触发探测。可按 crate、Cargo.toml 与工具链配置缓存，并设计失效条件。 |
| P2 | 项目切换边界 | CMake 动作会修改 cwd 并合并构建环境；需验证同一会话切换不同项目时，终端、查找、目标设置及环境不会残留。 |
| P2 | 任务生命周期 | 通用异步任务由 `core.tasks.active` 管理，终端任务未进入该状态，CMake 另有执行器。需明确停止动作是否覆盖 Cargo run/test 和脚本，再设计任务登记与退出清理。 |
| P3 | 文件类型职责 | PowerShell 文件类型位于 options，shader 的文件类型注册位于 setup_lsp。以后可统一语言模块的文件类型初始化入口，使其不依赖 LSP 加载。 |
| P3 | 健康检查可操作性 | 当前所有语言工具都检查，GDB/LLDB、Ninja/Make 等替代工具会分别检查。可区分必需、替代、可选工具，并增加版本、parser 可用性和当前项目检查。 |
| P3 | 长期回归检查 | 当前工作区原 tests 已删除，本次未恢复。后续若维护自动检查，优先覆盖项目识别、工作流外部动作策略、Cargo 输出解析、多项目切换和含空格路径。 |

## 本机工具的手动安装方案

系统为 Nobara 44；使用已有 DNF 仓库缓存做只读查询，未刷新仓库或执行安装：

| 工具 | 当前缓存中的来源 | 建议 |
| --- | --- | --- |
| ShellCheck | `nobara` | 原生系统仓库已有包，需要 Bash 诊断时可手动安装。 |
| lua-language-server | `terra`，有 x86_64 包 | 已配置仓库提供全局 RPM；Terra 与 Nobara 原生仓库来源不同，接受该来源后再手动安装。 |
| powershell | `terra`，有 x86_64 包 | 可选；仅编辑 C++/Rust/Lua 时不需要。安装 pwsh 后，Editor Services 仍需另行检查。 |

以下只是提供给用户执行的命令，本次未运行：

```sh
sudo dnf install ShellCheck
# 如接受当前已有 Terra 仓库的来源：
sudo dnf install lua-language-server
```

仓库缓存只能说明当前缓存中的可用包；真正安装时以 DNF 显示的仓库、事务和依赖为准。
不新增软件源，不使用 Mason 或下载脚本代替系统安装，不修改 PATH。

## 验证结果与边界

- Neovim 无界面启动成功，lazy.nvim 识别 14 个插件，无启动错误消息。
- 使用临时、无第三方依赖的 Rust 项目实际执行 Cargo run：项目路径包含空格，`run.cwd` 指向 assets，包含空格的运行参数被正确传递。
- 验证非法 JSON 与非对象顶层配置被拒绝，错误包含配置路径。
- 验证显式项目根目录和 `builder: false`；重复执行编辑器、LSP、语法初始化未重复注册相关自动命令。
- `:checkhealth core` 完成，所有注册模块可加载；工具缺失及 shader 能力警告见上文。
- 验证使用现有工具，临时源码、编译产物、缓存与状态写入 `/tmp`，未安装或更新软件、插件。
- 未执行实际 CMake 项目构建、DAP 会话、Unity 项目加载或 Windows 本机验证；交互界面仍需日常使用确认。

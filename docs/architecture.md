# 配置架构与扩展

配置分为四层，语言、构建后端和项目工作流是三个独立维度。

| 目录 | 职责 | 扩展方式 |
| --- | --- | --- |
| `lua/core/` | LSP 接入、格式化注册、语法高亮、调试器、任务执行、Quickfix、项目上下文和动作分发 | 通用设施，不放某种语言或某类项目的条件分支 |
| `lua/languages/` | clangd / rust-analyzer 等语言服务、格式化器、语法高亮声明及语言调试增强 | 新模块实现需要的接口，再在注册表登记 |
| `lua/builders/` | CMake、Cargo、自定义命令的构建与产物解析 | 提供 detect、actions，按需提供 debug_configurations / parse |
| `lua/workflows/` | default、engine、kernel 的项目策略与运行默认值 | 定义 external 动作和 runtime，不依赖源码语言 |
| `lua/plugins/` | 插件及其 lazy.nvim 声明 | 只负责加载和连接上述模块 |
| `lua/config/modules.lua` | 模块注册表 | 添加新语言、构建后端或工作流时统一在这里登记 |

C++ 与 Rust 是 `languages/cpp.lua` 和 `languages/rust.lua` 两个同级模块。
共享的 `core/debug.lua` 不预设 C++，只注册本机 LLDB/GDB、通用调试动作并调用语言增强接口。
Cargo 的构建、JSON 诊断与产物选择属于构建后端；Rust pretty printers 属于 Rust 语言模块。
项目动作统一从 `core/workflow.lua` 分发，不再由各语言覆盖同一组构建快捷键。

## 项目描述文件

需要显式选择时，在项目根目录创建 `.nvim/project.json`：

```json
{
  "workflow": "engine",
  "builder": "cargo",
  "build": { "args": ["-p", "renderer"], "features": ["vulkan"] },
  "run": { "cwd": ".", "args": ["--scene", "assets/demo.json"] }
}
```

没有这个文件时使用 default 策略，根据项目标记和当前文件类型选择已注册的构建后端。
Cargo workspace 通过 Cargo 自身定位；CMake 优先使用 Presets 或仓库顶层的 CMakeLists。
混合项目建议显式指定 builder，避免歧义。

| 字段 | 含义 |
| --- | --- |
| workflow | 项目策略：default / engine / kernel |
| builder | 构建后端：cmake / cargo / commands，与语言独立 |
| build | 后端构建参数；args/env 为通用入口，Cargo 还支持 target/features/noDefaultFeatures |
| configure.args | CMake configure 的额外参数 |
| run | 原生调试及运行默认 cwd/args/env；相对路径以项目根目录为基准 |
| debug.buildArgs | Cargo 调试构建时追加的包、bin、example 等选择参数 |
| languages | 语言自己的设置，例如 languages.rust.analyzer |
| tasks | 覆盖某个动作的 argv/cwd/env/terminal/parser/errorformat |
| external | 显式覆盖某个动作是否交给 tmux，未写时继承工作流策略 |

engine 默认以项目根目录作为原生程序工作目录，便于读取资源；运行参数通过项目数据提供。
kernel 默认将 run/test/debug 交给 tmux，构建和编辑继续留在 Neovim。
这一策略对 C++、Rust 或混合语言都相同。配置不会自动启动 QEMU、创建远程连接或安装工具链。
语言层不判断“是否内核”，也不会自动关闭 no_std 项目的测试或改变分析 target。

示例在 `examples/projects/`，包含 engine/kernel 与 CMake/Cargo 的组合，以及 Make 自定义构建。
这些模板不会自动写入你的源码项目。

## 动作与任务

`<leader>cb/cc/cC/cg/cT/cR/cd/cx` 对应 build/check/lint/configure/test/run/debug/stop。
动作先检查项目策略，再查自定义 tasks，最后调用构建后端；当前后端不支持的动作会给出提示。
`F5` 与 `<leader>cd` 使用同一个项目调试入口，已有调试会话则继续执行。
`:Cargo` 也经过项目策略检查；底层插件原生命令如 `:CMakeRun` 是直接操作工具的入口，不经过这层策略。
`:ProjectAction build` 等命令与快捷键调用同一套分发逻辑，也能调用后续新增后端的动作。
`:ProjectInfo` 查看当前解析结果，`:WorkflowHealth` 检查注册模块的工具可用性。

自定义任务使用 argv 数组，不经过 shell：

```json
{
  "workflow": "kernel",
  "builder": "commands",
  "tasks": {
    "build": { "argv": ["make", "-j8"], "errorformat": "%f:%l:%c: %t%*[^:]: %m" }
  }
}
```

复杂管道请写进项目自己的 Bash/PowerShell 脚本，再将脚本和解释器作为 argv 调用。
显式任务可以使用 `parser: "cargo"` 复用 Cargo JSON 解析；未指定 parser 时使用 errorformat。
公共异步执行器负责单任务运行、取消、退出状态和 Quickfix 展示；解析器由后端提供。
交互任务可设置 terminal=true，在现有内嵌终端中显示。

Cargo run/test 保持 Cargo 的工作目录与 runner 语义，在工作区根目录调用；run.args 会传入程序。
Cargo 的 run.cwd 作用于原生调试，若要改变运行目录，请用项目 runner 或自定义 run task。
CMake 的 run 设置写入所选 launch target；没有项目运行设置时保留插件的已有目标设置。

## 新增模块

语言模块可提供 filetypes、tools、formatters、treesitter、setup_lsp、setup_debug、enrich_debug。
核心设施只按注册表调用这些接口，不需要为新语言添加 if 分支。
构建后端可提供 detect(bufnr)、actions 和 debug_configurations(ctx)，输入是相同的项目上下文。
工作流只描述策略和默认运行数据，不引用 CMake/Cargo 或语言模块。

所有插件由 lazy.nvim 声明式恢复；机器上的字体、编译器、targets、SDK 和工具链仍由你选择安装方式。
项目 JSON 只作为数据读取，打开项目时不会执行项目 Lua。构建命令仅在你触发动作时运行；
语言服务器自己的索引、检查与构建脚本属于对应 LSP 的正常工作过程。

# 配置架构与扩展约定

本配置使用普通 Lua table、函数和显式注册表组织模块，不引入额外框架或工具安装器。

## 职责与数据流

```text
init.lua
  ├─ config.options / autocmds / keymaps   编辑器基础设置
  ├─ config.lazy → plugins/*             插件声明、依赖与加载
  └─ config.workflow                     初始化模块，注册项目命令和快捷键

命令 / 快捷键
  → core.actions.execute                 捕获并展示交互入口的错误
  → core.context.resolve                 识别项目、选择策略与构建后端
      → core.project                     读取、校验并归一化项目配置
      → core.registry                    加载并检查已注册模块的接口
  → core.actions.dispatch                按策略分发动作
      → builders/*                       构建、运行、解析输出
      → core.tasks / core.debug          进程生命周期与调试服务
```

- `languages/*` 管理语言编辑功能；`builders/*` 管理构建工具；`workflows/*` 只表达项目策略。
- `projects/cargo.lua` 是 Cargo 项目模型，提供根目录探测、参数解释与 argv 生成，同时供语言编辑与构建使用。
- `toolchains/rust.lua` 负责 Rust 工具链查询，不依赖语言模块或构建模块。
- 语言层与构建层不直接导入对方的具体模块；公共能力放在有明确职责的共享模块中。
- `core.workflow` 与旧的 `builders.cargo_project` 保留转发入口；内部代码使用新模块。

## 项目上下文

`core.context.resolve(source, opts)` 接受 buffer 编号或文件/目录路径。
`opts.builder` 可以为本次调用明确指定后端；`opts.filetype` 可覆盖探测使用的文件类型。

选择顺序：

1. 最近的 `.nvim/project.json` 提供显式项目根目录和设置。
2. 显式 workflow 优先，否则由工作流探测；默认使用 `default`。
3. 本次指定 builder、项目 builder、工作流默认 builder 依次优先；`false` 禁用自动选择。
4. 自动选择后端时，先匹配文件类型，再比较根目录深度，最后按名称稳定排序。
5. 没有其他根目录时使用 Git 根目录、传入路径或当前工作目录。

每次解析生成独立快照，不做跨动作的持久缓存：

| 字段 | 约定 |
| --- | --- |
| `root` | 归一化项目路径 |
| `project` | 原始且已校验的项目设置，调用方只读 |
| `profile` / `workflow` | 工作流模块及名称 |
| `builder` / `builder_name` | 构建后端模块及名称，允许为空 |
| `build` / `configure` / `debug` | 对应项目参数，公共默认值已经补齐 |
| `run` | 合并工作流默认值与项目覆盖后的 cwd、args、env |
| `run_configured` | 是否显式配置了运行设置；CMake 未配置时继续使用插件默认运行目录 |
| `external` | 工作流策略与项目覆盖后的外部动作集合 |
| `tasks` | 自定义动作定义 |

`run.env` 按 build 环境 → 工作流运行环境 → 项目运行环境覆盖。
后端使用传入上下文，不在一次动作内重新读取 project.json；需要修改参数时先复制。
下一次动作重新解析，因此配置文件修改会在下一次动作生效。

## 动作与错误边界

分发优先级保持为：外部动作策略 → 项目自定义任务 → 活跃任务停止或调试继续 → 后端动作。
未提供 debug 动作时使用通用 DAP 配置。项目通过 `external` 中的 `false` 可覆盖工作流的外部策略。

内部 `dispatch(ctx, action, args)` 和后端允许抛出错误，便于直接定位和测试。
交互入口 `execute(action, opts)` 捕获错误、通知用户，并返回 `nil, error`；成功时传递后端返回值。
异步进程完成结果由任务回调返回，不将“进程已启动”等同于“构建成功”。

## 扩展模块

在 `lua/config/modules.lua` 注册模块名称；`core.registry.get()` 检查声明类型及必需接口。
类型注释集中在 `core/registry.lua` 和 `core/context.lua`。

| 类型 | 必需接口 | 常用可选接口 |
| --- | --- | --- |
| 语言 | 无，允许仅声明格式化或高亮 | `setup`、`setup_lsp`、`setup_debug`、`enrich_debug`、`check_health`，以及 filetypes/tools/treesitter |
| 构建后端 | `actions`，值为 `function(ctx, args)` | `detect(source)`、`setup`、`parse(stdout, stderr, root)`、`debug_configurations(ctx)` |
| 工作流 | 无 | `detect(source)`、`default_builder`、`external`、`external_handler`、`runtime` |

新增语言的文件类型注册放在 `setup()`，不依赖 LSP 是否加载或安装。
后端特有字段由对应项目模型解释；公共 cwd/args/env 与任务字段统一由 `core.project` 校验。
模块声明按静态配置处理：首次加载后缓存契约检查，修改代码后建议重启 Neovim。

## 状态与插件边界

- `core.tasks` 管理通用异步构建和终端任务；停止按项目根目录匹配，进程退出后清理登记，Neovim 退出时停止其管理的任务。
- 交互项目 shell 不登记为构建/运行任务，按停止构建不会关闭该 shell。
- 通用异步构建仍限制为一个；终端任务可以有多个，停止时处理当前项目的已登记任务。
- CMake 执行器仍由 cmake-tools 管理。CMake 动作需要切换 cwd，这个副作用只在后端适配层发生，不在项目识别期间发生。
- CMake 参数覆盖按插件配置对象保存原值；删除覆盖后恢复先前环境和目标设置，保留其他插件设置。
- CMake 后端不再写入 `cmake-tools.const`。通用 native DAP adapter 负责实际选择 GDB/LLDB 与语言增强，沿用插件传入的可执行文件和运行参数。
- 尚未承诺同一会话并行调度多个 CMake 项目；其全局 cwd 与执行器行为仍受插件接口约束。native 调试增强使用 DAP 启动时的当前项目上下文。
- Cargo workspace 探测与 Rust 工具链查询仍含同步子进程；性能优化需另行测量并设计缓存失效。

## 验证

不安装测试依赖。前两项使用干净 Neovim，第三项使用已安装插件。
Cargo 验证只构建 `/tmp` 中无外部依赖的项目，并传入 `--offline`。
需要复现时，可将缓存和状态也重定向到临时目录：

```sh
export XDG_CACHE_HOME=/tmp/nvim-refactor-cache
export XDG_STATE_HOME=/tmp/nvim-refactor-state
export NVIM_LOG_FILE=/tmp/nvim-refactor.log
nvim --clean -l tests/refactor.lua
nvim --clean -l tests/cargo_smoke.lua
nvim -i NONE --headless '+lua dofile("tests/plugins.lua")'
stylua --check init.lua lua tests
```

覆盖项目识别、模块接口、配置错误、工作流运行默认值、动作优先级、配置快照、
CMake 参数恢复、任务隔离与清理、Cargo 实际构建运行，以及插件命令/调试配置集成。
CMake 参数恢复使用插件替身验证；本次未验证实际 CMake 构建、完整 DAP 会话或 Windows 环境。

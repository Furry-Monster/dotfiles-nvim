# Rust 语言与 Cargo 构建

Rust 与 C/C++ 是并列的语言模块，使用同一套 LSP、格式化、Quickfix、调试和项目动作设施。
Rust 模块不识别引擎或内核类别。项目策略见 [架构说明](architecture.md)，独立于语言和构建后端。
本次复用已有插件，不增加 Rust 大型插件；AI 等重型功能继续由 tmux 承载。

## 编辑与工具

rust-analyzer 提供语义高亮、补全、导航、重命名、代码操作、内联提示与宏展开。
`gd/gr/gi/K`、`<leader>cr/ca/ch` 保持原有行为，`<leader>cm` / `:RustExpandMacro` 展开宏。
`<leader>cf` 优先通过 rust-analyzer 调用项目对应的 rustfmt，未连接 LSP 时使用 rustfmt 兜底。
保存不自动格式化；构建读取磁盘文件，请先保存。Rust/TOML 已加入 Tree-sitter 启动注册，
缺少 parser 时可用 `:TSInstall rust toml`。

工具从 PATH 查找。需要 Rust/Cargo、rust-analyzer、rustfmt；Clippy、rust-src 与本机 GDB/LLDB
用于完整体验。rustup 代理文件存在不代表选定工具链具有对应组件。
`:WorkflowHealth` 检查可见工具；在 tmux 中可用 `rustup component list --installed`、
`rustup target list --installed` 检查实际组件。配置不会安装或修改工具链。
编辑器启动的 Rust 工具进程默认带 RUSTUP_AUTO_INSTALL=0，缺少项目工具链时报告缺失，
不会触发 rustup 隐式安装；该设置仅限子进程，不改动系统环境或 rustup 配置。

## Cargo 操作

无项目 JSON 时可自动识别 Cargo workspace。统一动作根据 builder=cargo 调用：

| 按键 | 行为 |
| --- | --- |
| `<leader>cb` / `cc` / `cC` | build / check / clippy |
| `<leader>cT` / `cR` | test / run（交互终端） |
| `<leader>cx` | 停止异步构建或检查；交互终端程序用 Ctrl-C |
| `<leader>cd` / F5 | 项目本机调试，或继续当前调试 |

支持 `:Cargo build/check/clippy/test/run` 加参数，例如：

```vim
:Cargo build -p renderer --features vulkan
:Cargo test -p renderer -- --nocapture
:ProjectInfo
```

build/check/clippy 使用公共异步执行器，Cargo JSON 解析器提取错误码、文件、行列和诊断类型，
送入现有美化 Quickfix。无位置的 Cargo/链接错误、构建脚本和其他文本输出也保留。
失败自动打开列表，成功后可用 `<leader>q` 查看。run/test 保留交互输出，遵循 Cargo runner。
是否允许 run/test/debug 由项目工作流决定，不由 Rust 模块限制。

## 项目参数与交叉编译

`rust-toolchain.toml` 决定项目 Rust 版本；`.cargo/config.toml` 继续管理 target/linker/rustflags/
runner/build-std 等 Cargo 参数，不需要把这些内容迁移到编辑器中。
若要将编辑器动作和分析目标明确对齐，可以使用共同的 `.nvim/project.json`：

```json
{
  "builder": "cargo",
  "build": {
    "target": "x86_64-unknown-linux-gnu",
    "features": [],
    "args": [],
    "env": {}
  },
  "languages": { "rust": { "analyzer": {} } }
}
```

build.target 可以是 triple 或相对项目根的 target JSON 路径，会同时传给 Cargo 与 rust-analyzer。
未指定时 Cargo 继承自己的配置，不设置全局 target，也不会擅自开启所有 features。
build.features、build.noDefaultFeatures 与检查参数同样用于分析；更多设置写在
languages.rust.analyzer 下。不要在 build.args 重复写 --target；临时 :Cargo 的 --target 参数仅影响该次构建。
修改项目描述后执行 `:lsp restart rust_analyzer`；构建动作每次重读项目 JSON。

自定义 target 的格式跟随 rustc 版本变化，应固定项目验证过的编译器。
no_std crate 仍使用通用 Rust 模块；其 target、测试 harness、panic、linker 等由项目决定。
必要时显式配置 languages.rust.analyzer 中的 cargo.allTargets、check.allTargets、cfg.setTest，
不以项目类别自动推断。非 Cargo 构建可用 analyzer.linkedProjects 指向生成的 rust-project.json，
该模型只提供分析信息，不会将其他构建系统转换成 Cargo。

## 本机调试

Cargo 后端提供 LLDB/GDB 的 binary 与 tests 选项，选择后异步构建或执行 cargo test --no-run，
从 JSON artifacts 中读取可执行文件，不猜 target/debug 路径，支持 workspace 和多 binary。
原生调试显式使用 rustc 的宿主 triple；build.target 显式指定非宿主目标时不提供本机启动。
跨目标/远程调试由你在 tmux 中处理，配置不启动远程连接或模拟器。

Rust 语言层为共享调试器加入当前工具链的 pretty printers；断点、单步、变量、栈与 REPL
继续使用公共按键。debug.buildArgs 可选择包/bin/example，run.cwd/args/env 决定本机调试运行环境。
不要在 debug.buildArgs 再写 --target。

参考：[rust-analyzer 配置](https://rust-analyzer.github.io/book/configuration)、
[Cargo JSON 消息](https://doc.rust-lang.org/cargo/reference/external-tools.html)、
[Cargo 配置](https://doc.rust-lang.org/cargo/reference/config.html)、
[自定义 target](https://doc.rust-lang.org/rustc/targets/custom.html)。

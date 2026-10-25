# C# language 与 Unity 工作流

C# 是与 C++、Rust 同级的语言模块：`lua/languages/csharp.lua`。
Unity 是独立的项目工作流：`lua/workflows/unity.lua`，不在 C# 模块中判断 Unity 项目。
复用当前 nvim-lspconfig 的 Roslyn 支持，不额外安装 C# 专用 Neovim 插件。

## 编辑范围

支持 Roslyn 补全、语义高亮、定义/引用/实现跳转、悬停、重命名、代码操作、内联提示与格式化。
使用现有 `gd/gr/gi/K`、`<leader>cr/ca/ch` 和 `<leader>cf`。
格式化由 Roslyn 完成，读取项目约定；没有增加 CSharpier 或全 solution 格式化任务，保存不自动格式化。
Tree-sitter 已注册 `cs` 文件类型，parser 名称为 `c_sharp`；缺少时可用 `:TSInstall c_sharp`。

没有加入 C# 构建后端、Unity 播放控制、调试适配器、远程桥接或 Unity CLI 调用。
Unity 项目的编译、播放、资源导入、测试与调试均交给 Unity Editor。

## 工具与迁移

Roslyn 使用 PATH 中已安装的 `Microsoft.CodeAnalysis.LanguageServer` 或 `roslyn-language-server`，
并以 `--stdio` 启动，不使用常驻 daemon 模式。不推测安装目录或复用旧工具管理器目录。
使用 .NET 全局工具时，先将其工具目录加入用户 PATH；迁移时只需准备同名命令。
运行时、SDK、Roslyn 服务器的安装和更新由你选择方式，配置不自动执行安装命令。
不更改 shell 或系统 PATH。必要时可在 `languages.csharp.cmd` 中指定完整命令数组，包括 dotnet + DLL 的启动方式。
`:WorkflowHealth` 会显示 Roslyn 是否可见。
原生安装支持 .NET 官方的用户级工具方式，具体命令和影响范围见 [外部工具说明](tools.md)。

Roslyn 自身所需的 .NET 运行时与项目脚本的目标框架是两回事。
Unity 脚本的语言版本、程序集引用和条件编译符号以 Unity 生成的工程为准，配置不把它们改成最新 .NET。
项目模型加载可能产生语言服务器缓存或 NuGet/design-time 项目数据，这是语言服务器的分析过程，
不等于启动 Unity 构建；不会调用 Unity 生成项目文件或修改 Unity 包与编辑器设置。

## Unity 工程模型

完整导航依赖正确的 `.sln/.slnx/.csproj` 与其中的 UnityEngine、UnityEditor、包和 asmdef 引用。
先在 Unity 中生成/更新项目文件，再从终端打开 Neovim。
不同版本通常可在 Preferences → External Tools 中找到 Regenerate project files，
具体生成能力由项目安装的 IDE 集成包提供。配置不会替你安装或更改这些包。
新增、删除脚本或修改 asmdef 后，如模型没有自动刷新，请在 Unity 重新生成工程，再执行 `:CSharpReload`。
不要手工修改 Unity 生成的引用来掩盖错误，它们会被后续生成覆盖。

单个 solution 会自动打开；多个 solution 时显示选择列表。
`:CSharpSolution` 可重新选择，`:CSharpSolution Game.sln` 可明确指定当前 analysis solution。
也可在项目根目录的 `.nvim/project.json` 中记录默认选择：

```json
{
  "workflow": "unity",
  "languages": {
    "csharp": { "solution": "Game.sln", "settings": {} }
  }
}
```

将 Game.sln 替换为实际文件名；没有歧义时无需该字段。
`languages.csharp.settings` 是普通 Roslyn LSP 设置，不限制在 Unity 使用。
没有 solution 的普通 C# 工程会读取根目录的 csproj；不附带任何 Unity 依赖。

## Unity 项目策略

同时存在 `Assets/` 与 `ProjectSettings/ProjectVersion.txt` 时自动识别 Unity 工作流。
也可复制 `examples/projects/unity.json` 到 `.nvim/project.json` 显式选择。
显式 workflow 字段优先于自动识别。
Unity 默认不选择构建后端，嵌套的原生插件 CMakeLists 不会把整个 Unity 工程切换成 CMake 工作流。
公共 build/check/lint/configure/test/run/debug/stop 动作只提示交给 Unity Editor，不启动任务。
这一策略同样适用于工程内的 C#、C++ 等文件，与源码语言无关。
直接调用底层插件的原生命令不属于统一项目动作入口。

背景分析默认限制在已打开文件，避免启动全 solution 分析；服务仍会加载引用以支持跨文件导航。
缺少 Unity 类型时，先检查工程文件与引用是否已生成，再使用 `:ProjectInfo`、`:WorkflowHealth` 和 LSP 日志排查。
这里提供标准 C# / Roslyn 编辑功能，不承诺 Rider 的 Unity 专有检视或事件方法模板。

参考：[Roslyn 的 nvim-lspconfig 配置](https://github.com/neovim/nvim-lspconfig/blob/master/lsp/roslyn_ls.lua)、
[Unity 工程文件生成](https://docs.unity.cn/Packages/com.unity.ide.visualstudio%402.0/manual/using-visual-studio-editor.html)。

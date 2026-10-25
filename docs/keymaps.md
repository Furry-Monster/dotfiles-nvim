# 快捷键

`<leader>` = 空格。保持 Vim 模式编辑、文本对象、窗口命令、`=` 缩进；终端无法传递的组合都有 leader 备用键。

| 操作 | 按键 |
| --- | --- |
| 保存 / 退出窗口 | `Ctrl+s` / `<leader>w`；`<leader>q` |
| 清除搜索高亮 | `Esc` |
| 窗口导航 | `Ctrl+h/j/k/l`，原生 `Ctrl+w` 保留 |
| 前后 buffer / 关闭 buffer | `Shift+h/l` / `<leader>bd` |
| 快速打开文件 | `Ctrl+p` / `<leader>ff` |
| 全部文件（含忽略文件，排除 .git） | `<leader>fF` |
| 项目内容 / 光标词搜索 | `<leader>fg` / `<leader>fw` |
| Buffer / 文件符号 / 工作区符号 | `<leader>fb` / `<leader>fs` / `<leader>fS` |
| 文件树 / 定位当前文件 | `<leader>fe` / `<leader>fE` |
| 恢复搜索 / 当前文件搜索 | `<leader>fr` / `<leader>f/` |
| 定义 / 声明 / 引用 / 实现 / 类型 | `gd` / `gD` / `grr` / `gri` / `grt` |
| C/C++ 头文件 / 源文件切换 | `<leader>ch` |
| 定义 / 重命名（IDE 风格） | `F12` / `F2` |
| 代码操作 / 重命名 / 文档 | `<leader>ca` / `<leader>cr` / `K` |
| 手动文件/所选行格式化 | `Shift+Alt+F` / `<leader>cf` |
| 普通补全 / 确认 / 关闭 | `Ctrl+Space` / 显式选中后 `Enter` / `Ctrl+e` |
| 补全选择 | `Ctrl+n/p` 或方向键；Tab 保留普通输入/片段跳转 |
| 当前位置 / 当前文件 / 全工程诊断 | `<leader>e` / `<leader>xl` / `<leader>xx` |
| 上下诊断 / quickfix | `[d`、`]d` / `[q`、`]q` |
| 打开 quickfix | `<leader>xq` |
| 构建 / configure / target / 构建目录 | `<leader>bb` / `<leader>bc` / `<leader>bt` / `<leader>bp` |
| 任务面板 / 重跑 / 停止 / 项目任务 | `<leader>bo` / `<leader>br` / `<leader>bs` / `<leader>bT` |
| 测试 / Rust Clippy | `<leader>tt` / `<leader>tc` |
| 启动或继续 / 断点 / 单步跳过 / 进入 / 跳出 / 停止 | `F5` / `F9` / `F10` / `F11` / `Shift+F11` / `Shift+F5` |
| 断点 / 条件断点 / 日志断点 | `<leader>db` / `<leader>dc` / `<leader>dl` |
| 调试 UI / 求值 / REPL / 终止 / 参数 | `<leader>du` / `<leader>de` / `<leader>dr` / `<leader>dt` / `<leader>da` |
| Git 状态 / 未暂存差异 / 已暂存差异 / 日志 / 当前行 blame | `<leader>gs` / `<leader>gd` / `<leader>gD` / `<leader>gl` / `<leader>gb` |
| Git 行内预览 / 暂存当前 hunk | `<leader>gp` / `<leader>gh` |
| 前后 Git hunk | `[h` / `]h` |
| AI Agent / 行内 AI | `<leader>aa` / `<leader>ai` |
| AI / Git 总开关 / 关闭全部 | `<leader>ua` / `<leader>ug` / `<leader>uQ` |
| 诊断 / 行内诊断 / inlay hints | `<leader>ud` / `<leader>uv` / `<leader>uh` |
| 工程终端 | `<leader>ut` |
| 离开终端输入模式 | 原生 `Ctrl+\` 后 `Ctrl+n`；或连按两次 `Ctrl+\` |
| 项目设置 / 根目录 / 健康检查 | `<leader>pt` / `<leader>pr` / `<leader>ph` |
| 查看全部按键 / 帮助 | `<leader>fk` / `<leader>fh` |

`mini.surround`：`sa` 添加、`sd` 删除、`sr` 替换包围符；`mini.ai` 扩展 `a/i` 文本对象。
Neovim 原生 `gcc` / `gc{motion}` 注释保留，不再叠加注释插件。
Konsole/KDE 若拦截组合键，先调整终端/桌面快捷键；配置不自动修改桌面设置。

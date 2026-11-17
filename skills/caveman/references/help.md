# Caveman 用法速查（Copilot）

平时用自然语言即可，不需要输入任何命令。

- “这次简短回答”：当前回答用lite，之后恢复。
- “以后少废话”：会话持续lite；“极简一点”可换ultra；“正常说话”关闭。
- “用文言文解释”：文言模式；没要求长期则只作用于当前回答。
- “帮我写提交信息”：自动使用commit规则，只生成说明，不执行提交。
- “审查这个diff”：自动使用review规则，完成后恢复此前会话风格。
- “压缩这个记忆文件 `/绝对路径/文件.md`”：先确认范围，按 `compress.md` 备份、生成候选、校验；不是仅仅改变回答长度。

强度：lite / full / ultra / wenyan-lite / wenyan-full / wenyan-ultra；wenyan作为wenyan-full的别名。

`/caveman` 可选，后面可写任务或强度，但不以手动调用为前提。旧独立命令不再单独注册。

“能否整理caveman”“解释compress实现”是讨论，不会启用表达模式或改写文件。查看帮助也不改变当前模式。

统计功能没有Copilot会话计量接入，不能提供真实token节省率；此前标称百分比不是当前会话实测。没有运行时，不自动读取 `CAVEMAN_DEFAULT_MODE` 或 `~/.config/caveman/config.json`。

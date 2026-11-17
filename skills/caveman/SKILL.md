---
name: caveman
description: "Adaptive concise-output skills for VS Code Copilot. Automatically select by the user's actual task: short answers/简短/少废话/省token; terse Conventional Commit messages/写提交信息; concise code or PR review/代码审查; explicitly compress a named prose or memory file/压缩记忆文件; caveman help/帮助; token stats questions/统计. Supports lite/full/ultra and wenyan-lite/wenyan-full/wenyan-ultra/文言文. Use natural language; slash commands are optional. Switch commit/review/compress only for that task, then restore the previous chat style. A mention, quotation, or request to organize these skills is not a mode command. Never rewrite files merely because the user asks for a shorter reply."
user-invocable: true
---

# Caveman — 自动选择任务模式

不要求用户记入口。根据**当前实际请求**选择规则，只读取对应参考；不要为每种任务再次调用旧独立 skill。主入口被发现与选择仍由 Copilot/模型决定，不是已安装的确定性 hook。

## 自动路由

| 模式 | 实际意图及例子 | 按需读取 | 作用域 |
|---|---|---|---|
| style | “以后回答简短一点”“简单点”“少说点”“少废话”“省 token”“caveman mode” | [表达规则](references/style.md) | 用户明确长期要求时保持至关闭/换档，否则仅当前回答 |
| style-level | “极简”“lite/full/ultra”“用文言文”“wenyan” | [表达规则](references/style.md) | 跟随用户作用域；wenyan等同wenyan-full |
| commit | “帮我写提交信息”“生成 commit message”；正在处理已暂存改动的提交说明 | [提交规则](references/commit.md) | 仅提交信息，不stage、不commit、不amend |
| review | “审查这个 diff”“review this PR”“看看代码有什么问题” | [审查规则](references/review.md) | 仅审查产物；不自动改代码或提交GitHub review |
| compress | “压缩这个记忆文件 `/路径/文件.md`”“精简指定文件里的自然语言” | [安全文件压缩](references/compress.md) | 仅明确授权的文件；缺少具体路径时先澄清，不写文件 |
| help | “caveman有什么用法”“怎么切换模式” | [用法速查](references/help.md) | 只解释，不改变会话风格 |
| stats | “这轮省了多少token”“caveman统计” | 见下方统计边界 | 只说明证据与限制，不改变风格 |
| stop | “正常说话”“stop caveman”“normal mode”“关闭简洁模式” | 无需额外文件 | 停止会话简洁风格，回到普通表达 |
| none | 只是引用上述词、讨论安装/整理/实现这些技能，或没有匹配意图 | 无需额外文件 | 不激活任何新模式，照常回答 |

## 切换与恢复

维护两个独立概念：**会话表达风格**和**本轮任务模式**。读取本 skill 本身不能把全部后续回答锁成 full。

1. 先辨别命令与讨论；否定、引用、假设及“整理 caveman 系列”不算启用。用户明确指定的要求优先于自动推断。
2. 用户要求提交、审查或文件压缩时，自动读取对应参考并切换任务模式。普通关键词“review”“commit”出现在待分析材料中不构成授权。
3. 任务模式覆盖**相应产物**，不永久覆盖聊天风格。产物格式优先于会话 style（如Conventional Commits结构、review可选严重级标记）；聊天风格只约束周边说明。结束后回到原 style（原来normal则normal）。
4. “把这次回答缩短”只影响本次；“以后简短一点”保持到用户关闭。未指定强度时，明确caveman请求用full，普通“简短一点”“简单点”“少说点”用lite，文言请求用wenyan-full；没有长期指示时仅本次。
5. 多意图按用户顺序处理：先review再写commit，分别载入规则。仅提到文件名不触发compress；要求“少说点”只调整表达，不压缩文件。
6. 用户要求详细解释、风险提示、不可逆操作确认、复杂步骤容易歧义时，临时恢复完整清晰的表达；结束后回原style。停止指令只关闭会话style，不取消当轮明确要求的实际任务，也不自行取消其产物格式；若用户明确要求本次产物详细/正常写，则覆盖该产物的简写默认值。
7. 不为了风格跳过必要的查证、验证、审批或工具说明。精简的是措辞，不是思考深度、证据、风险与技术准确性。
8. 不强制所有代码/文档/提交都用碎句。代码、命令、API、符号、数字、否定条件及错误原文按原意保持；使用用户语言，不强迫英文。

## 旧写法与宿主边界

- `/caveman-commit`、`/caveman-review`、`/caveman-compress`、`/caveman-help`、`/caveman-stats` 仅在实际命令意图下映射为上述模式，不表示旧命令仍注册。引用、否定、安装/整理/实现这些名称时不映射；自然语言足够，无需手动调用它们。
- 表达风格仅按用户指定作用域持续，专项模式始终在产物完成后自动结束，无需手动关闭。
- 没有安装SessionStart hook、后台tracker或跨会话状态恢复；环境变量和配置文件不会因这个skill自动执行。
- stats原来读取Claude Code日志，当前Copilot安装没有等价适配。无实际token计量时直接说明无法获取；不捏造65%等节省率，不以字符数冒充token数。若用户明确要求可提供标注为字符数/字节数的对比。
- 文件压缩由当前Copilot生成候选，附带脚本只做本地只读校验；不调用Anthropic API、Claude CLI或其他独立模型服务。
- 本次不改全局instructions、不加常驻hook；因此无法保证每次模型都会自动载入。加载后按本表切换，不要求用户改用独立入口。

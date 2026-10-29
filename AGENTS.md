# CanopyText 开发指导

本文件只写改这个仓库时要守的边界，以及已经发出的版本。面向用户的用法在 `README.md`，这里不复述。

## 仓库边界

CanopyText 是 CanopyDeck 的外部工具，独立进程。清单在仓库根的 `canopy.json`：`id` 是 `com.canopydeck.plugin.text`，`name` 是「转换器」，`executable` 是 `CanopyText`。轨道和命令图标是 `arrow.left.arrow.right`。标识保持不变。进程 hello 里的标识必须和这份清单一致，否则宿主会卸掉。

宿主不编译本仓库，也不运行这里的构建脚本。它钉住默认分支当前提交，找到指向同一提交的 git 标签，再从该标签的 GitHub Release 下载与 `executable` 同名的资源。没有这个 Release，或资源名不是 `CanopyText`，插件页会报「这个提交没有对应的 Release，或 Release 里没有清单写的可执行文件」。只推送提交装不上。

页面由本进程在 `127.0.0.1` 的临时端口上提供，hello 里带这个地址。宿主把网页放进甲板，可用区域大约 400×240，页面要铺满这块视窗。网页跟 `prefers-color-scheme`，不向宿主问外观。

助手不另开协议，调用的是 hello 里登记的命令。除「当前时间」外，`paths` 必须是一项：已有文件按 UTF-8 读取，上限与页面请求体相同；否则把这一项当原文。这些转换命令 `showsPage` 为真，甲板不另画按钮。给它们配的快捷键只展开页面。

依赖钉在 CanopyDeck `0.17.1` 的 `CanopyToolWire`。入口最先 `ProcessLocalization.bootstrapFromEnvironment()`，再发 hello。用户可见文案走进程内 `TextL10n`（`zh-Hans` / `en`），按 `CANOPY_APPLE_LANGUAGES` 选表；不要加 `Bundle.module` / String Catalog 资源包——宿主 Release 只装名为 `CanopyText` 的单个可执行文件。不要改清单里的可执行文件名，除非发版资源同时改成同一个名字。

## 发版

用户完成提交并推送之后再打标签。看上一个版本标签以来的改动：

- 只有缺陷修复或行为修正：升补丁位。
- 页面或转换有用户能感知的改动：升次版本。同一次里两者都有，取次版本。
- 纯文档、注释，且没有用户可感知的行为变化：不打标签。

仓库里没有发布脚本。标签必须打在宿主会钉住的那个提交上，也就是当时的默认分支 HEAD。

1. `swift build -c release --product CanopyText`。产物是 `.build/release/CanopyText`，Mach-O arm64。上传时文件名必须仍是 `CanopyText`，不要打成 zip。
2. 打附注标签。标签名是 `v` 加版本。附注是「版本、中文冒号、一句摘要」。
3. `git push origin vX.Y.Z`。
4. `gh release create`。标题是不带 `v` 的版本，正文是附注里冒号后面的那一句，资源是上面的二进制。
5. `gh release view` 确认资源名是 `CanopyText`，并且标签指向刚才那个提交。

不要移动已经发出的标签。打包或上传失败时不升下一个版本，只重试这一版。`.DS_Store` 不提交。

## 已发版本

| 标签 | 提交 | Release 正文 |
| :--- | :--- | :--- |
| `v0.1.0` | `7b1da80` | 文本页可以美化和压缩 JSON，做 Base64 与 URL 编解码，并在时间戳和本地时间之间转换。 |
| `v0.1.1` | `883e0dc` | 文本页露出输入和结果框。 |
| `v0.2.0` | `1ce5526` | 按工具重做文本页，JSON 着色，编解码和时间可以对照。 |
| `v0.3.0` | （见 git） | 把页面上的转换登记成助手命令。 |

语言与浅色适配属于用户可感知能力，相对 `v0.3.0` 应升次版本后再打标签、附 `CanopyText` 资源。

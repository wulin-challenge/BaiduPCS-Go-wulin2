# 百度网盘自动上传下载脚本教程

本文档总结 `baiduud.cmd` 与 `baiduud.sh` 的完整需求、参数、使用案例、运行流程和排错方法，并附带当前两份脚本的完整源码，便于以后直接查阅。

- 更新日期：2026-07-17
- Windows 脚本：[baiduud.cmd](./baiduud.cmd)
- Linux 脚本：[baiduud.sh](./baiduud.sh)
- Windows SHA-256：`71B4B6483AF1FA7F8F761B4F044F1F30BE89AE0B3B99DED03B7249FAAC79347F`
- Linux SHA-256：`BC7D0579B49206AD289598928D08D14190A61ED56AB3D23E76307829DB2CF800`

## 一、需求演进总结

本次工作基于已经安装、重命名为 `baiducmd` 并完成登录的 BaiduPCS-Go-wulin2 客户端。脚本经过以下阶段：

1. 创建 Windows 脚本，使用 `u` 上传、`d` 下载。
2. 初始版本在上传前清空网盘目录，然后再上传。
3. 本地和网盘目录不存在时自动创建并验证。
4. 增加中文注释、中文控制台日志和 `baiduud.log`。
5. 创建等价 Linux Bash 版本，支持隐藏文件和安全临时文件。
6. 增加 `-lu`、`-bu`、`-ld`、`-bd`，允许每次运行临时指定目录。
7. 增加 `baiduud help`，完整解释参数、规则、默认值和案例。
8. 将普通上传改为追加模式，远端同名文件使用 `overwrite` 策略覆盖。
9. 增加 `del` 和 `u -del`，只有明确指定时才清空网盘目录。
10. 下载前显示五列中文列表，支持按序号、多选或全部下载。
11. 修复 `ls -l` 名称右侧对齐空格导致远端路径错误、下载结果为 `0B` 的问题。
12. 下载后检查本地目标和客户端数据量，禁止把未生成文件的 `0B` 结果误报为成功。
13. 为 `del` 和 `u -del` 增加危险路径保护，禁止根目录、相对路径、通配符、重复斜杠和跳级路径段。
14. Windows 上传使用远端目标与精确字节数校验；Linux 上传仍要求客户端输出完成标记，两端下载也会验证本次新生成的内容。
15. Windows 版本支持分号开头文件，并明确拒绝会触发 CMD 二次变量展开的百分号文件名。
16. 修复 Windows 下载状态被缓冲、UTF-8 输出按 GBK 回放乱码及实际下载完成后误报失败的问题。
17. 增加只读 `list [-bu 网盘上传目录]` 命令，复用下载流程的五列表格但不进入下载选择。
18. 修复 Windows 上传状态被缓冲的问题；上传与下载都让 `baiducmd` 直接连接控制台，动态进度会持续显示。

## 二、最重要的安全规则

> [!WARNING]
> 普通 `u` 上传不会删除网盘已有内容。只有执行 `del` 或 `u -del` 时，脚本才会删除 `BAIDU_UPLOAD` 或 `-bu` 指定目录中的全部内容。删除只保留目标目录本身，并且脚本会拒绝 `/`、`////`、相对路径、`*`、`?`、`//`、`.` 和 `..` 路径段。

参数覆盖只对当前一次运行有效，不会修改脚本中的默认配置。本地上传和下载目录可以使用相对路径，并以当前工作目录为基准；用于 `del` 或 `u -del` 的网盘上传目录必须是安全的非根绝对路径。

## 三、命令格式

Windows：

```bat
baiduud help
baiduud u [-lu 本地上传目录] [-bu 网盘上传目录] [-del]
baiduud d [-ld 本地下载目录] [-bd 网盘下载目录]
baiduud del [-bu 网盘上传目录]
baiduud list [-bu 网盘上传目录]
```

Linux：

```bash
./baiduud.sh help
./baiduud.sh u [-lu 本地上传目录] [-bu 网盘上传目录] [-del]
./baiduud.sh d [-ld 本地下载目录] [-bd 网盘下载目录]
./baiduud.sh del [-bu 网盘上传目录]
./baiduud.sh list [-bu 网盘上传目录]
```

如果已将 Linux 脚本链接或安装为 `baiduud`，也可以运行 `baiduud help`。

## 四、参数速查

| 参数 | 适用操作 | 含义 | Windows 默认值 | Linux 默认值 |
| --- | --- | --- | --- | --- |
| `help` | 独立操作 | 显示帮助，不上传、不下载、不删除 | - | - |
| `u` | 独立操作 | 追加上传；同名文件覆盖 | - | - |
| `d` | 独立操作 | 列表选择后下载 | - | - |
| `del` | 独立操作 | 确认后清空网盘上传目录内容 | - | - |
| `list` | 独立操作 | 只显示网盘上传目录列表 | - | - |
| `-lu` | `u` | 指定本地上传目录 | `D:\conf\mhloctest\upload` | `/data/conf/mhloctest/upload` |
| `-bu` | `u`、`del`、`list` | 指定百度网盘上传、删除或查询目录 | `/resources/upload_temp` | `/resources/upload_temp` |
| `-ld` | `d` | 指定本地下载目录 | `D:\conf\mhloctest\download` | `/data/conf/mhloctest/download` |
| `-bd` | `d` | 指定百度网盘下载目录 | `/resources/upload_temp` | `/resources/upload_temp` |
| `-del` | `u` | 上传前先清空网盘上传目录，不二次确认 | - | - |

### 参数规则

1. 第一个参数必须是 `u`、`d`、`del`、`list` 或 `help`。
2. `u` 只能使用 `-lu`、`-bu`、`-del`。
3. `d` 只能使用 `-ld`、`-bd`。
4. `del` 只能使用 `-bu`，并在删除前要求输入 `y` 或 `Y`。
5. `list` 只能使用 `-bu`，不会显示下载选择提示，也不会执行下载。
6. 每个目录参数后必须紧跟目录值。
7. 路径包含空格时必须使用双引号。
8. 相对路径以当前工作目录为基准。
9. 同一个目录参数重复出现时，最后一个值生效。
10. 未提供的参数继续使用脚本顶部默认值。
11. `help`、`-h`、`--help` 均可显示帮助；推荐使用 `baiduud help`。
12. `del` 和 `u -del` 的 `-bu` 必须是非根绝对路径，不能包含通配符、重复斜杠、`.` 或 `..` 路径段。
13. Windows CMD 版本不支持文件或文件夹名称中包含百分号（`%`）；名称以分号（`;`）开头不受影响。

## 五、Windows 完整使用案例

### 5.1 查看帮助

```bat
baiduud help
```

帮助会显示全部操作、五个参数、默认值、选择规则和完整案例。该命令不要求 `baiducmd` 已登录，也不会执行文件操作。

### 5.2 普通追加上传

```bat
baiduud u
baiduud u -lu ./ -bu /resources/upload_temp
baiduud u -lu D:\conf\mhloctest\upload -bu /resources/upload_temp
```

这三条命令都不会清空网盘目录。脚本使用 `--policy overwrite`，覆盖远端同名文件，同时保留远端其他内容。Windows 会直接显示 `baiducmd` 的实时上传状态；每项完成后再用 `meta` 验证远端目标，普通文件还会比较精确字节数。

### 5.3 只查询网盘上传目录列表

```bat
baiduud list
baiduud list -bu /resources/upload_temp
```

`list` 使用默认 `BAIDU_UPLOAD` 或 `-bu` 指定目录，输出与 `baiduud d` 相同的序号、名称、类型、大小、修改日期五列表格。它不会显示下载选择提示，也不会上传、下载或删除数据。

### 5.4 独立删除网盘内容

```bat
baiduud del
baiduud del -bu /resources/upload_temp
```

`del` 只删除目标目录中的内容，保留目标目录本身。脚本先校验路径，再调用任何 `baiducmd` 命令；路径安全后才显示目标路径，只有输入 `y` 或 `Y` 才执行。输入其他内容会取消且返回成功。

### 5.5 删除后再上传

```bat
baiduud u -del
baiduud u -lu ./ -bu /resources/upload_temp -del
baiduud u -lu D:\conf\mhloctest\upload -bu /resources/upload_temp -del
```

`u -del` 已明确表达删除意图，因此不会再次询问。脚本仍会先执行与 `del` 相同的危险路径校验，然后清空并复查网盘目录，再使用覆盖策略上传。

### 5.6 列表选择下载

```bat
baiduud d
baiduud d -ld ./ -bd /resources/upload_temp
baiduud d -ld D:\conf\mhloctest\download -bd /resources/upload_temp
```

下载前会显示类似列表：

| 序号 | 名称 | 类型 | 大小 | 修改日期 |
| --- | --- | --- | --- | --- |
| 1 | xxx | 文件 | 10M | 2026-07-16 12:01:01 |
| 2 | xxx2 | 文件夹 | - | 2026-07-16 12:02:01 |

输入 `1` 下载第一个项目，输入 `1,2` 下载多个项目，输入 `a` 或 `A` 下载全部。逗号两侧可以有空格，重复序号会自动去重；非法或越界序号会提示后重新输入。文件夹大小因客户端不提供递归大小而显示为 `-`。

### 5.7 路径包含空格或只覆盖一个默认值

```bat
baiduud u -lu "D:\my upload" -bu "/resources/upload temp"
baiduud d -ld "D:\my download" -bd "/resources/upload temp"
baiduud u -lu D:\another\upload
baiduud d -ld D:\another\download
```

未指定的目录仍使用脚本顶部默认值。

## 六、Linux 完整使用案例

首次使用先设置权限：

```bash
cd docs
chmod +x baiduud.sh
```

### 6.1 查看帮助

```bash
./baiduud.sh help
```

### 6.2 普通追加上传

```bash
./baiduud.sh u
./baiduud.sh u -lu ./ -bu /resources/upload_temp
./baiduud.sh u -lu /data/conf/mhloctest/upload -bu /resources/upload_temp
```

### 6.3 只查询网盘上传目录列表

```bash
./baiduud.sh list
./baiduud.sh list -bu /resources/upload_temp
```

输出格式与 Windows `list` 和下载列表一致，不进入下载选择流程。

### 6.4 独立删除网盘内容

```bash
./baiduud.sh del
./baiduud.sh del -bu /resources/upload_temp
```

独立删除先校验网盘路径，安全路径才会要求输入 `y` 或 `Y` 确认，并保留目标目录本身。

### 6.5 删除后再上传

```bash
./baiduud.sh u -del
./baiduud.sh u -lu ./ -bu /resources/upload_temp -del
./baiduud.sh u -lu /data/conf/mhloctest/upload -bu /resources/upload_temp -del
```

### 6.6 列表选择下载

```bash
./baiduud.sh d
./baiduud.sh d -ld ./ -bd /resources/upload_temp
./baiduud.sh d -ld /data/conf/mhloctest/download -bd /resources/upload_temp
```

列表格式和选择规则与 Windows 相同：输入 `1`、`1,2` 或 `a`。

### 6.7 路径包含空格

```bash
./baiduud.sh u -lu "/data/my upload" -bu "/resources/upload temp"
./baiduud.sh d -ld "/data/my download" -bd "/resources/upload temp"
```

### 6.8 环境变量默认值与命令行覆盖

```bash
LOCAL_UPLOAD=/srv/default-upload \
BAIDU_UPLOAD=/resources/default-upload \
./baiduud.sh u -lu /srv/temporary-upload
```

最终本地上传目录是 `/srv/temporary-upload`，网盘上传目录是环境变量提供的 `/resources/default-upload`。优先级为：命令行参数 > 环境变量 > 脚本内置默认值。

## 七、错误案例

以下命令会返回退出码 `1` 并显示完整帮助：

```text
baiduud u -ld ./download
baiduud d -bu /resources/upload
baiduud d -del
baiduud del -bd /resources/upload
baiduud u -lu
baiduud d -unknown value
baiduud help extra
baiduud del -bu /
baiduud u -bu /resources/../other -del
baiduud list -bd /resources/upload_temp
```

常见错误含义：

- `参数 -lu 缺少目录值`：选项后没有目录。
- `参数 -ld 仅适用于下载操作 d`：上传命令使用了下载参数。
- `删除操作 del 只能使用 -bu`：`del` 使用了本地或下载目录参数。
- `参数 -del 仅适用于上传操作 u`：下载命令错误使用了删除标记。
- `列表操作 list 只能使用 -bu`：`list` 错误使用了本地目录、下载目录或 `-del` 参数。
- `未知参数`：参数拼写错误。
- `help 后面不能再添加其他参数`：帮助操作必须单独使用。
- `拒绝清空网盘目录`：删除路径是根目录、相对路径，或包含 `*`、`?`、`//`、`.`、`..` 路径段。
- `不支持名称中包含百分号`：Windows CMD 会二次展开百分号变量，必须先重命名该项目；Linux 版本没有此限制。

## 八、上传执行流程

1. 解析操作和目录覆盖参数。
2. 检查 `baiducmd` 是否位于 `PATH`。
3. 指定 `-del` 时先校验网盘删除路径；危险路径在任何 `baiducmd` 调用前直接拒绝。
4. 自动创建本地上传目录。
5. 创建网盘上传目录，并用 `ls -l` 验证可访问。
6. 指定 `-del` 时清空并复查网盘目录；普通上传跳过删除。
7. 本地目录为空时记录警告并正常结束。
8. 使用 `upload --policy overwrite` 逐项追加上传顶层文件和子目录。
9. Windows 让 `baiducmd` 直接连接控制台，实时显示每项上传状态；Linux 使用 `tee` 实时显示并记录，并要求输出包含 `上传结束`。
10. 每项上传后使用 `meta` 验证远端目标；普通文件还要比较本地与网盘精确字节数，目录验证远端目标存在。Windows 不依赖客户端中文完成文案，因此客户端版本调整文案不会导致误判。
11. 最后重新读取网盘目录并记录当前顶层项目数量。

远端允许保留额外项目，因此脚本不要求本地与远端项目总数相等。文件字节数校验可以拦截大部分无动作或截断上传，但不能代替内容哈希校验，重要数据仍建议另外保存校验值和本地备份。

## 九、删除执行流程

### 独立 `del`

1. 使用默认 `BAIDU_UPLOAD` 或 `-bu` 指定目录。
2. 在调用客户端前校验路径必须是安全的非根绝对路径，并移除单个末尾斜杠。
3. 自动创建并验证网盘目录。
4. 目录为空时正常结束。
5. 显示目标路径并等待输入 `y` 或 `Y`。
6. 执行 `<目录>/*` 删除内容，但保留目录本身。
7. 再次读取目录；如果仍有项目则返回失败。

### 上传参数 `-del`

`u -del` 使用相同的路径保护、删除与复查逻辑，但不要求二次确认。即使本地上传目录为空，安全路径上的 `-del` 仍会先执行已经明确要求的清空操作。

## 十、下载执行流程

1. 解析操作和目录覆盖参数。
2. 自动创建本地下载目录。
3. 创建并验证网盘下载目录。
4. 网盘目录为空时正常结束。
5. 解析 `ls -l`，移除名称右侧用于列对齐的空格，并显示从 1 开始的五列中文列表。
6. 等待输入单个序号、逗号分隔序号或 `a`。
7. 校验范围并去除重复序号，错误输入会重新提示。
8. Windows 为每个项目在正式下载目录下创建随机 `.baiduud_download_*` 暂存目录，并让 `baiducmd` 直接连接控制台，因此进度可以实时显示且中文不会被错误转码。
9. Windows 只校验本次暂存目录中新生成的项目；文件还会用 `meta` 比较精确字节数，验证后再覆盖文件或合并文件夹到正式目录，最后删除暂存目录。
10. Linux 使用 `tee` 实时显示并记录客户端输出，要求输出包含 `下载结束`，然后检查本地目标及非空文件大小。
11. 两个平台都不会用正式目录中的旧文件冒充本次下载结果；客户端未生成新内容时返回失败。

下载不会删除本地目录中仅存在于本地的文件。

## 十一、列表查询执行流程

1. `list` 使用默认 `BAIDU_UPLOAD` 或 `-bu` 指定查询目录。
2. 自动创建缺失的网盘目录，并通过 `ls -l` 验证目录可访问。
3. 复用下载流程的项目解析，输出从 1 开始的名称、类型、大小和修改日期。
4. 空目录记录中文提示并正常结束。
5. 查询完成后直接退出，不读取下载序号，也不调用上传、下载或删除命令。

## 十二、日志与排错

脚本自身的中文日志同时显示在控制台，并追加写入脚本目录下的 `baiduud.log`。Windows 上传和下载时，`baiducmd` 的动态进度直接显示在控制台，不再经过临时文件回放；客户端动态输出不重复写入日志，脚本日志仍记录开始、校验和完成结果。

```text
[2026-07-16 10:58:22] [信息] 未指定 -del，本次采用追加上传，不删除网盘已有内容。
[2026-07-16 10:58:23] [警告] 开始清空网盘目录：/resources/upload_temp
[2026-07-16 10:58:24] [信息] 已选择 2 个下载项目。
[2026-07-16 10:58:25] [错误] 参数 -lu 缺少目录值。
```

Windows 查询日志：

```bat
type docs\baiduud.log
```

Linux 查询日志：

```bash
tail -n 100 docs/baiduud.log
tail -f docs/baiduud.log
```

### 找不到 baiducmd

```bat
where baiducmd
baiducmd --version
```

```bash
command -v baiducmd
baiducmd --version
```

### 网盘目录创建或验证失败

检查 `baiducmd who`、登录状态、网络、父目录权限，并手工运行 `baiducmd ls <目录>`。

### 下载显示 0B 或本地没有文件

脚本会移除 `baiducmd ls -l` 为表格对齐补在名称右侧的空格，再拼接远端路径。Windows 下载到本次新建的隔离暂存目录，并比较远端与本地文件的精确字节数；Linux 检查 `下载结束`、本地目标和非空文件大小。客户端没有生成对应内容时，脚本会记录 `下载校验失败` 并返回退出码 `1`，正式目录中已有的旧文件不能掩盖失败。

排查时可以查看日志中的实际下载命令输出，并手工验证远端路径：

```bat
baiducmd meta "/resources/upload_temp/文件名"
```

### 上传命令退出为 0，但脚本报告上传校验失败

脚本不只检查退出码。Windows 要求 `baiducmd meta` 能读取远端目标，普通文件还必须返回与本地一致的精确字节数；Linux 另外要求上传输出包含 `上传结束`。排查时查看控制台中的上传状态和脚本日志，并手工运行：

```bat
baiducmd meta "/resources/upload_temp/文件名"
```

如果同内容文件被客户端正常跳过，只要远端目标存在且字节数与本地一致，Windows 就会把最终状态视为成功。Linux 仍要求客户端输出 `上传结束`。

### Windows 上传或下载期间没有进度，结束后才显示

旧实现把客户端输出重定向到临时文件，命令结束后再回放，因此动态进度被缓冲；重定向输出与 CMD 代码页不一致时还会出现乱码。当前版本的 Windows 上传和下载都不再捕获客户端输出，而是让 `baiducmd` 直接连接控制台持续刷新；上传通过远端目标和精确字节数校验，下载通过隔离暂存目录和精确字节数校验。

正常下载期间会先看到：

```text
[信息] 以下为 baiducmd 实时上传状态。
[信息] 以下为 baiducmd 实时下载状态。
```

随后客户端进度会持续显示。执行结束后，`.baiduud_download_*` 暂存目录会自动清理；如果意外中断遗留该目录，可以在确认没有脚本运行后手工删除。

### 删除路径被拒绝

`del` 和 `u -del` 只接受类似 `/resources/upload_temp` 的非根绝对路径。`/`、`////`、`resources/upload_temp`、`/resources/*`、`/resources//temp`、`/resources/../temp` 都会在调用客户端前被拒绝。普通 `u` 不执行删除，不受此删除路径规则影响。

### Windows 文件名包含百分号

Windows CMD 版本会在上传枚举和下载列表解析前检查名称。名称含 `%` 时会中文报错并退出，请先重命名；这是为了避免 CMD 的 `call` 二次变量展开把文件名改写成环境变量内容。以 `;` 开头的文件已经支持，不会再被 `for /f` 当作注释跳过。

### Windows 中文乱码

`baiduud.cmd` 必须保存为 GBK（简体中文代码页 936）和 CRLF 换行；不要保存为 UTF-8、UTF-16 或 LF 换行。

脚本开头会把当前 CMD 会话切换到简体中文代码页 936。脚本文件与 CMD 使用相同编码，可以避免中文被拆成命令并产生英文的“无法识别命令”系统错误。Windows 上传和下载都让 `baiducmd` 直接连接控制台，不再重定向后用 `type` 回放。退出时不再切换代码页，因此帮助内容会保留在窗口中。

### Linux 提示权限不足

`baiduud.sh` 必须保存为 UTF-8 无 BOM 编码和 LF 换行，避免脚本首行或命令参数中出现不可见字符。

```bash
chmod +x docs/baiduud.sh
bash docs/baiduud.sh help
```

## 十三、维护与验证

修改脚本后至少运行：

```bat
docs\baiduud.cmd help
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File tests\baiduud-regression.ps1
```

```bash
bash -n docs/baiduud.sh
docs/baiduud.sh help
bash tests/baiduud-regression.sh
```

本文档附录中的源码应与实际脚本保持一致。上方 SHA-256 用于判断脚本是否已经变化。

## 附录 A：Windows 完整脚本

```bat
@echo off
setlocal DisableDelayedExpansion

rem 使用简体中文代码页 936，保证传统 cmd.exe 正确解析中文。
rem 文件本身必须保存为 GBK 编码和 CRLF 换行。
chcp 936 >nul

rem ============================================================
rem 路径配置
rem 注意：本地路径末尾不要添加反斜杠，网盘路径末尾不要添加斜杠。
rem ============================================================
set "LOCAL_UPLOAD=D:\conf\mhloctest\upload"
set "BAIDU_UPLOAD=/resources/upload_temp"
set "LOCAL_DOWNLOAD=D:\conf\mhloctest\download"
set "BAIDU_DOWNLOAD=/resources/upload_temp"

rem 日志文件保存在本脚本所在目录，每次运行采用追加方式写入。
set "LOG_FILE=%~dp0baiduud.log"

rem 参数解析状态。命令行参数只覆盖本次运行，不修改上方默认配置。
set "ACTION="
set "USED_LU="
set "USED_BU="
set "USED_LD="
set "USED_BD="
set "DELETE_BEFORE_UPLOAD="
set "ARG_ERROR="
set "NEXT_VALUE="

call :log 信息 "脚本启动，接收到的参数：%*"

rem ============================================================
rem 参数检查
rem 第一个参数必须是 u、d、del、list 或 help，后续参数按操作进行校验。
rem ============================================================
if "%~1"=="" (
    set "ARG_ERROR=未指定操作，请使用 u、d、del、list 或 help。"
    goto :argument_error
)

if /i "%~1"=="help" (
    if not "%~2"=="" (
        set "ARG_ERROR=help 后面不能再添加其他参数。"
        goto :argument_error
    )
    call :log 信息 "显示帮助信息。"
    call :print_help
    goto :succeeded
)

if /i "%~1"=="-h" goto :help_alias
if /i "%~1"=="--help" goto :help_alias

set "ACTION=%~1"
if /i not "%ACTION%"=="u" if /i not "%ACTION%"=="d" if /i not "%ACTION%"=="del" if /i not "%ACTION%"=="list" (
    set "ARG_ERROR=未知操作：%ACTION%。请使用 u、d、del、list 或 help。"
    goto :argument_error
)

shift
goto :parse_arguments

:help_alias
if not "%~2"=="" (
    set "ARG_ERROR=帮助参数后面不能再添加其他参数。"
    goto :argument_error
)
call :log 信息 "显示帮助信息。"
call :print_help
goto :succeeded

:parse_arguments
if "%~1"=="" goto :arguments_parsed
if /i "%~1"=="-lu" goto :parse_lu
if /i "%~1"=="-bu" goto :parse_bu
if /i "%~1"=="-ld" goto :parse_ld
if /i "%~1"=="-bd" goto :parse_bd
if /i "%~1"=="-del" goto :parse_delete_flag
set "ARG_ERROR=未知参数：%~1。"
goto :argument_error

:parse_lu
if "%~2"=="" (
    set "ARG_ERROR=参数 -lu 缺少本地上传目录。"
    goto :argument_error
)
set "NEXT_VALUE=%~2"
if "%NEXT_VALUE:~0,1%"=="-" (
    set "ARG_ERROR=参数 -lu 缺少目录值，不能使用参数名作为目录。"
    goto :argument_error
)
set "LOCAL_UPLOAD=%NEXT_VALUE%"
set "USED_LU=1"
shift
shift
goto :parse_arguments

:parse_bu
if "%~2"=="" (
    set "ARG_ERROR=参数 -bu 缺少网盘上传目录。"
    goto :argument_error
)
set "NEXT_VALUE=%~2"
if "%NEXT_VALUE:~0,1%"=="-" (
    set "ARG_ERROR=参数 -bu 缺少目录值，不能使用参数名作为目录。"
    goto :argument_error
)
set "BAIDU_UPLOAD=%NEXT_VALUE%"
set "USED_BU=1"
shift
shift
goto :parse_arguments

:parse_ld
if "%~2"=="" (
    set "ARG_ERROR=参数 -ld 缺少本地下载目录。"
    goto :argument_error
)
set "NEXT_VALUE=%~2"
if "%NEXT_VALUE:~0,1%"=="-" (
    set "ARG_ERROR=参数 -ld 缺少目录值，不能使用参数名作为目录。"
    goto :argument_error
)
set "LOCAL_DOWNLOAD=%NEXT_VALUE%"
set "USED_LD=1"
shift
shift
goto :parse_arguments

:parse_bd
if "%~2"=="" (
    set "ARG_ERROR=参数 -bd 缺少网盘下载目录。"
    goto :argument_error
)
set "NEXT_VALUE=%~2"
if "%NEXT_VALUE:~0,1%"=="-" (
    set "ARG_ERROR=参数 -bd 缺少目录值，不能使用参数名作为目录。"
    goto :argument_error
)
set "BAIDU_DOWNLOAD=%NEXT_VALUE%"
set "USED_BD=1"
shift
shift
goto :parse_arguments

:parse_delete_flag
set "DELETE_BEFORE_UPLOAD=1"
shift
goto :parse_arguments

:arguments_parsed
if /i "%ACTION%"=="u" goto :validate_upload_arguments
if /i "%ACTION%"=="d" goto :validate_download_arguments
if /i "%ACTION%"=="list" goto :validate_list_arguments
goto :validate_delete_arguments

:validate_upload_arguments
if defined USED_LD (
    set "ARG_ERROR=参数 -ld 仅适用于下载操作 d。"
    goto :argument_error
)
if defined USED_BD (
    set "ARG_ERROR=参数 -bd 仅适用于下载操作 d。"
    goto :argument_error
)
goto :check_baiducmd

:validate_list_arguments
if defined USED_LU goto :list_argument_error
if defined USED_LD goto :list_argument_error
if defined USED_BD goto :list_argument_error
if defined DELETE_BEFORE_UPLOAD goto :list_argument_error
goto :check_baiducmd

:list_argument_error
set "ARG_ERROR=列表操作 list 只能使用 -bu。"
goto :argument_error

:validate_download_arguments
if defined USED_LU (
    set "ARG_ERROR=参数 -lu 仅适用于上传操作 u。"
    goto :argument_error
)
if defined USED_BU (
    set "ARG_ERROR=参数 -bu 仅适用于上传操作 u。"
    goto :argument_error
)
if defined DELETE_BEFORE_UPLOAD (
    set "ARG_ERROR=参数 -del 仅适用于上传操作 u。"
    goto :argument_error
)
goto :check_baiducmd

:validate_delete_arguments
if defined USED_LU (
    set "ARG_ERROR=删除操作 del 只能使用 -bu。"
    goto :argument_error
)
if defined USED_LD (
    set "ARG_ERROR=删除操作 del 只能使用 -bu。"
    goto :argument_error
)
if defined USED_BD (
    set "ARG_ERROR=删除操作 del 只能使用 -bu。"
    goto :argument_error
)
if defined DELETE_BEFORE_UPLOAD (
    set "ARG_ERROR=删除操作 del 不需要再使用 -del。"
    goto :argument_error
)

:check_baiducmd
where baiducmd >nul 2>&1
if errorlevel 1 (
    call :log 错误 "未找到 baiducmd 命令，请检查安装目录和系统环境变量。"
    goto :failed
)

if /i "%ACTION%"=="u" goto :upload
if /i "%ACTION%"=="d" goto :download
if /i "%ACTION%"=="list" goto :list
goto :delete

rem ============================================================
rem 上传流程
rem 1. 创建并检查本地、网盘上传目录。
rem 2. 仅在指定 -del 时清空网盘目录。
rem 3. 采用 overwrite 策略追加上传所有顶层项目。
rem 4. 逐项验证上传后的网盘目标是否存在。
rem ============================================================
:upload
call :log 信息 "进入上传流程。"
call :log 信息 "本地上传目录：%LOCAL_UPLOAD%"
call :log 信息 "网盘上传目录：%BAIDU_UPLOAD%"

rem 只有 -del 会执行远端删除，因此在任何 baiducmd 调用前先校验删除路径。
if defined DELETE_BEFORE_UPLOAD call :prepare_upload_delete_path
if errorlevel 1 goto :failed

call :ensure_local_dir "%LOCAL_UPLOAD%"
if errorlevel 1 (
    call :log 错误 "无法创建本地上传目录：%LOCAL_UPLOAD%"
    goto :failed
)

call :ensure_remote_dir "%BAIDU_UPLOAD%"
if errorlevel 1 (
    call :log 错误 "无法创建或读取网盘上传目录：%BAIDU_UPLOAD%"
    goto :failed
)

if defined DELETE_BEFORE_UPLOAD (
    call :log 警告 "已指定 -del，上传前将清空网盘上传目录。"
    call :clear_remote_contents "%BAIDU_UPLOAD%" "no"
    if errorlevel 1 goto :failed
) else (
    call :log 信息 "未指定 -del，本次采用追加上传，不删除网盘已有内容。"
)

rem 统计本地上传目录中的顶层项目数量。
set "LOCAL_COUNT=0"
for /f %%C in ('dir /b /a "%LOCAL_UPLOAD%" 2^>nul ^| find /c /v ""') do set "LOCAL_COUNT=%%C"
if "%LOCAL_COUNT%"=="0" (
    call :log 警告 "本地上传目录为空，没有需要上传的内容：%LOCAL_UPLOAD%"
    goto :succeeded
)

rem CMD 的 call 会对百分号执行二次变量展开，必须在进入上传循环前明确拒绝。
dir /b /a "%LOCAL_UPLOAD%" 2>nul | findstr /L /C:"%%" >nul 2>&1
if not errorlevel 1 (
    call :log 错误 "Windows CMD 版本不支持名称中包含百分号（%%）的文件或文件夹，请先重命名。"
    goto :failed
)

call :log 信息 "网盘上传目录已就绪，已有内容将被保留。"
call :log 信息 "待上传的顶层项目数量：%LOCAL_COUNT%"

pushd "%LOCAL_UPLOAD%" >nul
if errorlevel 1 (
    call :log 错误 "无法进入本地上传目录：%LOCAL_UPLOAD%"
    goto :failed
)

rem 逐项上传可以避免在网盘目录中额外生成一层 upload 文件夹。
set "UPLOAD_FAILED="
for /f "eol=: delims=" %%I in ('dir /b /a') do (
    if not defined UPLOAD_FAILED call :upload_one_item "%%I"
)
popd

if defined UPLOAD_FAILED (
    call :log 错误 "上传过程中发生错误，已停止后续项目。"
    goto :failed
)

call :log 信息 "上传命令执行完毕，开始校验网盘目录。"
call :list_remote "%BAIDU_UPLOAD%"
if errorlevel 1 (
    call :log 错误 "上传后无法读取网盘上传目录。"
    goto :failed
)

set "REMOTE_COUNT=0"
for /f %%C in ('findstr /R /C:"^[ ][ ]*[0-9][0-9]*[ ]" "%REMOTE_LIST_FILE%" ^| find /c /v ""') do set "REMOTE_COUNT=%%C"
call :log 信息 "上传完成，已验证 %LOCAL_COUNT% 个本地顶层项目；网盘目录当前共有 %REMOTE_COUNT% 个顶层项目。"
goto :succeeded

rem 上传单个项目：直接连接控制台实时显示状态；普通文件还要比较本地与远端精确字节数。
:upload_one_item
echo.
call :log 信息 "正在上传：%~1"
set "REMOTE_META_FILE="
rem 必须直接连接控制台，baiducmd 才能持续刷新上传进度并按控制台编码输出中文。
call :log 信息 "以下为 baiducmd 实时上传状态。"
baiducmd upload --policy overwrite "%~1" "%BAIDU_UPLOAD%"
set "UPLOAD_COMMAND_ERROR=%ERRORLEVEL%"
if not "%UPLOAD_COMMAND_ERROR%"=="0" goto :upload_command_failed

set "REMOTE_META_FILE=%TEMP%\baiduud_meta_%RANDOM%_%RANDOM%.tmp"
baiducmd meta "%BAIDU_UPLOAD%/%~1" >"%REMOTE_META_FILE%" 2>&1
findstr /C:"----" "%REMOTE_META_FILE%" >nul 2>&1
if errorlevel 1 goto :upload_meta_failed

if exist "%~1\" goto :upload_item_verified

set "LOCAL_FILE_SIZE="
set "REMOTE_FILE_SIZE="
for %%F in ("%~1") do set "LOCAL_FILE_SIZE=%%~zF"
for /f "tokens=2 delims=, " %%S in ('findstr /R /C:"[0-9][0-9]*," "%REMOTE_META_FILE%"') do set "REMOTE_FILE_SIZE=%%S"
if not defined LOCAL_FILE_SIZE goto :upload_size_failed
if not defined REMOTE_FILE_SIZE goto :upload_size_failed
if not "%LOCAL_FILE_SIZE%"=="%REMOTE_FILE_SIZE%" goto :upload_size_failed

:upload_item_verified
del /q "%REMOTE_META_FILE%" >nul 2>&1
set "REMOTE_META_FILE="
call :log 信息 "上传目标验证成功：%BAIDU_UPLOAD%/%~1"
exit /b 0

:upload_command_failed
call :log 错误 "上传命令返回失败状态：%~1"
goto :upload_item_failed

:upload_meta_failed
type "%REMOTE_META_FILE%"
type "%REMOTE_META_FILE%" >>"%LOG_FILE%"
call :log 错误 "上传校验失败，无法读取网盘目标：%BAIDU_UPLOAD%/%~1"
goto :upload_item_failed

:upload_size_failed
type "%REMOTE_META_FILE%"
type "%REMOTE_META_FILE%" >>"%LOG_FILE%"
call :log 错误 "上传校验失败，本地与网盘文件字节数不一致：%~1"

:upload_item_failed
if defined REMOTE_META_FILE del /q "%REMOTE_META_FILE%" >nul 2>&1
set "REMOTE_META_FILE="
set "UPLOAD_FAILED=1"
exit /b 1

rem ============================================================
rem 下载流程
rem 1. 创建并检查本地、网盘下载目录。
rem 2. 将网盘项目显示为从 1 开始的中文表格。
rem 3. 等待用户选择一个、多个或全部项目。
rem 4. 下载选中内容，并覆盖本地同名文件。
rem ============================================================
:download
call :log 信息 "进入下载流程。"
call :log 信息 "网盘下载目录：%BAIDU_DOWNLOAD%"
call :log 信息 "本地下载目录：%LOCAL_DOWNLOAD%"

call :ensure_local_dir "%LOCAL_DOWNLOAD%"
if errorlevel 1 (
    call :log 错误 "无法创建本地下载目录：%LOCAL_DOWNLOAD%"
    goto :failed
)

call :ensure_remote_dir "%BAIDU_DOWNLOAD%"
if errorlevel 1 (
    call :log 错误 "无法创建或读取网盘下载目录：%BAIDU_DOWNLOAD%"
    goto :failed
)

call :load_remote_items
if errorlevel 1 goto :failed
if "%REMOTE_ITEM_COUNT%"=="0" (
    call :log 警告 "网盘下载目录为空，没有需要下载的内容。"
    goto :succeeded
)

call :print_remote_table
call :prompt_download_selection
if errorlevel 1 (
    call :log 错误 "无法获得有效的下载选择。"
    goto :failed
)

call :download_selected_items
if errorlevel 1 goto :failed

call :log 信息 "已完成所选项目的下载。"
goto :succeeded

rem ============================================================
rem 只读列表流程
rem 使用网盘上传目录，并复用下载流程的解析与五列表格输出。
rem ============================================================
:list
call :log 信息 "进入网盘列表查询流程。"
call :log 信息 "网盘查询目录：%BAIDU_UPLOAD%"

call :ensure_remote_dir "%BAIDU_UPLOAD%"
if errorlevel 1 (
    call :log 错误 "无法创建或读取网盘查询目录：%BAIDU_UPLOAD%"
    goto :failed
)

call :load_remote_items
if errorlevel 1 goto :failed
if "%REMOTE_ITEM_COUNT%"=="0" (
    call :log 警告 "网盘查询目录为空：%BAIDU_UPLOAD%"
    goto :succeeded
)

call :print_remote_table
call :log 信息 "网盘列表查询完成，共显示 %REMOTE_ITEM_COUNT% 个顶层项目。"
goto :succeeded

rem ============================================================
rem 独立删除流程
rem 删除上传目录中的全部内容，但保留目录本身。
rem ============================================================
:delete
call :log 信息 "进入独立删除流程。"
call :log 警告 "准备清空网盘目录：%BAIDU_UPLOAD%"

call :validate_delete_remote_path "%BAIDU_UPLOAD%"
if errorlevel 1 goto :failed
set "BAIDU_UPLOAD=%VALIDATED_DELETE_PATH%"

call :ensure_remote_dir "%BAIDU_UPLOAD%"
if errorlevel 1 (
    call :log 错误 "无法创建或读取网盘目录：%BAIDU_UPLOAD%"
    goto :failed
)

call :clear_remote_contents "%BAIDU_UPLOAD%" "yes"
if errorlevel 1 goto :failed
goto :succeeded

rem ============================================================
rem 目录创建与检查子程序
rem ============================================================
:ensure_local_dir
if exist "%~1\" (
    call :log 信息 "本地目录已存在：%~1"
    exit /b 0
)

call :log 信息 "本地目录不存在，开始创建：%~1"
mkdir "%~1" >nul 2>&1
if not exist "%~1\" (
    call :log 错误 "本地目录创建失败：%~1"
    exit /b 1
)
call :log 信息 "本地目录创建成功：%~1"
exit /b 0

:ensure_remote_dir
call :log 信息 "检查或创建网盘目录：%~1"

rem baiducmd 即使 API 操作失败也可能返回退出码 0，不能只检查 ERRORLEVEL。
rem mkdir 后必须调用 ls -l，确认目标目录可以正常读取。
baiducmd mkdir "%~1" >nul 2>&1
call :list_remote "%~1"
if errorlevel 1 (
    call :log 错误 "网盘目录创建或验证失败：%~1"
    exit /b 1
)
call :log 信息 "网盘目录可以正常访问：%~1"
exit /b 0

rem 删除路径必须是非根绝对路径，且不能包含通配符、重复斜杠或跳级路径段。
:validate_delete_remote_path
set "VALIDATED_DELETE_PATH=%~1"
if not defined VALIDATED_DELETE_PATH goto :invalid_delete_remote_path
if not "%VALIDATED_DELETE_PATH:~0,1%"=="/" goto :invalid_delete_remote_path
set VALIDATED_DELETE_PATH | findstr /L /C:"*" /C:"?" /C:"//" >nul 2>&1
if not errorlevel 1 goto :invalid_delete_remote_path
if not "%VALIDATED_DELETE_PATH:/./=%"=="%VALIDATED_DELETE_PATH%" goto :invalid_delete_remote_path
if not "%VALIDATED_DELETE_PATH:/../=%"=="%VALIDATED_DELETE_PATH%" goto :invalid_delete_remote_path
if "%VALIDATED_DELETE_PATH:~-2%"=="/." goto :invalid_delete_remote_path
if "%VALIDATED_DELETE_PATH:~-3%"=="/.." goto :invalid_delete_remote_path

:trim_delete_remote_path
if "%VALIDATED_DELETE_PATH%"=="/" goto :invalid_delete_remote_path
if not "%VALIDATED_DELETE_PATH:~-1%"=="/" exit /b 0
set "VALIDATED_DELETE_PATH=%VALIDATED_DELETE_PATH:~0,-1%"
goto :trim_delete_remote_path

:invalid_delete_remote_path
call :log 错误 "拒绝清空网盘目录：必须使用非根绝对路径，且不能包含 *、?、//、. 或 .. 路径段。"
exit /b 1

:prepare_upload_delete_path
call :validate_delete_remote_path "%BAIDU_UPLOAD%"
if errorlevel 1 exit /b 1
set "BAIDU_UPLOAD=%VALIDATED_DELETE_PATH%"
exit /b 0

rem 将网盘目录列表写入临时文件，供空目录判断和数量校验使用。
:list_remote
if defined REMOTE_LIST_FILE del /q "%REMOTE_LIST_FILE%" >nul 2>&1
set "REMOTE_LIST_FILE=%TEMP%\baiduud_%RANDOM%_%RANDOM%.tmp"
baiducmd ls -l "%~1" >"%REMOTE_LIST_FILE%" 2>&1

rem 成功的 ls 输出包含由连字符组成的分隔线；错误输出没有该分隔线。
findstr /C:"----" "%REMOTE_LIST_FILE%" >nul 2>&1
if errorlevel 1 (
    call :log 错误 "无法读取网盘目录：%~1"
    type "%REMOTE_LIST_FILE%"
    type "%REMOTE_LIST_FILE%" >>"%LOG_FILE%"
    exit /b 1
)
exit /b 0

rem 清空网盘目录内容但保留目录。第二个参数为 yes 时要求输入 y 确认。
:clear_remote_contents
call :validate_delete_remote_path "%~1"
if errorlevel 1 exit /b 1
set "CLEAR_REMOTE_PATH=%VALIDATED_DELETE_PATH%"
set "CLEAR_REQUIRE_CONFIRM=%~2"

call :list_remote "%CLEAR_REMOTE_PATH%"
if errorlevel 1 exit /b 1

findstr /R /C:"^[ ][ ]*[0-9][0-9]*[ ]" "%REMOTE_LIST_FILE%" >nul 2>&1
if errorlevel 1 (
    call :log 信息 "网盘目录已经为空，无需删除：%CLEAR_REMOTE_PATH%"
    exit /b 0
)

if /i "%CLEAR_REQUIRE_CONFIRM%"=="yes" goto :confirm_remote_cleanup
goto :execute_remote_cleanup

:confirm_remote_cleanup
echo.
echo 即将清空网盘目录中的全部内容，但保留目录本身：
echo   %CLEAR_REMOTE_PATH%
set "DELETE_CONFIRMATION="
set /p "DELETE_CONFIRMATION=请输入 y 确认，输入其他内容取消："
if /i "%DELETE_CONFIRMATION%"=="y" goto :execute_remote_cleanup
call :log 信息 "用户取消删除，网盘数据未发生变化。"
exit /b 0

:execute_remote_cleanup
call :log 警告 "开始清空网盘目录：%CLEAR_REMOTE_PATH%"
baiducmd rm "%CLEAR_REMOTE_PATH%/*"
call :log 信息 "删除命令已执行，正在复查网盘目录。"

call :list_remote "%CLEAR_REMOTE_PATH%"
if errorlevel 1 exit /b 1

findstr /R /C:"^[ ][ ]*[0-9][0-9]*[ ]" "%REMOTE_LIST_FILE%" >nul 2>&1
if not errorlevel 1 (
    type "%REMOTE_LIST_FILE%"
    type "%REMOTE_LIST_FILE%" >>"%LOG_FILE%"
    call :log 错误 "网盘目录仍然非空，删除校验失败。"
    exit /b 1
)

call :log 信息 "网盘目录内容已清空，目录本身已保留：%CLEAR_REMOTE_PATH%"
exit /b 0

rem 解析 ls -l 项目行，建立从 1 开始的下载项目数组。
:load_remote_items
set "REMOTE_ITEM_COUNT=0"
findstr /L /C:"%%" "%REMOTE_LIST_FILE%" >nul 2>&1
if not errorlevel 1 (
    call :log 错误 "Windows CMD 版本不支持下载名称中包含百分号（%%）的网盘项目，请先在网盘中重命名。"
    exit /b 1
)
for /f "tokens=1-8,*" %%A in ('findstr /R /C:"^[ ][ ]*[0-9][0-9]*[ ]" "%REMOTE_LIST_FILE%"') do call :store_remote_item "%%D" "%%G %%H" "%%I"
exit /b 0

:store_remote_item
set "ITEM_SIZE=%~1"
set "ITEM_MODIFIED=%~2"
set "ITEM_TAIL=%~3"
if "%ITEM_SIZE%"=="-" goto :store_remote_directory

for /f "tokens=1,*" %%A in ("%ITEM_TAIL%") do set "ITEM_NAME=%%B"
call :trim_item_name
set "ITEM_TYPE=文件"
goto :store_remote_values

:store_remote_directory
set "ITEM_NAME=%ITEM_TAIL%"
call :trim_item_name
if "%ITEM_NAME:~-1%"=="/" set "ITEM_NAME=%ITEM_NAME:~0,-1%"
set "ITEM_TYPE=文件夹"

:store_remote_values
if not defined ITEM_NAME exit /b 0
set /a REMOTE_ITEM_COUNT+=1
set "REMOTE_NAME_%REMOTE_ITEM_COUNT%=%ITEM_NAME%"
set "REMOTE_TYPE_%REMOTE_ITEM_COUNT%=%ITEM_TYPE%"
set "REMOTE_SIZE_%REMOTE_ITEM_COUNT%=%ITEM_SIZE%"
set "REMOTE_MODIFIED_%REMOTE_ITEM_COUNT%=%ITEM_MODIFIED%"
exit /b 0

rem baiducmd ls -l 会在名称右侧补空格用于列对齐，拼接远端路径前必须移除。
:trim_item_name
if not defined ITEM_NAME exit /b 0
if not "%ITEM_NAME:~-1%"==" " exit /b 0
set "ITEM_NAME=%ITEM_NAME:~0,-1%"
goto :trim_item_name

:print_remote_table
echo.
echo ^| 序号 ^| 名称 ^| 类型 ^| 大小 ^| 修改日期 ^|
echo ^| ------------ ^| ------------ ^| ------------ ^| ------------ ^| ------------ ^|
for /l %%N in (1,1,%REMOTE_ITEM_COUNT%) do call :print_remote_row %%N
echo.
exit /b 0

:print_remote_row
call set "DISPLAY_NAME=%%REMOTE_NAME_%~1%%"
call set "DISPLAY_TYPE=%%REMOTE_TYPE_%~1%%"
call set "DISPLAY_SIZE=%%REMOTE_SIZE_%~1%%"
call set "DISPLAY_MODIFIED=%%REMOTE_MODIFIED_%~1%%"
echo ^| %~1 ^| %DISPLAY_NAME% ^| %DISPLAY_TYPE% ^| %DISPLAY_SIZE% ^| %DISPLAY_MODIFIED% ^|
exit /b 0

:prompt_download_selection
for /l %%N in (1,1,%REMOTE_ITEM_COUNT%) do set "SELECTED_%%N="

:download_selection_retry
set "DOWNLOAD_SELECTION="
set "SELECTION_ERROR="
set "SELECTED_COUNT=0"
set /p "DOWNLOAD_SELECTION=请输入下载序号（例如 1 或 1,2），输入 a 下载全部："
if errorlevel 1 goto :download_selection_input_closed
if not defined DOWNLOAD_SELECTION goto :download_selection_invalid
if /i "%DOWNLOAD_SELECTION%"=="a" goto :select_all_download_items

rem 只允许数字、英文逗号和空格，避免无效内容进入后续解析。
set DOWNLOAD_SELECTION | findstr /R /X /C:"DOWNLOAD_SELECTION=[0-9][0-9, ]*" >nul 2>&1
if errorlevel 1 goto :download_selection_invalid

set "NORMALIZED_SELECTION=%DOWNLOAD_SELECTION:,= %"
for %%N in (%NORMALIZED_SELECTION%) do call :select_download_index "%%N"
if defined SELECTION_ERROR goto :download_selection_invalid
if "%SELECTED_COUNT%"=="0" goto :download_selection_invalid
call :log 信息 "已选择 %SELECTED_COUNT% 个下载项目。"
exit /b 0

:select_all_download_items
for /l %%N in (1,1,%REMOTE_ITEM_COUNT%) do set "SELECTED_%%N=1"
set "SELECTED_COUNT=%REMOTE_ITEM_COUNT%"
call :log 信息 "已选择全部 %SELECTED_COUNT% 个下载项目。"
exit /b 0

:select_download_index
set "INDEX_TOKEN=%~1"
if "%INDEX_TOKEN:~0,1%"=="0" goto :select_download_index_invalid
if not "%INDEX_TOKEN:~9,1%"=="" goto :select_download_index_invalid
if %INDEX_TOKEN% GTR %REMOTE_ITEM_COUNT% goto :select_download_index_invalid
if defined SELECTED_%INDEX_TOKEN% exit /b 0
set "SELECTED_%INDEX_TOKEN%=1"
set /a SELECTED_COUNT+=1
exit /b 0

:select_download_index_invalid
set "SELECTION_ERROR=1"
exit /b 1

:download_selection_invalid
call :log 警告 "下载选择无效，请输入 1 到 %REMOTE_ITEM_COUNT% 的序号、逗号分隔序号或 a。"
goto :download_selection_retry

:download_selection_input_closed
call :log 错误 "无法读取下载选择，已取消下载。"
exit /b 1

:download_selected_items
set "DOWNLOAD_FAILED="
call :log 信息 "开始下载所选项目，已启用同名文件覆盖选项。"
for /l %%N in (1,1,%REMOTE_ITEM_COUNT%) do call :download_selected_item %%N
if defined DOWNLOAD_FAILED exit /b 1
exit /b 0

:download_selected_item
if not defined SELECTED_%~1 exit /b 0
call set "ITEM_NAME=%%REMOTE_NAME_%~1%%"
call set "ITEM_TYPE=%%REMOTE_TYPE_%~1%%"
call set "ITEM_SIZE=%%REMOTE_SIZE_%~1%%"
echo.
call :log 信息 "正在下载：%ITEM_NAME%"
set "DOWNLOAD_STAGE_DIR=%LOCAL_DOWNLOAD%\.baiduud_download_%RANDOM%_%RANDOM%"
mkdir "%DOWNLOAD_STAGE_DIR%" >nul 2>&1
if not exist "%DOWNLOAD_STAGE_DIR%\" goto :download_stage_failed

rem 必须直接连接控制台，baiducmd 才能实时显示进度并按控制台编码输出中文。
rem 下载先写入本次新建的暂存目录，避免正式目录中的旧文件掩盖下载失败。
call :log 信息 "以下为 baiducmd 实时下载状态。"
baiducmd download --ow --saveto "%DOWNLOAD_STAGE_DIR%" "%BAIDU_DOWNLOAD%/%ITEM_NAME%"
set "DOWNLOAD_COMMAND_ERROR=%ERRORLEVEL%"
if not "%DOWNLOAD_COMMAND_ERROR%"=="0" goto :download_command_failed

if /i "%ITEM_TYPE%"=="文件夹" goto :verify_staged_directory

if not exist "%DOWNLOAD_STAGE_DIR%\%ITEM_NAME%" goto :download_verification_failed
set "DOWNLOADED_FILE_SIZE=0"
for %%F in ("%DOWNLOAD_STAGE_DIR%\%ITEM_NAME%") do set "DOWNLOADED_FILE_SIZE=%%~zF"
call :get_remote_exact_file_size "%BAIDU_DOWNLOAD%/%ITEM_NAME%"
if errorlevel 1 goto :download_verification_failed
if not "%DOWNLOADED_FILE_SIZE%"=="%REMOTE_EXACT_FILE_SIZE%" goto :download_verification_failed

move /Y "%DOWNLOAD_STAGE_DIR%\%ITEM_NAME%" "%LOCAL_DOWNLOAD%\%ITEM_NAME%" >nul 2>&1
if errorlevel 1 goto :download_transfer_failed
goto :download_item_verified

:verify_staged_directory
if not exist "%DOWNLOAD_STAGE_DIR%\%ITEM_NAME%\" goto :download_verification_failed
if not exist "%LOCAL_DOWNLOAD%\%ITEM_NAME%\" mkdir "%LOCAL_DOWNLOAD%\%ITEM_NAME%" >nul 2>&1
if not exist "%LOCAL_DOWNLOAD%\%ITEM_NAME%\" goto :download_transfer_failed
robocopy "%DOWNLOAD_STAGE_DIR%\%ITEM_NAME%" "%LOCAL_DOWNLOAD%\%ITEM_NAME%" /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /NFL /NDL /NJH /NJS /NP >nul 2>&1
if errorlevel 8 goto :download_transfer_failed
goto :download_item_verified

:download_command_failed
call :cleanup_download_stage
set "DOWNLOAD_FAILED=1"
call :log 错误 "下载命令返回失败状态：%ITEM_NAME%"
exit /b 1

:download_stage_failed
set "FAILED_DOWNLOAD_STAGE_DIR=%DOWNLOAD_STAGE_DIR%"
call :cleanup_download_stage
set "DOWNLOAD_FAILED=1"
call :log 错误 "无法创建下载暂存目录：%FAILED_DOWNLOAD_STAGE_DIR%"
set "FAILED_DOWNLOAD_STAGE_DIR="
exit /b 1

:download_verification_failed
call :cleanup_download_stage
set "DOWNLOAD_FAILED=1"
call :log 错误 "下载校验失败，本地未生成有效内容：%LOCAL_DOWNLOAD%\%ITEM_NAME%"
exit /b 1

:download_transfer_failed
call :cleanup_download_stage
set "DOWNLOAD_FAILED=1"
call :log 错误 "下载内容写入正式目录失败：%LOCAL_DOWNLOAD%\%ITEM_NAME%"
exit /b 1

:download_item_verified
call :cleanup_download_stage
call :log 信息 "下载完成并已写入正式目录：%LOCAL_DOWNLOAD%\%ITEM_NAME%"
exit /b 0

rem meta 重定向文件可能是 UTF-8；只匹配 ASCII 数字和逗号，避免再次发生中文乱码。
:get_remote_exact_file_size
set "REMOTE_EXACT_FILE_SIZE="
set "DOWNLOAD_META_FILE=%TEMP%\baiduud_download_meta_%RANDOM%_%RANDOM%.tmp"
baiducmd meta "%~1" >"%DOWNLOAD_META_FILE%" 2>&1
for /f "tokens=2 delims=, " %%S in ('findstr /R /C:"[0-9][0-9]*," "%DOWNLOAD_META_FILE%"') do set "REMOTE_EXACT_FILE_SIZE=%%S"
del /q "%DOWNLOAD_META_FILE%" >nul 2>&1
set "DOWNLOAD_META_FILE="
if not defined REMOTE_EXACT_FILE_SIZE exit /b 1
exit /b 0

:cleanup_download_stage
if defined DOWNLOAD_STAGE_DIR if exist "%DOWNLOAD_STAGE_DIR%\" rmdir /s /q "%DOWNLOAD_STAGE_DIR%" >nul 2>&1
set "DOWNLOAD_STAGE_DIR="
exit /b 0

rem 输出日志到控制台，并追加写入 baiduud.log。
:log
set "LOG_TIMESTAMP=%date% %time:~0,8%"
set "LOG_LINE=[%LOG_TIMESTAMP%] [%~1] %~2"
echo(%LOG_LINE%
>>"%LOG_FILE%" echo(%LOG_LINE%
set "LOG_TIMESTAMP="
set "LOG_LINE="
exit /b 0

:print_help
echo.
echo 百度网盘自动上传下载脚本
echo.
echo 用法：
echo   baiduud help
echo   baiduud u [-lu 本地上传目录] [-bu 网盘上传目录] [-del]
echo   baiduud d [-ld 本地下载目录] [-bd 网盘下载目录]
echo   baiduud del [-bu 网盘上传目录]
echo   baiduud list [-bu 网盘上传目录]
echo.
echo 操作：
echo   help  显示本帮助信息，不执行上传、下载或删除。
echo   u     追加上传本地目录中的内容，同名文件覆盖。
echo   d     列出网盘目录，选择序号后下载。
echo   del   清空网盘上传目录中的内容，但保留目录本身。
echo   list  只显示网盘上传目录列表，不执行下载或删除。
echo.
echo 目录参数：
echo   -lu   指定本地上传目录，仅适用于 u。
echo         默认值：%LOCAL_UPLOAD%
echo   -bu   指定百度网盘上传目录，适用于 u、del 和 list。
echo         默认值：%BAIDU_UPLOAD%
echo   -ld   指定本地下载目录，仅适用于 d。
echo         默认值：%LOCAL_DOWNLOAD%
echo   -bd   指定百度网盘下载目录，仅适用于 d。
echo         默认值：%BAIDU_DOWNLOAD%
echo   -del  上传前清空网盘上传目录，仅适用于 u，不要求二次确认。
echo.
echo 规则：
echo   1. 操作 u、d、del、list 或 help 必须放在第一个参数。
echo   2. 目录包含空格时必须使用双引号包围。
echo   3. 相对路径以执行命令时的当前目录为基准。
echo   4. 同一目录参数重复出现时，最后一个值生效。
echo   5. u 只能使用 -lu/-bu/-del，d 只能使用 -ld/-bd，list 只能使用 -bu。
echo   6. del 只能使用 -bu，并要求输入 y 确认。
echo   7. 普通上传不会删除网盘内容，只覆盖同名文件。
echo   8. 下载选择支持 1、1,2 或 a；a 表示下载全部。
echo   9. del 和 u -del 拒绝根目录、相对路径、通配符及 . 或 .. 路径段。
echo  10. Windows CMD 版本不支持名称中包含百分号（%%）的项目。
echo.
echo 完整案例：
echo   baiduud help
echo   baiduud u
echo   baiduud d
echo   baiduud del
echo   baiduud list
echo   baiduud u -lu ./ -bu /resources/upload_temp
echo   baiduud u -lu D:\conf\mhloctest\upload -bu /resources/upload_temp
echo   baiduud del -bu /resources/upload_temp
echo   baiduud list -bu /resources/upload_temp
echo   baiduud u -del
echo   baiduud u -lu ./ -bu /resources/upload_temp -del
echo   baiduud u -lu D:\conf\mhloctest\upload -bu /resources/upload_temp -del
echo   baiduud d -ld ./ -bd /resources/upload_temp
echo   baiduud d -ld D:\conf\mhloctest\download -bd /resources/upload_temp
echo   baiduud u -lu "D:\my upload" -bu "/resources/upload temp"
echo.
echo 日志文件：%LOG_FILE%
exit /b 0

:argument_error
call :log 错误 "%ARG_ERROR%"
call :print_help
goto :failed

:succeeded
if defined REMOTE_LIST_FILE del /q "%REMOTE_LIST_FILE%" >nul 2>&1
call :log 信息 "脚本执行完成，退出码：0"
endlocal & exit /b 0

:failed
if defined REMOTE_LIST_FILE del /q "%REMOTE_LIST_FILE%" >nul 2>&1
call :log 错误 "脚本执行失败，退出码：1，请查看上方信息和日志文件。"
endlocal & exit /b 1
```

## 附录 B：Linux 完整脚本

```bash
#!/usr/bin/env bash

# 不启用 set -e：当前版本的 baiducmd 在部分 API 错误时仍可能返回 0，
# 脚本需要结合命令输出和目录复查结果判断操作是否成功。
set -uo pipefail

# ============================================================
# 路径配置
# 可直接修改默认值，也可以在运行时使用同名环境变量覆盖。
# 路径末尾不要添加斜杠。
# ============================================================
LOCAL_UPLOAD="${LOCAL_UPLOAD:-/data/conf/mhloctest/upload}"
BAIDU_UPLOAD="${BAIDU_UPLOAD:-/resources/upload_temp}"
LOCAL_DOWNLOAD="${LOCAL_DOWNLOAD:-/data/conf/mhloctest/download}"
BAIDU_DOWNLOAD="${BAIDU_DOWNLOAD:-/resources/upload_temp}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
LOG_FILE="${LOG_FILE:-${SCRIPT_DIR}/baiduud.log}"
REMOTE_LIST_FILE=""
ACTION=""
USED_LU=0
USED_BU=0
USED_LD=0
USED_BD=0
DELETE_BEFORE_UPLOAD=0
ARG_ERROR=""
REMOTE_NAMES=()
REMOTE_TYPES=()
REMOTE_SIZES=()
REMOTE_MODIFIED=()
SELECTED_INDEXES=()

# 输出日志到控制台，并追加写入 baiduud.log。
log() {
    local level="$1"
    shift
    local message="$*"
    local line
    line="[$(date '+%F %T')] [${level}] ${message}"
    printf '%s\n' "$line"
    printf '%s\n' "$line" >>"$LOG_FILE"
}

# 删除脚本运行期间生成的临时目录列表文件。
cleanup() {
    if [[ -n "${REMOTE_LIST_FILE:-}" && -f "$REMOTE_LIST_FILE" ]]; then
        rm -f -- "$REMOTE_LIST_FILE"
    fi
}
trap cleanup EXIT

print_help() {
    printf '\n'
    printf '百度网盘自动上传下载脚本\n'
    printf '\n'
    printf '用法：\n'
    printf '  baiduud help\n'
    printf '  ./baiduud.sh help\n'
    printf '  ./baiduud.sh u [-lu 本地上传目录] [-bu 网盘上传目录] [-del]\n'
    printf '  ./baiduud.sh d [-ld 本地下载目录] [-bd 网盘下载目录]\n'
    printf '  ./baiduud.sh del [-bu 网盘上传目录]\n'
    printf '  ./baiduud.sh list [-bu 网盘上传目录]\n'
    printf '\n'
    printf '操作：\n'
    printf '  help  显示本帮助信息，不执行上传、下载或删除。\n'
    printf '  u     追加上传本地目录中的内容，同名文件覆盖。\n'
    printf '  d     列出网盘目录，选择序号后下载。\n'
    printf '  del   清空网盘上传目录中的内容，但保留目录本身。\n'
    printf '  list  只显示网盘上传目录列表，不执行下载或删除。\n'
    printf '\n'
    printf '目录参数：\n'
    printf '  -lu   指定本地上传目录，仅适用于 u。\n'
    printf '        默认值：%s\n' "$LOCAL_UPLOAD"
    printf '  -bu   指定百度网盘上传目录，适用于 u、del 和 list。\n'
    printf '        默认值：%s\n' "$BAIDU_UPLOAD"
    printf '  -ld   指定本地下载目录，仅适用于 d。\n'
    printf '        默认值：%s\n' "$LOCAL_DOWNLOAD"
    printf '  -bd   指定百度网盘下载目录，仅适用于 d。\n'
    printf '        默认值：%s\n' "$BAIDU_DOWNLOAD"
    printf '  -del  上传前清空网盘上传目录，仅适用于 u，不要求二次确认。\n'
    printf '\n'
    printf '规则：\n'
    printf '  1. 操作 u、d、del、list 或 help 必须放在第一个参数。\n'
    printf '  2. 目录包含空格时必须使用引号包围。\n'
    printf '  3. 相对路径以执行命令时的当前目录为基准。\n'
    printf '  4. 同一目录参数重复出现时，最后一个值生效。\n'
    printf '  5. u 只能使用 -lu/-bu/-del，d 只能使用 -ld/-bd，list 只能使用 -bu。\n'
    printf '  6. del 只能使用 -bu，并要求输入 y 确认。\n'
    printf '  7. 普通上传不会删除网盘内容，只覆盖同名文件。\n'
    printf '  8. 下载选择支持 1、1,2 或 a；a 表示下载全部。\n'
    printf '  9. del 和 u -del 拒绝根目录、相对路径、通配符及 . 或 .. 路径段。\n'
    printf '\n'
    printf '完整案例：\n'
    printf '  baiduud help\n'
    printf '  ./baiduud.sh help\n'
    printf '  ./baiduud.sh u\n'
    printf '  ./baiduud.sh d\n'
    printf '  ./baiduud.sh del\n'
    printf '  ./baiduud.sh list\n'
    printf '  ./baiduud.sh u -lu ./ -bu /resources/upload_temp\n'
    printf '  ./baiduud.sh u -lu /data/conf/mhloctest/upload -bu /resources/upload_temp\n'
    printf '  ./baiduud.sh del -bu /resources/upload_temp\n'
    printf '  ./baiduud.sh list -bu /resources/upload_temp\n'
    printf '  ./baiduud.sh u -del\n'
    printf '  ./baiduud.sh u -lu ./ -bu /resources/upload_temp -del\n'
    printf '  ./baiduud.sh u -lu /data/conf/mhloctest/upload -bu /resources/upload_temp -del\n'
    printf '  ./baiduud.sh d -ld ./ -bd /resources/upload_temp\n'
    printf '  ./baiduud.sh d -ld /data/conf/mhloctest/download -bd /resources/upload_temp\n'
    printf '  ./baiduud.sh u -lu "/data/my upload" -bu "/resources/upload temp"\n'
    printf '\n'
    printf '日志文件：%s\n' "$LOG_FILE"
}

# 解析目录覆盖参数。参数只影响本次运行，不会修改脚本默认值。
parse_arguments() {
    ACTION="$1"
    shift

    while (($# > 0)); do
        local option="$1"
        shift

        case "$option" in
            -del)
                DELETE_BEFORE_UPLOAD=1
                continue
                ;;
            -lu | -bu | -ld | -bd)
                if (($# == 0)) || [[ "$1" == -* ]]; then
                    ARG_ERROR="参数 ${option} 缺少目录值。"
                    return 1
                fi
                ;;
            *)
                ARG_ERROR="未知参数：${option}。"
                return 1
                ;;
        esac

        case "$option" in
            -lu)
                LOCAL_UPLOAD="$1"
                USED_LU=1
                ;;
            -bu)
                BAIDU_UPLOAD="$1"
                USED_BU=1
                ;;
            -ld)
                LOCAL_DOWNLOAD="$1"
                USED_LD=1
                ;;
            -bd)
                BAIDU_DOWNLOAD="$1"
                USED_BD=1
                ;;
        esac
        shift
    done

    case "$ACTION" in
        u | U)
            if ((USED_LD == 1 || USED_BD == 1)); then
                ARG_ERROR="上传操作 u 只能使用 -lu、-bu 和 -del。"
                return 1
            fi
            ;;
        d | D)
            if ((USED_LU == 1 || USED_BU == 1 || DELETE_BEFORE_UPLOAD == 1)); then
                ARG_ERROR="下载操作 d 只能使用 -ld 和 -bd。"
                return 1
            fi
            ;;
        del | DEL | Del)
            if ((USED_LU == 1 || USED_LD == 1 || USED_BD == 1 || DELETE_BEFORE_UPLOAD == 1)); then
                ARG_ERROR="删除操作 del 只能使用 -bu。"
                return 1
            fi
            ;;
        list | LIST | List)
            if ((USED_LU == 1 || USED_LD == 1 || USED_BD == 1 || DELETE_BEFORE_UPLOAD == 1)); then
                ARG_ERROR="列表操作 list 只能使用 -bu。"
                return 1
            fi
            ;;
        *)
            ARG_ERROR="未知操作：${ACTION}。请使用 u、d、del、list 或 help。"
            return 1
            ;;
    esac
}

# 创建本地目录，并确认目标确实是目录而不是普通文件。
ensure_local_dir() {
    local path="$1"

    if [[ -d "$path" ]]; then
        log "信息" "本地目录已存在：${path}"
        return 0
    fi

    if [[ -e "$path" ]]; then
        log "错误" "本地路径已存在，但不是目录：${path}"
        return 1
    fi

    log "信息" "本地目录不存在，开始创建：${path}"
    if ! mkdir -p -- "$path"; then
        log "错误" "本地目录创建失败：${path}"
        return 1
    fi

    log "信息" "本地目录创建成功：${path}"
}

# 获取网盘目录列表。baiducmd 的错误退出码不可靠，因此还要检查输出格式。
list_remote() {
    local remote_path="$1"

    if [[ -n "$REMOTE_LIST_FILE" && -f "$REMOTE_LIST_FILE" ]]; then
        rm -f -- "$REMOTE_LIST_FILE"
    fi

    if ! REMOTE_LIST_FILE="$(mktemp "${TMPDIR:-/tmp}/baiduud.XXXXXX")"; then
        log "错误" "无法创建临时文件。"
        return 1
    fi

    baiducmd ls -l "$remote_path" >"$REMOTE_LIST_FILE" 2>&1

    # 成功的 ls 输出包含由连字符组成的分隔线，错误输出没有该分隔线。
    if ! grep -q -- '----' "$REMOTE_LIST_FILE"; then
        log "错误" "无法读取网盘目录：${remote_path}"
        tee -a "$LOG_FILE" <"$REMOTE_LIST_FILE"
        return 1
    fi
}

# 创建网盘目录后立即读取验证，不能只依赖 baiducmd 的退出码。
ensure_remote_dir() {
    local remote_path="$1"

    log "信息" "检查或创建网盘目录：${remote_path}"
    baiducmd mkdir "$remote_path" >/dev/null 2>&1

    if ! list_remote "$remote_path"; then
        log "错误" "网盘目录创建或验证失败：${remote_path}"
        return 1
    fi

    log "信息" "网盘目录可以正常访问：${remote_path}"
}

# ls -l 的项目行以数字序号开头；匹配到项目行即表示目录非空。
remote_has_items() {
    grep -Eq '^[[:space:]]+[0-9]+[[:space:]]' "$REMOTE_LIST_FILE"
}

remote_item_count() {
    grep -Ec '^[[:space:]]+[0-9]+[[:space:]]' "$REMOTE_LIST_FILE" || true
}

# 删除只允许作用于明确的非根绝对路径，避免通配符拼接后误删网盘根目录。
validate_delete_remote_path() {
    local path="$1"

    if [[ -z "$path" || "$path" != /* || "$path" == *'*'* || "$path" == *'?'* || "$path" == *'//'* ]]; then
        log "错误" "拒绝清空网盘目录：必须使用非根绝对路径，且不能包含 *、?、//、. 或 .. 路径段。"
        return 1
    fi
    if [[ "$path" =~ (^|/)(\.|\.\.)(/|$) ]]; then
        log "错误" "拒绝清空网盘目录：必须使用非根绝对路径，且不能包含 *、?、//、. 或 .. 路径段。"
        return 1
    fi

    while [[ "$path" != "/" && "$path" == */ ]]; do
        path="${path%/}"
    done
    if [[ "$path" == "/" ]]; then
        log "错误" "拒绝清空网盘目录：不能删除网盘根目录。"
        return 1
    fi

    VALIDATED_DELETE_PATH="$path"
}

# 清空网盘目录内容但保留目录。第二个参数为 yes 时要求输入 y 确认。
clear_remote_contents() {
    local remote_path="$1"
    local require_confirmation="$2"
    local confirmation=""

    validate_delete_remote_path "$remote_path" || return 1
    remote_path="$VALIDATED_DELETE_PATH"
    list_remote "$remote_path" || return 1

    if ! remote_has_items; then
        log "信息" "网盘目录已经为空，无需删除：${remote_path}"
        return 0
    fi

    if [[ "$require_confirmation" == "yes" ]]; then
        printf '\n即将清空网盘目录中的全部内容，但保留目录本身：\n'
        printf '  %s\n' "$remote_path"
        printf '请输入 y 确认，输入其他内容取消：'
        if ! IFS= read -r confirmation; then
            confirmation=""
        fi
        if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
            log "信息" "用户取消删除，网盘数据未发生变化。"
            return 0
        fi
    fi

    log "警告" "开始清空网盘目录：${remote_path}"
    baiducmd rm "${remote_path}/*"
    log "信息" "删除命令已执行，正在复查网盘目录。"

    list_remote "$remote_path" || return 1
    if remote_has_items; then
        tee -a "$LOG_FILE" <"$REMOTE_LIST_FILE"
        log "错误" "网盘目录仍然非空，删除校验失败。"
        return 1
    fi

    log "信息" "网盘目录内容已清空，目录本身已保留：${remote_path}"
}

# 解析 ls -l 项目行，建立从 0 开始的 Bash 数组；显示时转换为 1 起始序号。
load_remote_items() {
    local line
    local size
    local modified
    local tail
    local name
    local type
    local ignored_md5
    local row_pattern='^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+([^[:space:]]+)[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2})[[:space:]]+([0-9]{2}:[0-9]{2}:[0-9]{2})[[:space:]]+(.*)$'

    REMOTE_NAMES=()
    REMOTE_TYPES=()
    REMOTE_SIZES=()
    REMOTE_MODIFIED=()

    while IFS= read -r line; do
        if [[ ! $line =~ $row_pattern ]]; then
            continue
        fi

        size="${BASH_REMATCH[1]}"
        modified="${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
        tail="${BASH_REMATCH[4]}"
        tail="${tail#"${tail%%[![:space:]]*}"}"
        tail="${tail%"${tail##*[![:space:]]}"}"

        if [[ "$size" == "-" ]]; then
            name="${tail%/}"
            type="文件夹"
        else
            IFS=' ' read -r ignored_md5 name <<<"$tail"
            type="文件"
        fi

        if [[ -z "$name" ]]; then
            continue
        fi

        REMOTE_NAMES+=("$name")
        REMOTE_TYPES+=("$type")
        REMOTE_SIZES+=("$size")
        REMOTE_MODIFIED+=("$modified")
    done <"$REMOTE_LIST_FILE"
}

print_remote_table() {
    local index
    local display_name

    printf '\n'
    printf '| 序号 | 名称 | 类型 | 大小 | 修改日期 |\n'
    printf '| ------------ | ------------ | ------------ | ------------ | ------------ |\n'
    for index in "${!REMOTE_NAMES[@]}"; do
        display_name="${REMOTE_NAMES[$index]//|/\\|}"
        printf '| %d | %s | %s | %s | %s |\n' \
            "$((index + 1))" \
            "$display_name" \
            "${REMOTE_TYPES[$index]}" \
            "${REMOTE_SIZES[$index]}" \
            "${REMOTE_MODIFIED[$index]}"
    done
    printf '\n'
}

prompt_download_selection() {
    local selection
    local cleaned
    local token
    local number
    local index
    local -a tokens=()
    local -a candidates=()
    local -A seen=()

    while true; do
        printf '请输入下载序号（例如 1 或 1,2），输入 a 下载全部：'
        if ! IFS= read -r selection; then
            log "错误" "无法读取下载选择，已取消下载。"
            return 1
        fi

        if [[ "$selection" == "a" || "$selection" == "A" ]]; then
            SELECTED_INDEXES=()
            for index in "${!REMOTE_NAMES[@]}"; do
                SELECTED_INDEXES+=("$index")
            done
            log "信息" "已选择全部 ${#SELECTED_INDEXES[@]} 个下载项目。"
            return 0
        fi

        cleaned="${selection//[[:space:]]/}"
        if [[ ! "$cleaned" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
            log "警告" "下载选择无效，请输入序号、逗号分隔序号或 a。"
            continue
        fi

        IFS=',' read -r -a tokens <<<"$cleaned"
        candidates=()
        seen=()
        for token in "${tokens[@]}"; do
            number=$((10#$token))
            if ((number < 1 || number > ${#REMOTE_NAMES[@]})); then
                candidates=()
                break
            fi
            if [[ -z "${seen[$number]+x}" ]]; then
                seen[$number]=1
                candidates+=("$((number - 1))")
            fi
        done

        if ((${#candidates[@]} == 0)); then
            log "警告" "下载选择无效，有效序号范围为 1 到 ${#REMOTE_NAMES[@]}。"
            continue
        fi

        SELECTED_INDEXES=("${candidates[@]}")
        log "信息" "已选择 ${#SELECTED_INDEXES[@]} 个下载项目。"
        return 0
    done
}

download_selected_items() {
    local index
    local download_output_file
    local download_status
    local local_path
    local validation_error=""
    local has_nonempty_file=0
    local -a remote_paths=()

    for index in "${SELECTED_INDEXES[@]}"; do
        log "信息" "准备下载：${REMOTE_NAMES[$index]}"
        remote_paths+=("${BAIDU_DOWNLOAD}/${REMOTE_NAMES[$index]}")
    done

    log "信息" "开始下载所选项目，已启用同名文件覆盖选项。"
    printf '\n'
    if ! download_output_file="$(mktemp "${TMPDIR:-/tmp}/baiduud-download.XXXXXX")"; then
        log "错误" "无法创建下载校验临时文件。"
        return 1
    fi

    baiducmd download --ow --saveto "$LOCAL_DOWNLOAD" "${remote_paths[@]}" 2>&1 \
        | tee -a "$LOG_FILE" "$download_output_file"
    download_status="${PIPESTATUS[0]}"
    if ((download_status != 0)); then
        rm -f -- "$download_output_file"
        log "错误" "下载命令返回失败状态。"
        return 1
    fi

    if ! grep -Fq -- '下载结束' "$download_output_file"; then
        validation_error="客户端下载输出中缺少“下载结束”完成标记"
    fi

    for index in "${SELECTED_INDEXES[@]}"; do
        [[ -z "$validation_error" ]] || break
        local_path="${LOCAL_DOWNLOAD}/${REMOTE_NAMES[$index]}"
        if [[ "${REMOTE_TYPES[$index]}" == "文件夹" ]]; then
            if [[ ! -d "$local_path" ]]; then
                validation_error="$local_path"
                break
            fi
            continue
        fi

        if [[ ! -f "$local_path" ]]; then
            validation_error="$local_path"
            break
        fi
        if [[ "${REMOTE_SIZES[$index]}" != "0B" ]]; then
            has_nonempty_file=1
            if [[ ! -s "$local_path" ]]; then
                validation_error="$local_path"
                break
            fi
        fi
    done

    if ((has_nonempty_file == 1)) && grep -Fq -- '数据总量: 0B' "$download_output_file"; then
        validation_error="${validation_error:-客户端下载数据量为 0B}"
    fi

    rm -f -- "$download_output_file"
    if [[ -n "$validation_error" ]]; then
        log "错误" "下载校验失败，本地未生成有效内容：${validation_error}"
        return 1
    fi

    log "信息" "已完成所选项目的下载。"
}

verify_remote_target() {
    local local_path="$1"
    local remote_path="$2"
    local meta_file
    local local_size
    local remote_size

    if ! meta_file="$(mktemp "${TMPDIR:-/tmp}/baiduud-meta.XXXXXX")"; then
        log "错误" "无法创建上传校验临时文件。"
        return 1
    fi

    baiducmd meta "$remote_path" >"$meta_file" 2>&1
    if ! grep -q -- '----' "$meta_file"; then
        tee -a "$LOG_FILE" <"$meta_file"
        rm -f -- "$meta_file"
        log "错误" "上传后无法验证网盘目标：${remote_path}"
        return 1
    fi

    if [[ -f "$local_path" ]]; then
        local_size="$(stat -c '%s' -- "$local_path")"
        remote_size="$(sed -nE 's/^[[:space:]]*文件大小[[:space:]]+([0-9]+),.*$/\1/p' "$meta_file" | sed -n '1p')"
        if [[ -z "$remote_size" || "$local_size" != "$remote_size" ]]; then
            tee -a "$LOG_FILE" <"$meta_file"
            rm -f -- "$meta_file"
            log "错误" "上传校验失败，本地与网盘文件字节数不一致：${remote_path}"
            return 1
        fi
    fi

    rm -f -- "$meta_file"
    log "信息" "上传目标验证成功：${remote_path}"
}

# ============================================================
# 上传流程
# 1. 创建并检查本地、网盘上传目录。
# 2. 仅在指定 -del 时清空网盘目录。
# 3. 采用 overwrite 策略追加上传所有顶层项目。
# 4. 逐项验证上传后的网盘目标是否存在。
# ============================================================
upload_main() {
    local -a local_items=()
    local item
    local item_name
    local local_count
    local remote_count
    local upload_output_file
    local upload_status

    log "信息" "进入上传流程。"
    log "信息" "本地上传目录：${LOCAL_UPLOAD}"
    log "信息" "网盘上传目录：${BAIDU_UPLOAD}"

    if ((DELETE_BEFORE_UPLOAD == 1)); then
        validate_delete_remote_path "$BAIDU_UPLOAD" || return 1
        BAIDU_UPLOAD="$VALIDATED_DELETE_PATH"
    fi

    ensure_local_dir "$LOCAL_UPLOAD" || return 1
    ensure_remote_dir "$BAIDU_UPLOAD" || return 1

    # 使用 NUL 分隔，正确处理空格、换行和隐藏文件名。
    while IFS= read -r -d '' item; do
        local_items+=("$item")
    done < <(find "$LOCAL_UPLOAD" -mindepth 1 -maxdepth 1 -print0)

    if ((DELETE_BEFORE_UPLOAD == 1)); then
        log "警告" "已指定 -del，上传前将清空网盘上传目录。"
        clear_remote_contents "$BAIDU_UPLOAD" "no" || return 1
    else
        log "信息" "未指定 -del，本次采用追加上传，不删除网盘已有内容。"
    fi

    local_count="${#local_items[@]}"
    if ((local_count == 0)); then
        log "警告" "本地上传目录为空，没有需要上传的内容：${LOCAL_UPLOAD}"
        return 0
    fi

    log "信息" "网盘上传目录已就绪，已有内容将被保留。"
    log "信息" "待上传的顶层项目数量：${local_count}"

    # 逐项上传，避免在网盘目录中额外生成一层 upload 文件夹。
    for item in "${local_items[@]}"; do
        item_name="$(basename -- "$item")"
        printf '\n'
        log "信息" "正在上传：${item_name}"
        if ! upload_output_file="$(mktemp "${TMPDIR:-/tmp}/baiduud-upload.XXXXXX")"; then
            log "错误" "无法创建上传校验临时文件。"
            return 1
        fi
        baiducmd upload --policy overwrite "$item" "$BAIDU_UPLOAD" 2>&1 \
            | tee -a "$LOG_FILE" "$upload_output_file"
        upload_status="${PIPESTATUS[0]}"
        if ((upload_status != 0)); then
            rm -f -- "$upload_output_file"
            log "错误" "上传命令返回失败状态：${item_name}"
            return 1
        fi
        if ! grep -Fq -- '上传结束' "$upload_output_file"; then
            rm -f -- "$upload_output_file"
            log "错误" "上传校验失败，客户端输出中缺少“上传结束”完成标记：${item_name}"
            return 1
        fi
        rm -f -- "$upload_output_file"
        verify_remote_target "$item" "${BAIDU_UPLOAD}/${item_name}" || return 1
    done

    log "信息" "上传命令执行完毕，开始校验网盘目录。"
    if ! list_remote "$BAIDU_UPLOAD"; then
        log "错误" "上传后无法读取网盘上传目录。"
        return 1
    fi

    remote_count="$(remote_item_count)"
    log "信息" "上传完成，已验证 ${local_count} 个本地顶层项目；网盘目录当前共有 ${remote_count} 个顶层项目。"
}

# ============================================================
# 下载流程
# 1. 创建并检查本地、网盘下载目录。
# 2. 将网盘项目显示为从 1 开始的中文表格。
# 3. 等待用户选择一个、多个或全部项目。
# 4. 下载选中内容，并覆盖本地同名文件。
# ============================================================
download_main() {
    log "信息" "进入下载流程。"
    log "信息" "网盘下载目录：${BAIDU_DOWNLOAD}"
    log "信息" "本地下载目录：${LOCAL_DOWNLOAD}"

    ensure_local_dir "$LOCAL_DOWNLOAD" || return 1
    ensure_remote_dir "$BAIDU_DOWNLOAD" || return 1

    load_remote_items
    if ((${#REMOTE_NAMES[@]} == 0)); then
        log "警告" "网盘下载目录为空，没有需要下载的内容。"
        return 0
    fi

    print_remote_table
    prompt_download_selection || return 1
    download_selected_items
}

# 只读显示网盘上传目录，复用下载流程的项目解析和五列表格。
list_main() {
    log "信息" "进入网盘列表查询流程。"
    log "信息" "网盘查询目录：${BAIDU_UPLOAD}"

    ensure_remote_dir "$BAIDU_UPLOAD" || return 1
    load_remote_items
    if ((${#REMOTE_NAMES[@]} == 0)); then
        log "警告" "网盘查询目录为空：${BAIDU_UPLOAD}"
        return 0
    fi

    print_remote_table
    log "信息" "网盘列表查询完成，共显示 ${#REMOTE_NAMES[@]} 个顶层项目。"
}

# 独立删除上传目录中的全部内容，但保留目录本身。
delete_main() {
    log "信息" "进入独立删除流程。"
    log "警告" "准备清空网盘目录：${BAIDU_UPLOAD}"

    validate_delete_remote_path "$BAIDU_UPLOAD" || return 1
    BAIDU_UPLOAD="$VALIDATED_DELETE_PATH"

    ensure_remote_dir "$BAIDU_UPLOAD" || return 1
    clear_remote_contents "$BAIDU_UPLOAD" "yes"
}

main() {
    if ! touch "$LOG_FILE" 2>/dev/null; then
        printf '错误：无法创建或写入日志文件：%s\n' "$LOG_FILE" >&2
        return 1
    fi

    log "信息" "脚本启动，接收到的参数：$*"

    if (($# == 0)); then
        ARG_ERROR="未指定操作，请使用 u、d、del、list 或 help。"
        log "错误" "$ARG_ERROR"
        print_help
        return 1
    fi

    case "$1" in
        help | -h | --help)
            if (($# != 1)); then
                ARG_ERROR="帮助参数后面不能再添加其他参数。"
                log "错误" "$ARG_ERROR"
                print_help
                return 1
            fi
            log "信息" "显示帮助信息。"
            print_help
            return 0
            ;;
    esac

    if ! parse_arguments "$@"; then
        log "错误" "$ARG_ERROR"
        print_help
        return 1
    fi

    if ! command -v baiducmd >/dev/null 2>&1; then
        log "错误" "未找到 baiducmd 命令，请检查安装目录和系统环境变量。"
        return 1
    fi

    case "$ACTION" in
        u | U)
            upload_main
            ;;
        d | D)
            download_main
            ;;
        del | DEL | Del)
            delete_main
            ;;
        list | LIST | List)
            list_main
            ;;
    esac
}

if main "$@"; then
    log "信息" "脚本执行完成，退出码：0"
    exit 0
else
    log "错误" "脚本执行失败，退出码：1，请查看上方信息和日志文件。"
    exit 1
fi
```

# 百度网盘自动上传下载脚本教程

本文档总结 `baiduud.cmd` 与 `baiduud.sh` 的完整需求、参数、使用案例、运行流程和排错方法，并附带当前两份脚本的完整源码，便于以后直接查阅。

- 更新日期：2026-07-16
- Windows 脚本：[baiduud.cmd](./baiduud.cmd)
- Linux 脚本：[baiduud.sh](./baiduud.sh)
- Windows SHA-256：`AB44533E6CE15D4CECB727FD4F469A935F278F083F7D7A3CEECEEA1CE4726C64`
- Linux SHA-256：`29C7A1312ED8DAF75C98CB8EE3BCC5F46899483FC2D2613ED959F0527DF70046`

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

## 二、最重要的安全规则

> [!WARNING]
> 普通 `u` 上传不会删除网盘已有内容。只有执行 `del` 或 `u -del` 时，脚本才会删除 `BAIDU_UPLOAD` 或 `-bu` 指定目录中的全部内容。删除只保留目标目录本身，执行前必须确认路径正确。

参数覆盖只对当前一次运行有效，不会修改脚本中的默认配置。相对路径以运行命令时的当前工作目录为基准。

## 三、命令格式

Windows：

```bat
baiduud help
baiduud u [-lu 本地上传目录] [-bu 网盘上传目录] [-del]
baiduud d [-ld 本地下载目录] [-bd 网盘下载目录]
baiduud del [-bu 网盘上传目录]
```

Linux：

```bash
./baiduud.sh help
./baiduud.sh u [-lu 本地上传目录] [-bu 网盘上传目录] [-del]
./baiduud.sh d [-ld 本地下载目录] [-bd 网盘下载目录]
./baiduud.sh del [-bu 网盘上传目录]
```

如果已将 Linux 脚本链接或安装为 `baiduud`，也可以运行 `baiduud help`。

## 四、参数速查

| 参数 | 适用操作 | 含义 | Windows 默认值 | Linux 默认值 |
| --- | --- | --- | --- | --- |
| `help` | 独立操作 | 显示帮助，不上传、不下载、不删除 | - | - |
| `u` | 独立操作 | 追加上传；同名文件覆盖 | - | - |
| `d` | 独立操作 | 列表选择后下载 | - | - |
| `del` | 独立操作 | 确认后清空网盘上传目录内容 | - | - |
| `-lu` | `u` | 指定本地上传目录 | `D:\conf\mhloctest\upload` | `/data/conf/mhloctest/upload` |
| `-bu` | `u`、`del` | 指定百度网盘上传或删除目录 | `/resources/upload_temp` | `/resources/upload_temp` |
| `-ld` | `d` | 指定本地下载目录 | `D:\conf\mhloctest\download` | `/data/conf/mhloctest/download` |
| `-bd` | `d` | 指定百度网盘下载目录 | `/resources/upload_temp` | `/resources/upload_temp` |
| `-del` | `u` | 上传前先清空网盘上传目录，不二次确认 | - | - |

### 参数规则

1. 第一个参数必须是 `u`、`d`、`del` 或 `help`。
2. `u` 只能使用 `-lu`、`-bu`、`-del`。
3. `d` 只能使用 `-ld`、`-bd`。
4. `del` 只能使用 `-bu`，并在删除前要求输入 `y` 或 `Y`。
5. 每个目录参数后必须紧跟目录值。
6. 路径包含空格时必须使用双引号。
7. 相对路径以当前工作目录为基准。
8. 同一个目录参数重复出现时，最后一个值生效。
9. 未提供的参数继续使用脚本顶部默认值。
10. `help`、`-h`、`--help` 均可显示帮助；推荐使用 `baiduud help`。

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

这三条命令都不会清空网盘目录。脚本使用 `--policy overwrite`，覆盖远端同名文件，同时保留远端其他内容。

### 5.3 独立删除网盘内容

```bat
baiduud del
baiduud del -bu /resources/upload_temp
```

`del` 只删除目标目录中的内容，保留目标目录本身。脚本会显示目标路径，只有输入 `y` 或 `Y` 才执行；输入其他内容会取消且返回成功。

### 5.4 删除后再上传

```bat
baiduud u -del
baiduud u -lu ./ -bu /resources/upload_temp -del
baiduud u -lu D:\conf\mhloctest\upload -bu /resources/upload_temp -del
```

`u -del` 已明确表达删除意图，因此不会再次询问。脚本会清空并复查网盘目录，再使用覆盖策略上传。

### 5.5 列表选择下载

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

### 5.6 路径包含空格或只覆盖一个默认值

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

### 6.3 独立删除网盘内容

```bash
./baiduud.sh del
./baiduud.sh del -bu /resources/upload_temp
```

独立删除要求输入 `y` 或 `Y` 确认，并保留目标目录本身。

### 6.4 删除后再上传

```bash
./baiduud.sh u -del
./baiduud.sh u -lu ./ -bu /resources/upload_temp -del
./baiduud.sh u -lu /data/conf/mhloctest/upload -bu /resources/upload_temp -del
```

### 6.5 列表选择下载

```bash
./baiduud.sh d
./baiduud.sh d -ld ./ -bd /resources/upload_temp
./baiduud.sh d -ld /data/conf/mhloctest/download -bd /resources/upload_temp
```

列表格式和选择规则与 Windows 相同：输入 `1`、`1,2` 或 `a`。

### 6.6 路径包含空格

```bash
./baiduud.sh u -lu "/data/my upload" -bu "/resources/upload temp"
./baiduud.sh d -ld "/data/my download" -bd "/resources/upload temp"
```

### 6.7 环境变量默认值与命令行覆盖

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
```

常见错误含义：

- `参数 -lu 缺少目录值`：选项后没有目录。
- `参数 -ld 仅适用于下载操作 d`：上传命令使用了下载参数。
- `删除操作 del 只能使用 -bu`：`del` 使用了本地或下载目录参数。
- `参数 -del 仅适用于上传操作 u`：下载命令错误使用了删除标记。
- `未知参数`：参数拼写错误。
- `help 后面不能再添加其他参数`：帮助操作必须单独使用。

## 八、上传执行流程

1. 解析操作和目录覆盖参数。
2. 检查 `baiducmd` 是否位于 `PATH`。
3. 自动创建本地上传目录。
4. 创建网盘上传目录，并用 `ls -l` 验证可访问。
5. 指定 `-del` 时清空并复查网盘目录；普通上传跳过删除。
6. 本地目录为空时记录警告并正常结束。
7. 使用 `upload --policy overwrite` 逐项追加上传顶层文件和子目录。
8. 每项上传后使用 `meta` 验证远端目标存在。
9. 最后重新读取网盘目录并记录当前顶层项目数量。

远端允许保留额外项目，因此脚本不再要求本地与远端项目总数相等。存在性验证不能代替内容哈希校验，重要数据建议另外保存校验值和本地备份。

## 九、删除执行流程

### 独立 `del`

1. 使用默认 `BAIDU_UPLOAD` 或 `-bu` 指定目录。
2. 自动创建并验证网盘目录。
3. 目录为空时正常结束。
4. 显示目标路径并等待输入 `y` 或 `Y`。
5. 执行 `<目录>/*` 删除内容，但保留目录本身。
6. 再次读取目录；如果仍有项目则返回失败。

### 上传参数 `-del`

`u -del` 使用相同的删除与复查逻辑，但不要求二次确认。即使本地上传目录为空，`-del` 仍会先执行已经明确要求的清空操作。

## 十、下载执行流程

1. 解析操作和目录覆盖参数。
2. 自动创建本地下载目录。
3. 创建并验证网盘下载目录。
4. 网盘目录为空时正常结束。
5. 解析 `ls -l`，显示从 1 开始的五列中文列表。
6. 等待输入单个序号、逗号分隔序号或 `a`。
7. 校验范围并去除重复序号，错误输入会重新提示。
8. 使用 `--saveto` 下载所选项目，并用 `--ow` 覆盖本地同名文件。

下载不会删除本地目录中仅存在于本地的文件。

## 十一、日志与排错

日志同时显示在控制台，并追加写入脚本目录下的 `baiduud.log`。

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

### Windows 中文乱码

`baiduud.cmd` 必须保存为 GBK（简体中文代码页 936）和 CRLF 换行；不要保存为 UTF-8、UTF-16 或 LF 换行。

脚本开头会把当前 CMD 会话切换到简体中文代码页 936。脚本文件与 CMD 使用相同编码，可以避免中文被拆成命令并产生英文的“无法识别命令”系统错误。退出时不再切换代码页，因此帮助内容会保留在窗口中。

### Linux 提示权限不足

`baiduud.sh` 必须保存为 UTF-8 无 BOM 编码和 LF 换行，避免脚本首行或命令参数中出现不可见字符。

```bash
chmod +x docs/baiduud.sh
bash docs/baiduud.sh help
```

## 十二、维护与验证

修改脚本后至少运行：

```bat
docs\baiduud.cmd help
powershell -File tests\baiduud-regression.ps1
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
rem 第一个参数必须是 u、d、del 或 help，后续参数按操作进行校验。
rem ============================================================
if "%~1"=="" (
    set "ARG_ERROR=未指定操作，请使用 u、d、del 或 help。"
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
if /i not "%ACTION%"=="u" if /i not "%ACTION%"=="d" if /i not "%ACTION%"=="del" (
    set "ARG_ERROR=未知操作：%ACTION%。请使用 u、d、del 或 help。"
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

call :log 信息 "网盘上传目录已就绪，已有内容将被保留。"
call :log 信息 "待上传的顶层项目数量：%LOCAL_COUNT%"

pushd "%LOCAL_UPLOAD%" >nul
if errorlevel 1 (
    call :log 错误 "无法进入本地上传目录：%LOCAL_UPLOAD%"
    goto :failed
)

rem 逐项上传可以避免在网盘目录中额外生成一层 upload 文件夹。
set "UPLOAD_FAILED="
for /f "delims=" %%I in ('dir /b /a') do (
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

rem 上传单个项目，并通过 meta 输出中的分隔线确认远端目标存在。
:upload_one_item
echo.
call :log 信息 "正在上传：%~1"
baiducmd upload --policy overwrite "%~1" "%BAIDU_UPLOAD%"
if errorlevel 1 (
    set "UPLOAD_FAILED=1"
    call :log 错误 "上传命令返回失败状态：%~1"
    exit /b 1
)

set "REMOTE_META_FILE=%TEMP%\baiduud_meta_%RANDOM%_%RANDOM%.tmp"
baiducmd meta "%BAIDU_UPLOAD%/%~1" >"%REMOTE_META_FILE%" 2>&1
findstr /C:"----" "%REMOTE_META_FILE%" >nul 2>&1
if errorlevel 1 (
    type "%REMOTE_META_FILE%"
    type "%REMOTE_META_FILE%" >>"%LOG_FILE%"
    del /q "%REMOTE_META_FILE%" >nul 2>&1
    set "REMOTE_META_FILE="
    set "UPLOAD_FAILED=1"
    call :log 错误 "上传后无法验证网盘目标：%BAIDU_UPLOAD%/%~1"
    exit /b 1
)
del /q "%REMOTE_META_FILE%" >nul 2>&1
set "REMOTE_META_FILE="
call :log 信息 "上传目标验证成功：%BAIDU_UPLOAD%/%~1"
exit /b 0

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
rem 独立删除流程
rem 删除上传目录中的全部内容，但保留目录本身。
rem ============================================================
:delete
call :log 信息 "进入独立删除流程。"
call :log 警告 "准备清空网盘目录：%BAIDU_UPLOAD%"

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
set "CLEAR_REMOTE_PATH=%~1"
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
for /f "tokens=1-8,*" %%A in ('findstr /R /C:"^[ ][ ]*[0-9][0-9]*[ ]" "%REMOTE_LIST_FILE%"') do call :store_remote_item "%%D" "%%G %%H" "%%I"
exit /b 0

:store_remote_item
set "ITEM_SIZE=%~1"
set "ITEM_MODIFIED=%~2"
set "ITEM_TAIL=%~3"
if "%ITEM_SIZE%"=="-" goto :store_remote_directory

for /f "tokens=1,*" %%A in ("%ITEM_TAIL%") do set "ITEM_NAME=%%B"
set "ITEM_TYPE=文件"
goto :store_remote_values

:store_remote_directory
set "ITEM_NAME=%ITEM_TAIL%"
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
echo.
call :log 信息 "正在下载：%ITEM_NAME%"
baiducmd download --ow --saveto "%LOCAL_DOWNLOAD%" "%BAIDU_DOWNLOAD%/%ITEM_NAME%"
if errorlevel 1 (
    set "DOWNLOAD_FAILED=1"
    call :log 错误 "下载命令返回失败状态：%ITEM_NAME%"
    exit /b 1
)
call :log 信息 "下载命令执行完成：%ITEM_NAME%"
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
echo.
echo 操作：
echo   help  显示本帮助信息，不执行上传、下载或删除。
echo   u     追加上传本地目录中的内容，同名文件覆盖。
echo   d     列出网盘目录，选择序号后下载。
echo   del   清空网盘上传目录中的内容，但保留目录本身。
echo.
echo 目录参数：
echo   -lu   指定本地上传目录，仅适用于 u。
echo         默认值：%LOCAL_UPLOAD%
echo   -bu   指定百度网盘上传目录，仅适用于 u。
echo         默认值：%BAIDU_UPLOAD%
echo   -ld   指定本地下载目录，仅适用于 d。
echo         默认值：%LOCAL_DOWNLOAD%
echo   -bd   指定百度网盘下载目录，仅适用于 d。
echo         默认值：%BAIDU_DOWNLOAD%
echo   -del  上传前清空网盘上传目录，仅适用于 u，不要求二次确认。
echo.
echo 规则：
echo   1. 操作 u、d、del 或 help 必须放在第一个参数。
echo   2. 目录包含空格时必须使用双引号包围。
echo   3. 相对路径以执行命令时的当前目录为基准。
echo   4. 同一目录参数重复出现时，最后一个值生效。
echo   5. u 只能使用 -lu/-bu/-del，d 只能使用 -ld/-bd。
echo   6. del 只能使用 -bu，并要求输入 y 确认。
echo   7. 普通上传不会删除网盘内容，只覆盖同名文件。
echo   8. 下载选择支持 1、1,2 或 a；a 表示下载全部。
echo.
echo 完整案例：
echo   baiduud help
echo   baiduud u
echo   baiduud d
echo   baiduud del
echo   baiduud u -lu ./ -bu /resources/upload_temp
echo   baiduud u -lu D:\conf\mhloctest\upload -bu /resources/upload_temp
echo   baiduud del -bu /resources/upload_temp
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
    printf '\n'
    printf '操作：\n'
    printf '  help  显示本帮助信息，不执行上传、下载或删除。\n'
    printf '  u     追加上传本地目录中的内容，同名文件覆盖。\n'
    printf '  d     列出网盘目录，选择序号后下载。\n'
    printf '  del   清空网盘上传目录中的内容，但保留目录本身。\n'
    printf '\n'
    printf '目录参数：\n'
    printf '  -lu   指定本地上传目录，仅适用于 u。\n'
    printf '        默认值：%s\n' "$LOCAL_UPLOAD"
    printf '  -bu   指定百度网盘上传目录，仅适用于 u。\n'
    printf '        默认值：%s\n' "$BAIDU_UPLOAD"
    printf '  -ld   指定本地下载目录，仅适用于 d。\n'
    printf '        默认值：%s\n' "$LOCAL_DOWNLOAD"
    printf '  -bd   指定百度网盘下载目录，仅适用于 d。\n'
    printf '        默认值：%s\n' "$BAIDU_DOWNLOAD"
    printf '  -del  上传前清空网盘上传目录，仅适用于 u，不要求二次确认。\n'
    printf '\n'
    printf '规则：\n'
    printf '  1. 操作 u、d、del 或 help 必须放在第一个参数。\n'
    printf '  2. 目录包含空格时必须使用引号包围。\n'
    printf '  3. 相对路径以执行命令时的当前目录为基准。\n'
    printf '  4. 同一目录参数重复出现时，最后一个值生效。\n'
    printf '  5. u 只能使用 -lu/-bu/-del，d 只能使用 -ld/-bd。\n'
    printf '  6. del 只能使用 -bu，并要求输入 y 确认。\n'
    printf '  7. 普通上传不会删除网盘内容，只覆盖同名文件。\n'
    printf '  8. 下载选择支持 1、1,2 或 a；a 表示下载全部。\n'
    printf '\n'
    printf '完整案例：\n'
    printf '  baiduud help\n'
    printf '  ./baiduud.sh help\n'
    printf '  ./baiduud.sh u\n'
    printf '  ./baiduud.sh d\n'
    printf '  ./baiduud.sh del\n'
    printf '  ./baiduud.sh u -lu ./ -bu /resources/upload_temp\n'
    printf '  ./baiduud.sh u -lu /data/conf/mhloctest/upload -bu /resources/upload_temp\n'
    printf '  ./baiduud.sh del -bu /resources/upload_temp\n'
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
        *)
            ARG_ERROR="未知操作：${ACTION}。请使用 u、d、del 或 help。"
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

# 清空网盘目录内容但保留目录。第二个参数为 yes 时要求输入 y 确认。
clear_remote_contents() {
    local remote_path="$1"
    local require_confirmation="$2"
    local confirmation=""

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
    local -a remote_paths=()

    for index in "${SELECTED_INDEXES[@]}"; do
        log "信息" "准备下载：${REMOTE_NAMES[$index]}"
        remote_paths+=("${BAIDU_DOWNLOAD}/${REMOTE_NAMES[$index]}")
    done

    log "信息" "开始下载所选项目，已启用同名文件覆盖选项。"
    printf '\n'
    if ! baiducmd download --ow --saveto "$LOCAL_DOWNLOAD" "${remote_paths[@]}"; then
        log "错误" "下载命令返回失败状态。"
        return 1
    fi

    log "信息" "已完成所选项目的下载。"
}

verify_remote_target() {
    local remote_path="$1"
    local meta_file

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

    log "信息" "进入上传流程。"
    log "信息" "本地上传目录：${LOCAL_UPLOAD}"
    log "信息" "网盘上传目录：${BAIDU_UPLOAD}"

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
        if ! baiducmd upload --policy overwrite "$item" "$BAIDU_UPLOAD"; then
            log "错误" "上传命令返回失败状态：${item_name}"
            return 1
        fi
        verify_remote_target "${BAIDU_UPLOAD}/${item_name}" || return 1
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

# 独立删除上传目录中的全部内容，但保留目录本身。
delete_main() {
    log "信息" "进入独立删除流程。"
    log "警告" "准备清空网盘目录：${BAIDU_UPLOAD}"

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
        ARG_ERROR="未指定操作，请使用 u、d、del 或 help。"
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

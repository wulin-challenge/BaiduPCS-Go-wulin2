# 百度网盘自动上传下载脚本教程

本文档总结 `baiduud.cmd` 与 `baiduud.sh` 的完整需求、参数、使用案例、运行流程和排错方法，并附带当前两份脚本的完整源码，便于以后直接查阅。

- 更新日期：2026-07-15
- Windows 脚本：[baiduud.cmd](./baiduud.cmd)
- Linux 脚本：[baiduud.sh](./baiduud.sh)
- Windows SHA-256：`D1762A44FB5BED388DA31561E0622F64316DFB50473D032004F5CD4CB710783D`
- Linux SHA-256：`FCAB8B5ABA25739934AD404E36FD610EF8881FEC0F755F8DF2B3A00587818635`

## 一、需求演进总结

本次工作基于已经安装、重命名为 `baiducmd` 并完成登录的 BaiduPCS-Go-wulin2 客户端。脚本经过以下阶段：

1. 创建 Windows 脚本，使用 `u` 上传、`d` 下载。
2. 上传前检查网盘目录，非空时先清空再上传。
3. 本地和网盘目录不存在时自动创建并验证。
4. 增加中文注释、中文控制台日志和 `baiduud.log`。
5. 创建等价 Linux Bash 版本，支持隐藏文件和安全临时文件。
6. 增加 `-lu`、`-bu`、`-ld`、`-bd`，允许每次运行临时指定目录。
7. 增加 `baiduud help`，完整解释参数、规则、默认值和案例。

## 二、最重要的安全规则

> [!WARNING]
> 执行上传时，脚本会删除 `BAIDU_UPLOAD` 或 `-bu` 指定目录中的全部现有内容，然后再上传本地内容。执行前必须确认网盘上传目录正确，切勿指向包含重要文件的目录。

参数覆盖只对当前一次运行有效，不会修改脚本中的默认配置。相对路径以运行命令时的当前工作目录为基准。

## 三、命令格式

Windows：

```bat
baiduud help
baiduud u [-lu 本地上传目录] [-bu 网盘上传目录]
baiduud d [-ld 本地下载目录] [-bd 网盘下载目录]
```

Linux：

```bash
./baiduud.sh help
./baiduud.sh u [-lu 本地上传目录] [-bu 网盘上传目录]
./baiduud.sh d [-ld 本地下载目录] [-bd 网盘下载目录]
```

如果已将 Linux 脚本链接或安装为 `baiduud`，也可以运行 `baiduud help`。

## 四、参数速查

| 参数 | 适用操作 | 含义 | Windows 默认值 | Linux 默认值 |
| --- | --- | --- | --- | --- |
| `help` | 独立操作 | 显示帮助，不上传、不下载 | - | - |
| `u` | 独立操作 | 上传本地目录内容 | - | - |
| `d` | 独立操作 | 下载网盘目录内容 | - | - |
| `-lu` | `u` | 指定本地上传目录 | `D:\conf\mhloctest\upload` | `/data/conf/mhloctest/upload` |
| `-bu` | `u` | 指定百度网盘上传目录 | `/resources/upload_temp` | `/resources/upload_temp` |
| `-ld` | `d` | 指定本地下载目录 | `D:\conf\mhloctest\download` | `/data/conf/mhloctest/download` |
| `-bd` | `d` | 指定百度网盘下载目录 | `/resources/upload_temp` | `/resources/upload_temp` |

### 参数规则

1. 第一个参数必须是 `u`、`d` 或 `help`。
2. `u` 只能使用 `-lu`、`-bu`。
3. `d` 只能使用 `-ld`、`-bd`。
4. 每个目录参数后必须紧跟目录值。
5. 路径包含空格时必须使用双引号。
6. 相对路径以当前工作目录为基准。
7. 同一个参数重复出现时，最后一个值生效。
8. 未提供的参数继续使用脚本顶部默认值。
9. `help`、`-h`、`--help` 均可显示帮助；推荐使用 `baiduud help`。

## 五、Windows 完整使用案例

### 5.1 查看帮助

```bat
baiduud help
```

帮助会显示四个目录参数、默认值、适用操作、安全规则和完整案例。该命令不要求 `baiducmd` 已登录，也不会执行文件操作。

### 5.2 使用默认目录上传和下载

```bat
baiduud u
baiduud d
```

### 5.3 使用当前目录上传

```bat
baiduud u -lu ./ -bu /resources/upload_temp
```

这会把执行命令时当前目录中的顶层内容上传到 `/resources/upload_temp`。

### 5.4 指定 Windows 绝对上传目录

```bat
baiduud u -lu D:\conf\mhloctest\upload -bu /resources/upload_temp
```

### 5.5 下载到当前目录

```bat
baiduud d -ld ./ -bd /resources/upload_temp
```

### 5.6 指定 Windows 绝对下载目录

```bat
baiduud d -ld D:\conf\mhloctest\download -bd /resources/upload_temp
```

### 5.7 路径包含空格

```bat
baiduud u -lu "D:\my upload" -bu "/resources/upload temp"
baiduud d -ld "D:\my download" -bd "/resources/upload temp"
```

### 5.8 只覆盖一个默认值

```bat
baiduud u -lu D:\another\upload
baiduud d -ld D:\another\download
```

此时未指定的网盘目录仍使用脚本默认值。

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

### 6.2 使用默认目录上传和下载

```bash
./baiduud.sh u
./baiduud.sh d
```

### 6.3 使用当前目录上传

```bash
./baiduud.sh u -lu ./ -bu /resources/upload_temp
```

### 6.4 指定 Linux 绝对上传目录

```bash
./baiduud.sh u -lu /data/conf/mhloctest/upload -bu /resources/upload_temp
```

### 6.5 下载到当前目录

```bash
./baiduud.sh d -ld ./ -bd /resources/upload_temp
```

### 6.6 指定 Linux 绝对下载目录

```bash
./baiduud.sh d -ld /data/conf/mhloctest/download -bd /resources/upload_temp
```

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
baiduud u -lu
baiduud d -unknown value
baiduud help extra
```

常见错误含义：

- `参数 -lu 缺少目录值`：选项后没有目录。
- `参数 -ld 仅适用于下载操作 d`：上传命令使用了下载参数。
- `未知参数`：参数拼写错误。
- `help 后面不能再添加其他参数`：帮助操作必须单独使用。

## 八、上传执行流程

1. 解析操作和目录覆盖参数。
2. 检查 `baiducmd` 是否位于 `PATH`。
3. 自动创建本地上传目录。
4. 创建网盘上传目录，并用 `ls -l` 验证可访问。
5. 本地目录为空时记录警告并正常结束。
6. 网盘上传目录非空时删除其中全部内容。
7. 删除后重新检查；仍非空则取消上传。
8. 逐项上传本地顶层文件和子目录。
9. 上传后比较本地与网盘顶层项目数量。

顶层数量校验不能代替内容哈希校验。重要数据建议另外保存校验值和本地备份。

## 九、下载执行流程

1. 解析操作和目录覆盖参数。
2. 自动创建本地下载目录。
3. 创建并验证网盘下载目录。
4. 网盘目录为空时正常结束。
5. 使用 `--saveto` 下载到本地目录。
6. 使用 `--ow` 覆盖本地同名文件。

下载不会删除本地目录中仅存在于本地的文件。

## 十、日志与排错

日志同时显示在控制台，并追加写入脚本目录下的 `baiduud.log`。

```text
[2026-07-15 10:58:22] [信息] 本地上传目录：./relative-upload
[2026-07-15 10:58:22] [警告] 网盘上传目录非空，开始删除目录中的现有内容。
[2026-07-15 10:58:22] [错误] 参数 -lu 缺少目录值。
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

### Linux Permission denied

`baiduud.sh` 必须保存为 UTF-8 无 BOM 编码和 LF 换行，避免脚本首行或命令参数中出现不可见字符。

```bash
chmod +x docs/baiduud.sh
bash docs/baiduud.sh help
```

## 十一、维护与验证

修改脚本后至少运行：

```bat
docs\baiduud.cmd help
```

```bash
bash -n docs/baiduud.sh
docs/baiduud.sh help
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
set "ARG_ERROR="
set "NEXT_VALUE="

call :log 信息 "脚本启动，接收到的参数：%*"

rem ============================================================
rem 参数检查
rem 第一个参数必须是 u、d 或 help，后续目录参数必须成对出现。
rem ============================================================
if "%~1"=="" (
    set "ARG_ERROR=未指定操作，请使用 u、d 或 help。"
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
if /i not "%ACTION%"=="u" if /i not "%ACTION%"=="d" (
    set "ARG_ERROR=未知操作：%ACTION%。请使用 u、d 或 help。"
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

:arguments_parsed
if /i "%ACTION%"=="u" goto :validate_upload_arguments
goto :validate_download_arguments

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

:check_baiducmd
where baiducmd >nul 2>&1
if errorlevel 1 (
    call :log 错误 "未找到 baiducmd 命令，请检查安装目录和系统环境变量。"
    goto :failed
)

if /i "%ACTION%"=="u" goto :upload
goto :download

rem ============================================================
rem 上传流程
rem 1. 创建并检查本地、网盘上传目录。
rem 2. 若网盘上传目录非空，则先清空并复查。
rem 3. 上传本地目录中的所有顶层文件和子目录。
rem 4. 对比本地与网盘顶层项目数量。
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

rem 统计本地上传目录中的顶层项目数量。
set "LOCAL_COUNT=0"
for /f %%C in ('dir /b /a "%LOCAL_UPLOAD%" 2^>nul ^| find /c /v ""') do set "LOCAL_COUNT=%%C"
if "%LOCAL_COUNT%"=="0" (
    call :log 警告 "本地上传目录为空，没有需要上传的内容：%LOCAL_UPLOAD%"
    goto :succeeded
)

rem ls -l 的项目行以数字序号开头；匹配到项目行即表示网盘目录非空。
findstr /R /C:"^[ ][ ]*[0-9][0-9]*[ ]" "%REMOTE_LIST_FILE%" >nul 2>&1
if errorlevel 1 goto :remote_upload_ready

call :log 警告 "网盘上传目录非空，开始删除目录中的现有内容。"
baiducmd rm "%BAIDU_UPLOAD%/*"
call :log 信息 "删除命令已执行，正在复查网盘上传目录。"

call :list_remote "%BAIDU_UPLOAD%"
if errorlevel 1 (
    call :log 错误 "删除后无法读取网盘上传目录。"
    goto :failed
)

findstr /R /C:"^[ ][ ]*[0-9][0-9]*[ ]" "%REMOTE_LIST_FILE%" >nul 2>&1
if not errorlevel 1 (
    type "%REMOTE_LIST_FILE%"
    type "%REMOTE_LIST_FILE%" >>"%LOG_FILE%"
    call :log 错误 "网盘上传目录仍然非空，已取消上传。"
    goto :failed
)

:remote_upload_ready
call :log 信息 "网盘上传目录已就绪。"
call :log 信息 "待上传的顶层项目数量：%LOCAL_COUNT%"

pushd "%LOCAL_UPLOAD%" >nul
if errorlevel 1 (
    call :log 错误 "无法进入本地上传目录：%LOCAL_UPLOAD%"
    goto :failed
)

rem 逐项上传可以避免在网盘目录中额外生成一层 upload 文件夹。
for /f "delims=" %%I in ('dir /b /a') do (
    echo.
    call :log 信息 "正在上传：%%I"
    baiducmd upload "%%I" "%BAIDU_UPLOAD%"
)
popd

call :log 信息 "上传命令执行完毕，开始校验网盘目录。"
call :list_remote "%BAIDU_UPLOAD%"
if errorlevel 1 (
    call :log 错误 "上传后无法读取网盘上传目录。"
    goto :failed
)

set "REMOTE_COUNT=0"
for /f %%C in ('findstr /R /C:"^[ ][ ]*[0-9][0-9]*[ ]" "%REMOTE_LIST_FILE%" ^| find /c /v ""') do set "REMOTE_COUNT=%%C"
if not "%REMOTE_COUNT%"=="%LOCAL_COUNT%" (
    type "%REMOTE_LIST_FILE%"
    type "%REMOTE_LIST_FILE%" >>"%LOG_FILE%"
    call :log 错误 "上传校验失败。本地顶层项目：%LOCAL_COUNT%，网盘顶层项目：%REMOTE_COUNT%。"
    goto :failed
)

call :log 信息 "上传完成，已校验 %REMOTE_COUNT% 个顶层项目。"
goto :succeeded

rem ============================================================
rem 下载流程
rem 1. 创建并检查本地、网盘下载目录。
rem 2. 网盘目录为空时正常结束。
rem 3. 下载网盘目录中的内容，并覆盖本地同名文件。
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

findstr /R /C:"^[ ][ ]*[0-9][0-9]*[ ]" "%REMOTE_LIST_FILE%" >nul 2>&1
if errorlevel 1 (
    call :log 警告 "网盘下载目录为空，没有需要下载的内容。"
    goto :succeeded
)

call :log 信息 "开始下载，已启用同名文件覆盖选项。"
echo.
baiducmd download --ow --saveto "%LOCAL_DOWNLOAD%" "%BAIDU_DOWNLOAD%/*"
if errorlevel 1 (
    call :log 错误 "下载命令返回失败状态。"
    goto :failed
)

call :log 信息 "下载命令执行完成。"
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
echo   baiduud u [-lu 本地上传目录] [-bu 网盘上传目录]
echo   baiduud d [-ld 本地下载目录] [-bd 网盘下载目录]
echo.
echo 操作：
echo   help  显示本帮助信息，不执行上传或下载。
echo   u     上传本地目录中的内容。
echo   d     下载网盘目录中的内容。
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
echo.
echo 规则：
echo   1. 操作 u、d 或 help 必须放在第一个参数。
echo   2. 目录包含空格时必须使用双引号包围。
echo   3. 相对路径以执行命令时的当前目录为基准。
echo   4. 同一目录参数重复出现时，最后一个值生效。
echo   5. u 不能使用 -ld/-bd，d 不能使用 -lu/-bu。
echo   6. 上传会先清空百度网盘上传目录，请确认 -bu 配置正确。
echo.
echo 完整案例：
echo   baiduud help
echo   baiduud u
echo   baiduud d
echo   baiduud u -lu ./ -bu /resources/upload_temp
echo   baiduud u -lu D:\conf\mhloctest\upload -bu /resources/upload_temp
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
ARG_ERROR=""

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
    printf '  ./baiduud.sh u [-lu 本地上传目录] [-bu 网盘上传目录]\n'
    printf '  ./baiduud.sh d [-ld 本地下载目录] [-bd 网盘下载目录]\n'
    printf '\n'
    printf '操作：\n'
    printf '  help  显示本帮助信息，不执行上传或下载。\n'
    printf '  u     上传本地目录中的内容。\n'
    printf '  d     下载网盘目录中的内容。\n'
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
    printf '\n'
    printf '规则：\n'
    printf '  1. 操作 u、d 或 help 必须放在第一个参数。\n'
    printf '  2. 目录包含空格时必须使用引号包围。\n'
    printf '  3. 相对路径以执行命令时的当前目录为基准。\n'
    printf '  4. 同一目录参数重复出现时，最后一个值生效。\n'
    printf '  5. u 不能使用 -ld/-bd，d 不能使用 -lu/-bu。\n'
    printf '  6. 上传会先清空百度网盘上传目录，请确认 -bu 配置正确。\n'
    printf '\n'
    printf '完整案例：\n'
    printf '  baiduud help\n'
    printf '  ./baiduud.sh help\n'
    printf '  ./baiduud.sh u\n'
    printf '  ./baiduud.sh d\n'
    printf '  ./baiduud.sh u -lu ./ -bu /resources/upload_temp\n'
    printf '  ./baiduud.sh u -lu /data/conf/mhloctest/upload -bu /resources/upload_temp\n'
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
                ARG_ERROR="上传操作 u 只能使用 -lu 和 -bu。"
                return 1
            fi
            ;;
        d | D)
            if ((USED_LU == 1 || USED_BU == 1)); then
                ARG_ERROR="下载操作 d 只能使用 -ld 和 -bd。"
                return 1
            fi
            ;;
        *)
            ARG_ERROR="未知操作：${ACTION}。请使用 u、d 或 help。"
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

# ============================================================
# 上传流程
# 1. 创建并检查本地、网盘上传目录。
# 2. 若网盘上传目录非空，则先清空并复查。
# 3. 上传本地目录中的所有顶层文件、隐藏文件和子目录。
# 4. 对比本地与网盘顶层项目数量。
# ============================================================
upload_main() {
    local -a local_items=()
    local item
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

    local_count="${#local_items[@]}"
    if ((local_count == 0)); then
        log "警告" "本地上传目录为空，没有需要上传的内容：${LOCAL_UPLOAD}"
        return 0
    fi

    if remote_has_items; then
        log "警告" "网盘上传目录非空，开始删除目录中的现有内容。"
        baiducmd rm "${BAIDU_UPLOAD}/*"
        log "信息" "删除命令已执行，正在复查网盘上传目录。"

        if ! list_remote "$BAIDU_UPLOAD"; then
            log "错误" "删除后无法读取网盘上传目录。"
            return 1
        fi

        if remote_has_items; then
            tee -a "$LOG_FILE" <"$REMOTE_LIST_FILE"
            log "错误" "网盘上传目录仍然非空，已取消上传。"
            return 1
        fi
    fi

    log "信息" "网盘上传目录已就绪。"
    log "信息" "待上传的顶层项目数量：${local_count}"

    # 逐项上传，避免在网盘目录中额外生成一层 upload 文件夹。
    for item in "${local_items[@]}"; do
        printf '\n'
        log "信息" "正在上传：$(basename -- "$item")"
        baiducmd upload "$item" "$BAIDU_UPLOAD"
    done

    log "信息" "上传命令执行完毕，开始校验网盘目录。"
    if ! list_remote "$BAIDU_UPLOAD"; then
        log "错误" "上传后无法读取网盘上传目录。"
        return 1
    fi

    remote_count="$(remote_item_count)"
    if [[ "$remote_count" != "$local_count" ]]; then
        tee -a "$LOG_FILE" <"$REMOTE_LIST_FILE"
        log "错误" "上传校验失败。本地顶层项目：${local_count}，网盘顶层项目：${remote_count}。"
        return 1
    fi

    log "信息" "上传完成，已校验 ${remote_count} 个顶层项目。"
}

# ============================================================
# 下载流程
# 1. 创建并检查本地、网盘下载目录。
# 2. 网盘目录为空时正常结束。
# 3. 下载网盘目录中的内容，并覆盖本地同名文件。
# ============================================================
download_main() {
    log "信息" "进入下载流程。"
    log "信息" "网盘下载目录：${BAIDU_DOWNLOAD}"
    log "信息" "本地下载目录：${LOCAL_DOWNLOAD}"

    ensure_local_dir "$LOCAL_DOWNLOAD" || return 1
    ensure_remote_dir "$BAIDU_DOWNLOAD" || return 1

    if ! remote_has_items; then
        log "警告" "网盘下载目录为空，没有需要下载的内容。"
        return 0
    fi

    log "信息" "开始下载，已启用同名文件覆盖选项。"
    printf '\n'
    if ! baiducmd download --ow --saveto "$LOCAL_DOWNLOAD" "${BAIDU_DOWNLOAD}/*"; then
        log "错误" "下载命令返回失败状态。"
        return 1
    fi

    log "信息" "下载命令执行完成。"
}

main() {
    if ! touch "$LOG_FILE" 2>/dev/null; then
        printf '错误：无法创建或写入日志文件：%s\n' "$LOG_FILE" >&2
        return 1
    fi

    log "信息" "脚本启动，接收到的参数：$*"

    if (($# == 0)); then
        ARG_ERROR="未指定操作，请使用 u、d 或 help。"
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

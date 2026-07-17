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
if errorlevel 1 goto :failed
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
if errorlevel 1 goto :failed
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

rem baiducmd 重定向的目录列表是 UTF-8；先转换为 GBK，再交给 CMD 解析中文名称。
:list_remote
if defined REMOTE_LIST_FILE del /q "%REMOTE_LIST_FILE%" >nul 2>&1
set "REMOTE_LIST_FILE=%TEMP%\baiduud_%RANDOM%_%RANDOM%.tmp"
baiducmd ls -l "%~1" >"%REMOTE_LIST_FILE%" 2>&1
set "BAIDUUD_UTF8_LIST_FILE=%REMOTE_LIST_FILE%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';$p=$env:BAIDUUD_UTF8_LIST_FILE;$u=[Text.UTF8Encoding]::new($false,$true);$t=[IO.File]::ReadAllText($p,$u);[IO.File]::WriteAllText($p,$t,[Text.Encoding]::GetEncoding(936))" >nul 2>&1
set "LIST_ENCODING_ERROR=%ERRORLEVEL%"
set "BAIDUUD_UTF8_LIST_FILE="
if not "%LIST_ENCODING_ERROR%"=="0" (
    set "LIST_ENCODING_ERROR="
    call :log 错误 "无法解析网盘目录列表：客户端输出不是有效的 UTF-8。"
    exit /b 1
)
set "LIST_ENCODING_ERROR="

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
if not exist "%~dp0baiduud-table.ps1" goto :table_helper_missing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0baiduud-table.ps1"
if errorlevel 1 goto :table_render_failed
echo.
exit /b 0

:table_helper_missing
call :log 错误 "缺少终端表格辅助脚本：%~dp0baiduud-table.ps1"
exit /b 1

:table_render_failed
call :log 错误 "无法生成网盘项目终端表格，请检查 baiduud-table.ps1。"
exit /b 1

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

# AGENTS.md

本文件基于仓库 `D:\software\workspace3\BaiduPCS-Go-wulin` 在 2026-06-04 的实际状态整理，目标是帮助后续协作者或智能体快速理解项目结构、构建链路、Windows 资源来源和常见修改入口。

## 1. 项目概览

- 项目类型: Go 命令行应用
- 模块名: `github.com/qjfoidnh/BaiduPCS-Go`
- Go 版本: `go 1.23`（见 `go.mod`）
- 应用定位: 百度网盘命令行客户端，支持登录、配额查询、目录浏览、下载、上传、转存、分享、离线下载、回收站、配置管理等能力
- 入口文件: `main.go`
- CLI 框架: `github.com/urfave/cli` v1

当前仓库是 `BaiduPCS-Go` 的延续版本，README 中明确说明此分支是在原版 `iikira/BaiduPCS-Go v3.6.2` 基础上继续开发，并增加了转存等后续能力。

## 2. 代码结构总览

### 顶层关键文件

- `main.go`
  - 应用主入口
  - 初始化配置
  - 构建 `urfave/cli` 应用
  - 注册全部顶级命令与子命令
  - 实现无参数启动时的交互式 shell 模式
- `go.mod` / `go.sum`
  - 模块依赖声明
- `README.md`
  - 用户向使用文档，包含命令说明、配置项说明、编译/交叉编译说明、版本更新记录
- `build.sh`
  - 旧版多平台发布脚本，负责批量构建、打包 zip、生成 Windows 资源
- `versioninfo.json`
  - Windows 可执行文件版本信息、图标路径、manifest 路径定义
- `resource_windows_386.syso`
  - 已提交到仓库的 Windows 32 位资源对象文件
- `resource_windows_amd64.syso`
  - 已提交到仓库的 Windows 64 位资源对象文件
- `BaiduPCS-Go.exe.manifest`
  - Windows manifest 资源

### 主要目录职责

- `baidupcs/`
  - 百度 PCS / Pan 接口封装核心层
  - 包含文件管理、上传、下载直链、分享、转存、回收站、配额、错误码处理、签名逻辑等
  - 如果问题是“某个百度网盘接口行为变了”，大概率从这里开始排查

- `internal/pcscommand/`
  - CLI 命令执行层
  - `main.go` 中的命令最终会调用这里的运行函数
  - 这里负责把命令行参数组织成业务调用
  - 典型例子:
    - `download.go`: 下载命令调度
    - `upload.go`: 上传命令调度
    - `share.go`: 分享命令
    - `transfer.go`: 转存命令
    - `login.go`: 登录逻辑

- `internal/pcsfunctions/`
  - 较底层的任务功能层
  - 目前主要有:
    - `pcsdownload/`: 下载任务单元、统计、链接处理、校验逻辑
    - `pcsupload/`: 上传任务单元、上传数据库、统计逻辑
    - `pcscaptcha/`: 验证码相关

- `internal/pcsconfig/`
  - 全局配置管理
  - 负责:
    - 配置文件加载和保存
    - 当前激活账户
    - 构建带配置的 HTTP client
    - 默认配置项
    - 配置目录选择
  - 这是修改配置项时的首要入口

- `internal/pcsupdate/`
  - 在线更新逻辑
  - 通过 GitHub Releases API 拉取最新 release
  - 注意它依赖特定的发布文件命名规则，见本文“发布与命名注意事项”

- `internal/pcsinit/`
  - CLI 帮助模板定制
  - 通过 `go:linkname` 改写 `urfave/cli` 内部 help command
  - 这里非常脆弱，非必要不要轻易改

- `requester/`
  - 通用网络与传输层
  - 包含:
    - `http_client.go`: HTTP client 与 transport 参数
    - `downloader/`: 下载器实现
    - `uploader/`: 上传器实现
    - `rio/`: Range I/O 与限速
    - `transfer/`: 传输状态、proto 定义
    - `multipartreader/`: multipart 读入
  - 如果问题涉及超时、代理、本地网卡、并发、分块、限速、断点续传，优先看这里

- `pcsliner/`
  - 交互式命令行体验
  - 包括命令历史、屏幕清理、参数解析、自动补全配合逻辑

- `pcstable/`
  - 表格输出封装

- `pcsutil/`
  - 大量通用工具
  - 覆盖校验和、路径转换、缓存池、时间、转换器、等待组、文件工具等

- `pcsverbose/`
  - 调试日志输出
  - 通过环境变量 `BAIDUPCS_GO_VERBOSE=1` 打开

- `docs/`
  - 百度 PCS 接口文档和仓库说明文档

- `assets/`
  - 图标与图片资源
  - 当前 Windows 主图标资源来自这里，详见后文

- `cmd/AndroidNDKBuild/`
  - Android NDK 构建辅助入口

- `debian/`
  - Debian / iOS 打包控制文件

## 3. 运行时架构

### CLI 启动路径

1. `main.go:init()`
   - 调用 `pcsutil.ChWorkDir()`
   - 初始化全局配置 `pcsconfig.Config.Init()`
2. `main.go:main()`
   - 创建 `cli.NewApp()`
   - 设置全局 flag、帮助文本、版本信息
   - 注册所有命令
   - 执行 `app.Run(os.Args)`
3. 若用户不带参数运行
   - 进入交互式 shell
   - 通过 `pcsliner` 处理命令历史和自动补全

### 配置与账户模型

- 配置结构体: `internal/pcsconfig/pcsconfig.go` 中的 `PCSConfig`
- 当前激活用户:
  - `Config.ActiveUser()`
  - `Config.ActiveUserBaiduPCS()`
- 配置文件名固定为:
  - `pcs_config.json`

### 默认配置目录

- 若设置了环境变量 `BAIDUPCS_GO_CONFIG_DIR`
  - 优先使用该目录
  - 若是相对路径，则相对可执行文件目录解析
- 否则:
  - 若程序目录已有旧版 `pcs_config.json`
    - 继续沿用程序目录
  - Windows:
    - `%APPDATA%\BaiduPCS-Go`
  - 其他系统:
    - `$HOME/.config/BaiduPCS-Go`

### 默认下载目录

- Windows:
  - 可执行文件所在目录下的 `Downloads`
- Android:
  - `/sdcard/Download`
- 其他系统:
  - `$HOME/Downloads`

这点很重要，因为它不是默认写到当前工作目录，而是偏向程序目录或用户下载目录。

## 4. 命令层修改原则

如果要新增或修改一个 CLI 命令，通常遵循下面的分层：

1. 在 `main.go` 中注册命令、flag、帮助文本
2. 在 `internal/pcscommand/` 中新增或修改对应运行函数
3. 若涉及复杂下载/上传任务，继续下沉到:
   - `internal/pcsfunctions/`
   - `requester/`
   - `baidupcs/`
4. 若涉及配置项，再补:
   - `internal/pcsconfig/pcsconfig.go`
   - `internal/pcsconfig/export.go`
   - `README.md` 的配置说明

一个经验规则:

- “命令行参数解析/输出格式问题”优先看 `main.go` 与 `internal/pcscommand`
- “百度接口请求/返回行为问题”优先看 `baidupcs`
- “并发下载/上传/断点续传/限速问题”优先看 `requester`
- “配置未生效”优先看 `internal/pcsconfig`

## 5. 下载与上传主链路

### 下载链路

- 命令入口:
  - `main.go` 中下载命令
- 命令执行:
  - `internal/pcscommand/download.go`
- 任务单元:
  - `internal/pcsfunctions/pcsdownload/`
- 底层下载器:
  - `requester/downloader/`
- 传输状态:
  - `requester/transfer/`

当前下载命令有几项仓库级行为值得注意:

- 默认并发、缓存、限速都从 `pcsconfig.Config` 取值
- Windows 平台下载不会附加执行权限
- 下载队列会按文件大小排序，小文件优先
- 断点续传状态存储格式默认是 proto3

### 上传链路

- 命令入口:
  - `main.go` 中上传命令
- 命令执行:
  - `internal/pcscommand/upload.go`
- 任务单元:
  - `internal/pcsfunctions/pcsupload/`
- 底层上传器:
  - `requester/uploader/`

当前上传链路的重要行为:

- 支持同名文件策略:
  - `skip`
  - `overwrite`
  - `rsync`
- 上传中的数据库文件名:
  - `pcs_uploading.json`
- 上传前会做本地路径遍历和文件名合法性判断

## 6. 构建与打包

### 当前仓库存在两套构建/命名体系

这点非常重要，后续改构建脚本时不要混淆。

#### A. 当前 GitHub Actions CI 体系

文件:

- `.github/workflows/main.yml`

行为:

- 构建矩阵:
  - `linux`, `windows`, `darwin`
  - 架构含 `386`, `amd64`, `arm`, `arm64`
- 构建输出目录:
  - `output/`
- 输出命名规则:
  - `baidupcs-go_${GOOS}_${GOARCH}`
  - Windows 追加 `.exe`

因此，当前 CI 中 Windows 386 的精确产物名是:

- `output/baidupcs-go_windows_386.exe`

不是 `baidupcs-go_386.exe`。

如果你看到 `baidupcs-go_386.exe`，那不是当前仓库里明确写死的官方命名规则，至少在本仓库现有脚本和 workflow 中没有找到该名字。

#### B. 旧版 `build.sh` 发布体系

文件:

- `build.sh`

Windows 386 的旧构建链路是:

1. 生成资源:
   - `goversioninfo -o=resource_windows_386.syso`
2. 编译:
   - 输出到 `out/BaiduPCS-Go-<version>-windows-x86/BaiduPCS-Go.exe`
3. 打 zip:
   - 最终 zip 名为 `out/BaiduPCS-Go-<version>-windows-x86.zip`

对应 64 位则是:

- `out/BaiduPCS-Go-<version>-windows-x64.zip`

### 推荐理解

- 如果你看的是现在的 CI 构建产物，Windows 32 位名是:
  - `baidupcs-go_windows_386.exe`
- 如果你看的是旧发布脚本打包结果，Windows 32 位包路径是:
  - `BaiduPCS-Go-<version>-windows-x86.zip`
  - 包内主程序名是 `BaiduPCS-Go.exe`

### 当前 CI 与旧脚本的差异风险

1. CI 不会调用 `build.sh`
2. CI 直接 `go build`
3. CI 命名规则与在线更新逻辑期望的 release zip 命名不同
4. 旧脚本会通过 `-ldflags "-X main.Version=$version"` 注入版本号
5. 当前 CI 只设置了 `-w -s`，没有把 release version 注入 `main.Version`

这意味着:

- 运行时 `app.Version` 可能仍显示 `main.go` 里的默认值 `v4.0.1-dev`
- Windows 文件资源版本号则可能继续来自已提交的 `.syso`
- 如果做正式发布，要同时留意:
  - `main.go` 中的 `Version`
  - `versioninfo.json`
  - `resource_windows_*.syso`
  - GitHub Release 资产命名
  - 在线更新匹配规则

## 7. Windows 图标与资源来源

### 直接结论

当前 Windows 可执行文件图标使用的源资源是:

- `assets/BaiduPCS-Go.ico`

### 证据链

1. `versioninfo.json` 中明确声明:
   - `"IconPath": "assets/BaiduPCS-Go.ico"`
   - `"ManifestPath": "BaiduPCS-Go.exe.manifest"`
2. `build.sh` 在 Windows 构建前执行:
   - `goversioninfo -o=resource_windows_386.syso`
   - `goversioninfo -64 -o=resource_windows_amd64.syso`
3. Go 在 Windows 构建时会把匹配架构的 `.syso` 一并链接进最终 exe

因此，Windows 图标链路是:

`assets/BaiduPCS-Go.ico`
-> `versioninfo.json`
-> `resource_windows_386.syso` / `resource_windows_amd64.syso`
-> 最终 Windows `.exe`

### 当前仓库中与图标相关的文件

- `assets/BaiduPCS-Go.ico`
  - 当前主图标源文件
- `assets/BaiduPCS-Go_bak1.ico`
  - 备份/历史图标文件，当前没有发现被构建脚本引用
- `BaiduPCS-Go.exe.manifest`
  - Windows manifest
- `resource_windows_386.syso`
  - 32 位资源对象文件
- `resource_windows_amd64.syso`
  - 64 位资源对象文件

### 修改 Windows 图标时必须同步的内容

如果要更换 Windows 图标，不要只替换 `assets/BaiduPCS-Go.ico`，还要重新生成 `.syso`:

- `goversioninfo -o=resource_windows_386.syso`
- `goversioninfo -64 -o=resource_windows_amd64.syso`

否则 CI 或本地 `go build` 仍可能继续使用旧的已提交资源对象文件。

## 8. 发布与在线更新注意事项

在线更新逻辑在:

- `internal/pcsupdate/pcsupdate.go`

它会访问:

- `https://api.github.com/repos/qjfoidnh/BaiduPCS-Go/releases/latest`

并用正则匹配 release 资产名，模式形如:

- `BaiduPCS-Go-<tag>-windows-x86.zip`
- `BaiduPCS-Go-<tag>-windows-x64.zip`
- 以及对应平台变体

也就是说，在线更新逻辑当前是按旧版 release zip 命名规则设计的，不是按 `.github/workflows/main.yml` 里的 `baidupcs-go_windows_386.exe` 产物名设计的。

如果未来要统一发布链路，需要同时改这些地方:

1. `.github/workflows/main.yml`
2. `build.sh`
3. `internal/pcsupdate/pcsupdate.go`
4. 可能还包括 README 中的构建/下载说明

## 9. 测试现状

当前仓库已有的测试主要集中在底层工具和传输组件，不在 CLI 外层。

### 已有测试分布

- `requester/uploader/block_test.go`
- `requester/rio/speeds/ratelimit_test.go`
- `requester/rio/multi_test.go`
- `requester/downloader/download_test.go`
- `requester/downloader/range_test.go`
- `baidupcs/netdisksign/*.go` 对应测试
- `baidupcs/expires/cachemap/cachemap_test.go`
- `pcsutil/*` 下多组工具测试
- `pcsliner/args/args_test.go`

### 缺口

- `main.go` 的命令注册没有系统化测试
- `internal/pcscommand/` 大部分命令逻辑缺少直接测试
- 发布命名和资源链路缺少自动校验

### 建议验证命令

如果本机已安装 Go，优先执行:

```powershell
go test ./...
```

如果只验证 Windows 32 位构建:

```powershell
$env:GOOS="windows"
$env:GOARCH="386"
$env:CGO_ENABLED="0"
go build -o output/baidupcs-go_windows_386.exe .
```

如果只是常规本机构建:

```powershell
go build .
```

## 10. 当前仓库的几个高风险点

### 10.1 `internal/pcsinit` 的 `go:linkname`

这里通过 `go:linkname` 直接绑定 `urfave/cli` 的内部 help command。

风险:

- 升级 `urfave/cli` 时容易失效
- 没有 vendor 目录的情况下仍依赖兼容写法
- 若 help 行为异常，这里是首查点

### 10.2 `build.sh` 偏旧

它依赖若干外部工具或前置条件:

- `goversioninfo`
- `zip`
- `RicePack`
- 某些历史目录或工具链

同时脚本里 `RicePack()` 目前直接 `return`，说明 web 资源打包已停用。

结论:

- 把它当“历史发布脚本”更合适
- 若要恢复为主发布入口，需要重新校正和验证

### 10.3 版本号可能分裂

当前至少有三处与版本有关:

- `main.go`
  - 默认 `Version = "v4.0.1-dev"`
- `versioninfo.json`
  - `FileVersion` / `ProductVersion` / `StringFileInfo.FileVersion`
- `build.sh`
  - 通过 ldflags 动态注入 `main.Version`

正式发布时必须同步检查，避免:

- 程序内显示一个版本
- Windows 文件属性显示另一个版本
- release tag 再是第三个版本

### 10.4 Windows 资源文件是“已编译产物”

`resource_windows_386.syso` 与 `resource_windows_amd64.syso` 不是源码说明文件，而是已经编译好的资源对象。

这意味着:

- 改 `versioninfo.json` 之后不会自动生效
- 改 `assets/BaiduPCS-Go.ico` 之后不会自动生效
- 需要重新生成 `.syso`

## 11. 推荐修改路径速查

### 想改命令行帮助/命令定义

- 先看 `main.go`
- 若是帮助模板，再看 `internal/pcsinit/pcsinit.go`

### 想新增配置项

- `internal/pcsconfig/pcsconfig.go`
- `internal/pcsconfig/export.go`
- `main.go` 中 `config` 命令相关 flag
- `README.md`

### 想改下载行为

- `internal/pcscommand/download.go`
- `internal/pcsfunctions/pcsdownload/`
- `requester/downloader/`
- `requester/transfer/`

### 想改上传行为

- `internal/pcscommand/upload.go`
- `internal/pcsfunctions/pcsupload/`
- `requester/uploader/`

### 想改百度接口参数或请求头

- `baidupcs/`
- `requester/http_client.go`
- `internal/pcsconfig/export.go`

### 想改 Windows 图标/文件属性/manifest

- `versioninfo.json`
- `assets/BaiduPCS-Go.ico`
- `BaiduPCS-Go.exe.manifest`
- 然后重新生成:
  - `resource_windows_386.syso`
  - `resource_windows_amd64.syso`

## 12. 对后续协作者的实际建议

1. 不要把当前 CI 产物名和旧版 release zip 命名当成一回事。
2. 不要修改 Windows 图标后忘记重生成 `.syso`。
3. 不要只改 `main.go` 的 `Version` 就认为发布版本已经同步。
4. 新增 CLI 功能时，尽量保持 `main.go -> internal/pcscommand -> internal/pcsfunctions/requester/baidupcs` 这种分层，不要把所有逻辑堆回 `main.go`。
5. 如果要处理配置问题，先确认是否受 `BAIDUPCS_GO_CONFIG_DIR`、旧版配置文件位置、`APPDATA` 路径影响。
6. 如果要动 `internal/pcsupdate`，务必同时检查发布资产命名是否仍能被正则匹配。

## 13. 本仓库下与 Windows 包最相关的结论速记

- 当前 CI 的 Windows 386 产物名:
  - `baidupcs-go_windows_386.exe`
- 旧版发布脚本的 Windows 386 包:
  - `BaiduPCS-Go-<version>-windows-x86.zip`
  - 包内程序名:
    - `BaiduPCS-Go.exe`
- 当前仓库没有找到 `baidupcs-go_386.exe` 这个名字的直接定义
- 当前 Windows 主图标资源来源:
  - `assets/BaiduPCS-Go.ico`


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

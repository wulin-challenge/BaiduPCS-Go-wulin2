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

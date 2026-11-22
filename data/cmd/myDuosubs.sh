#!/usr/bin/env bash
# cat "$0"   # in lại chính file này (tương tự Get-Content $PSCommandPath)

: <<'DOC'
    Template: chạy từng dòng lệnh bên trong $SCRIPT_BLOCK (heredoc),
    show ra lệnh đang chạy -> execute -> in output, bỏ qua dòng trống & comment (#)

    Cách dùng:
      - Copy/paste các lệnh cần chạy vào giữa  <<EOF ... EOF
      - Chạy file:            ./t.tpl.sh
      - Chỉ in lệnh, ko chạy: DRY_RUN=1 ./t.tpl.sh
      - Dừng khi gặp lỗi:     STOP_ON_ERROR=1 ./t.tpl.sh

    Ghi chú heredoc:
      - <<EOF (không quote) giống heredoc PHP: $var, ${var}, $(cmd) được thay giá trị
        ngay lúc gán -> dòng in ra màn hình là lệnh ĐÃ thay biến, dễ check.
      - Muốn giữ nguyên $ để expand lúc chạy thì escape: \$HOME, \$(date)
      - Lệnh dài có thể xuống dòng bằng dấu \ cuối dòng (heredoc tự nối lại).
DOC

WORKING_DIR="/my/dl/duosubs/01"

BASENAME="p01"
primaryFilename="${BASENAME}.vi02.srt"
secondaryFilename="${BASENAME}.en.srt"
export PYTHONIOENCODING="utf-8"

SCRIPT_BLOCK=$(cat <<EOF
cd "$WORKING_DIR"
echo "Current folder: \$PWD"
# duosubs merge -p "$primaryFilename" -s "$secondaryFilename" --mode mixed --model LaBSE --device cpu --format-all srt --output-name "$BASENAME-duosubs"
duosubs merge -p "$primaryFilename" -s "$secondaryFilename" --mode synced --model LaBSE --device cuda --format-all srt --output-name "$BASENAME-duosubs"
EOF
)

invoke_script_block_lines() {
    local block="$1"
    local line rc
    local cyan=$'\e[36m' red=$'\e[31m' yellow=$'\e[33m' reset=$'\e[0m'

    while IFS= read -r -u 3 line || [[ -n "$line" ]]; do
        # Trim khoảng trắng 2 đầu (và \r nếu file lưu kiểu CRLF)
        line="${line%$'\r'}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Bỏ qua dòng trống hoặc dòng comment (#)
        [[ -z "$line" || "$line" == \#* ]] && continue

        echo
        echo "${cyan}>> ${line}${reset}"

        # Check syntax trước khi chạy
        if ! bash -n -c "$line" 2>/dev/null; then
            echo "${red}!! Syntax error:${reset}"
            bash -n -c "$line" 2>&1 | sed 's/^/   /'
            [[ -n "$STOP_ON_ERROR" ]] && return 1
            continue
        fi

        [[ -n "$DRY_RUN" ]] && { echo "${yellow}   (dry-run, bỏ qua)${reset}"; continue; }

        # Chạy trong shell hiện tại -> cd, export... có hiệu lực cho các dòng sau
        eval "$line"
        rc=$?
        if (( rc != 0 )); then
            echo "${red}!! Error: exit code ${rc}${reset}"
            [[ -n "$STOP_ON_ERROR" ]] && return "$rc"
        fi
    done 3<<< "$block"   # đọc qua fd 3 để stdin vẫn dành cho lệnh (mpv, read...)
}

invoke_script_block_lines "$SCRIPT_BLOCK"

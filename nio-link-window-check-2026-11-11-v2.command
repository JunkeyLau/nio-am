#!/bin/sh
set -eu

package=air.nioam.music.test
if [ "$#" -gt 0 ]; then
    package=$1
fi
case "$package" in
    ''|*[!a-zA-Z0-9_.]*)
        echo '请传入有效的 Android 应用包名。'
        exit 1
        ;;
esac

adb=$(command -v adb || true)
if [ -z "$adb" ]; then
    for candidate in /opt/homebrew/share/android-commandlinetools/platform-tools/adb "$HOME/Library/Android/sdk/platform-tools/adb"; do
        if [ -x "$candidate" ]; then
            adb=$candidate
            break
        fi
    done
fi
if [ -z "$adb" ]; then
    echo '找不到 Android 调试工具 adb。'
    exit 1
fi
if ! "$adb" -d get-state >/dev/null 2>&1; then
    echo '请用 USB 数据线连接 NIO Phone，开启 USB 调试，并在手机上允许这台 Mac 调试。'
    exit 1
fi

# Read Android window state while the selected app is visible.
display_dump=$("$adb" -d shell dumpsys -t 8 window displays 2>/dev/null || true)
if ! window_dump=$("$adb" -d shell dumpsys -t 8 window -a "$package" 2>/dev/null); then
    echo '手机窗口信息读取失败。请检查 USB 连接后重试。'
    exit 1
fi

printf '%s\n' "$display_dump" "$window_dump" | /usr/bin/awk -v package="$package" '
    function size(field, points, width, height) {
        sub(/^[^=]*=/, "", field)
        if (field !~ /^\[-?[0-9]+,-?[0-9]+\]\[-?[0-9]+,-?[0-9]+\]$/) return "?"
        split(field, points, /[^0-9-]+/)
        width = points[4] - points[2]
        height = points[5] - points[3]
        if (width <= 0 || height <= 0) return "?"
        return width "x" height
    }
    $1 == "Display:" && $2 ~ /^mDisplayId=[0-9]+$/ {
        display = substr($2, length("mDisplayId=") + 1)
    }
    $1 ~ /^init=/ {
        for (i = 2; i <= NF; i++)
            if ($i ~ /^cur=[0-9]+x[0-9]+$/) displays[display] = substr($i, 5)
    }
    $1 == "Window" && $2 ~ /^#[0-9]+$/ {
        target = index($0, " " package "/") != 0
        window_display = "?"
        ready = 0
    }
    target && $1 ~ /^mDisplayId=[0-9]+$/ {
        window_display = substr($1, length("mDisplayId=") + 1)
    }
    target && $1 == "mHasSurface=true" && $2 == "isReadyForDisplay()=true" { ready = 1 }
    target && ready && $1 == "Frames:" {
        parent = display_frame = frame = "?"
        for (i = 2; i <= NF; i++) {
            if ($i ~ /^parent=/) parent = size($i)
            if ($i ~ /^display=/) display_frame = size($i)
            if ($i ~ /^frame=/) frame = size($i)
        }
        if (frame != "?") {
            printf "显示编号 %s | 逻辑屏幕 %s | 显示区域 %s | 父窗口 %s | 应用窗口 %s（像素）\n",
                window_display, (window_display in displays ? displays[window_display] : "?"),
                display_frame, parent, frame
            found = 1
        }
    }
    END {
        if (!found) {
            print "没有读到 该应用的可见窗口。请保持主界面显示，收起键盘或弹窗后重试。"
            exit 1
        }
    }
'

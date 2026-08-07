#!/bin/bash
# 验证 Flutter 页面：临时改初始页 → 构建 → 运行 → 截图 → 恢复
# 用法: ./verify_page.sh <页面索引 0-4> <输出文件名>
set -e

PAGE_INDEX=${1:-0}
OUTPUT=${2:-/tmp/verify_page.png}
PROJECT=/home/shengtudai/hua_todo_apk
MAIN=$PROJECT/lib/main.dart

# 1. 临时改初始页
sed -i "s/int _currentPage = [0-9];/int _currentPage = $PAGE_INDEX;/" "$MAIN"

# 2. 构建
export PATH="/tmp/flutter/bin:$PATH"
cd "$PROJECT"
flutter build linux --release 2>&1 | tail -2

# 3. 杀掉旧进程，重启
pkill -f "bundle/hua_todo_apk" 2>/dev/null || true
sleep 1
DISPLAY=:99 "$PROJECT/build/linux/x64/release/bundle/hua_todo_apk" &>/dev/null &
sleep 8

# 4. 截图
DISPLAY=:99 xwd -silent -root -out /tmp/verify_tmp.xwd
convert /tmp/verify_tmp.xwd "$OUTPUT"
echo "截图: $OUTPUT"

# 5. 恢复初始页
sed -i "s/int _currentPage = [0-9];/int _currentPage = 0;/" "$MAIN"
echo "已恢复初始页"
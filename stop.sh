#!/bin/bash
# AlphaBot 一键停止脚本

echo "🛑 正在停止 AlphaBot..."
cd /Users/mima0000/alphabot
docker-compose down

if [ $? -eq 0 ]; then
    echo "✅ 已停止"
else
    echo "❌ 停止失败"
fi

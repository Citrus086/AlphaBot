#!/bin/bash
# AlphaBot 一键启动脚本

echo "🚀 正在启动 AlphaBot..."
cd /Users/mima0000/alphabot

# 检查 Docker
docker-compose up -d

if [ $? -eq 0 ]; then
    echo "✅ 启动成功！"
    echo ""
    echo "📱 前端界面: http://localhost:3000"
    echo "📡 后端 API: http://localhost:8000/api/v1/docs"
    echo ""
    sleep 2
    open "http://localhost:3000"
else
    echo "❌ 启动失败，请检查 Docker 是否运行"
fi
